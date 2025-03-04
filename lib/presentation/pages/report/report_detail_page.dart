import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:attendance_app/core/platform/platform_info.dart';
import 'package:attendance_app/domain/entities/report.dart';
import 'package:attendance_app/presentation/bloc/report/report_bloc.dart';
import 'package:attendance_app/presentation/widgets/common/app_bar.dart';
import 'package:attendance_app/presentation/widgets/common/snackbar.dart';

/// Página de detalle de un reporte
class ReportDetailPage extends StatelessWidget {
  /// Reporte a mostrar
  final Report report;

  /// Usuario actual
  final PlatformInfo platformInfo;

  /// Constructor
  const ReportDetailPage({
    Key? key,
    required this.report,
    required this.platformInfo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppCustomAppBar(
        title: 'Detalle del Reporte',
        platformInfo: platformInfo,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Descargar',
            onPressed: () {
              context.read<ReportBloc>().add(DownloadReportEvent(
                    reportBytes:
                        Uint8List(0), // Deberías guardar los bytes del reporte
                    fileName: _getFileName(),
                  ));
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Compartir',
            onPressed: () {
              // Lógica para compartir
              AppSnackBar.showInfo(
                context: context,
                message: 'Función de compartir en desarrollo',
                platformInfo: platformInfo,
              );
            },
          ),
        ],
      ),
      body: BlocListener<ReportBloc, ReportState>(
        listener: (context, state) {
          if (state is ReportDownloaded) {
            AppSnackBar.showSuccess(
              context: context,
              message: 'Reporte descargado correctamente',
              platformInfo: platformInfo,
            );
          } else if (state is ReportError) {
            AppSnackBar.showError(
              context: context,
              message: state.message,
              platformInfo: platformInfo,
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tarjeta de información del reporte
              _buildReportInfoCard(context),
              const SizedBox(height: 24),

              // Previsualización del reporte
              _buildReportPreview(context),
              const SizedBox(height: 24),

              // Acciones
              _buildActions(context),
            ],
          ),
        ),
      ),
    );
  }

  /// Construye la tarjeta de información del reporte
  Widget _buildReportInfoCard(BuildContext context) {
    final DateFormat dateFormat = DateFormat('dd/MM/yyyy');

    String reportTypeText;
    switch (report.type) {
      case ReportType.daily:
        reportTypeText = 'Diario';
        break;
      case ReportType.weekly:
        reportTypeText = 'Semanal';
        break;
      case ReportType.monthly:
        reportTypeText = 'Mensual';
        break;
      case ReportType.custom:
        reportTypeText = 'Personalizado';
        break;
    }

    String formatText;
    switch (report.format) {
      case ReportFormat.pdf:
        formatText = 'PDF';
        break;
      case ReportFormat.excel:
        formatText = 'Excel';
        break;
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              report.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              report.description,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              context,
              'Tipo de reporte:',
              reportTypeText,
              Icons.description,
            ),
            _buildInfoRow(
              context,
              'Formato:',
              formatText,
              report.format == ReportFormat.pdf
                  ? Icons.picture_as_pdf
                  : Icons.table_chart,
            ),
            _buildInfoRow(
              context,
              'Período:',
              '${dateFormat.format(report.startDate)} - ${dateFormat.format(report.endDate)}',
              Icons.date_range,
            ),
            _buildInfoRow(
              context,
              'Fecha de creación:',
              dateFormat.format(report.createdAt),
              Icons.calendar_today,
            ),
            _buildInfoRow(
              context,
              'Tamaño:',
              _formatFileSize(report.fileSize),
              Icons.storage,
            ),
          ],
        ),
      ),
    );
  }

  /// Construye una fila de información
  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData iconData,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(iconData, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construye la previsualización del reporte
  Widget _buildReportPreview(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Previsualización',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          height: 400,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: report.format == ReportFormat.pdf
              ? _buildPdfPreview(context)
              : _buildExcelPreview(context),
        ),
      ],
    );
  }

  /// Construye la previsualización de un PDF
  Widget _buildPdfPreview(BuildContext context) {
    // En una implementación real, aquí se mostraría una previsualización del PDF
    // usando un paquete como pdf_viewer_plugin o similar
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.picture_as_pdf,
            size: 64,
            color: Colors.red[700],
          ),
          const SizedBox(height: 16),
          const Text(
            'Archivo PDF',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.visibility),
            label: const Text('Ver completo'),
            onPressed: () {
              // En una implementación real, aquí se abriría el visualizador de PDF
              context.read<ReportBloc>().add(ViewReportEvent(
                    reportBytes:
                        Uint8List(0), // Deberías guardar los bytes del reporte
                    fileName: _getFileName(),
                    reportFormat: report.format,
                  ));
            },
          ),
        ],
      ),
    );
  }

  /// Construye la previsualización de un Excel
  Widget _buildExcelPreview(BuildContext context) {
    // En una implementación real, aquí se mostraría una previsualización del Excel
    // lo que es más complicado, posiblemente mostrando una tabla con algunos datos
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.table_chart,
            size: 64,
            color: Colors.green[700],
          ),
          const SizedBox(height: 16),
          const Text(
            'Archivo Excel',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.download),
            label: const Text('Descargar para ver'),
            onPressed: () {
              context.read<ReportBloc>().add(DownloadReportEvent(
                    reportBytes:
                        Uint8List(0), // Deberías guardar los bytes del reporte
                    fileName: _getFileName(),
                  ));
            },
          ),
        ],
      ),
    );
  }

  /// Construye las acciones disponibles
  Widget _buildActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.visibility),
          label: const Text('Ver'),
          onPressed: () {
            context.read<ReportBloc>().add(ViewReportEvent(
                  reportBytes:
                      Uint8List(0), // Deberías guardar los bytes del reporte
                  fileName: _getFileName(),
                  reportFormat: report.format,
                ));
          },
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.download),
          label: const Text('Descargar'),
          onPressed: () {
            context.read<ReportBloc>().add(DownloadReportEvent(
                  reportBytes:
                      Uint8List(0), // Deberías guardar los bytes del reporte
                  fileName: _getFileName(),
                ));
          },
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.share),
          label: const Text('Compartir'),
          onPressed: () {
            // Lógica para compartir
            AppSnackBar.showInfo(
              context: context,
              message: 'Función de compartir en desarrollo',
              platformInfo: platformInfo,
            );
          },
        ),
      ],
    );
  }

  /// Formatea el tamaño de archivo
  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  /// Obtiene el nombre de archivo para el reporte
  String _getFileName() {
    final dateStr = DateFormat('yyyy-MM-dd').format(report.createdAt);
    final extension = report.format == ReportFormat.pdf ? 'pdf' : 'xlsx';
    return '${report.name.replaceAll(' ', '_')}_$dateStr.$extension';
  }
}
