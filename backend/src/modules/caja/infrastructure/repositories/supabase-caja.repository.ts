import { Injectable, InternalServerErrorException, BadRequestException, ConflictException } from '@nestjs/common';
import { SupabaseService } from '../../../../shared/infrastructure/supabase/supabase.service';
import {
  ICajaRepository, CajaFilter, CajaListResult,
  AbrirCajaData, CerrarCajaData, RegistrarMovCajaData, ReporteCaja,
} from '../../domain/ports/caja.repository.port';
import { SesionCaja, MovimientoCaja } from '../../domain/entities/caja.entity';

@Injectable()
export class SupabaseCajaRepository implements ICajaRepository {
  constructor(private readonly supabase: SupabaseService) {}

  async list(f: CajaFilter): Promise<CajaListResult> {
    const page  = f.page ?? 1;
    const limit = Math.min(f.limit ?? 20, 100);
    const from  = (page - 1) * limit;

    let q = this.supabase.db
      .from('sesiones_caja').select('*', { count: 'exact' })
      .eq('codigo_empresa', f.codigoEmpresa)
      .order('fecha_apertura', { ascending: false })
      .range(from, from + limit - 1);

    if (f.codigoCaja) q = q.eq('codigo_caja', f.codigoCaja);
    if (f.estado) q = q.eq('estado', f.estado);

    const { data, error, count } = await q;
    if (error) throw new InternalServerErrorException(error.message);
    const total = count ?? 0;
    return { data: (data ?? []).map(this.toSesion), total, page, lastPage: Math.ceil(total / limit) || 1 };
  }

  async findById(id: string, codigoEmpresa: string): Promise<SesionCaja | null> {
    const { data, error } = await this.supabase.db
      .from('sesiones_caja').select('*')
      .eq('id', id).eq('codigo_empresa', codigoEmpresa).maybeSingle();
    if (error) throw new InternalServerErrorException(error.message);
    return data ? this.toSesion(data) : null;
  }

  async abrir(codigoEmpresa: string, d: AbrirCajaData): Promise<SesionCaja> {
    // Prevent opening the same caja twice
    const { data: abierta } = await this.supabase.db
      .from('sesiones_caja').select('id')
      .eq('codigo_empresa', codigoEmpresa)
      .eq('codigo_caja', d.codigoCaja)
      .eq('estado', 'ABIERTA').maybeSingle();
    if (abierta) throw new ConflictException(`Caja ${d.codigoCaja} ya tiene una sesión abierta`);

    const { data, error } = await this.supabase.db
      .from('sesiones_caja').insert({
        codigo_empresa:  codigoEmpresa,
        codigo_caja:     d.codigoCaja,
        codigo_usuario:  d.codigoUsuario,
        fecha_apertura:  new Date().toISOString(),
        monto_apertura:  d.montoApertura,
        estado:          'ABIERTA',
      }).select().single();
    if (error) throw new InternalServerErrorException(error.message);
    return this.toSesion(data);
  }

  async cerrar(codigoEmpresa: string, d: CerrarCajaData): Promise<SesionCaja> {
    const sesion = await this.findById(d.sesionCajaId, codigoEmpresa);
    if (!sesion) throw new BadRequestException('Sesión de caja no encontrada');
    if (sesion.estado === 'CERRADA') throw new BadRequestException('La caja ya está cerrada');

    const reporte = await this.reporte(codigoEmpresa, d.sesionCajaId);
    const diferencia = parseFloat((d.montosCierre - reporte.saldoFinal).toFixed(2));

    const { data, error } = await this.supabase.db
      .from('sesiones_caja').update({
        fecha_cierre:  new Date().toISOString(),
        montos_cierre: d.montosCierre,
        diferencia,
        estado: 'CERRADA',
      }).eq('id', d.sesionCajaId).eq('codigo_empresa', codigoEmpresa)
      .select().single();
    if (error) throw new InternalServerErrorException(error.message);
    return this.toSesion(data);
  }

  async registrarMovimiento(codigoEmpresa: string, d: RegistrarMovCajaData): Promise<MovimientoCaja> {
    const sesion = await this.findById(d.sesionCajaId, codigoEmpresa);
    if (!sesion) throw new BadRequestException('Sesión de caja no encontrada');
    if (sesion.estado === 'CERRADA') throw new BadRequestException('La caja está cerrada');

    const { data, error } = await this.supabase.db
      .from('movimientos_caja').insert({
        codigo_empresa:  codigoEmpresa,
        sesion_caja_id:  d.sesionCajaId,
        tipo:            d.tipo,
        concepto:        d.concepto,
        referencia:      d.referencia ?? null,
        monto:           d.monto,
        fecha:           d.fecha,
        codigo_usuario:  d.codigoUsuario,
      }).select().single();
    if (error) throw new InternalServerErrorException(error.message);
    return this.toMovimiento(data);
  }

  async getMovimientos(codigoEmpresa: string, sesionCajaId: string): Promise<MovimientoCaja[]> {
    const { data, error } = await this.supabase.db
      .from('movimientos_caja').select('*')
      .eq('codigo_empresa', codigoEmpresa)
      .eq('sesion_caja_id', sesionCajaId)
      .order('fecha', { ascending: true });
    if (error) throw new InternalServerErrorException(error.message);
    return (data ?? []).map(this.toMovimiento);
  }

  async reporte(codigoEmpresa: string, sesionCajaId: string): Promise<ReporteCaja> {
    const sesion = await this.findById(sesionCajaId, codigoEmpresa);
    if (!sesion) throw new BadRequestException('Sesión de caja no encontrada');
    const movimientos = await this.getMovimientos(codigoEmpresa, sesionCajaId);
    const totalIngresos = movimientos.filter(m => m.tipo === 'INGRESO').reduce((s, m) => s + m.monto, 0);
    const totalEgresos  = movimientos.filter(m => m.tipo === 'EGRESO' ).reduce((s, m) => s + m.monto, 0);
    const saldoFinal    = parseFloat((sesion.montoApertura + totalIngresos - totalEgresos).toFixed(2));
    return { sesion, movimientos, totalIngresos, totalEgresos, saldoFinal };
  }

  private toSesion(r: Record<string, unknown>): SesionCaja {
    return {
      id: r.id as string,
      codigoEmpresa: r.codigo_empresa as string,
      codigoCaja: r.codigo_caja as string,
      codigoUsuario: r.codigo_usuario as string,
      fechaApertura: r.fecha_apertura as string,
      montoApertura: Number(r.monto_apertura),
      fechaCierre: r.fecha_cierre as string | undefined,
      montosCierre: r.montos_cierre != null ? Number(r.montos_cierre) : undefined,
      diferencia: r.diferencia != null ? Number(r.diferencia) : undefined,
      estado: r.estado as SesionCaja['estado'],
      createdAt: r.created_at as string | undefined,
    };
  }

  private toMovimiento(r: Record<string, unknown>): MovimientoCaja {
    return {
      id: r.id as string,
      codigoEmpresa: r.codigo_empresa as string,
      sesionCajaId: r.sesion_caja_id as string,
      tipo: r.tipo as MovimientoCaja['tipo'],
      concepto: r.concepto as string,
      referencia: r.referencia as string | undefined,
      monto: Number(r.monto),
      fecha: r.fecha as string,
      codigoUsuario: r.codigo_usuario as string,
      createdAt: r.created_at as string | undefined,
    };
  }
}
