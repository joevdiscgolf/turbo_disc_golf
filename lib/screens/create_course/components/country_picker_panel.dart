import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:turbo_disc_golf/components/panels/panel_header.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/country.dart';
import 'package:turbo_disc_golf/services/logging/logging_service.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/utils/country_constants.dart';

class CountryPickerPanel extends StatefulWidget {
  const CountryPickerPanel({
    super.key,
    this.selectedCountryCode,
    required this.onCountrySelected,
  });

  static const String panelName = 'Select Country';

  final String? selectedCountryCode;
  final void Function(Country) onCountrySelected;

  static void show(
    BuildContext context, {
    String? selectedCountryCode,
    required void Function(Country) onCountrySelected,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => CountryPickerPanel(
        selectedCountryCode: selectedCountryCode,
        onCountrySelected: onCountrySelected,
      ),
    );
  }

  @override
  State<CountryPickerPanel> createState() => _CountryPickerPanelState();
}

class _CountryPickerPanelState extends State<CountryPickerPanel> {
  final TextEditingController _controller = TextEditingController();
  late final LoggingServiceBase _logger;

  Timer? _debounce;
  late List<Country> _filteredCountries;

  @override
  void initState() {
    super.initState();

    // Create scoped logger with base properties
    final LoggingService loggingService = locator.get<LoggingService>();
    _logger = loggingService.withBaseProperties({
      'panel_name': CountryPickerPanel.panelName,
    });

    // Track panel impression
    _logger.track(
      'Panel Impression',
      properties: {'panel_class': 'CountryPickerPanel'},
    );

    _filteredCountries = List.from(allCountries);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();

    if (query.trim().isEmpty) {
      setState(() => _filteredCountries = List.from(allCountries));
      return;
    }

    _logger.track(
      'Country Search Executed',
      properties: {'query_length': query.length},
    );

    _debounce = Timer(const Duration(milliseconds: 300), () {
      final String lowerQuery = query.toLowerCase();
      setState(() {
        _filteredCountries = allCountries.where((country) {
          return country.name.toLowerCase().contains(lowerQuery) ||
                 country.code.toLowerCase().contains(lowerQuery);
        }).toList();
      });

      _logger.track(
        'Country Search Results Returned',
        properties: {'result_count': _filteredCountries.length},
      );
    });
  }

  void _selectCountry(Country country) {
    _logger.track(
      'Country Selected',
      properties: {
        'country_code': country.code,
        'country_name': country.name,
      },
    );

    HapticFeedback.lightImpact();
    widget.onCountrySelected(country);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return SafeArea(
          child: Column(
            children: [
              PanelHeader(
                title: 'Select Country',
                onClose: () {
                  _logger.track('Close Panel Button Tapped');
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop();
                },
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                child: TextField(
                  controller: _controller,
                  onChanged: _onSearchChanged,
                  decoration: const InputDecoration(
                    hintText: 'Search countries…',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              Expanded(
                child: _buildCountryList(scrollController),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCountryList(ScrollController scrollController) {
    if (_filteredCountries.isEmpty) {
      if (_controller.text.isEmpty) {
        return _EmptyStateWidget(
          icon: Icons.public_outlined,
          title: 'Choose your country',
          subtitle: 'Search above to get started',
        );
      } else {
        return _EmptyStateWidget(
          icon: Icons.search_outlined,
          title: 'No matches found',
          subtitle: "We couldn't find \"${_controller.text}\"",
        );
      }
    }

    return ListView.separated(
      controller: scrollController,
      itemCount: _filteredCountries.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        thickness: 1,
        color: SenseiColors.gray.shade50,
        indent: 16,
        endIndent: 16,
      ),
      physics: const ClampingScrollPhysics(),
      itemBuilder: (context, index) {
        final Country country = _filteredCountries[index];
        final bool isSelected = country.code == widget.selectedCountryCode;

        return _CountryListItem(
          country: country,
          isSelected: isSelected,
          onTap: () => _selectCountry(country),
        );
      },
    );
  }
}

class _CountryListItem extends StatelessWidget {
  const _CountryListItem({
    required this.country,
    required this.isSelected,
    required this.onTap,
  });

  final Country country;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          color: isSelected ? Colors.blue.shade50 : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Text(
                country.flagEmoji,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      country.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? SenseiColors.blue
                            : SenseiColors.gray.shade800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      country.code,
                      style: TextStyle(
                        fontSize: 12,
                        color: SenseiColors.gray.shade400,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: SenseiColors.blue,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyStateWidget extends StatelessWidget {
  const _EmptyStateWidget({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade50,
                    Colors.blue.shade100.withValues(alpha: 0.5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: Colors.blue.shade300),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: SenseiColors.gray.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: SenseiColors.gray.shade400,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
