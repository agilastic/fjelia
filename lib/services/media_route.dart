import 'dart:math' as math;

/// A point of a recorded route.
typedef RoutePoint = ({double lat, double lng});

/// How far a photo's own location may lie from the route and still be
/// shown on it; anything further was taken somewhere else.
const mediaRouteMaxDistanceMeters = 1000.0;

/// Where on the route a photo or video belongs: its own location when it was
/// taken near the route, else the point the athlete had reached at the time
/// it was taken (by elapsed time). Null when it fits neither, e.g. a photo
/// from home or from the day before.
RoutePoint? mediaRoutePoint({
  required List<RoutePoint> route,
  required DateTime start,
  required int durationSeconds,
  double? latitude,
  double? longitude,
  DateTime? takenAt,
}) {
  if (route.isEmpty) return null;
  if (latitude != null && longitude != null) {
    final own = (lat: latitude, lng: longitude);
    // Every few points is plenty to tell "on the route" from "elsewhere".
    final step = math.max(1, route.length ~/ 500);
    for (var i = 0; i < route.length; i += step) {
      if (distanceMeters(own, route[i]) <= mediaRouteMaxDistanceMeters) {
        return own;
      }
    }
    return null;
  }
  if (takenAt == null || durationSeconds <= 0) return null;
  const margin = Duration(minutes: 5);
  final end = start.add(Duration(seconds: durationSeconds));
  if (takenAt.isBefore(start.subtract(margin)) ||
      takenAt.isAfter(end.add(margin))) {
    return null;
  }
  final fraction =
      (takenAt.difference(start).inMilliseconds / (durationSeconds * 1000))
          .clamp(0.0, 1.0);
  return route[(fraction * (route.length - 1)).round()];
}

/// Great-circle distance in metres.
double distanceMeters(RoutePoint a, RoutePoint b) {
  const r = 6371000.0;
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(b.lat - a.lat), dLng = rad(b.lng - a.lng);
  final h =
      math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(a.lat)) *
          math.cos(rad(b.lat)) *
          math.pow(math.sin(dLng / 2), 2);
  return 2 * r * math.asin(math.sqrt(h));
}
