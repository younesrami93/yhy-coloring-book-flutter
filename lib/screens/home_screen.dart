import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yhy_coloring_book_flutter/widgets/purchase_credits_dialog.dart';
import '../core/auth_provider.dart'; // Ensure this has the refreshUser method
import '../widgets/credit_badge.dart';
import '../widgets/sleek_bottom_nav.dart';
import '../providers/generations_provider.dart';

// Import Tabs
import 'tabs/home_tab.dart';
import 'tabs/history_tab.dart';
import 'tabs/settings_tab.dart';

final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

// CHANGED: Converted to ConsumerStatefulWidget to handle initState
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {

  @override
  void initState() {
    super.initState();
    // 1. FETCH FRESH DATA ON LOAD
    // This ensures we have the correct credit balance from the server immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {

      // 1. Refresh User Data
      ref.read(authProvider.notifier).refreshUser();

      // 2. CHECK PURCHASE INTENT
      // If the user was sent to Login from "Get Credits", this will be true.

      if (ref.read(purchaseIntentProvider)) {
        // Reset the flag so it doesn't show again next time
        ref.read(purchaseIntentProvider.notifier).state = false;

        // Show the purchase dialog
        showDialog(
            context: context,
            builder: (_) => const PurchaseCreditsDialog()
        );
      }


    });
  }

  @override
  Widget build(BuildContext context) {
    // This automatically rebuilds whenever authProvider updates (e.g. credits change)
    final user = ref.watch(authProvider);
    final currentIndex = ref.watch(bottomNavIndexProvider);
    final theme = Theme.of(context);

    final List<Widget> pages = const [
      HomeTab(),
      HistoryTab(),
      SettingsTab(),
    ];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: theme.brightness == Brightness.light
                ? [const Color(0xFFDCE6F5), const Color(0xFFF0F3F8)]
                : [const Color(0xFF0F141E), const Color(0xFF0A0E17)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // --- TOP BAR ---
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Profile Section
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: theme.colorScheme.primary.withOpacity(0.5),
                                width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: theme.colorScheme.surface,
                            child: Text(
                              user?.name.isNotEmpty == true
                                  ? user!.name[0].toUpperCase()
                                  : "G",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Welcome back,",
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              user?.name ?? "Guest",
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Credit Badge (Updates automatically via ref.watch)
                    CreditBadge(
                      credits: user?.credits ?? 0,
                      onTap: () {
                        // Optional: Refresh manually on tap
                        ref.read(authProvider.notifier).refreshUser();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Refreshing credits...")),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // --- BODY CARD ---
              Expanded(
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                      bottom: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.shadowColor,
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: IndexedStack(
                    index: currentIndex,
                    children: pages,
                  ),
                ),
              ),

              // --- BOTTOM NAV ---
              SleekBottomNav(
                currentIndex: currentIndex,
                onTap: (index) {
                  ref.read(bottomNavIndexProvider.notifier).state = index;

                  // 2. SMART REFRESH
                  // When switching to History, refresh history list
                  if (index == 1) {
                    ref.read(generationsProvider.notifier).refresh();
                  }
                  // When switching to Home (or any tab), refreshing user data is good practice
                  ref.read(authProvider.notifier).refreshUser();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}