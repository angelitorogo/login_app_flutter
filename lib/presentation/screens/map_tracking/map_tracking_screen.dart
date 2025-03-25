// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:login_app/infraestructure/datasources/foreground_task_handler.dart';
import 'package:login_app/main.dart';
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
                  Text('Obtendiendo ubicación...'),
                ],
              ),
            )
          : Column(
            children: [
              SizedBox(
                height: 400,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                  child: GoogleMap(
                    fortyFiveDegreeImageryEnabled: true,
                    mapType: currentMapType,
                    initialCameraPosition: CameraPosition(
                      target: initialPosition!,
                      zoom: 14,
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

              // Lista de puntos GPS
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const Text('Puntos:'),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: ListView.builder(
                            itemCount: trackState.points.length,
                            itemBuilder: (context, index) {
                              final point = trackState.points[index];
                              return ListTile(
                                dense: true,
                                visualDensity: const VisualDensity(vertical: -2),
                                title: Text(
                                  '(${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)})',
                                ),
                                subtitle: Text('Alt: ${point.elevation.toStringAsFixed(1)}m - ${point.timestamp}'),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),


              
            ],
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
          
          // Dentro del botón flotante (trackingButton)
          FloatingActionButton(
            heroTag: 'trackingButton',
            backgroundColor: (trackState.isTracking) ? Colors.red : Colors.green,
            onPressed: () async {
              if (!trackState.isTracking) {
                if (!await Permission.locationAlways.isGranted) {
                  await Permission.locationAlways.request();
                }
                trackNotifier.startTracking();

                FlutterForegroundTask.init(
                  androidNotificationOptions: AndroidNotificationOptions(
                    channelId: 'tracking_channel',
                    channelName: 'Grabando Track GPS',
                    channelDescription: 'Grabando ruta en segundo plano.',
                    channelImportance: NotificationChannelImportance.LOW,
                    priority: NotificationPriority.LOW,
                    iconData: const NotificationIconData(
                      resType: ResourceType.mipmap,
                      resPrefix: ResourcePrefix.ic,
                      name: 'launcher',
                    ),
                  ),
                  iosNotificationOptions: const IOSNotificationOptions(),
                  foregroundTaskOptions: const ForegroundTaskOptions(interval: 5000),
                );

                FlutterForegroundTask.startService(
                  notificationTitle: 'La Dama del Cancho',
                  notificationText: 'Grabando ruta GPS...',
                  callback: startCallback,
                );

              } else {
                await trackNotifier.stopTrackingAndSaveGpx();
                FlutterForegroundTask.stopService();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Track guardado en carpeta GPX en Downloads")),
                );
              }
            },
            child: Icon(trackState.isTracking ? Icons.stop : Icons.play_arrow),
          ),
                    

        ],
      ),
    );
  }

  
}



