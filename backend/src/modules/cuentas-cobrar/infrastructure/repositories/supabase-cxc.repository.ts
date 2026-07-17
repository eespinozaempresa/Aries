import { Injectable, InternalServerErrorException, BadRequestException, ConflictException } from '@nestjs/common';
import { SupabaseService } from '../../../../shared/infrastructure/supabase/supabase.service';
import { NumeroDocumentoService } from '../../../../shared/infrastructure/supabase/numero-documento.service';
import {
  ICxCRepository, CxCFilter, CxCListResult,
  RegistrarCobroData, RenovarCxCData,
} from '../../domain/ports/cxc.repository.port';
import { CuentaCobrar, Cobro } from '../../domain/entities/cuenta-cobrar.entity';

@Injectable()
export class SupabaseCxCRepository implements ICxCRepository {
  constructor(
    private readonly supabase: SupabaseService,
    private readonly numeracion: NumeroDocumentoService,
  ) {}

  async list(f: CxCFilter): Promise<CxCListResult> {
    const page  = f.page ?? 1;
    const limit = Math.min(f.limit ?? 20, 100);
    const from  = (page - 1) * limit;

    let q = this.supabase.db
      .from('cuentas_cobrar').select('*', { count: 'exact' })
      .eq('codigo_empresa', f.codigoEmpresa)
      .order('numero_provision', { ascending: false })
      .range(from, from + limit - 1);

    if (f.codigoCliente) q = q.eq('codigo_cliente', f.codigoCliente);
    if (f.pendiente !== undefined) q = q.eq('pendiente', f.pendiente);
    if (f.desde) q = q.gte('fecha_emision', f.desde);
    if (f.hasta) q = q.lte('fecha_emision', f.hasta);

    const { data, error, count } = await q;
    if (error) throw new InternalServerErrorException(error.message);
    const total = count ?? 0;
    return { data: (data ?? []).map(this.toCxC), total, page, lastPage: Math.ceil(total / limit) || 1 };
  }

  async findById(id: string, codigoEmpresa: string): Promise<CuentaCobrar | null> {
    const { data, error } = await this.supabase.db
      .from('cuentas_cobrar').select('*')
      .eq('id', id).eq('codigo_empresa', codigoEmpresa).maybeSingle();
    if (error) throw new InternalServerErrorException(error.message);
    return data ? this.toCxC(data) : null;
  }

  async registrarCobro(codigoEmpresa: string, d: RegistrarCobroData): Promise<Cobro> {
    const cxc = await this.findById(d.cuentaCobrarId, codigoEmpresa);
    if (!cxc) throw new BadRequestException('Cuenta por cobrar no encontrada');
    if (!cxc.pendiente) throw new BadRequestException('La cuenta ya está cancelada');
    if (d.monto > cxc.saldo) throw new BadRequestException(`Monto (${d.monto}) supera el saldo (${cxc.saldo})`);

    const { data: cobro, error } = await this.supabase.db
      .from('cobros')
      .insert({
        codigo_empresa:   codigoEmpresa,
        cuenta_cobrar_id: d.cuentaCobrarId,
        numero_recibo:    d.numeroRecibo,
        fecha:            d.fecha,
        tipo_pago:        d.tipoPago,
        numero_operacion: d.numeroOperacion ?? null,
        codigo_banco:     d.codigoBanco ?? null,
        monto:            d.monto,
        estado:           'ACTIVO',
        codigo_usuario:   d.codigoUsuario,
      })
      .select().single();
    if (error) {
      if (error.code === '23505') throw new ConflictException('Número de recibo ya existe');
      throw new InternalServerErrorException(error.message);
    }

    const nuevoMontoPagado = parseFloat((cxc.montoPagado + d.monto).toFixed(2));
    const nuevoSaldo       = parseFloat((cxc.montoTotal  - nuevoMontoPagado).toFixed(2));
    const pendiente        = nuevoSaldo > 0;

    await this.supabase.db.from('cuentas_cobrar').update({
      monto_pagado: nuevoMontoPagado,
      saldo:        nuevoSaldo,
      pendiente,
    }).eq('id', d.cuentaCobrarId).eq('codigo_empresa', codigoEmpresa);

    return this.toCobro(cobro);
  }

