import { Injectable, InternalServerErrorException, BadRequestException, ConflictException } from '@nestjs/common';
import { SupabaseService } from '../../../../shared/infrastructure/supabase/supabase.service';
import { NumeroDocumentoService } from '../../../../shared/infrastructure/supabase/numero-documento.service';
import {
  ICxPRepository, CxPFilter, CxPListResult,
  RegistrarPagoData, RenovarCxPData,
} from '../../domain/ports/cxp.repository.port';
import { CuentaPagar, Pago } from '../../domain/entities/cuenta-pagar.entity';

@Injectable()
export class SupabaseCxPRepository implements ICxPRepository {
  constructor(
    private readonly supabase: SupabaseService,
    private readonly numeracion: NumeroDocumentoService,
  ) {}

  async list(f: CxPFilter): Promise<CxPListResult> {
    const page  = f.page ?? 1;
    const limit = Math.min(f.limit ?? 20, 500);
    const from  = (page - 1) * limit;

    let q = this.supabase.db
      .from('cuentas_pagar').select('*', { count: 'exact' })
      .eq('codigo_empresa', f.codigoEmpresa)
      .order('numero_provision', { ascending: false })
      .range(from, from + limit - 1);

    if (f.codigoProveedor) q = q.eq('codigo_proveedor', f.codigoProveedor);
    if (f.pendiente !== undefined) q = q.eq('pendiente', f.pendiente);
    if (f.desde) q = q.gte('fecha_emision', f.desde);
    if (f.hasta) q = q.lte('fecha_emision', f.hasta);

    const { data, error, count } = await q;
    if (error) throw new InternalServerErrorException(error.message);

    const rows = data ?? [];
    const proveedorCodes = [...new Set(rows.map((r) => r.codigo_proveedor as string))];
    const docCodes       = [...new Set(rows.map((r) => r.codigo_documento as string))];

    const [{ data: proveedores }, { data: documentos }] = await Promise.all([
      proveedorCodes.length
        ? this.supabase.db.from('proveedores').select('codigo, razon_social').eq('codigo_empresa', f.codigoEmpresa).in('codigo', proveedorCodes)
        : Promise.resolve({ data: [] }),
      docCodes.length
        ? this.supabase.db.from('documentos').select('codigo, abreviatura, serie').eq('codigo_empresa', f.codigoEmpresa).in('codigo', docCodes)
        : Promise.resolve({ data: [] }),
    ]);

    const provMap = new Map((proveedores ?? []).map((p: any) => [p.codigo, p.razon_social]));
    const docMap  = new Map((documentos  ?? []).map((d: any) => [d.codigo, { abreviatura: d.abreviatura, serie: d.serie }]));

    const total = count ?? 0;
    return {
      data: rows.map((r) => ({
        ...this.toCxP(r),
        razonSocialProveedor: provMap.get(r.codigo_proveedor as string) as string | undefined,
        abreviaturaDocumento: (docMap.get(r.codigo_documento as string) as any)?.abreviatura as string | undefined,
        serieDocumento:       (docMap.get(r.codigo_documento as string) as any)?.serie        as string | undefined,
      })),
      total,
      page,
      lastPage: Math.ceil(total / limit) || 1,
    };
  }

  async findById(id: string, codigoEmpresa: string): Promise<CuentaPagar | null> {
    const { data, error } = await this.supabase.db
      .from('cuentas_pagar').select('*')
      .eq('id', id).eq('codigo_empresa', codigoEmpresa).maybeSingle();
    if (error) throw new InternalServerErrorException(error.message);
    if (!data) return null;

    const [{ data: prov }, { data: doc }] = await Promise.all([
      this.supabase.db.from('proveedores').select('razon_social')
        .eq('codigo_empresa', codigoEmpresa).eq('codigo', data.codigo_proveedor as string).maybeSingle(),
      this.supabase.db.from('documentos').select('abreviatura, serie')
        .eq('codigo_empresa', codigoEmpresa).eq('codigo', data.codigo_documento as string).maybeSingle(),
    ]);

    return {
      ...this.toCxP(data),
      razonSocialProveedor: (prov as any)?.razon_social as string | undefined,
      abreviaturaDocumento: (doc  as any)?.abreviatura  as string | undefined,
      serieDocumento:       (doc  as any)?.serie         as string | undefined,
    };
  }

