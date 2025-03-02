part of 'report_bloc.dart';

/// Clase base para todos los estados de reportes
abstract class ReportState extends Equatable {
  const ReportState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial antes de generar reportes
class ReportInitial extends ReportState {}

/// Estado cuando se está procesando una operación de reportes
class ReportLoading extends ReportState {}

/// Estado cuando se ha generado un reporte
class ReportGenerated extends ReportState {
  final ReportType reportType;
  final ReportFormat reportFormat;
  final DateTime startDate;
  final DateTime endDate;
  final Uint8List reportBytes;
  final String fileName;

  const ReportGenerated({
    required this.reportType,
    required this.reportFormat,
    required this.startDate,
    required this.endDate,
    required this.reportBytes,
    required this.fileName,
  });

  @override
  List<Object> get props => [
        reportType,
        reportFormat,
        startDate,
        endDate,
        reportBytes,
        fileName,
      ];
}

/// Estado cuando se ha visualizado un reporte
class ReportViewed extends ReportState {
  final Uint8List reportBytes;
  final String fileName;

  const ReportViewed({
    required this.reportBytes,
    required this.fileName,
  });

  @override
  List<Object> get props => [reportBytes, fileName];
}

/// Estado cuando se ha descargado un reporte
class ReportDownloaded extends ReportState {
  final Uint8List reportBytes;
  final String fileName;

  const ReportDownloaded({
    required this.reportBytes,
    required this.fileName,
  });

  @override
  List<Object> get props => [reportBytes, fileName];
}

/// Estado cuando ocurre un error en el proceso de reportes
class ReportError extends ReportState {
  final String message;

  const ReportError({
    required this.message,
  });

  @override
  List<Object> get props => [message];
}
