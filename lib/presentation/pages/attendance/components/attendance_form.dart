import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:attendance_app/domain/entities/attendance.dart';
import 'package:attendance_app/domain/entities/location.dart';
import 'package:attendance_app/presentation/bloc/attendance/attendance_bloc.dart';
import 'package:attendance_app/presentation/pages/attendance/components/camera_widget.dart';
import 'package:attendance_app/presentation/pages/attendance/components/signature_widget.dart';
import 'package:geolocator/geolocator.dart';

/// Formulario para registrar asistencia
class AttendanceForm extends StatefulWidget {
  /// ID del usuario que registra la asistencia
  final String userId;

  /// Tipo de registro de asistencia
  final AttendanceType type;

  /// Lista de ubicaciones disponibles
  final List<Location> locations;

  /// Constructor del formulario de asistencia
  const AttendanceForm({
    Key? key,
    required this.userId,
    required this.type,
    required this.locations,
  }) : super(key: key);

  @override
  State<AttendanceForm> createState() => _AttendanceFormState();
}

class _AttendanceFormState extends State<AttendanceForm> {
  // Variables de estado
  Location? _selectedLocation;
  Uint8List? _photoBytes;
  Uint8List? _signatureBytes;
  Position? _currentPosition;
  bool _isLoadingLocation = false;
  bool _isLocationVerified = false;

  @override
  void initState() {
    super.initState();
    _initLocation();
    // Seleccionar la primera ubicación por defecto
    if (widget.locations.isNotEmpty) {
      _selectedLocation = widget.locations.first;
    }
  }

