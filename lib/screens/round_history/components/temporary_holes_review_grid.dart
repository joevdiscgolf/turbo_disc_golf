import 'package:flutter/material.dart';

import 'package:turbo_disc_golf/components/buttons/primary_button.dart';

class TemporaryHolesReviewGrid extends StatelessWidget {
  const TemporaryHolesReviewGrid({
    super.key,
    required this.holeDescriptions,
    required this.onHoleTap,
    required this.onFinishAndParse,
    required this.onBack,
    required this.allHolesFilled,
    required this.bottomViewPadding,
  });

  final Map<int, String> holeDescriptions;
  final Function(int holeIndex) onHoleTap;
  final VoidCallback onFinishAndParse;
  final VoidCallback onBack;
  final bool allHolesFilled;
  final double bottomViewPadding;

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width - 32;
    final double itemWidth = screenWidth / 3;

    return Column(
      children: [
        _buildBackButton(context),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 64),
            child: Wrap(
              spacing: 0,
              runSpacing: 0,
              children: List.generate(18, (index) {
                final String? description = holeDescriptions[index];
                final bool hasContent =
                    description != null && description.trim().isNotEmpty;
                return _HoleGridCard(
                  holeNumber: index + 1,
                  hasTranscript: hasContent,
                  width: itemWidth,
                  onTap: () => onHoleTap(index),
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildBottomButtons(),
      ],
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.arrow_back,
                      size: 20,
                      color: Color(0xFF2196F3),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Back to Editing',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2196F3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, bottom: bottomViewPadding),
      child: PrimaryButton(
        label: 'Finish & Parse',
        labelColor: Colors.white,
        width: double.infinity,
        height: 56,
        disabled: !allHolesFilled,
        onPressed: onFinishAndParse,
      ),
    );
  }
}

class _HoleGridCard extends StatelessWidget {
  const _HoleGridCard({
    required this.holeNumber,
    required this.hasTranscript,
    required this.width,
    required this.onTap,
  });

  final int holeNumber;
  final bool hasTranscript;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        height: 96,
        child: Card(
          elevation: 1,
          margin: const EdgeInsets.all(4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: hasTranscript ? Colors.green.shade50 : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Hole $holeNumber',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                _buildStatusIcon(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    if (hasTranscript) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle),
        child: const Icon(Icons.check, color: Colors.white, size: 20),
      );
    } else {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400, width: 2),
          shape: BoxShape.circle,
        ),
      );
    }
  }
}
