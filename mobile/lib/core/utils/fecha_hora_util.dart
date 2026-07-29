import 'package:intl/intl.dart';

/// Punto único de formateo y corrección de zona horaria para toda la app.
///
/// Los timestamps que llegan de Supabase (columnas TIMESTAMPTZ) vienen en UTC.
/// Lima-Perú usa UTC-5 todo el año (no tiene horario de verano), así que el
/// offset se fija en el código en vez de depender de la zona horaria del
/// dispositivo o del servidor, para que el resultado sea siempre determinista.
class FechaHoraUtil {
  FechaHoraUtil._();

  static const Duration _offsetLima = Duration(hours: -5);
  static final RegExp _soloFecha = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  static final DateFormat _fmtFecha = DateFormat('dd/MM/yyyy');
  static final DateFormat _fmtFechaHora = DateFormat('dd/MM/yyyy HH:mm:ss');
  static final DateFormat _fmtIso = DateFormat('yyyy-MM-dd');

  /// Fecha y hora actual, ya ajustada a hora de Lima.
  static DateTime ahora() => DateTime.now().toUtc().add(_offsetLima);

  /// Convierte un timestamp real (DateTime o String con hora/zona) a hora de Lima.
  /// Los valores que son solo fecha (columnas DATE, 'yyyy-MM-dd') no tienen
  /// componente horario y se devuelven tal cual: aplicarles el offset de zona
  /// horaria movería el día mostrado, en vez de corregirlo.
  static DateTime aHoraLima(dynamic value) {
    if (value is String && _soloFecha.hasMatch(value)) {
      return DateTime.parse(value);
    }
    final dt = value is DateTime ? value : DateTime.parse(value as String);
    return dt.toUtc().add(_offsetLima);
  }

  /// Formatea como 'dd/MM/yyyy', convirtiendo a hora de Lima si el valor trae hora.
  static String formatearFecha(dynamic value) {
    if (value == null) return '';
    return _fmtFecha.format(aHoraLima(value));
  }

  /// Formatea como 'dd/MM/yyyy HH:mm:ss', convirtiendo a hora de Lima.
  static String formatearFechaHora(dynamic value) {
    if (value == null) return '';
    return _fmtFechaHora.format(aHoraLima(value));
  }

  /// Formatea un [DateTime] ya resuelto (p. ej. de un selector de fecha, o de
  /// [ahora]) como 'dd/MM/yyyy', sin aplicar ninguna conversión de zona horaria.
  static String formatoCorto(DateTime date) => _fmtFecha.format(date);

  /// Formatea un [DateTime] ya resuelto como 'yyyy-MM-dd' (para columnas DATE),
  /// sin aplicar ninguna conversión de zona horaria.
  static String iso(DateTime date) => _fmtIso.format(date);

  /// Fecha de hoy en Lima, en formato 'yyyy-MM-dd' (para columnas DATE).
  static String fechaHoyIso() => iso(ahora());
}
