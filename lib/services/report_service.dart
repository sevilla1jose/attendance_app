import 'dart:typed_data';
import 'package:attendance_app/domain/entities/user.dart';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'package:attendance_app/core/errors/exceptions.dart';
import 'package:attendance_app/data/models/attendance_model.dart';
import 'package:attendance_app/data/models/location_model.dart';
import 'package:attendance_app/data/models/user_model.dart';
import 'package:attendance_app/domain/entities/attendance.dart';
import 'package:attendance_app/domain/entities/report.dart';
import 'package:attendance_app/services/pdf_service.dart';
import 'package:intl/intl.dart';

/// Interfaz para el servicio de generación de reportes
abstract class ReportService {
  /// Genera un reporte en formato PDF o Excel
  Future<Uint8List> generateReport({
    required ReportType type,
    required DateTime startDate,
    required DateTime endDate,
    required List<AttendanceModel> attendanceRecords,
    required List<UserModel> users,
    required List<LocationModel> locations,
    required ReportFormat format,
    String? title,
    String? subtitle,
    String? companyName,
    String? companyLogo,
    String? userId,
    String? locationId,
  });

  /// Genera un reporte en formato Excel
  Future<Uint8List> generateExcelReport({
    required ReportType type,
    required DateTime startDate,
    required DateTime endDate,
    required List<AttendanceModel> attendanceRecords,
    required List<UserModel> users,
    required List<LocationModel> locations,
    String? title,
    String? subtitle,
    String? companyName,
    String? userId,
    String? locationId,
  });

