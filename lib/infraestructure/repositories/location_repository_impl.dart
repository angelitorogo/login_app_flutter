

import 'package:login_app/domain/datasources/location_datasource.dart';
import 'package:login_app/domain/entities/location_point.dart';
import 'package:login_app/domain/repositories/location_repository.dart';

class LocationRepositoryImpl extends LocationRepository {

  final LocationDatasource datasource;

  LocationRepositoryImpl(this.datasource);

  @override
  Stream<LocationPoint> getLocationStream() {
    return datasource.getLocationStream();
  }

  

}