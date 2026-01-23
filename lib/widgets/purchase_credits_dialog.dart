import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme.dart';

class PurchaseCreditsDialog extends StatelessWidget {
  const PurchaseCreditsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.goldAccent.withOpacity(0.15),
              ),
              child: Column(
                children: [
                  const Icon(FontAwesomeIcons.store, color: AppTheme.goldAccent, size: 32),
                  const SizedBox(height: 12),
                  Text(
                    "Credit Store",
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Packages List
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _CreditPackageTile(
                    credits: 10,
                    price: "\$1.99",
                    theme: theme,
                    onTap: () => _simulatePurchase(context, 10),
                  ),
                  const SizedBox(height: 12),
                  _CreditPackageTile(
                    credits: 50,
                    price: "\$4.99",
                    isPopular: true,
                    theme: theme,
                    onTap: () => _simulatePurchase(context, 50),
                  ),
                  const SizedBox(height: 12),
                  _CreditPackageTile(
                    credits: 100,
                    price: "\$8.99",
                    theme: theme,
                    onTap: () => _simulatePurchase(context, 100),
                  ),

                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("Maybe Later", style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _simulatePurchase(BuildContext context, int amount) {
    // TODO: Implement Real In-App Purchase
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Purchased $amount credits! (Simulation)")),
    );
  }
}

class _CreditPackageTile extends StatelessWidget {
  final int credits;
  final String price;
  final bool isPopular;
  final ThemeData theme;
  final VoidCallback onTap;

  const _CreditPackageTile({
    required this.credits,
    required this.price,
    this.isPopular = false,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: isPopular ? Border.all(color: AppTheme.goldAccent, width: 2) : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(FontAwesomeIcons.coins, color: AppTheme.goldAccent, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$credits Credits",
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  if (isPopular)
                    Text(
                      "Best Value",
                      style: theme.textTheme.labelSmall?.copyWith(color: AppTheme.goldAccent, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isPopular ? AppTheme.goldAccent : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                price,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isPopular ? Colors.black : theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}