import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:attendance_app/core/platform/platform_info.dart';
import 'package:attendance_app/core/utils/validators.dart';
import 'package:attendance_app/domain/entities/location.dart';
import 'package:attendance_app/domain/entities/user.dart';
import 'package:attendance_app/presentation/bloc/location/location_bloc.dart';
import 'package:attendance_app/presentation/widgets/common/app_bar.dart';
import 'package:attendance_app/presentation/widgets/common/loading_indicator.dart';
import 'package:attendance_app/presentation/widgets/common/snackbar.dart';

/// Página para crear o editar ubicaciones
class LocationFormPage extends StatefulWidget {
  /// Ubicación a editar (nulo si es creación)
  final Location? location;

  /// Usuario actual
  final User currentUser;

  /// Información de la plataforma
  final PlatformInfo platformInfo;

  /// Constructor
  const LocationFormPage({
    Key? key,
    this.location,
    required this.currentUser,
    required this.platformInfo,
  }) : super(key: key);

  @override
  State<LocationFormPage> createState() => _LocationFormPageState();
}

class _LocationFormPageState extends State<LocationFormPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _radiusController = TextEditingController();

  bool _isActive = true;
  bool _isGettingLocation = false;

  @override
  void initState() {
    super.initState();

    // Si es edición, cargamos los datos de la ubicación
    if (widget.location != null) {
      _nameController.text = widget.location!.name;
      _addressController.text = widget.location!.address;
      _latitudeController.text = widget.location!.latitude.toString();
      _longitudeController.text = widget.location!.longitude.toString();
      _radiusController.text = widget.location!.radius.toString();
      _isActive = widget.location!.isActive;
    } else {
      // Valores por defecto para nueva ubicación
      _radiusController.text = '100'; // 100 metros por defecto
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  /// Obtiene la ubicación actual del dispositivo
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
    });

    try {
      // Verificar permisos
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          AppSnackBar.showError(
            context: context,
            message: 'Permiso de ubicación denegado',
            platformInfo: widget.platformInfo,
          );
          setState(() {
            _isGettingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        AppSnackBar.showError(
          context: context,
          message:
              'Los permisos de ubicación están permanentemente denegados, no se puede solicitar permiso',
          platformInfo: widget.platformInfo,
        );
        setState(() {
          _isGettingLocation = false;
        });
        return;
      }

      // Obtener ubicación
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitudeController.text = position.latitude.toString();
        _longitudeController.text = position.longitude.toString();
        _isGettingLocation = false;
      });
    } catch (e) {
      AppSnackBar.showError(
        context: context,
        message: 'Error al obtener la ubicación: $e',
        platformInfo: widget.platformInfo,
      );
      setState(() {
        _isGettingLocation = false;
      });
    }
  }

  /// Guarda la ubicación
  void _saveLocation() {
    if (_formKey.currentState?.validate() ?? false) {
      final name = _nameController.text.trim();
      final address = _addressController.text.trim();
      final latitude = double.parse(_latitudeController.text.trim());
      final longitude = double.parse(_longitudeController.text.trim());
      final radius = double.parse(_radiusController.text.trim());

      if (widget.location == null) {
        // Crear nueva ubicación
        context.read<LocationBloc>().add(
              AddLocationEvent(
                name: name,
                address: address,
                latitude: latitude,
                longitude: longitude,
                radius: radius,
              ),
            );
      } else {
        // Actualizar ubicación existente
        context.read<LocationBloc>().add(
              UpdateLocationEvent(
                id: widget.location!.id,
                name: name,
                address: address,
                latitude: latitude,
                longitude: longitude,
                radius: radius,
                isActive: _isActive,
              ),
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.location != null;
    final String title = isEditing ? 'Editar Ubicación' : 'Nueva Ubicación';

    return Scaffold(
      appBar: AppCustomAppBar(
        title: title,
        platformInfo: widget.platformInfo,
      ),
      body: BlocConsumer<LocationBloc, LocationState>(
        listener: (context, state) {
          if (state is LocationAdded || state is LocationUpdated) {
            // Navegamos atrás y enviamos true para indicar éxito
            Navigator.of(context).pop(true);
          } else if (state is LocationError) {
            AppSnackBar.showError(
              context: context,
              message: state.message,
              platformInfo: widget.platformInfo,
            );
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              // Formulario
              SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombre
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre de la ubicación',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.business),
                        ),
                        validator: (value) => Validators.validateRequired(value,
                            fieldName: 'Nombre'),
                      ),
                      const SizedBox(height: 16),

                      // Dirección
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Dirección',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        validator: (value) => Validators.validateRequired(value,
                            fieldName: 'Dirección'),
                      ),
                      const SizedBox(height: 24),

                      // Coordenadas
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Coordenadas',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed:
                                _isGettingLocation ? null : _getCurrentLocation,
                            icon: const Icon(Icons.my_location),
                            label: const Text('Ubicación actual'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Latitud
                      TextFormField(
                        controller: _latitudeController,
                        decoration: const InputDecoration(
                          labelText: 'Latitud',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.compass_calibration),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        validator: Validators.validateLatitude,
                      ),
                      const SizedBox(height: 16),

                      // Longitud
                      TextFormField(
                        controller: _longitudeController,
                        decoration: const InputDecoration(
                          labelText: 'Longitud',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.compass_calibration),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        validator: Validators.validateLongitude,
                      ),
                      const SizedBox(height: 24),

                      // Radio
                      Text(
                        'Radio de validación (metros)',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _radiusController,
                        decoration: const InputDecoration(
                          labelText: 'Radio en metros',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.radio_button_checked),
                          hintText: 'Ej: 100',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) => Validators.validateNumericRange(
                          value,
                          min: 10,
                          max: 1000,
                          fieldName: 'Radio',
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Estado (solo para edición)
                      if (isEditing) ...[
                        Row(
                          children: [
                            Text(
                              'Estado',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(width: 16),
                            Switch(
                              value: _isActive,
                              onChanged: (value) {
                                setState(() {
                                  _isActive = value;
                                });
                              },
                            ),
                            Text(_isActive ? 'Activo' : 'Inactivo'),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Botón guardar
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              state is LocationLoading ? null : _saveLocation,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            isEditing ? 'Actualizar' : 'Guardar',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Indicador de carga
              if (state is LocationLoading)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.3),
                    child: Center(
                      child: AppLoadingIndicator(
                        platformInfo: widget.platformInfo,
                        color: Colors.white,
                        text: isEditing
                            ? 'Actualizando ubicación...'
                            : 'Guardando ubicación...',
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
