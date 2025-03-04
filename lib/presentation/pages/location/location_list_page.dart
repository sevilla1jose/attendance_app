import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:attendance_app/core/platform/platform_info.dart';
import 'package:attendance_app/domain/entities/location.dart';
import 'package:attendance_app/domain/entities/user.dart';
import 'package:attendance_app/presentation/bloc/location/location_bloc.dart';
import 'package:attendance_app/presentation/pages/location/location_form_page.dart';
import 'package:attendance_app/presentation/widgets/common/app_bar.dart';
import 'package:attendance_app/presentation/widgets/common/loading_indicator.dart';
import 'package:attendance_app/presentation/widgets/common/snackbar.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Página para mostrar la lista de ubicaciones
class LocationListPage extends StatefulWidget {
  /// Usuario actual
  final User currentUser;

  /// Información de la plataforma
  final PlatformInfo platformInfo;

  /// Constructor
  const LocationListPage({
    Key? key,
    required this.currentUser,
    required this.platformInfo,
  }) : super(key: key);

  @override
  State<LocationListPage> createState() => _LocationListPageState();
}

class _LocationListPageState extends State<LocationListPage> {
  final TextEditingController _searchController = TextEditingController();
  Set<Marker> _markers = {};
  GoogleMapController? _mapController;
  bool _showOnlyActive = true;

