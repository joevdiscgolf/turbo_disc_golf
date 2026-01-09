import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:turbo_disc_golf/services/map/map_provider.dart';

/// Implementation of MapProvider using Google Maps.
/// Requires a valid API key configured in Android/iOS native files.
class GoogleMapProvider implements MapProvider {
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

    final Set<Marker> markers = {};
    if (selectedLatitude != null && selectedLongitude != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('selected_location'),
          position: LatLng(selectedLatitude, selectedLongitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(centerLat, centerLng),
        zoom: zoom,
      ),
      markers: markers,
      onTap: (position) {
        onLocationSelected(position.latitude, position.longitude);
      },
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: true,
      mapToolbarEnabled: false,
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
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(latitude, longitude),
              zoom: 14.0,
            ),
            markers: {
              Marker(
                markerId: const MarkerId('course_location'),
                position: LatLng(latitude, longitude),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueRed,
                ),
              ),
            },
            zoomControlsEnabled: false,
            scrollGesturesEnabled: false,
            zoomGesturesEnabled: false,
            rotateGesturesEnabled: false,
            tiltGesturesEnabled: false,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            mapToolbarEnabled: false,
            liteModeEnabled: true, // Static image mode for better performance
          ),
        ),
      ),
    );
  }
}
