import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Widget para capturar la firma del usuario
class SignaturePad extends StatefulWidget {
  /// Ancho del widget
  final double width;

  /// Alto del widget
  final double height;

  /// Color del trazo
  final Color strokeColor;

  /// Ancho del trazo
  final double strokeWidth;

  /// Color del fondo del pad
  final Color backgroundColor;

  /// Mensaje de guía para el usuario
  final String? hintText;

  /// Estilo del texto de la guía
  final TextStyle? hintTextStyle;

  /// Si la firma debe adaptarse para ser mostrada en el contenedor
  final bool fitSignatureToContainer;

  /// Callback cuando la firma cambia
  final Function(List<Offset>? points)? onChanged;

  /// Constructor del widget
  const SignaturePad({
    Key? key,
    this.width = double.infinity,
    this.height = 180,
    this.strokeColor = Colors.black,
    this.strokeWidth = 3.0,
    this.backgroundColor = Colors.white,
    this.hintText,
    this.hintTextStyle,
    this.fitSignatureToContainer = true,
    this.onChanged,
  }) : super(key: key);

  @override
  State<SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<SignaturePad> {
  List<List<Offset>> _strokes = [];
  List<Offset>? _currentStroke;
  final GlobalKey _key = GlobalKey();

  // Limpiar la firma
  void clear() {
    setState(() {
      _strokes = [];
      _currentStroke = null;
    });

    if (widget.onChanged != null) {
      widget.onChanged!(null);
    }
  }

  // Captura la imagen de la firma como bytes
  Future<Uint8List?> captureSignature() async {
    if (_strokes.isEmpty) {
      return null;
    }

    try {
      // Encontrar el RenderObject asociado con este widget
      final RenderRepaintBoundary boundary =
          _key.currentContext!.findRenderObject() as RenderRepaintBoundary;

      // Convertir a imagen
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);

      // Convertir la imagen a bytes
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        return byteData.buffer.asUint8List();
      }

      return null;
    } catch (e) {
      debugPrint('Error capturing signature: $e');
      return null;
    }
  }

  // Obtener todos los puntos de la firma
  List<Offset> getAllPoints() {
    final allPoints = <Offset>[];
    for (final stroke in _strokes) {
      allPoints.addAll(stroke);
    }
    return allPoints;
  }

  // Convertir punto de pantalla a coordenadas locales
  Offset _localPosition(Offset position) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    return box.globalToLocal(position);
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: _key,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            // Área de firma
            GestureDetector(
              onPanStart: (details) {
                setState(() {
                  _currentStroke = [_localPosition(details.globalPosition)];
                  _strokes.add(_currentStroke!);
                });
              },
              onPanUpdate: (details) {
                setState(() {
                  if (_currentStroke != null) {
                    _currentStroke!.add(_localPosition(details.globalPosition));

                    // Notificar cambios
                    if (widget.onChanged != null) {
                      widget.onChanged!(getAllPoints());
                    }
                  }
                });
              },
              onPanEnd: (details) {
                setState(() {
                  _currentStroke = null;
                });
              },
              child: CustomPaint(
                painter: _SignaturePainter(
                  strokes: _strokes,
                  strokeColor: widget.strokeColor,
                  strokeWidth: widget.strokeWidth,
                  fitToContainer: widget.fitSignatureToContainer,
                ),
                size: Size(widget.width, widget.height),
              ),
            ),

            // Mensaje de guía
            if (widget.hintText != null && _strokes.isEmpty)
              Center(
                child: Text(
                  widget.hintText!,
                  style: widget.hintTextStyle ??
                      TextStyle(color: Colors.grey[500], fontSize: 16),
                ),
              ),

            // Botón para limpiar
            Positioned(
              top: 5,
              right: 5,
              child: IconButton(
                icon: const Icon(Icons.clear, size: 20),
                onPressed: clear,
                tooltip: 'Limpiar firma',
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pintor personalizado para dibujar la firma
class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final Color strokeColor;
  final double strokeWidth;
  final bool fitToContainer;

  _SignaturePainter({
    required this.strokes,
    required this.strokeColor,
    required this.strokeWidth,
    required this.fitToContainer,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (strokes.isEmpty) return;

    final paint = Paint()
      ..color = strokeColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Si necesitamos ajustar la firma al contenedor
    double minX = double.infinity;
    double maxX = -double.infinity;
    double minY = double.infinity;
    double maxY = -double.infinity;

    if (fitToContainer) {
      // Encontrar los límites de todos los trazos
      for (final stroke in strokes) {
        for (final point in stroke) {
          minX = min(minX, point.dx);
          maxX = max(maxX, point.dx);
          minY = min(minY, point.dy);
          maxY = max(maxY, point.dy);
        }
      }

      // Si hay puntos suficientes para calcular un límite
      if (minX < double.infinity &&
          maxX > -double.infinity &&
          minY < double.infinity &&
          maxY > -double.infinity) {
        final signatureWidth = maxX - minX;
        final signatureHeight = maxY - minY;

        if (signatureWidth > 0 && signatureHeight > 0) {
          // Calcular factores de escala
          final scaleX = (size.width - 20) / signatureWidth;
          final scaleY = (size.height - 20) / signatureHeight;

          // Usar la escala más pequeña para mantener la proporción
          final scale = min(scaleX, scaleY);

          // Calcular el offset para centrar
          final offsetX =
              (size.width - signatureWidth * scale) / 2 - minX * scale;
          final offsetY =
              (size.height - signatureHeight * scale) / 2 - minY * scale;

          // Aplicar transformación al canvas
          canvas.save();
          canvas.translate(offsetX, offsetY);
          canvas.scale(scale, scale);
        }
      }
    }

    // Dibujar cada trazo
    for (final stroke in strokes) {
      if (stroke.length < 2) continue;

      final path = Path();
      path.moveTo(stroke.first.dx, stroke.first.dy);

      for (int i = 1; i < stroke.length; i++) {
        // Suavizar la línea usando una curva de Bézier si hay suficientes puntos
        if (i < stroke.length - 1) {
          final p0 = stroke[i - 1];
          final p1 = stroke[i];
          final p2 = stroke[i + 1];

          // Punto de control para suavizar
          final xc1 = (p0.dx + p1.dx) / 2;
          final yc1 = (p0.dy + p1.dy) / 2;
          final xc2 = (p1.dx + p2.dx) / 2;
          final yc2 = (p1.dy + p2.dy) / 2;

          path.quadraticBezierTo(p1.dx, p1.dy, xc2, yc2);
        } else {
          path.lineTo(stroke[i].dx, stroke[i].dy);
        }
      }

      canvas.drawPath(path, paint);
    }

    if (fitToContainer) {
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_SignaturePainter oldDelegate) {
    return oldDelegate.strokes != strokes ||
        oldDelegate.strokeColor != strokeColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.fitToContainer != fitToContainer;
  }
}

/// Extensión para [SignaturePad] que proporciona métodos para exportar la firma
extension SignaturePadExtension on SignaturePad {
  /// Obtiene el estado actual del [SignaturePad]
  _SignaturePadState? get state {
    return currentState as _SignaturePadState?;
  }

  /// Captura la firma actual como una imagen [Uint8List]
  Future<Uint8List?> capture() async {
    return await state?.captureSignature();
  }

  /// Limpia la firma actual
  void clear() {
    state?.clear();
  }
}