  // Inicializar la ubicación
  Future<void> _initLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Verificar permisos de ubicación
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      // Obtener ubicación actual
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });

      // Verificar si la ubicación es válida
      _verifyLocation();
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
      });
      _showErrorSnackBar('Error al obtener la ubicación: $e');
    }
  }

  // Verificar si la ubicación es válida
  void _verifyLocation() {
    if (_currentPosition == null || _selectedLocation == null) return;

    context.read<AttendanceBloc>().add(
          CheckLocationEvent(
            locationId: _selectedLocation!.id,
            userLatitude: _currentPosition!.latitude,
            userLongitude: _currentPosition!.longitude,
          ),
        );
  }

  // Mostrar un mensaje de error
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // Registrar la asistencia
  void _submitAttendance() {
    if (_selectedLocation == null) {
      _showErrorSnackBar('Selecciona una ubicación');
      return;
    }

    if (_photoBytes == null) {
      _showErrorSnackBar('Toma una foto para el registro');
      return;
    }

    if (_signatureBytes == null) {
      _showErrorSnackBar('Firma para completar el registro');
      return;
    }

    if (!_isLocationVerified) {
      _showErrorSnackBar('Tu ubicación no ha sido verificada');
      return;
    }

    // Enviar evento para crear el registro de asistencia
    context.read<AttendanceBloc>().add(
          CreateAttendanceEvent(
            userId: widget.userId,
            locationId: _selectedLocation!.id,
            type: widget.type,
            photoBytes: _photoBytes!,
            signatureBytes: _signatureBytes!,
            latitude: _currentPosition?.latitude,
            longitude: _currentPosition?.longitude,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AttendanceBloc, AttendanceState>(
      listener: (context, state) {
        if (state is LocationCheckPassed) {
          setState(() {
            _isLocationVerified = true;
          });
        } else if (state is LocationCheckFailed) {
          setState(() {
            _isLocationVerified = false;
          });
          _showErrorSnackBar(state.message);
        } else if (state is AttendanceRecordCreated) {
          // Registro creado exitosamente
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registro de asistencia guardado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
          // Navegar atrás
          Navigator.of(context).pop(true);
        } else if (state is AttendanceError) {
          _showErrorSnackBar(state.message);
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Título del formulario
              Text(
                _getFormTitle(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Selector de ubicación
              _buildLocationSelector(),
              const SizedBox(height: 16),

              // Indicador de ubicación
              _buildLocationStatus(),
              const SizedBox(height: 24),

              // Captura de foto
              const Text(
                'Toma una foto para el registro:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              CameraWidget(
                onImageCaptured: (imageBytes) {
                  setState(() {
                    _photoBytes = imageBytes;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Captura de firma
              const Text(
                'Firma para completar el registro:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SignaturePad(
                width: double.infinity,
                height: 200,
                hintText: 'Firma aquí',
                onChanged: (points) {
                  // Aquí capturamos los cambios, pero realmente necesitamos la imagen
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  // Este método debería comunicarse con el SignaturePad para obtener la imagen
                  // Para este ejemplo, simulamos que tenemos una firma
                  // En una implementación real, se utilizaría una referencia o método en SignaturePad
                  // para obtener la imagen como Uint8List
                  setState(() {
                    // Simular una firma para este ejemplo
                    _signatureBytes = Uint8List.fromList(
                        List.generate(100, (index) => index));
                  });
                },
                child: const Text('Guardar Firma'),
              ),
              const SizedBox(height: 32),

              // Botón de envío
              BlocBuilder<AttendanceBloc, AttendanceState>(
                builder: (context, state) {
                  return ElevatedButton(
                    onPressed:
                        state is AttendanceLoading ? null : _submitAttendance,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: _getButtonColor(),
                    ),
                    child: state is AttendanceLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            _getButtonText(),
                            style: const TextStyle(
                                fontSize: 18, color: Colors.white),
                          ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Construye el selector de ubicación
  Widget _buildLocationSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ubicación:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<Location>(
          value: _selectedLocation,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          items: widget.locations.map((location) {
            return DropdownMenuItem<Location>(
              value: location,
              child: Text(location.name),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedLocation = value;
              _isLocationVerified = false;
            });
            _verifyLocation();
          },
        ),
      ],
    );
  }

  // Construye el indicador de estado de ubicación
  Widget _buildLocationStatus() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              _isLoadingLocation
                  ? Icons.hourglass_top
                  : _isLocationVerified
                      ? Icons.check_circle
                      : Icons.error,
              color: _isLoadingLocation
                  ? Colors.orange
                  : _isLocationVerified
                      ? Colors.green
                      : Colors.red,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isLoadingLocation
                        ? 'Verificando ubicación...'
                        : _isLocationVerified
                            ? 'Ubicación verificada'
                            : 'Ubicación no válida',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_currentPosition != null)
                    Text(
                      'Lat: ${_currentPosition!.latitude.toStringAsFixed(6)}, Lon: ${_currentPosition!.longitude.toStringAsFixed(6)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
            if (!_isLoadingLocation && !_isLocationVerified)
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  _initLocation();
                },
                tooltip: 'Reintentar',
              ),
          ],
        ),
      ),
    );
  }

  // Obtiene el título del formulario según el tipo de registro
  String _getFormTitle() {
    switch (widget.type) {
      case AttendanceType.checkIn:
        return 'Registro de Entrada';
      case AttendanceType.checkOut:
        return 'Registro de Salida';
      case AttendanceType.lunchOut:
        return 'Salida a Almuerzo';
      case AttendanceType.lunchIn:
        return 'Regreso de Almuerzo';
    }
  }

  // Obtiene el texto del botón según el tipo de registro
  String _getButtonText() {
    switch (widget.type) {
      case AttendanceType.checkIn:
        return 'Registrar Entrada';
      case AttendanceType.checkOut:
        return 'Registrar Salida';
      case AttendanceType.lunchOut:
        return 'Registrar Salida a Almuerzo';
      case AttendanceType.lunchIn:
        return 'Registrar Regreso de Almuerzo';
    }
  }

  // Obtiene el color del botón según el tipo de registro
  Color _getButtonColor() {
    switch (widget.type) {
      case AttendanceType.checkIn:
        return Colors.green;
      case AttendanceType.checkOut:
        return Colors.red;
      case AttendanceType.lunchOut:
        return Colors.orange;
      case AttendanceType.lunchIn:
        return Colors.amber;
    }
  }
}