  async getCobros(codigoEmpresa: string, cuentaCobrarId: string): Promise<Cobro[]> {
    const { data, error } = await this.supabase.db
      .from('cobros').select('*')
      .eq('codigo_empresa', codigoEmpresa)
      .eq('cuenta_cobrar_id', cuentaCobrarId)
      .order('fecha', { ascending: false });
    if (error) throw new InternalServerErrorException(error.message);
    return (data ?? []).map(this.toCobro);
  }

  async renovar(codigoEmpresa: string, d: RenovarCxCData): Promise<CuentaCobrar> {
    const original = await this.findById(d.cuentaCobrarId, codigoEmpresa);
    if (!original) throw new BadRequestException('Cuenta por cobrar no encontrada');
    if (!original.pendiente) throw new BadRequestException('La cuenta ya está cancelada');

    // Cerrar la original
    await this.supabase.db.from('cuentas_cobrar').update({ pendiente: false })
      .eq('id', d.cuentaCobrarId).eq('codigo_empresa', codigoEmpresa);

    // Crear nueva con el saldo + interés
    const numProvStr = await this.numeracion.siguiente(codigoEmpresa, 'CXC', '0001');
    const numProv    = parseInt(numProvStr, 10);
    const interes   = d.interes ?? 0;
    const nuevoMonto = parseFloat((original.saldo + interes).toFixed(2));

    const { data: nueva, error } = await this.supabase.db
      .from('cuentas_cobrar').insert({
        codigo_empresa:           codigoEmpresa,
        numero_provision:         numProv,
        numero_provision_origen:  original.numeroProvision,
        tipo:                     'RENOVACION',
        codigo_documento:         d.codigoDocumento,
        numero_documento:         d.numeroDocumento,
        monto_total:              nuevoMonto,
        monto_pagado:             0,
        saldo:                    nuevoMonto,
        interes,
        fecha_emision:            new Date().toISOString().substring(0, 10),
        fecha_vencimiento:        d.nuevaFechaVencimiento,
        codigo_cliente:           original.codigoCliente,
        pendiente:                true,
        referencia:               `Renovación de prov. ${original.numeroProvision}`,
      }).select().single();
    if (error) throw new InternalServerErrorException(error.message);
    return this.toCxC(nueva);
  }

  private toCxC(r: Record<string, unknown>): CuentaCobrar {
    return {
      id: r.id as string,
      codigoEmpresa: r.codigo_empresa as string,
      numeroProvision: Number(r.numero_provision),
      numeroProvisionOrigen: r.numero_provision_origen ? Number(r.numero_provision_origen) : undefined,
      tipo: r.tipo as CuentaCobrar['tipo'],
      codigoDocumento: r.codigo_documento as string,
      numeroDocumento: r.numero_documento as string,
      numeroCuota: Number(r.numero_cuota),
      totalCuotas: Number(r.total_cuotas),
      montoTotal: Number(r.monto_total),
      montoPagado: Number(r.monto_pagado),
      saldo: Number(r.saldo),
      interes: Number(r.interes),
      fechaEmision: r.fecha_emision as string,
      fechaVencimiento: r.fecha_vencimiento as string | undefined,
      codigoCliente: r.codigo_cliente as string,
      descripcion: r.descripcion as string | undefined,
      pendiente: r.pendiente as boolean,
      referencia: r.referencia as string | undefined,
      createdAt: r.created_at as string | undefined,
    };
  }

  private toCobro(r: Record<string, unknown>): Cobro {
    return {
      id: r.id as string,
      codigoEmpresa: r.codigo_empresa as string,
      cuentaCobrarId: r.cuenta_cobrar_id as string,
      numeroRecibo: r.numero_recibo as string,
      fecha: r.fecha as string,
      tipoPago: r.tipo_pago as Cobro['tipoPago'],
      numeroOperacion: r.numero_operacion as string | undefined,
      codigoBanco: r.codigo_banco as string | undefined,
      monto: Number(r.monto),
      estado: r.estado as Cobro['estado'],
      codigoUsuario: r.codigo_usuario as string,
      createdAt: r.created_at as string | undefined,
    };
  }
}
