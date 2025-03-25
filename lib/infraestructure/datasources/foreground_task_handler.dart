// path: lib/infraestructure/datasources/foreground_task_handler.dart

import 'dart:async';
import 'dart:isolate';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:login_app/domain/entities/location_point.dart';

class ForegroundTaskHandler extends TaskHandler {
  StreamSubscription<Position>? _positionSubscription;
  static final StreamController<LocationPoint> locationStreamController =
      StreamController<LocationPoint>.broadcast();

  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    print("🟡 ForegroundTaskHandler.onStart() INICIADO");

    try {
      // Permiso y configuración deben haberse hecho previamente en UI thread

      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
        timeLimit: null,
      );

      _positionSubscription =
          Geolocator.getPositionStream(locationSettings: locationSettings)
              .listen((Position position) {
        print("📍 Nuevo punto recibido: ${position.latitude}, ${position.longitude}");

        final point = LocationPoint(
          latitude: position.latitude,
          longitude: position.longitude,
          elevation: position.altitude,
          timestamp: position.timestamp ?? DateTime.now(),
        );

        locationStreamController.add(point);
        sendPort?.send([point.latitude, point.longitude]);
      });

      print("📡 Suscripción a getPositionStream iniciada");
    } catch (e, st) {
      print("❌ Error en onStart ForegroundTaskHandler: $e");
      print(st);
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {
    print("🛑 ForegroundTaskHandler.onDestroy()");
    await _positionSubscription?.cancel();
    await locationStreamController.close();
  }

  @override
  void onNotificationPressed() {
    print("🔔 Notificación presionada");
  }

  @override
  void onRepeatEvent(DateTime timestamp, SendPort? sendPort) {}
}
