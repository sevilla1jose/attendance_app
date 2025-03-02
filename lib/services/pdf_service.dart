import 'dart:typed_data';
import 'package:attendance_app/domain/entities/user.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:attendance_app/core/errors/exceptions.dart';
import 'package:attendance_app/data/models/attendance_model.dart';
import 'package:attendance_app/data/models/location_model.dart';
import 'package:attendance_app/data/models/user_model.dart';
import 'package:attendance_app/domain/entities/attendance.dart';

/// Interfaz para el servicio de generación de PDF
abstract class PdfService {
  /// Genera un PDF con el reporte de asistencia diario
  Future<Uint8List> generateDailyAttendanceReport({
    required DateTime date,
    required List<AttendanceModel> attendanceRecords,
    required List<UserModel> users,
    required List<LocationModel> locations,
    String? title,
    String? subtitle,
    String? companyName,
    String? companyLogo,
  });

  /// Genera un PDF con el reporte de asistencia semanal
  Future<Uint8List> generateWeeklyAttendanceReport({
    required DateTime startDate,
    required DateTime endDate,
    required List<AttendanceModel> attendanceRecords,
    required List<UserModel> users,
    required List<LocationModel> locations,
    String? title,
    String? subtitle,
    String? companyName,
    String? companyLogo,
  });

  /// Genera un PDF con el reporte de asistencia mensual
  Future<Uint8List> generateMonthlyAttendanceReport({
    required DateTime month,
    required List<AttendanceModel> attendanceRecords,
    required List<UserModel> users,
    required List<LocationModel> locations,
    String? title,
    String? subtitle,
    String? companyName,
    String? companyLogo,
  });

  /// Genera un PDF con el reporte de asistencia personalizado
  Future<Uint8List> generateCustomAttendanceReport({
    required DateTime startDate,
    required DateTime endDate,
    required List<AttendanceModel> attendanceRecords,
    required List<UserModel> users,
    required List<LocationModel> locations,
    String? title,
    String? subtitle,
    String? companyName,
    String? companyLogo,
    String? userId,
    String? locationId,
  });

  /// Imprime un PDF
  Future<void> printPdf(Uint8List pdfBytes);

  /// Previsualiza un PDF
  Future<void> previewPdf(Uint8List pdfBytes, {String? title});
}

