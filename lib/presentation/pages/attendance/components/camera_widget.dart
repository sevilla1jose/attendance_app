import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;

/// Widget para capturar fotos
class CameraWidget extends StatefulWidget {
  /// Callback cuando se captura una imagen
  final Function(Uint8List) onImageCaptured;

  /// Constructor del widget de cámara
  const CameraWidget({
    Key? key,
    required this.onImageCaptured,
  }) : super(key: key);

  @override
  State<CameraWidget> createState() => _CameraWidgetState();
}

class _CameraWidgetState extends State<CameraWidget>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isCapturing = false;
  bool _isFrontCamera = true;
  Uint8List? _capturedImage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Gestionar cambios en el ciclo de vida de la app
    final CameraController? cameraController = _controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      // Obtener cámaras disponibles
      _cameras = await availableCameras();

      if (_cameras!.isEmpty) {
        setState(() {
          _isCameraInitialized = false;
        });
        return;
      }

      // Seleccionar cámara frontal por defecto
      CameraDescription selectedCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      // Inicializar controlador
      _controller = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error al inicializar la cámara: $e');
      setState(() {
        _isCameraInitialized = false;
      });
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_isCameraInitialized || _isCapturing) {
      return;
    }

    try {
      setState(() {
        _isCapturing = true;
      });

      // Capturar imagen
      final XFile file = await _controller!.takePicture();

      // Procesar imagen capturada
      Uint8List imageBytes;

      if (kIsWeb) {
        // Para web
        imageBytes = await file.readAsBytes();
      } else {
        // Para móviles
        File imageFile = File(file.path);
        imageBytes = await imageFile.readAsBytes();
      }

      // Redimensionar y comprimir imagen para un tamaño más manejable
      imageBytes = await _processImage(imageBytes);

      setState(() {
        _capturedImage = imageBytes;
        _isCapturing = false;
      });

      // Llamar al callback con la imagen capturada
      widget.onImageCaptured(imageBytes);
    } catch (e) {
      debugPrint('Error al tomar la foto: $e');
      setState(() {
        _isCapturing = false;
      });
    }
  }

  Future<void> _toggleCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;

    setState(() {
      _isFrontCamera = !_isFrontCamera;
      _isCameraInitialized = false;
    });

    await _controller?.dispose();

    // Seleccionar la cámara opuesta
    CameraDescription selectedCamera = _cameras!.firstWhere(
      (camera) => _isFrontCamera
          ? camera.lensDirection == CameraLensDirection.front
          : camera.lensDirection == CameraLensDirection.back,
      orElse: () => _cameras!.first,
    );

    // Inicializar controlador con la nueva cámara
    _controller = CameraController(
      selectedCamera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await _controller!.initialize();

    if (mounted) {
      setState(() {
        _isCameraInitialized = true;
      });
    }
  }

  Future<Uint8List> _processImage(Uint8List imageBytes) async {
    // Decodificar la imagen
    img.Image? image = img.decodeImage(imageBytes);
    if (image == null) return imageBytes;

    // Redimensionar a un tamaño más pequeño (por ejemplo, 480x640)
    int targetWidth = 480;
    int targetHeight = (image.height * targetWidth / image.width).round();
    img.Image resizedImage = img.copyResize(
      image,
      width: targetWidth,
      height: targetHeight,
    );

    // Codificar la imagen con compresión
    List<int> jpegBytes = img.encodeJpg(resizedImage, quality: 85);

    return Uint8List.fromList(jpegBytes);
  }

  @override
  Widget build(BuildContext context) {
    if (_capturedImage != null) {
      return _buildCapturedImageView();
    } else {
      return _buildCameraView();
    }
  }

  Widget _buildCameraView() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            if (!_isCameraInitialized) ...[
              // Indicador de carga mientras se inicializa la cámara
              const Center(
                child: CircularProgressIndicator(),
              ),
            ] else ...[
              // Previsualización de la cámara
              Center(
                child: CameraPreview(_controller!),
              ),
            ],

            // Controles de la cámara
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 100,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Botón para cambiar de cámara
                    IconButton(
                      icon: const Icon(Icons.flip_camera_ios),
                      color: Colors.white,
                      onPressed: _cameras != null && _cameras!.length > 1
                          ? _toggleCamera
                          : null,
                    ),

                    // Botón para tomar foto
                    GestureDetector(
                      onTap: _takePicture,
                      child: Container(
                        height: 60,
                        width: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 3,
                          ),
                        ),
                        child: _isCapturing
                            ? const CircularProgressIndicator()
                            : const Icon(Icons.camera_alt),
                      ),
                    ),

                    // Espacio para equilibrar el diseño
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapturedImageView() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Imagen capturada
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              _capturedImage!,
              fit: BoxFit.cover,
            ),
          ),

          // Controles
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 80,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Botón para rechazar y tomar otra foto
                  ElevatedButton.icon(
                    icon: const Icon(Icons.replay),
                    label: const Text('Volver a tomar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        _capturedImage = null;
                      });
                    },
                  ),

                  // Botón para aceptar la foto
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('Aceptar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      // La foto ya fue enviada al onImageCaptured cuando se tomó
                      // Este botón es solo para confirmar visualmente
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
