import 'package:intl/intl.dart';
import 'package:attendance_app/core/constants/app_constants.dart';

/// Utilidades para el manejo de fechas y horas
class DateTimeUtils {
  /// Formatea una fecha al formato estándar de la aplicación
  static String formatDate(DateTime dateTime) {
    return DateFormat(AppConstants.dateFormat).format(dateTime);
  }

  /// Formatea una hora al formato estándar de la aplicación
  static String formatTime(DateTime dateTime) {
    return DateFormat(AppConstants.timeFormat).format(dateTime);
  }

  /// Formatea una fecha y hora al formato estándar de la aplicación
  static String formatDateTime(DateTime dateTime) {
    return DateFormat(AppConstants.dateTimeFormat).format(dateTime);
  }

  /// Convierte una cadena de fecha al formato de fecha de Dart
  static DateTime parseDate(String dateString) {
    return DateFormat(AppConstants.dateFormat).parse(dateString);
  }

  /// Convierte una cadena de hora al formato de hora de Dart
  static DateTime parseTime(String timeString) {
    return DateFormat(AppConstants.timeFormat).parse(timeString);
  }

  /// Convierte una cadena de fecha y hora al formato de DateTime de Dart
  static DateTime parseDateTime(String dateTimeString) {
    return DateFormat(AppConstants.dateTimeFormat).parse(dateTimeString);
  }

  /// Obtiene el inicio del día actual
  static DateTime startOfDay(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }

  /// Obtiene el fin del día actual
  static DateTime endOfDay(DateTime dateTime) {
    return DateTime(
        dateTime.year, dateTime.month, dateTime.day, 23, 59, 59, 999);
  }

  /// Obtiene el inicio de la semana actual
  static DateTime startOfWeek(DateTime dateTime) {
    final dayOfWeek = dateTime.weekday;
    return DateTime(
        dateTime.year, dateTime.month, dateTime.day - (dayOfWeek - 1));
  }

  /// Obtiene el fin de la semana actual
  static DateTime endOfWeek(DateTime dateTime) {
    final dayOfWeek = dateTime.weekday;
    return DateTime(dateTime.year, dateTime.month,
        dateTime.day + (7 - dayOfWeek), 23, 59, 59, 999);
  }

  /// Obtiene el inicio del mes actual
  static DateTime startOfMonth(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, 1);
  }

  /// Obtiene el fin del mes actual
  static DateTime endOfMonth(DateTime dateTime) {
    final nextMonth = dateTime.month < 12
        ? DateTime(dateTime.year, dateTime.month + 1, 1)
        : DateTime(dateTime.year + 1, 1, 1);
    return nextMonth.subtract(const Duration(microseconds: 1));
  }

  /// Calcula la diferencia en horas entre dos fechas
  static double hoursBetween(DateTime start, DateTime end) {
    final difference = end.difference(start);
    return difference.inMinutes / 60;
  }

  /// Calcula la diferencia en minutos entre dos fechas
  static int minutesBetween(DateTime start, DateTime end) {
    final difference = end.difference(start);
    return difference.inMinutes;
  }

  /// Verifica si una fecha está en el rango de dos fechas
  static bool isDateInRange(DateTime date, DateTime start, DateTime end) {
    return date.isAfter(start) && date.isBefore(end) ||
        date.isAtSameMomentAs(start) ||
        date.isAtSameMomentAs(end);
  }

  /// Obtiene una lista de días entre dos fechas
  static List<DateTime> getDaysInRange(DateTime start, DateTime end) {
    final days = <DateTime>[];
    var current = startOfDay(start);

    while (!current.isAfter(end)) {
      days.add(current);
      current = current.add(const Duration(days: 1));
    }

    return days;
  }

  /// Obtiene una lista de meses entre dos fechas
  static List<DateTime> getMonthsInRange(DateTime start, DateTime end) {
    final months = <DateTime>[];
    var current = DateTime(start.year, start.month, 1);

    while (!current.isAfter(end)) {
      months.add(current);
      if (current.month < 12) {
        current = DateTime(current.year, current.month + 1, 1);
      } else {
        current = DateTime(current.year + 1, 1, 1);
      }
    }

    return months;
  }

  /// Verifica si dos fechas son del mismo día
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Verifica si dos fechas son del mismo mes
  static bool isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  /// Verifica si una fecha es hoy
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return isSameDay(date, now);
  }

  /// Obtiene el nombre del día de la semana
  static String getDayName(DateTime date, {bool short = false}) {
    final formatter = DateFormat(short ? 'E' : 'EEEE');
    return formatter.format(date);
  }

  /// Obtiene el nombre del mes
  static String getMonthName(DateTime date, {bool short = false}) {
    final formatter = DateFormat(short ? 'MMM' : 'MMMM');
    return formatter.format(date);
  }

  /// Calcula el tiempo transcurrido desde una fecha en formato legible
  static String timeAgo(DateTime date, {bool short = false}) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? (short ? 'año' : 'año') : (short ? 'años' : 'años')}';
    }

    if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? (short ? 'mes' : 'mes') : (short ? 'meses' : 'meses')}';
    }

    if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? (short ? 'd' : 'día') : (short ? 'd' : 'días')}';
    }

    if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? (short ? 'h' : 'hora') : (short ? 'h' : 'horas')}';
    }

    if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? (short ? 'min' : 'minuto') : (short ? 'min' : 'minutos')}';
    }

    return short ? 'ahora' : 'hace un momento';
  }
}
