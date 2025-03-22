

// Repositorio inmutable, proporciona a los demas providers la informacion de donde sale la info
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_app/infraestructure/datasources/location_datasource_impl.dart';
import 'package:login_app/infraestructure/repositories/location_repository_impl.dart';

final locationRepositoryProvider = Provider<LocationRepositoryImpl>( (ref) {
  return LocationRepositoryImpl(LocationDatasourceImpl());
});