  @override
  void initState() {
    super.initState();
    // Cargar ubicaciones
    context.read<LocationBloc>().add(LoadLocationsEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = widget.currentUser.isAdmin;

    return Scaffold(
      appBar: AttendanceAppBar(
        title: 'Ubicaciones',
        currentUser: widget.currentUser,
        platformInfo: widget.platformInfo,
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar ubicaciones...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _filterLocations();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    onChanged: (_) => _filterLocations(),
                  ),
                ),
                if (isAdmin) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add_location_alt),
                    tooltip: 'Agregar ubicación',
                    onPressed: () => _navigateToLocationForm(context),
                  ),
                ],
              ],
            ),
          ),

          // Filtro de activo/inactivo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Text('Mostrar solo activas:'),
                Switch(
                  value: _showOnlyActive,
                  onChanged: (value) {
                    setState(() {
                      _showOnlyActive = value;
                    });
                    _filterLocations();
                  },
                ),
                const Spacer(),
                BlocBuilder<LocationBloc, LocationState>(
                  builder: (context, state) {
                    if (state is LocationsLoaded) {
                      return Text(
                        'Total: ${state.locations.length} ubicaciones',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),

          // Lista y mapa de ubicaciones
          Expanded(
            child: BlocBuilder<LocationBloc, LocationState>(
              builder: (context, state) {
                if (state is LocationLoading) {
                  return Center(
                    child: AppLoadingIndicator(
                      platformInfo: widget.platformInfo,
                      text: 'Cargando ubicaciones...',
                    ),
                  );
                } else if (state is LocationsLoaded) {
                  // Filtrar ubicaciones
                  final locations = _filterLocationsList(state.locations);

                  if (locations.isEmpty) {
                    return const Center(
                      child: Text('No se encontraron ubicaciones'),
                    );
                  }

                  // Actualizar marcadores del mapa
                  _updateMapMarkers(locations);

                  return Column(
                    children: [
                      // Mapa con todas las ubicaciones
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: GoogleMap(
                              initialCameraPosition: const CameraPosition(
                                target: LatLng(0, 0),
                                zoom: 2,
                              ),
                              markers: _markers,
                              onMapCreated: (controller) {
                                _mapController = controller;
                                _fitBounds(locations);
                              },
                              myLocationEnabled: true,
                              myLocationButtonEnabled: true,
                              mapToolbarEnabled: false,
                            ),
                          ),
                        ),
                      ),

                      // Lista de ubicaciones
                      Expanded(
                        flex: 3,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: locations.length,
                          itemBuilder: (context, index) {
                            final location = locations[index];
                            return _buildLocationCard(location, isAdmin);
                          },
                        ),
                      ),
                    ],
                  );
                } else if (state is LocationError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${state.message}',
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            context
                                .read<LocationBloc>()
                                .add(LoadLocationsEvent());
                          },
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                } else {
                  return Center(
                    child: ElevatedButton(
                      onPressed: () {
                        context.read<LocationBloc>().add(LoadLocationsEvent());
                      },
                      child: const Text('Cargar ubicaciones'),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(Location location, bool isAdmin) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: location.isActive ? Colors.green : Colors.grey,
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: location.isActive ? Colors.green : Colors.grey,
          child: const Icon(Icons.location_on, color: Colors.white),
        ),
        title: Text(
          location.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(location.address),
            const SizedBox(height: 4),
            Text(
              'Radio: ${location.radius.toInt()} metros',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.map, color: Colors.blue),
              tooltip: 'Ver en mapa',
              onPressed: () => _centerMapOnLocation(location),
            ),
            if (isAdmin) ...[
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.orange),
                tooltip: 'Editar',
                onPressed: () =>
                    _navigateToLocationForm(context, location: location),
              ),
            ],
          ],
        ),
        onTap: () => _centerMapOnLocation(location),
      ),
    );
  }

  void _filterLocations() {
    // Llamar al bloc para filtrar ubicaciones
    context.read<LocationBloc>().add(
          FilterLocationsEvent(
            isActive: _showOnlyActive ? true : null,
            searchQuery: _searchController.text.isNotEmpty
                ? _searchController.text
                : null,
          ),
        );
  }

  List<Location> _filterLocationsList(List<Location> locations) {
    List<Location> filteredLocations = locations;

    if (_showOnlyActive) {
      filteredLocations =
          filteredLocations.where((location) => location.isActive).toList();
    }

    if (_searchController.text.isNotEmpty) {
      final searchTerm = _searchController.text.toLowerCase();
      filteredLocations = filteredLocations.where((location) {
        return location.name.toLowerCase().contains(searchTerm) ||
            location.address.toLowerCase().contains(searchTerm);
      }).toList();
    }

    return filteredLocations;
  }

  void _updateMapMarkers(List<Location> locations) {
    // Actualizar marcadores del mapa
    _markers = locations.map((location) {
      return Marker(
        markerId: MarkerId(location.id),
        position: LatLng(location.latitude, location.longitude),
        infoWindow: InfoWindow(
          title: location.name,
          snippet: location.address,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          location.isActive
              ? BitmapDescriptor.hueGreen
              : BitmapDescriptor.hueCyan,
        ),
      );
    }).toSet();
  }

  void _fitBounds(List<Location> locations) {
    if (locations.isEmpty || _mapController == null) return;

    // Si solo hay una ubicación, centrar en ella
    if (locations.length == 1) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(locations.first.latitude, locations.first.longitude),
          15,
        ),
      );
      return;
    }

    // Calcular límites para todas las ubicaciones
    double minLat = 90;
    double maxLat = -90;
    double minLng = 180;
    double maxLng = -180;

    for (final location in locations) {
      if (location.latitude < minLat) minLat = location.latitude;
      if (location.latitude > maxLat) maxLat = location.latitude;
      if (location.longitude < minLng) minLng = location.longitude;
      if (location.longitude > maxLng) maxLng = location.longitude;
    }

    // Aplicar padding
    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    // Mover cámara para mostrar todas las ubicaciones
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50),
    );
  }

  void _centerMapOnLocation(Location location) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(location.latitude, location.longitude),
        15,
      ),
    );
  }

  Future<void> _navigateToLocationForm(BuildContext context,
      {Location? location}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationFormPage(
          location: location,
          currentUser: widget.currentUser,
          platformInfo: widget.platformInfo,
        ),
      ),
    );

    if (result == true) {
      // Recargar ubicaciones si se creó o actualizó una ubicación
      context.read<LocationBloc>().add(LoadLocationsEvent());

      AppSnackBar.showSuccess(
        context: context,
        message: location != null
            ? 'Ubicación actualizada correctamente'
            : 'Ubicación creada correctamente',
        platformInfo: widget.platformInfo,
      );
    }
  }
}
