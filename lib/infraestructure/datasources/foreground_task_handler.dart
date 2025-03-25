import 'dart:async';
import 'dart:isolate';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:location/location.dart';
import 'package:login_app/domain/entities/location_point.dart';

class ForegroundTaskHandler extends TaskHandler {
  StreamSubscription<LocationData>? _locationSubscription;
  final Location _location = Location();

  static final StreamController<LocationPoint> locationStreamController = StreamController.broadcast();

  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    print('🟡 ForegroundTaskHandler.onStart() INICIADO');

    try {
      _location.changeSettings(interval: 5000, distanceFilter: 5);
      print('✅ Configuración de ubicación cambiada');

      _locationSubscription = _location.onLocationChanged.listen((locData) {
        print('📍 Punto recibido: ${locData.latitude}, ${locData.longitude}');

        final point = LocationPoint(
          latitude: locData.latitude!,
          longitude: locData.longitude!,
          elevation: locData.altitude ?? 0,
          timestamp: DateTime.fromMillisecondsSinceEpoch(locData.time!.toInt()),
        );

        locationStreamController.add(point);
      });

      print('📡 Suscripción a onLocationChanged iniciada');
    } catch (e, st) {
      print('❌ Error en onStart ForegroundTaskHandler: $e');
      print(st);
    }
  }


  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {
    await _locationSubscription?.cancel();
    await locationStreamController.close();
  }


  @override
  void onNotificationPressed() {}
  
  @override
  void onRepeatEvent(DateTime timestamp, SendPort? sendPort) {
  }
}
