import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpx/gpx.dart';
import 'package:login_app/presentation/providers/location/location_repository_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:login_app/domain/entities/location_point.dart';
import '../../../infraestructure/repositories/location_repository_impl.dart';

class TrackState {
  final bool isTracking;
  final List<LocationPoint> points;

  TrackState({this.isTracking = false, this.points = const []});

  TrackState copyWith({bool? isTracking, List<LocationPoint>? points}) {
    return TrackState(
      isTracking: isTracking ?? this.isTracking,
      points: points ?? this.points,
    );
  }
}

class TrackNotifier extends StateNotifier<TrackState> {
  final LocationRepositoryImpl locationRepository;
  StreamSubscription<LocationPoint>? _locationSubscription;

  TrackNotifier(this.locationRepository) : super(TrackState());

  List<LatLng> get polylinePoints =>
      state.points.map((p) => LatLng(p.latitude, p.longitude)).toList();

  void startTracking() {
    state = state.copyWith(isTracking: true, points: []);
    _locationSubscription = locationRepository.getLocationStream().listen((point) {

      print('📡 TrackNotifier recibió punto: ${point.latitude}, ${point.longitude}');
      
      state = state.copyWith(points: [...state.points, point]);
    });
  }

  Future<File> stopTrackingAndSaveGpx() async {
    state = state.copyWith(isTracking: false);
    await _locationSubscription?.cancel();

    final gpx = Gpx();
    gpx.creator = "La Dama del Cancho App";
    final track = Trk(name: "Track grabado");
    track.trksegs.add(
      Trkseg(
        trkpts: state.points
            .map((p) => Wpt(
                  lat: p.latitude,
                  lon: p.longitude,
                  ele: p.elevation,
                  time: p.timestamp,
                ))
            .toList(),
      ),
    );

    gpx.trks.add(track);
    final gpxString = GpxWriter().asString(gpx, pretty: true);

    final directory = await getApplicationDocumentsDirectory();
    final fileName = "track_${DateTime.now().millisecondsSinceEpoch}.gpx";
    final file = File("${directory.path}/$fileName");
    await file.writeAsString(gpxString);

    // Guardamos archivo GPX
    await saveGpxToPublicDocuments(file);

    return file;
  }

  Future<void> saveGpxToPublicDocuments(File file) async {
    final downloadsDir = Directory('/storage/emulated/0/Download/GPX');
    if (!(await downloadsDir.exists())) {
      await downloadsDir.create(recursive: true);
    }
    final publicFile = File('${downloadsDir.path}/${file.uri.pathSegments.last}');
    await file.copy(publicFile.path);
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }
}

final trackProvider = StateNotifierProvider<TrackNotifier, TrackState>((ref) {
  final locationRepository = ref.watch(locationRepositoryProvider);
  return TrackNotifier(locationRepository);
});
