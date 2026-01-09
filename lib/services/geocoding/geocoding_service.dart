import 'dart:convert';

import 'package:http/http.dart' as http;

/// Location details returned from reverse geocoding.
class LocationDetails {
  const LocationDetails({
    this.city,
    this.state,
    this.country,
    this.displayName,
  });

  final String? city;
  final String? state;
  final String? country;
  final String? displayName;

  @override
  String toString() => 'LocationDetails(city: $city, state: $state, country: $country)';
}

/// Service for reverse geocoding coordinates to location details.
/// Uses Nominatim (OpenStreetMap) API - free with 1 request/second rate limit.
class GeocodingService {
  static const String _nominatimBaseUrl =
      'https://nominatim.openstreetmap.org/reverse';

  /// Performs reverse geocoding to convert coordinates to location details.
  /// Returns null if the request fails or no results are found.
  Future<LocationDetails?> reverseGeocode(double lat, double lng) async {
    try {
      final Uri uri = Uri.parse(_nominatimBaseUrl).replace(
        queryParameters: {
          'lat': lat.toString(),
          'lon': lng.toString(),
          'format': 'json',
          'addressdetails': '1',
        },
      );

      final http.Response response = await http.get(
        uri,
        headers: {
          // Nominatim requires a valid User-Agent
          'User-Agent': 'TurboDiscGolf/1.0 (https://turbo-disc-golf.com)',
        },
      );

      if (response.statusCode != 200) {
        return null;
      }

      final Map<String, dynamic> data = json.decode(response.body);
      final Map<String, dynamic>? address = data['address'];

      if (address == null) {
        return null;
      }

      // Extract city - Nominatim uses different keys for different location types
      final String? city =
          address['city'] ??
          address['town'] ??
          address['village'] ??
          address['municipality'] ??
          address['hamlet'];

      // Extract state/province
      final String? state = address['state'] ?? address['province'];

      // Extract country
      final String? country = address['country'];

      // Full display name from Nominatim
      final String? displayName = data['display_name'];

      return LocationDetails(
        city: city,
        state: state,
        country: country,
        displayName: displayName,
      );
    } catch (e) {
      // Log error but don't crash - geocoding is optional
      return null;
    }
  }
}