/// Implementación del servicio de generación de PDF
class PdfServiceImpl implements PdfService {
  @override
  Future<Uint8List> generateDailyAttendanceReport({
    required DateTime date,
    required List<AttendanceModel> attendanceRecords,
    required List<UserModel> users,
    required List<LocationModel> locations,
    String? title,
    String? subtitle,
    String? companyName,
    String? companyLogo,
  }) async {
    try {
      // Crear un documento PDF
      final pdf = pw.Document();

      // Obtener la fecha formateada
      final dateFormat = DateFormat('dd/MM/yyyy');
      final dateStr = dateFormat.format(date);

      // Título del reporte
      final reportTitle = title ?? 'Reporte de Asistencia Diario';
      final reportSubtitle = subtitle ?? 'Fecha: $dateStr';

      // Obtener los asistentes y ausentes del día
      final attendees = <String>{};
      for (final record in attendanceRecords) {
        attendees.add(record.userId);
      }

      final absentees = users
          .where((user) => !attendees.contains(user.id) && user.isActive)
          .toList();

      // Agrupar los registros por usuario
      final userRecords = <String, List<AttendanceModel>>{};
      for (final record in attendanceRecords) {
        if (!userRecords.containsKey(record.userId)) {
          userRecords[record.userId] = [];
        }
        userRecords[record.userId]!.add(record);
      }

      // Crear el PDF
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      companyName ?? 'Sistema de Asistencia',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Fecha: $dateStr',
                      style: const pw.TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Text(
                  reportTitle,
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (reportSubtitle != null) ...[
                  pw.SizedBox(height: 5),
                  pw.Text(
                    reportSubtitle,
                    style: const pw.TextStyle(fontSize: 14),
                  ),
                ],
                pw.SizedBox(height: 10),
              ],
            );
          },
          footer: (pw.Context context) {
            return pw.Column(
              children: [
                pw.Divider(),
                pw.SizedBox(height: 5),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Página ${context.pageNumber} de ${context.pagesCount}',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                    pw.Text(
                      'Generado el ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ],
            );
          },
          build: (pw.Context context) {
            return [
              // Sección de asistentes
              pw.Header(
                level: 1,
                text: 'Asistentes',
                outlineStyle: pw.PdfOutlineStyle.italic,
              ),
              pw.SizedBox(height: 10),
              if (userRecords.isEmpty) ...[
                pw.Text('No hay registros de asistencia para este día.'),
                pw.SizedBox(height: 20),
              ] else ...[
                // Tabla de asistentes
                pw.Table.fromTextArray(
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.grey300,
                  ),
                  cellAlignments: {
                    0: pw.Alignment.centerLeft,
                    1: pw.Alignment.center,
                    2: pw.Alignment.center,
                    3: pw.Alignment.center,
                    4: pw.Alignment.center,
                  },
                  headers: [
                    'Nombre',
                    'Entrada',
                    'Salida Almuerzo',
                    'Retorno Almuerzo',
                    'Salida'
                  ],
                  data: _buildAttendanceTableData(userRecords, users),
                ),
                pw.SizedBox(height: 20),
              ],

              // Sección de ausentes
              pw.Header(
                level: 1,
                text: 'Ausentes',
                outlineStyle: pw.PdfOutlineStyle.italic,
              ),
              pw.SizedBox(height: 10),
              if (absentees.isEmpty) ...[
                pw.Text('No hay ausentes para este día.'),
              ] else ...[
                // Tabla de ausentes
                pw.Table.fromTextArray(
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.grey300,
                  ),
                  cellAlignments: {
                    0: pw.Alignment.centerLeft,
                    1: pw.Alignment.center,
                    2: pw.Alignment.center,
                  },
                  headers: ['Nombre', 'Cargo', 'Email'],
                  data: absentees.map((user) {
                    String roleName = '';
                    switch (user.role) {
                      case UserRole.admin:
                        roleName = 'Administrador';
                        break;
                      case UserRole.supervisor:
                        roleName = 'Supervisor';
                        break;
                      case UserRole.assistant:
                        roleName = 'Asistente';
                        break;
                    }

                    return [
                      user.name,
                      roleName,
                      user.email,
                    ];
                  }).toList(),
                ),
              ],
            ];
          },
        ),
      );

      // Devolver los bytes del PDF
      return pdf.save();
    } catch (e) {
      debugPrint('Error al generar el reporte diario: $e');
      throw ReportException(
          'Error al generar el reporte diario: ${e.toString()}');
    }
  }

  @override
  Future<Uint8List> generateWeeklyAttendanceReport({
    required DateTime startDate,
    required DateTime endDate,
    required List<AttendanceModel> attendanceRecords,
    required List<UserModel> users,
    required List<LocationModel> locations,
    String? title,
    String? subtitle,
    String? companyName,
    String? companyLogo,
  }) async {
    try {
      // Similar a generateDailyAttendanceReport pero adaptado para semanas
      // Se implementaría mostrando un resumen por día de la semana

      // Por ahora, este es un placeholder
      return generateDailyAttendanceReport(
        date: startDate,
        attendanceRecords: attendanceRecords,
        users: users,
        locations: locations,
        title: title ?? 'Reporte de Asistencia Semanal',
        subtitle: subtitle ??
            'Semana: ${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}',
        companyName: companyName,
        companyLogo: companyLogo,
      );
    } catch (e) {
      debugPrint('Error al generar el reporte semanal: $e');
      throw ReportException(
          'Error al generar el reporte semanal: ${e.toString()}');
    }
  }

  @override
  Future<Uint8List> generateMonthlyAttendanceReport({
    required DateTime month,
    required List<AttendanceModel> attendanceRecords,
    required List<UserModel> users,
    required List<LocationModel> locations,
    String? title,
    String? subtitle,
    String? companyName,
    String? companyLogo,
  }) async {
    try {
      // Similar a generateDailyAttendanceReport pero adaptado para meses
      // Se implementaría mostrando un resumen por semana o por día del mes

      // Por ahora, este es un placeholder
      final startOfMonth = DateTime(month.year, month.month, 1);
      final endOfMonth = DateTime(month.year, month.month + 1, 0);

      return generateDailyAttendanceReport(
        date: startOfMonth,
        attendanceRecords: attendanceRecords,
        users: users,
        locations: locations,
        title: title ?? 'Reporte de Asistencia Mensual',
        subtitle: subtitle ?? 'Mes: ${DateFormat('MMMM yyyy').format(month)}',
        companyName: companyName,
        companyLogo: companyLogo,
      );
    } catch (e) {
      debugPrint('Error al generar el reporte mensual: $e');
      throw ReportException(
          'Error al generar el reporte mensual: ${e.toString()}');
    }
  }

  @override
  Future<Uint8List> generateCustomAttendanceReport({
    required DateTime startDate,
    required DateTime endDate,
    required List<AttendanceModel> attendanceRecords,
    required List<UserModel> users,
    required List<LocationModel> locations,
    String? title,
    String? subtitle,
    String? companyName,
    String? companyLogo,
    String? userId,
    String? locationId,
  }) async {
    try {
      // Similar a generateDailyAttendanceReport pero con filtros personalizados

      // Filtrar registros si se especifica un usuario o ubicación
      var filteredRecords = attendanceRecords;

      if (userId != null) {
        filteredRecords =
            filteredRecords.where((record) => record.userId == userId).toList();
      }

      if (locationId != null) {
        filteredRecords = filteredRecords
            .where((record) => record.locationId == locationId)
            .toList();
      }

      // Por ahora, este es un placeholder
      return generateDailyAttendanceReport(
        date: startDate,
        attendanceRecords: filteredRecords,
        users: users,
        locations: locations,
        title: title ?? 'Reporte de Asistencia Personalizado',
        subtitle: subtitle ??
            'Período: ${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}',
        companyName: companyName,
        companyLogo: companyLogo,
      );
    } catch (e) {
      debugPrint('Error al generar el reporte personalizado: $e');
      throw ReportException(
          'Error al generar el reporte personalizado: ${e.toString()}');
    }
  }

  @override
  Future<void> printPdf(Uint8List pdfBytes) async {
    try {
      await Printing.layoutPdf(
        onLayout: (_) => pdfBytes,
      );
    } catch (e) {
      debugPrint('Error al imprimir el PDF: $e');
      throw ReportException('Error al imprimir el PDF: ${e.toString()}');
    }
  }

  @override
  Future<void> previewPdf(Uint8List pdfBytes, {String? title}) async {
    try {
      await Printing.layoutPdf(
        onLayout: (_) => pdfBytes,
        name: title ?? 'Reporte de Asistencia',
      );
    } catch (e) {
      debugPrint('Error al previsualizar el PDF: $e');
      throw ReportException('Error al previsualizar el PDF: ${e.toString()}');
    }
  }

  /// Construye los datos para la tabla de asistencia
  List<List<String>> _buildAttendanceTableData(
    Map<String, List<AttendanceModel>> userRecords,
    List<UserModel> users,
  ) {
    final data = <List<String>>[];

    for (final userId in userRecords.keys) {
      final user = users.firstWhere(
        (u) => u.id == userId,
        orElse: () => UserModel(
          id: userId,
          name: 'Usuario Desconocido',
          email: '',
          role: UserRole.assistant,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final records = userRecords[userId]!;

      // Encontrar los registros de cada tipo
      String checkInTime = '-';
      String lunchOutTime = '-';
      String lunchInTime = '-';
      String checkOutTime = '-';

      for (final record in records) {
        final time = DateFormat('HH:mm').format(record.createdAt);

        switch (record.type) {
          case AttendanceType.checkIn:
            checkInTime = time;
            break;
          case AttendanceType.lunchOut:
            lunchOutTime = time;
            break;
          case AttendanceType.lunchIn:
            lunchInTime = time;
            break;
          case AttendanceType.checkOut:
            checkOutTime = time;
            break;
        }
      }

      data.add([
        user.name,
        checkInTime,
        lunchOutTime,
        lunchInTime,
        checkOutTime,
      ]);
    }

    return data;
  }
}
