import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:attendance_app/domain/entities/report.dart';
import 'package:attendance_app/domain/usecases/attendance/generate_attendance_report.dart';
import 'package:attendance_app/services/report_service.dart';
import 'package:attendance_app/data/models/attendance_model.dart';
import 'package:attendance_app/data/models/user_model.dart';
import 'package:attendance_app/data/models/location_model.dart';

part 'report_event.dart';
part 'report_state.dart';

/// BLoC para gestionar el estado de reportes
class ReportBloc extends Bloc<ReportEvent, ReportState> {
  final GenerateAttendanceReport generateAttendanceReport;
  final ReportService reportService;

  ReportBloc({
    required this.generateAttendanceReport,
    required this.reportService,
  }) : super(ReportInitial()) {
    // Generar un reporte
    on<GenerateReportEvent>(_onGenerateReport);

    // Visualizar un reporte
    on<ViewReportEvent>(_onViewReport);

    // Descargar un reporte
    on<DownloadReportEvent>(_onDownloadReport);
  }

  /// Maneja el evento para generar un reporte
  Future<void> _onGenerateReport(
    GenerateReportEvent event,
    Emitter<ReportState> emit,
  ) async {
    emit(ReportLoading());

    try {
      // Generar reporte usando el servicio de reportes
      final reportBytes = await reportService.generateReport(
        type: event.reportType,
        startDate: event.startDate,
        endDate: event.endDate,
        attendanceRecords: event.attendanceRecords,
        users: event.users,
        locations: event.locations,
        format: event.reportFormat,
        title: event.title,
        subtitle: event.subtitle,
        companyName: event.companyName,
        companyLogo: event.companyLogo,
        userId: event.userId,
        locationId: event.locationId,
      );

      // Generar nombre de archivo para el reporte
      final fileName = _generateReportFileName(
        event.reportType,
        event.startDate,
        event.endDate,
        event.reportFormat,
      );

      emit(ReportGenerated(
        reportType: event.reportType,
        reportFormat: event.reportFormat,
        startDate: event.startDate,
        endDate: event.endDate,
        reportBytes: reportBytes,
        fileName: fileName,
      ));
    } catch (e) {
      emit(
          ReportError(message: 'Error al generar el reporte: ${e.toString()}'));
    }
  }

  /// Maneja el evento para visualizar un reporte
  Future<void> _onViewReport(
    ViewReportEvent event,
    Emitter<ReportState> emit,
  ) async {
    try {
      if (event.reportFormat == ReportFormat.pdf) {
        await reportService.pdfervice.previewPdf(
          event.reportBytes,
          title: event.fileName,
        );

        emit(ReportViewed(
          reportBytes: event.reportBytes,
          fileName: event.fileName,
        ));
      } else {
        // Para Excel u otros formatos, se debe manejar de otra manera
        // (por ejemplo, abrir con una biblioteca externa)
        emit(const ReportError(
            message: 'La previsualización solo está disponible para PDF.'));
      }
    } catch (e) {
      emit(ReportError(
          message: 'Error al visualizar el reporte: ${e.toString()}'));
    }
  }

  /// Maneja el evento para descargar un reporte
  Future<void> _onDownloadReport(
    DownloadReportEvent event,
    Emitter<ReportState> emit,
  ) async {
    try {
      // Aquí se implementaría la lógica para descargar el archivo
      // Utilizando un servicio de almacenamiento o compartir archivos

      // Por ahora, solo simulamos que se ha descargado
      emit(ReportDownloaded(
        reportBytes: event.reportBytes,
        fileName: event.fileName,
      ));
    } catch (e) {
      emit(ReportError(
          message: 'Error al descargar el reporte: ${e.toString()}'));
    }
  }

  /// Genera un nombre de archivo para el reporte
  String _generateReportFileName(
    ReportType reportType,
    DateTime startDate,
    DateTime endDate,
    ReportFormat reportFormat,
  ) {
    final dateFormat = (day) =>
        '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    final extension = reportFormat == ReportFormat.pdf ? '.pdf' : '.xlsx';

    switch (reportType) {
      case ReportType.daily:
        return 'reporte_diario_${dateFormat(startDate)}$extension';
      case ReportType.weekly:
        return 'reporte_semanal_${dateFormat(startDate)}_a_${dateFormat(endDate)}$extension';
      case ReportType.monthly:
        return 'reporte_mensual_${startDate.year}_${startDate.month.toString().padLeft(2, '0')}$extension';
      case ReportType.custom:
        return 'reporte_personalizado_${dateFormat(startDate)}_a_${dateFormat(endDate)}$extension';
      default:
        return 'reporte$extension';
    }
  }
}
