import { Injectable, InternalServerErrorException, BadRequestException, ConflictException, NotFoundException } from '@nestjs/common';
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
    const limit = Math.min(f.limit ?? 20, 500);
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

    const rows        = data ?? [];
    const docCodes    = [...new Set(rows.map((r) => r.codigo_documento as string))];
    const clientCodes = [...new Set(rows.map((r) => r.codigo_cliente as string))];

    const [{ data: documentos }, { data: clientes }] = await Promise.all([
      docCodes.length
        ? this.supabase.db.from('documentos').select('codigo, abreviatura, serie').eq('codigo_empresa', f.codigoEmpresa).in('codigo', docCodes)
        : Promise.resolve({ data: [] }),
      clientCodes.length
        ? this.supabase.db.from('clientes').select('codigo, razon_social').eq('codigo_empresa', f.codigoEmpresa).in('codigo', clientCodes)
        : Promise.resolve({ data: [] }),
    ]);

    const docMap     = new Map((documentos ?? []).map((d: any) => [d.codigo as string, { abreviatura: d.abreviatura, serie: d.serie }]));
    const clienteMap = new Map((clientes ?? []).map((c: any) => [c.codigo as string, c.razon_social as string]));

    const total = count ?? 0;
    return {
      data: rows.map((r) => ({
        ...this.toCxC(r),
        abreviaturaDocumento: (docMap.get(r.codigo_documento as string) as any)?.abreviatura as string | undefined,
        serieDocumento:       (docMap.get(r.codigo_documento as string) as any)?.serie        as string | undefined,
        razonSocialCliente:  clienteMap.get(r.codigo_cliente as string),
      })),
      total,
      page,
      lastPage: Math.ceil(total / limit) || 1,
    };
  }

  async findById(id: string, codigoEmpresa: string): Promise<CuentaCobrar | null> {
    const { data, error } = await this.supabase.db
      .from('cuentas_cobrar').select('*')
      .eq('id', id).eq('codigo_empresa', codigoEmpresa).maybeSingle();
    if (error) throw new InternalServerErrorException(error.message);
    if (!data) return null;

    const [{ data: doc }, { data: cliente }] = await Promise.all([
      this.supabase.db.from('documentos').select('abreviatura, serie')
        .eq('codigo_empresa', codigoEmpresa).eq('codigo', data.codigo_documento as string).maybeSingle(),
      this.supabase.db.from('clientes').select('razon_social')
        .eq('codigo_empresa', codigoEmpresa).eq('codigo', data.codigo_cliente as string).maybeSingle(),
    ]);

    return {
      ...this.toCxC(data),
      abreviaturaDocumento: (doc as any)?.abreviatura as string | undefined,
      serieDocumento:       (doc as any)?.serie        as string | undefined,
      razonSocialCliente:  (cliente as any)?.razon_social as string | undefined,
    };
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

  async eliminarCobro(codigoEmpresa: string, cobroId: string): Promise<CuentaCobrar> {
    const { data: cobroRow, error: findErr } = await this.supabase.db
      .from('cobros')
      .select('id, cuenta_cobrar_id')
      .eq('id', cobroId)
      .eq('codigo_empresa', codigoEmpresa)
      .maybeSingle();
    if (findErr) throw new InternalServerErrorException(findErr.message);
    if (!cobroRow) throw new NotFoundException('Cobro no encontrado');

    const cuentaCobrarId = cobroRow.cuenta_cobrar_id as string;

    const { error: delErr } = await this.supabase.db
      .from('cobros').delete()
      .eq('id', cobroId).eq('codigo_empresa', codigoEmpresa);
    if (delErr) throw new InternalServerErrorException(delErr.message);

    const cxc = await this.findById(cuentaCobrarId, codigoEmpresa);
    if (!cxc) throw new InternalServerErrorException('Cuenta por cobrar no encontrada');

    const { data: restantes, error: sumErr } = await this.supabase.db
      .from('cobros')
      .select('monto')
      .eq('cuenta_cobrar_id', cuentaCobrarId)
      .eq('codigo_empresa', codigoEmpresa);
    if (sumErr) throw new InternalServerErrorException(sumErr.message);

    const nuevoMontoPagado = parseFloat(
      (restantes ?? []).reduce((s, r: any) => s + Number(r.monto), 0).toFixed(2),
    );
    const nuevoSaldo = parseFloat((cxc.montoTotal - nuevoMontoPagado).toFixed(2));

    await this.supabase.db.from('cuentas_cobrar').update({
      monto_pagado: nuevoMontoPagado,
      saldo:        nuevoSaldo,
      pendiente:    nuevoSaldo > 0,
    }).eq('id', cuentaCobrarId).eq('codigo_empresa', codigoEmpresa);

    return (await this.findById(cuentaCobrarId, codigoEmpresa)) as CuentaCobrar;
  }

  async renovar(codigoEmpresa: string, d: RenovarCxCData): Promise<CuentaCobrar[]> {
    const original = await this.findById(d.cuentaCobrarId, codigoEmpresa);
    if (!original) throw new BadRequestException('Cuenta por cobrar no encontrada');
    if (!original.pendiente) throw new BadRequestException('La cuenta ya está cancelada');
    if (!d.cuotas.length) throw new BadRequestException('Debe indicar al menos una cuota');

    await this.supabase.db.from('cuentas_cobrar').update({ pendiente: false })
      .eq('id', d.cuentaCobrarId).eq('codigo_empresa', codigoEmpresa);

    const { data: maxRow } = await this.supabase.db
      .from('cuentas_cobrar')
      .select('numero_provision')
      .eq('codigo_empresa', codigoEmpresa)
      .order('numero_provision', { ascending: false })
      .limit(1)
      .maybeSingle();
    const baseProvision = (maxRow?.numero_provision ?? 0) + 1;

    const today = new Date().toISOString().substring(0, 10);
    const totalCuotas = d.cuotas.length;

    const records = d.cuotas.map((c, i) => ({
      codigo_empresa:          codigoEmpresa,
      numero_provision:        baseProvision + i,
      numero_provision_origen: original.numeroProvision,
      tipo:                    'RENOVACION',
      codigo_documento:        original.codigoDocumento,
      numero_documento:        c.numeroLetra,
      numero_cuota:            c.numeroCuota,
      total_cuotas:            totalCuotas,
      monto_total:             c.monto,
      monto_pagado:            0,
      saldo:                   c.monto,
      interes:                 0,
      fecha_emision:           today,
      fecha_vencimiento:       c.fechaVencimiento,
      codigo_cliente:          original.codigoCliente,
      pendiente:               true,
      referencia:              'RENOVACION',
    }));

    const { data: nuevas, error } = await this.supabase.db
      .from('cuentas_cobrar').insert(records).select();
    if (error) throw new InternalServerErrorException(error.message);
    return (nuevas ?? []).map((r) => this.toCxC(r));
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
      numeroCuota: Number(r.numero_cuota ?? 1),
      totalCuotas: Number(r.total_cuotas ?? 1),
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
