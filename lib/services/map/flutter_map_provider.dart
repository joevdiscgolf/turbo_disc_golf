import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:turbo_disc_golf/services/map/map_provider.dart';

/// Implementation of MapProvider using flutter_map with OpenStreetMap tiles.
/// Free to use, no API key required.
class FlutterMapProvider implements MapProvider {
  /// Default center point (roughly center of continental US)
  static const double _defaultLat = 39.8283;
  static const double _defaultLng = -98.5795;
  static const double _defaultZoom = 4.0;
  static const double _selectedZoom = 15.0;

  @override
  Widget buildInteractiveMap({
    required double? initialLatitude,
    required double? initialLongitude,
    required double? selectedLatitude,
    required double? selectedLongitude,
    required void Function(double lat, double lng) onLocationSelected,
  }) {
    final double centerLat = selectedLatitude ?? initialLatitude ?? _defaultLat;
    final double centerLng =
        selectedLongitude ?? initialLongitude ?? _defaultLng;
    final double zoom =
        (selectedLatitude != null || initialLatitude != null)
            ? _selectedZoom
            : _defaultZoom;

    return FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(centerLat, centerLng),
        initialZoom: zoom,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
        onTap: (tapPosition, point) {
          onLocationSelected(point.latitude, point.longitude);
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.turbo_disc_golf',
        ),
        if (selectedLatitude != null && selectedLongitude != null)
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(selectedLatitude, selectedLongitude),
                width: 40,
                height: 40,
                child: const Icon(
                  Icons.location_pin,
                  color: Colors.red,
                  size: 40,
                ),
              ),
            ],
          ),
      ],
    );
  }

  @override
  Widget buildMiniMap({
    required double latitude,
    required double longitude,
    double height = 120,
    double borderRadius = 12,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        height: height,
        child: IgnorePointer(
          child: FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(latitude, longitude),
              initialZoom: 14.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.none,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.turbo_disc_golf',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(latitude, longitude),
                    width: 32,
                    height: 32,
                    child: const Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 32,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
