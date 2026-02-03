import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../services/purchase_service.dart';
import '../providers/auth_provider.dart';

class PurchaseCreditsDialog extends ConsumerStatefulWidget {
  const PurchaseCreditsDialog({super.key});

  @override
  ConsumerState<PurchaseCreditsDialog> createState() => _PurchaseCreditsDialogState();
}

class _PurchaseCreditsDialogState extends ConsumerState<PurchaseCreditsDialog> {
  final PurchaseService _purchaseService = PurchaseService();
  List<Package> _packages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    final packages = await _purchaseService.fetchPackages();
    if (mounted) {
      setState(() {
        _packages = packages;
        _isLoading = false;
      });
    }
  }

  Future<void> _buy(Package package) async {
    setState(() => _isLoading = true);

    final success = await _purchaseService.purchasePackage(package);

    if (success) {
      // 1. Refresh User Data (to see new credits from backend)
      await ref.read(authProvider.notifier).refreshUser();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Purchase Successful! Credits Added.")),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Purchase Failed or Cancelled")),
        );
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Get More Credits",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            if (_isLoading)
              const CircularProgressIndicator()
            else if (_packages.isEmpty)
              const Text("No packages available currently.")
            else
              ..._packages.map((package) => ListTile(
                title: Text(package.storeProduct.title),
                subtitle: Text(package.storeProduct.description),
                trailing: FilledButton(
                  onPressed: () => _buy(package),
                  child: Text(package.storeProduct.priceString),
                ),
              )),

            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
          ],
        ),
      ),
    );
  }
}