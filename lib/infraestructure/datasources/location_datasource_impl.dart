/*
import 'package:location/location.dart';
import 'package:login_app/domain/datasources/location_datasource.dart';
import '../../domain/entities/location_point.dart';

class LocationDatasourceImpl implements LocationDatasource {
  
  final Location location = Location();

  @override
  Stream<LocationPoint> getLocationStream() {
    location.changeSettings(interval: 5000, distanceFilter: 5);
    return location.onLocationChanged.map((locData) => LocationPoint(
      latitude: locData.latitude!,
      longitude: locData.longitude!,
      elevation: locData.altitude ?? 0,
      timestamp: DateTime.fromMillisecondsSinceEpoch(locData.time!.toInt()),
    ));
  }
}
*/
import '../../domain/entities/location_point.dart';
import '../../domain/datasources/location_datasource.dart';
import 'foreground_task_handler.dart';

class LocationDatasourceImpl implements LocationDatasource {
  @override
  Stream<LocationPoint> getLocationStream() {

    print('🔄 getLocationStream() llamado');
    
    return ForegroundTaskHandler.locationStreamController.stream;
  }
}