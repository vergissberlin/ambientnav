import 'package:dio/dio.dart';

import '../domain/entities/route.dart';
import 'dto/route_response_dto.dart';

/// Which routing engine the API client talks to.
enum RoutingEngine { osrm, valhalla }

/// Thin HTTP client for an online routing engine (OSRM or Valhalla).
///
/// Security: only HTTPS base URLs are accepted (no plaintext routing traffic).
class RoutingApi {
  RoutingApi({
    required this.baseUrl,
    this.engine = RoutingEngine.osrm,
    Dio? dio,
  })  : assert(baseUrl.startsWith('https://'), 'Routing must use HTTPS'),
        _dio = dio ?? Dio();

  final String baseUrl;
  final RoutingEngine engine;
  final Dio _dio;

  Future<Routes> route(GeoPoint origin, GeoPoint destination) async {
    switch (engine) {
      case RoutingEngine.osrm:
        return _osrm(origin, destination);
      case RoutingEngine.valhalla:
        return _valhalla(origin, destination);
    }
  }

  Future<Routes> _osrm(GeoPoint o, GeoPoint d) async {
    final coords = '${o.longitude},${o.latitude};${d.longitude},${d.latitude}';
    final res = await _dio.get<Map<String, dynamic>>(
      '$baseUrl/route/v1/driving/$coords',
      queryParameters: const {
        'overview': 'full',
        'geometries': 'polyline',
        'steps': 'true',
      },
    );
    return RouteResponseDto.fromOsrm(res.data!);
  }

  Future<Routes> _valhalla(GeoPoint o, GeoPoint d) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '$baseUrl/route',
      data: {
        'locations': [
          {'lat': o.latitude, 'lon': o.longitude},
          {'lat': d.latitude, 'lon': d.longitude},
        ],
        'costing': 'auto',
        'directions_options': {'units': 'kilometers'},
      },
    );
    return RouteResponseDto.fromValhalla(res.data!);
  }
}
