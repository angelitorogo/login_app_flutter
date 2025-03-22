// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:login_app/presentation/providers/location/track_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:location/location.dart';

class MapTrackingScreen extends ConsumerStatefulWidget {
  static const name = 'map-tracking-screen';

  const MapTrackingScreen({super.key});

  @override
  ConsumerState<MapTrackingScreen> createState() => _MapTrackingScreenState();
}

class _MapTrackingScreenState extends ConsumerState<MapTrackingScreen> {
  GoogleMapController? mapController;
  LatLng? initialPosition;
  StreamSubscription<LocationData>? locationSubscription;
  MapType currentMapType = MapType.satellite;

  @override
  void initState() {
    super.initState();
    getInitialLocation();
  }

  Future<void> getInitialLocation() async {
    final location = Location();

    final permissionGranted = await Permission.location.request();
    if (!permissionGranted.isGranted) {
      return;
    }

    final currentLocation = await location.getLocation();
    setState(() {
      initialPosition = LatLng(
        currentLocation.latitude!,
        currentLocation.longitude!,
      );
    });

    locationSubscription = location.onLocationChanged.listen((newLocation) {
      if (!mounted || mapController == null) return;

      final newLatLng = LatLng(newLocation.latitude!, newLocation.longitude!);
      mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: newLatLng, zoom: 16),
        ),
      );
    });
  }

  void toggleMapType() {
    setState(() {
      currentMapType = currentMapType == MapType.satellite
          ? MapType.normal
          : MapType.satellite;
    });
  }


  Future<bool> checkLocationPermission() async {
  final locationStatus = await Permission.location.request();
  return locationStatus.isGranted;
}

  @override
  void dispose() {
    locationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trackState = ref.watch(trackProvider);
    final trackNotifier = ref.read(trackProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Grabación Track')),
      body: initialPosition == null
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 15),
                  Text('Obtendiendo ubicación...')
                ],
              ),
            )
          : SizedBox(
              height: 400,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                child: GoogleMap(
                  mapType: currentMapType,
                  initialCameraPosition: CameraPosition(
                    target: initialPosition!,
                    zoom: 16,
                  ),
                  myLocationEnabled: true,
                  polylines: {
                    Polyline(
                      polylineId: const PolylineId('tracking_polyline'),
                      points: trackNotifier.polylinePoints,
                      width: 5,
                      color: Colors.blue,
                    ),
                  },
                  onMapCreated: (controller) => mapController = controller,
                ),
              ),
            ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'mapTypeButton',
            backgroundColor: Colors.grey[800],
            onPressed: toggleMapType,
            child: const Icon(Icons.layers),
          ),
          const SizedBox(height: 12),
          // Dentro del botón flotante trackingButton
          FloatingActionButton(
            heroTag: 'trackingButton',
            backgroundColor: trackState.isTracking ? Colors.red : Colors.green,
            onPressed: () async {
              if (!trackState.isTracking) {
                final locationGranted = await Permission.location.request();
                if (!locationGranted.isGranted) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Debes otorgar permiso de ubicación")),
                    );
                  }
                  return;
                }
                trackNotifier.startTracking();
              } else {

                /*
                if (Platform.isAndroid) {
                  // Verifica el permiso especial claramente (gestionar almacenamiento)
                  if (!(await Permission.manageExternalStorage.isGranted)) {
                    // Abre directamente la pantalla específica del sistema para permisos especiales
                    await openAppSettings(); 
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Activa 'Gestionar todos los archivos' en ajustes")),
                      );
                    }
                    return;
                  }
                }
                */

                /*
                // Manejo correcto del permiso especial en Android 11+
                if (Platform.isAndroid && await Permission.manageExternalStorage.isDenied) {
                  // Redirige claramente al usuario a configuración manual
                  final result = await openAppSettings();
                  if (!result) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Debes otorgar permiso manualmente en ajustes")),
                      );
                    }
                    return;
                  }
                  return; // Espera a que el usuario vuelva después de otorgar el permiso
                }
                */

                await trackNotifier.stopTrackingAndSaveGpx();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Track guardado en carpeta Downloads ")),
                  );
                }
              }
            },
            child: Icon(trackState.isTracking ? Icons.stop : Icons.play_arrow),
          ),

        ],
      ),
    );
  }
}



/* old

FloatingActionButton(
            heroTag: 'trackingButton',
            backgroundColor: trackState.isTracking ? Colors.red : Colors.green,
            onPressed: () async {
              if (!trackState.isTracking) {
                final locationGranted = await checkLocationPermission();
                if (!locationGranted) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Debes otorgar el permiso de ubicación"),
                      ),
                    );
                  }
                  return;
                }
                trackNotifier.startTracking();
              } else {
                 

                final file = await trackNotifier.stopTrackingAndSaveGpx();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Track guardado en: ${file.path}")),
                  );
                }
              }
            },

            child: Icon(trackState.isTracking ? Icons.stop : Icons.play_arrow),
          ),

*/