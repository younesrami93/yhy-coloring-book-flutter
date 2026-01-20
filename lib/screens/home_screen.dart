import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/auth_provider.dart';
import '../widgets/credit_badge.dart';
import '../widgets/sleek_bottom_nav.dart';

// Import Tabs
import 'tabs/home_tab.dart';
import 'tabs/history_tab.dart';
import 'tabs/settings_tab.dart';

final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final currentIndex = ref.watch(bottomNavIndexProvider);
    final theme = Theme.of(context);

    final List<Widget> pages = const [
      HomeTab(),
      HistoryTab(),
      SettingsTab(),
    ];

    // Colors for the card "Sheet" effect
    final Color innerBodyColor = theme.colorScheme.surface;

    return Scaffold(
      // We remove the solid backgroundColor so our Container gradient shows
      body: Container(
        // --- 1. MESH GRADIENT BACKGROUND ---
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: theme.brightness == Brightness.light
                ? [
              const Color(0xFFDCE6F5), // Light Blue Top
              const Color(0xFFF0F3F8), // Grey Bottom
            ]
                : [
              const Color(0xFF0F141E), // Deep Blue Top
              const Color(0xFF0A0E17), // Black Bottom
            ],
          ),
        ),
        child: SafeArea(
          bottom: false, // We let the gradient go behind the nav bar
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
                                width: 2
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: theme.colorScheme.surface,
                            child: Text(
                              user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : "G",
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

                    // Credit Badge
                    CreditBadge(
                      credits: user?.credits ?? 0,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Open Store")),
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
                    color: innerBodyColor,
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
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}