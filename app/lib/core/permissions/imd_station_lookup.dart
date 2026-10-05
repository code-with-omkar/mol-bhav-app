import 'dart:math' as math;

/// An IMD forecast station. [id] is the key the weather API takes as
/// `stationId`.
class ImdStation {
  const ImdStation(this.id, this.name, this.lat, this.lon);

  final String id;
  final String name;
  final double lat;
  final double lon;
}

/// The 36 stations (one per state / UT capital) the forecast is served for.
/// Ids are the API's station slugs and must match the backend's IMD mapping.
abstract final class ImdStationLookup {
  /// Further than this from every station: no forecast is offered.
  static const maxDistanceKm = 400.0;

  static const stations = [
    ImdStation('port-blair', 'Port Blair', 11.62, 92.73),
    ImdStation('amaravati', 'Amaravati', 16.51, 80.52),
    ImdStation('itanagar', 'Itanagar', 27.08, 93.61),
    ImdStation('guwahati', 'Guwahati', 26.14, 91.74),
    ImdStation('patna', 'Patna', 25.59, 85.14),
    ImdStation('chandigarh', 'Chandigarh', 30.73, 76.78),
    ImdStation('raipur', 'Raipur', 21.25, 81.63),
    ImdStation('daman', 'Daman', 20.40, 72.83),
    ImdStation('delhi', 'New Delhi', 28.61, 77.21),
    ImdStation('panaji', 'Panaji', 15.50, 73.83),
    ImdStation('ahmedabad', 'Ahmedabad', 23.02, 72.57),
    ImdStation('gandhinagar', 'Gandhinagar', 23.22, 72.65),
    ImdStation('shimla', 'Shimla', 31.10, 77.17),
    ImdStation('srinagar', 'Srinagar', 34.08, 74.80),
    ImdStation('jammu', 'Jammu', 32.73, 74.87),
    ImdStation('ranchi', 'Ranchi', 23.34, 85.31),
    ImdStation('bengaluru', 'Bengaluru', 12.97, 77.59),
    ImdStation('thiruvananthapuram', 'Thiruvananthapuram', 8.52, 76.94),
    ImdStation('leh', 'Leh', 34.15, 77.58),
    ImdStation('kavaratti', 'Kavaratti', 10.57, 72.64),
    ImdStation('bhopal', 'Bhopal', 23.26, 77.41),
    ImdStation('mumbai', 'Mumbai', 19.08, 72.88),
    ImdStation('imphal', 'Imphal', 24.82, 93.94),
    ImdStation('shillong', 'Shillong', 25.58, 91.89),
    ImdStation('aizawl', 'Aizawl', 23.73, 92.72),
    ImdStation('kohima', 'Kohima', 25.67, 94.11),
    ImdStation('bhubaneswar', 'Bhubaneswar', 20.30, 85.82),
    ImdStation('puducherry', 'Puducherry', 11.93, 79.83),
    ImdStation('jaipur', 'Jaipur', 26.91, 75.79),
    ImdStation('gangtok', 'Gangtok', 27.34, 88.61),
    ImdStation('chennai', 'Chennai', 13.08, 80.27),
    ImdStation('hyderabad', 'Hyderabad', 17.39, 78.49),
    ImdStation('agartala', 'Agartala', 23.83, 91.28),
    ImdStation('lucknow', 'Lucknow', 26.85, 80.95),
    ImdStation('dehradun', 'Dehradun', 30.32, 78.03),
    ImdStation('kolkata', 'Kolkata', 22.57, 88.36),
  ];

  static ImdStation? byId(String id) =>
      stations.where((s) => s.id == id).firstOrNull;

  /// The closest station to a coordinate, or `null` beyond [maxDistanceKm].
  static ImdStation? nearest(double lat, double lon) {
    ImdStation? best;
    var bestKm = double.infinity;
    for (final s in stations) {
      final km = _haversineKm(lat, lon, s.lat, s.lon);
      if (km < bestKm) {
        best = s;
        bestKm = km;
      }
    }
    return bestKm <= maxDistanceKm ? best : null;
  }

  static double _haversineKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthKm = 6371.0;
    double rad(double d) => d * math.pi / 180;
    final dLat = rad(lat2 - lat1), dLon = rad(lon2 - lon1);
    final a =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(rad(lat1)) *
            math.cos(rad(lat2)) *
            math.pow(math.sin(dLon / 2), 2);
    return 2 * earthKm * math.asin(math.sqrt(a));
  }
}
