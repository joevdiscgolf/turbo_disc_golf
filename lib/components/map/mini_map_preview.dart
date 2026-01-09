import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:turbo_disc_golf/services/map/map_provider.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

/// Small, non-interactive map preview widget showing a course location.
/// Tappable to open the full location picker.
class MiniMapPreview extends StatelessWidget {
  const MiniMapPreview({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.onTap,
    required this.onClear,
    this.height = 120,
    this.isLoading = false,
  });

  final double latitude;
  final double longitude;
  final VoidCallback onTap;
  final VoidCallback onClear;
  final double height;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final MapProvider mapProvider = MapProvider.getProvider();

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: TurbColors.gray.shade200),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            mapProvider.buildMiniMap(
              latitude: latitude,
              longitude: longitude,
              height: height,
              borderRadius: 0,
            ),
            _buildOverlay(context),
            _buildClearButton(),
            if (isLoading) _buildLoadingIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlay(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.6),
            ],
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_pin, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const Icon(Icons.edit, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildClearButton() {
    return Positioned(
      top: 8,
      right: 8,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onClear();
        },
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
              ),
            ],
          ),
          child: Icon(
            Icons.close,
            size: 18,
            color: TurbColors.gray.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Positioned.fill(
      child: Container(
        color: Colors.white.withValues(alpha: 0.7),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(height: 8),
              Text(
                'Getting location details...',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