  async registrarPago(codigoEmpresa: string, d: RegistrarPagoData): Promise<Pago> {
    const cxp = await this.findById(d.cuentaPagarId, codigoEmpresa);
    if (!cxp) throw new BadRequestException('Cuenta por pagar no encontrada');
    if (!cxp.pendiente) throw new BadRequestException('La cuenta ya está cancelada');
    if (d.monto > cxp.saldo) throw new BadRequestException(`Monto (${d.monto}) supera el saldo (${cxp.saldo})`);

    const { data: pago, error } = await this.supabase.db
      .from('pagos')
      .insert({
        codigo_empresa:   codigoEmpresa,
        cuenta_pagar_id:  d.cuentaPagarId,
        numero_voucher:   d.numeroVoucher,
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
      if (error.code === '23505') throw new ConflictException('Número de voucher ya existe');
      throw new InternalServerErrorException(error.message);
    }

    const nuevoMontoPagado = parseFloat((cxp.montoPagado + d.monto).toFixed(2));
    const nuevoSaldo       = parseFloat((cxp.montoTotal  - nuevoMontoPagado).toFixed(2));
    const pendiente        = nuevoSaldo > 0;

    await this.supabase.db.from('cuentas_pagar').update({
      monto_pagado: nuevoMontoPagado,
      saldo:        nuevoSaldo,
      pendiente,
    }).eq('id', d.cuentaPagarId).eq('codigo_empresa', codigoEmpresa);

    return this.toPago(pago);
  }

  async getPagos(codigoEmpresa: string, cuentaPagarId: string): Promise<Pago[]> {
    const { data, error } = await this.supabase.db
      .from('pagos').select('*')
      .eq('codigo_empresa', codigoEmpresa)
      .eq('cuenta_pagar_id', cuentaPagarId)
      .order('fecha', { ascending: false });
    if (error) throw new InternalServerErrorException(error.message);
    return (data ?? []).map(this.toPago);
  }

  async renovar(codigoEmpresa: string, d: RenovarCxPData): Promise<CuentaPagar[]> {
    const original = await this.findById(d.cuentaPagarId, codigoEmpresa);
    if (!original) throw new BadRequestException('Cuenta por pagar no encontrada');
    if (!original.pendiente) throw new BadRequestException('La cuenta ya está cancelada');
    if (!d.cuotas.length) throw new BadRequestException('Debe indicar al menos una cuota');

    await this.supabase.db.from('cuentas_pagar').update({ pendiente: false })
      .eq('id', d.cuentaPagarId).eq('codigo_empresa', codigoEmpresa);

    const { data: maxRow } = await this.supabase.db
      .from('cuentas_pagar')
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
      codigo_proveedor:        original.codigoProveedor,
      pendiente:               true,
      referencia:              'RENOVACION',
    }));

    const { data: nuevas, error } = await this.supabase.db
      .from('cuentas_pagar').insert(records).select();
    if (error) throw new InternalServerErrorException(error.message);
    return (nuevas ?? []).map((r) => this.toCxP(r));
  }

  private toCxP(r: Record<string, unknown>): CuentaPagar {
    return {
      id: r.id as string,
      codigoEmpresa: r.codigo_empresa as string,
      numeroProvision: Number(r.numero_provision),
      numeroProvisionOrigen: r.numero_provision_origen ? Number(r.numero_provision_origen) : undefined,
      tipo: r.tipo as CuentaPagar['tipo'],
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
      codigoProveedor: r.codigo_proveedor as string,
      descripcion: r.descripcion as string | undefined,
      pendiente: r.pendiente as boolean,
      referencia: r.referencia as string | undefined,
      createdAt: r.created_at as string | undefined,
    };
  }

  private toPago(r: Record<string, unknown>): Pago {
    return {
      id: r.id as string,
      codigoEmpresa: r.codigo_empresa as string,
      cuentaPagarId: r.cuenta_pagar_id as string,
      numeroVoucher: r.numero_voucher as string,
      fecha: r.fecha as string,
      tipoPago: r.tipo_pago as Pago['tipoPago'],
      numeroOperacion: r.numero_operacion as string | undefined,
      codigoBanco: r.codigo_banco as string | undefined,
      monto: Number(r.monto),
      estado: r.estado as Pago['estado'],
      codigoUsuario: r.codigo_usuario as string,
      createdAt: r.created_at as string | undefined,
    };
  }
}
