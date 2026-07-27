export const STOCK_INSUFICIENTE_PG_CODE = 'AR001';
export const STOCK_INSUFICIENTE_MESSAGE =
  'Articulo no tiene stock necesario\nNo se puede realizar esta operación\nRealice un Ingreso/Compra para tener stock';

// La función SQL registrar_movimiento (ver supabase/migrations/024_control_stock_salidas.sql)
// ya calcula stock actual y cantidad solicitada al lanzar la excepción; este regex solo
// extrae esos números (el signo negativo es válido: el stock puede quedar en negativo si
// control_stock_salidas se activó después de que ya estaba en negativo).
const STOCK_INSUFICIENTE_REGEX =
  /articulo \S+ en almacen \S+ \(stock (-?[\d.]+), solicitado (-?[\d.]+)\)/;

function formatearCantidad(n: number): string {
  return Number(n.toFixed(4)).toString();
}

export function buildStockInsuficienteMessage(pgMessage?: string | null): string {
  const match = pgMessage ? STOCK_INSUFICIENTE_REGEX.exec(pgMessage) : null;
  if (!match) return STOCK_INSUFICIENTE_MESSAGE;

  const stock      = Number(match[1]);
  const solicitado = Number(match[2]);
  const faltante   = Math.max(0, solicitado - stock);

  return (
    `Stock disponible: ${formatearCantidad(stock)}. Cantidad solicitada: ${formatearCantidad(solicitado)}.\n` +
    `Faltan ${formatearCantidad(faltante)} unidad(es): realice un Ingreso/Compra para completar esta operación.`
  );
}