  /// Genera un reporte en formato PDF
  Future<Uint8List> generatePdfReport({
    required ReportType type,
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
}

/// Implementación del servicio de generación de reportes
class ReportServiceImpl implements ReportService {
  final PdfService pdfService;

  ReportServiceImpl({
    required this.pdfService,
  });

  @override
  Future<Uint8List> generateReport({
    required ReportType type,
    required DateTime startDate,
    required DateTime endDate,
    required List<AttendanceModel> attendanceRecords,
    required List<UserModel> users,
    required List<LocationModel> locations,
    required ReportFormat format,
    String? title,
    String? subtitle,
    String? companyName,
    String? companyLogo,
    String? userId,
    String? locationId,
  }) async {
    try {
      switch (format) {
        case ReportFormat.pdf:
          return await generatePdfReport(
            type: type,
            startDate: startDate,
            endDate: endDate,
            attendanceRecords: attendanceRecords,
            users: users,
            locations: locations,
            title: title,
            subtitle: subtitle,
            companyName: companyName,
            companyLogo: companyLogo,
            userId: userId,
            locationId: locationId,
          );
        case ReportFormat.excel:
          return await generateExcelReport(
            type: type,
            startDate: startDate,
            endDate: endDate,
            attendanceRecords: attendanceRecords,
            users: users,
            locations: locations,
            title: title,
            subtitle: subtitle,
            companyName: companyName,
            userId: userId,
            locationId: locationId,
          );
        default:
          throw ReportException('Formato de reporte no soportado');
      }
    } catch (e) {
      debugPrint('Error al generar el reporte: $e');
      throw ReportException('Error al generar el reporte: ${e.toString()}');
    }
  }

  @override
  Future<Uint8List> generateExcelReport({
    required ReportType type,
    required DateTime startDate,
    required DateTime endDate,
    required List<AttendanceModel> attendanceRecords,
    required List<UserModel> users,
    required List<LocationModel> locations,
    String? title,
    String? subtitle,
    String? companyName,
    String? userId,
    String? locationId,
  }) async {
    try {
      // Crear un libro de Excel
      final Workbook workbook = Workbook();

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

      // Determinar el título del reporte según su tipo
      String reportTitle;
      switch (type) {
        case ReportType.daily:
          reportTitle = title ?? 'Reporte de Asistencia Diario';
          break;
        case ReportType.weekly:
          reportTitle = title ?? 'Reporte de Asistencia Semanal';
          break;
        case ReportType.monthly:
          reportTitle = title ?? 'Reporte de Asistencia Mensual';
          break;
        case ReportType.custom:
          reportTitle = title ?? 'Reporte de Asistencia Personalizado';
          break;
        default:
          reportTitle = title ?? 'Reporte de Asistencia';
      }

      // Crear la hoja de resumen
      final Worksheet summarySheet = workbook.worksheets[0];
      summarySheet.name = 'Resumen';

      // Establecer el título
      summarySheet.getRangeByName('A1').setText(reportTitle);
      summarySheet.getRangeByName('A1').cellStyle.fontSize = 16;
      summarySheet.getRangeByName('A1').cellStyle.bold = true;

      // Establecer el subtítulo
      final dateFormat = DateFormat('dd/MM/yyyy');
      final reportPeriod =
          'Período: ${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}';
      summarySheet.getRangeByName('A2').setText(subtitle ?? reportPeriod);

      // Establecer el encabezado de la tabla
      summarySheet.getRangeByName('A4').setText('Empleado');
      summarySheet.getRangeByName('B4').setText('Asistencias');
      summarySheet.getRangeByName('C4').setText('Ausencias');
      summarySheet.getRangeByName('D4').setText('Retrasos');

      // Dar formato al encabezado
      summarySheet.getRangeByName('A4:D4').cellStyle.bold = true;
      summarySheet.getRangeByName('A4:D4').cellStyle.backColor = '#D3D3D3';

      // Agrupar los registros por usuario
      final userAttendance = <String, Map<String, dynamic>>{};

      for (final user in users) {
        userAttendance[user.id] = {
          'name': user.name,
          'attendance': 0,
          'absences': 0,
          'delays': 0,
        };
      }

      // Calcular días en el período
      final daysInPeriod = endDate.difference(startDate).inDays + 1;

      // Contar asistencias y retrasos
      for (final record in filteredRecords) {
        if (record.type == AttendanceType.checkIn) {
          if (userAttendance.containsKey(record.userId)) {
            userAttendance[record.userId]!['attendance'] += 1;

            // Verificar si hay retraso (por ejemplo, después de las 9:00 AM)
            final checkInTime = record.createdAt;
            final workStartTime = DateTime(
              checkInTime.year,
              checkInTime.month,
              checkInTime.day,
              9, // Hora de inicio laboral (9:00 AM)
              0,
            );

            if (checkInTime.isAfter(workStartTime)) {
              userAttendance[record.userId]!['delays'] += 1;
            }
          }
        }
      }

      // Calcular ausencias
      for (final userId in userAttendance.keys) {
        final attendance = userAttendance[userId]!['attendance'] as int;
        userAttendance[userId]!['absences'] = daysInPeriod - attendance;
      }

      // Llenar los datos de la tabla
      int row = 5;
      for (final userId in userAttendance.keys) {
        final data = userAttendance[userId]!;

        summarySheet.getRangeByName('A$row').setText(data['name']);
        summarySheet.getRangeByName('B$row').setNumber(data['attendance']);
        summarySheet.getRangeByName('C$row').setNumber(data['absences']);
        summarySheet.getRangeByName('D$row').setNumber(data['delays']);

        row++;
      }

      // Ajustar el ancho de las columnas
      summarySheet.getRangeByName('A:A').columnWidth = 30;
      summarySheet.getRangeByName('B:D').columnWidth = 15;

      // Crear la hoja de detalles
      final Worksheet detailsSheet = workbook.worksheets.add();
      detailsSheet.name = 'Detalles';

      // Establecer el título
      detailsSheet.getRangeByName('A1').setText('Detalles de Asistencia');
      detailsSheet.getRangeByName('A1').cellStyle.fontSize = 16;
      detailsSheet.getRangeByName('A1').cellStyle.bold = true;

      // Establecer el encabezado de la tabla
      detailsSheet.getRangeByName('A3').setText('Fecha');
      detailsSheet.getRangeByName('B3').setText('Empleado');
      detailsSheet.getRangeByName('C3').setText('Tipo');
      detailsSheet.getRangeByName('D3').setText('Hora');
      detailsSheet.getRangeByName('E3').setText('Ubicación');
      detailsSheet.getRangeByName('F3').setText('Validación');

      // Dar formato al encabezado
      detailsSheet.getRangeByName('A3:F3').cellStyle.bold = true;
      detailsSheet.getRangeByName('A3:F3').cellStyle.backColor = '#D3D3D3';

      // Ordenar los registros por fecha
      filteredRecords.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      // Llenar los datos de la tabla
      row = 4;
      for (final record in filteredRecords) {
        final user = users.firstWhere(
          (u) => u.id == record.userId,
          orElse: () => UserModel(
            id: record.userId,
            name: 'Usuario Desconocido',
            email: '',
            role: UserRole.assistant,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        final location = locations.firstWhere(
          (l) => l.id == record.locationId,
          orElse: () => LocationModel(
            id: record.locationId,
            name: 'Ubicación Desconocida',
            address: '',
            latitude: 0,
            longitude: 0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        String typeText;
        switch (record.type) {
          case AttendanceType.checkIn:
            typeText = 'Entrada';
            break;
          case AttendanceType.checkOut:
            typeText = 'Salida';
            break;
          case AttendanceType.lunchOut:
            typeText = 'Salida Almuerzo';
            break;
          case AttendanceType.lunchIn:
            typeText = 'Retorno Almuerzo';
            break;
          default:
            typeText = 'Desconocido';
        }

        detailsSheet
            .getRangeByName('A$row')
            .setText(dateFormat.format(record.createdAt));
        detailsSheet.getRangeByName('B$row').setText(user.name);
        detailsSheet.getRangeByName('C$row').setText(typeText);
        detailsSheet
            .getRangeByName('D$row')
            .setText(DateFormat('HH:mm').format(record.createdAt));
        detailsSheet.getRangeByName('E$row').setText(location.name);
        detailsSheet
            .getRangeByName('F$row')
            .setText(record.isValid ? 'Válido' : 'Inválido');

        row++;
      }

      // Ajustar el ancho de las columnas
      detailsSheet.getRangeByName('A:A').columnWidth = 15;
      detailsSheet.getRangeByName('B:B').columnWidth = 30;
      detailsSheet.getRangeByName('C:C').columnWidth = 20;
      detailsSheet.getRangeByName('D:D').columnWidth = 10;
      detailsSheet.getRangeByName('E:E').columnWidth = 25;
      detailsSheet.getRangeByName('F:F').columnWidth = 15;

      // Guardar el libro de Excel
      final List<int> bytes = workbook.saveAsStream();

      // Cerrar el libro de Excel
      workbook.dispose();

      return Uint8List.fromList(bytes);
    } catch (e) {
      debugPrint('Error al generar el reporte Excel: $e');
      throw ReportException(
          'Error al generar el reporte Excel: ${e.toString()}');
    }
  }

  @override
  Future<Uint8List> generatePdfReport({
    required ReportType type,
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
      switch (type) {
        case ReportType.daily:
          return await pdfService.generateDailyAttendanceReport(
            date: startDate,
            attendanceRecords: attendanceRecords,
            users: users,
            locations: locations,
            title: title,
            subtitle: subtitle,
            companyName: companyName,
            companyLogo: companyLogo,
          );
        case ReportType.weekly:
          return await pdfService.generateWeeklyAttendanceReport(
            startDate: startDate,
            endDate: endDate,
            attendanceRecords: attendanceRecords,
            users: users,
            locations: locations,
            title: title,
            subtitle: subtitle,
            companyName: companyName,
            companyLogo: companyLogo,
          );
        case ReportType.monthly:
          return await pdfService.generateMonthlyAttendanceReport(
            month: startDate,
            attendanceRecords: attendanceRecords,
            users: users,
            locations: locations,
            title: title,
            subtitle: subtitle,
            companyName: companyName,
            companyLogo: companyLogo,
          );
        case ReportType.custom:
          return await pdfService.generateCustomAttendanceReport(
            startDate: startDate,
            endDate: endDate,
            attendanceRecords: attendanceRecords,
            users: users,
            locations: locations,
            title: title,
            subtitle: subtitle,
            companyName: companyName,
            companyLogo: companyLogo,
            userId: userId,
            locationId: locationId,
          );
        default:
          throw ReportException('Tipo de reporte no soportado');
      }
    } catch (e) {
      debugPrint('Error al generar el reporte PDF: $e');
      throw ReportException('Error al generar el reporte PDF: ${e.toString()}');
    }
  }
}
