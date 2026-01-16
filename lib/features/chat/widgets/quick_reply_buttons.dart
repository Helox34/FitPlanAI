import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Widget for quick YES/NO replies in chat
class QuickReplyButtons extends StatelessWidget {
  final VoidCallback onYes;
  final VoidCallback onNo;
  final String? yesLabel;
  final String? noLabel;
  final IconData? yesIcon;
  final IconData? noIcon;

  const QuickReplyButtons({
    super.key,
    required this.onYes,
    required this.onNo,
    this.yesLabel,
    this.noLabel,
    this.yesIcon,
    this.noIcon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // NO Button (left)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onNo,
              icon: Icon(
                noIcon ?? Icons.close,
                size: 20,
              ),
              label: Text(noLabel ?? 'NIE'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey[700],
                side: BorderSide(color: Colors.grey[400]!, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal:16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // YES Button (right)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onYes,
              icon: Icon(
                yesIcon ?? Icons.check,
                size: 20,
              ),
              label: Text(yesLabel ?? 'TAK'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget for multiple choice quick replies
class QuickChoiceChips extends StatelessWidget {
  final List<String> choices;
  final Function(String) onSelected;

  const QuickChoiceChips({
    super.key,
    required this.choices,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: choices.map((choice) {
          return ActionChip(
            label: Text(choice),
            onPressed: () => onSelected(choice),
            backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
            labelStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            side: BorderSide.none,
          );
        }).toList(),
      ),
    );
  }
}
