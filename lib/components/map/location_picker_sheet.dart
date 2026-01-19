import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:turbo_disc_golf/components/buttons/primary_button.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/services/logging/logging_service.dart';
import 'package:turbo_disc_golf/services/map/map_provider.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

/// Full-screen sheet for selecting a course location on a map.
class LocationPickerSheet extends StatefulWidget {
  const LocationPickerSheet({
    super.key,
    required this.onLocationSelected,
    this.initialLatitude,
    this.initialLongitude,
    required this.topViewPadding,
  });

  final void Function(double lat, double lng) onLocationSelected;
  final double? initialLatitude;
  final double? initialLongitude;
  final double topViewPadding;

  @override
  State<LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<LocationPickerSheet> {
  static const String _sheetName = 'Location Picker';

  double? _selectedLat;
  double? _selectedLng;
  late final MapProvider _mapProvider;
  late final LoggingServiceBase _logger;

  @override
  void initState() {
    super.initState();

    // Setup scoped logger
    final LoggingService loggingService = locator.get<LoggingService>();
    _logger = loggingService.withBaseProperties({'modal_name': _sheetName});

    // Track modal opened
    _logger.track(
      'Modal Opened',
      properties: {
        'modal_type': 'full_screen_modal',
        'modal_name': _sheetName,
        'has_initial_location': widget.initialLatitude != null,
      },
    );

    _selectedLat = widget.initialLatitude;
    _selectedLng = widget.initialLongitude;
    _mapProvider = MapProvider.getProvider();
  }

  bool get _hasSelection => _selectedLat != null && _selectedLng != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        children: [
          _buildMap(),
          _buildAppBar(context),
          _buildBottomSheet(context),
          if (!_hasSelection) _buildInstructionOverlay(),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return Positioned.fill(
      child: _mapProvider.buildInteractiveMap(
        initialLatitude: widget.initialLatitude,
        initialLongitude: widget.initialLongitude,
        selectedLatitude: _selectedLat,
        selectedLongitude: _selectedLng,
        onLocationSelected: (double lat, double lng) {
          HapticFeedback.lightImpact();
          setState(() {
            _selectedLat = lat;
            _selectedLng = lng;
          });
        },
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(top: widget.topViewPadding),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withValues(alpha: 0.5), Colors.transparent],
          ),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            const Expanded(
              child: Text(
                'Select Course Location',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 48), // Balance the close button
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheet(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_hasSelection) ...[
              _buildCoordinatesDisplay(),
              const SizedBox(height: 12),
            ],
            PrimaryButton(
              width: double.infinity,
              height: 52,
              label: 'Confirm Location',
              gradientBackground: _hasSelection
                  ? const [Color(0xFF137e66), Color(0xFF1a9f7f)]
                  : null,
              backgroundColor: _hasSelection
                  ? Colors.transparent
                  : SenseiColors.gray.shade200,
              labelColor: _hasSelection
                  ? Colors.white
                  : SenseiColors.gray.shade400,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              disabled: !_hasSelection,
              onPressed: () {
                if (_hasSelection) {
                  widget.onLocationSelected(_selectedLat!, _selectedLng!);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoordinatesDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: SenseiColors.gray.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.location_pin, color: Colors.red.shade600, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${_selectedLat!.toStringAsFixed(5)}, ${_selectedLng!.toStringAsFixed(5)}',
              style: TextStyle(
                fontSize: 14,
                color: SenseiColors.gray.shade700,
                fontFamily: 'monospace',
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                _selectedLat = null;
                _selectedLng = null;
              });
            },
            child: Icon(
              Icons.clear,
              color: SenseiColors.gray.shade500,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionOverlay() {
    return Positioned(
      top: widget.topViewPadding + 60,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.touch_app, color: SenseiColors.gray.shade600, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Tap on the map to place a pin at your course location',
                style: TextStyle(
                  fontSize: 14,
                  color: SenseiColors.gray.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
