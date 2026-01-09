import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/services/map/flutter_map_provider.dart';
import 'package:turbo_disc_golf/services/map/google_map_provider.dart';
import 'package:turbo_disc_golf/utils/constants/testing_constants.dart';

/// Abstract interface for map providers.
/// Allows swapping between flutter_map and Google Maps implementations.
abstract class MapProvider {
  /// Builds an interactive map widget for location selection.
  Widget buildInteractiveMap({
    required double? initialLatitude,
    required double? initialLongitude,
    required double? selectedLatitude,
    required double? selectedLongitude,
    required void Function(double lat, double lng) onLocationSelected,
  });

  /// Builds a small, non-interactive map preview widget.
  Widget buildMiniMap({
    required double latitude,
    required double longitude,
    double height,
    double borderRadius,
  });

  /// Factory to get the configured map provider based on testing_constants.
  static MapProvider getProvider() {
    switch (mapProvider) {
      case 'google_maps':
        return GoogleMapProvider();
      case 'flutter_map':
      default:
        return FlutterMapProvider();
    }
  }
}
