import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/app_state.dart';
import '../../providers/auth_provider.dart';
import '../login_screen.dart';

class SettingsTab extends ConsumerWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final user = ref.watch(authProvider);
    final isGuest = user?.isGuest ?? true;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // SafeArea ensures we don't go behind the status bar since we removed the AppBar
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  children: [
                    // --- 1. PROFILE SECTION ---
                    if (isGuest) ...[
                      _GuestBanner(theme: theme),
                      const SizedBox(height: 16),
                      _ActionCard(
                        title: "Sign in to your account",
                        subtitle: "Sync your art across devices",
                        icon: FontAwesomeIcons.google,
                        color: theme.colorScheme.primary,
                        textColor: Colors.white,
                        onTap: () => _navigateToLogin(context),
                      ),
                    ] else ...[
                      _UserProfileHeader(user: user!, theme: theme),
                      const SizedBox(height: 24),

                      // --- 2. PREMIUM WALLET CARD (Encourages Clicks) ---
                      _PremiumWalletCard(
                          credits: user.credits,
                          onTap: () {
                            // TODO: Open Purchase Dialog
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Opening Store..."))
                            );
                          }
                      ),
                    ],

                    const SizedBox(height: 32),

                    // --- 3. PREFERENCES ---
                    _SectionHeader(title: "Preferences"),
                    _SettingsGroup(
                      children: [
                        _SettingsTile(
                          icon: _getThemeIcon(themeMode),
                          title: "Appearance",
                          value: _getThemeText(themeMode),
                          onTap: () => _showThemeDialog(context, ref, themeMode),
                        ),
                        _SettingsDivider(),
                        _SettingsTile(
                          icon: FontAwesomeIcons.globe,
                          title: "Language",
                          value: "English",
                          onTap: () {
                            // Language logic
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // --- 4. LEGAL & SUPPORT ---
                    _SectionHeader(title: "About"),
                    _SettingsGroup(
                      children: [
                        _SettingsTile(
                          icon: FontAwesomeIcons.shieldHalved,
                          title: "Privacy Policy",
                          onTap: () {},
                        ),
                        _SettingsDivider(),
                        _SettingsTile(
                          icon: FontAwesomeIcons.fileContract,
                          title: "Terms of Use",
                          onTap: () {},
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // --- 5. LOGOUT ---
                    if (!isGuest)
                      _SettingsGroup(
                        children: [
                          _SettingsTile(
                            icon: FontAwesomeIcons.arrowRightFromBracket,
                            title: "Log Out",
                            textColor: theme.colorScheme.error,
                            iconColor: theme.colorScheme.error,
                            hideChevron: true,
                            onTap: () => _confirmLogout(context, ref),
                          ),
                        ],
                      ),

                    const SizedBox(height: 40),
                    Text(
                      "Version 1.0.0",
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.disabledColor,
                      ),
                    ),
                    const SizedBox(height: 100), // Spacing for bottom nav
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- NAVIGATION & ACTIONS ---
  void _navigateToLogin(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Log Out"),
        content: const Text("Are you sure?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Log Out"),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await ref.read(authProvider.notifier).logout();
      if (context.mounted) _navigateToLogin(context);
    }
  }

  String _getThemeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system: return "System";
      case ThemeMode.light: return "Light";
      case ThemeMode.dark: return "Dark";
    }
  }

  IconData _getThemeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system: return FontAwesomeIcons.mobileScreen;
      case ThemeMode.light: return FontAwesomeIcons.sun;
      case ThemeMode.dark: return FontAwesomeIcons.moon;
    }
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref, ThemeMode currentMode) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text("Appearance"),
        children: [
          for (var mode in ThemeMode.values)
            RadioListTile<ThemeMode>(
              title: Text(_getThemeText(mode)),
              value: mode,
              groupValue: currentMode,
              onChanged: (val) {
                ref.read(themeProvider.notifier).setTheme(val!);
                Navigator.pop(context);
              },
            ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
//                                  COMPONENTS
// -----------------------------------------------------------------------------

class _PremiumWalletCard extends StatelessWidget {
  final int credits;
  final VoidCallback onTap;

  const _PremiumWalletCard({required this.credits, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFA000), Color(0xFFFFC107)], // Amber/Gold Gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFA000).withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // 1. Decorative Background Coin (Big & Faded)
              Positioned(
                right: -20,
                bottom: -30,
                child: Icon(
                  FontAwesomeIcons.coins,
                  size: 140,
                  color: Colors.white.withOpacity(0.15),
                ),
              ),

              // 2. Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(FontAwesomeIcons.coins, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          "BALANCE",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "$credits",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 6),
                          child: Text(
                            "Credits",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Get More Credits",
                            style: TextStyle(
                              color: Color(0xFFFFA000),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFFFFA000))
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserProfileHeader extends StatelessWidget {
  final dynamic user;
  final ThemeData theme;

  const _UserProfileHeader({required this.user, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: theme.colorScheme.primaryContainer,
          backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
          child: user.avatarUrl == null
              ? Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : "U",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
          )
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.name.isNotEmpty ? user.name : "User",
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (user.email != null)
                Text(
                  user.email!,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.disabledColor),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GuestBanner extends StatelessWidget {
  final ThemeData theme;
  const _GuestBanner({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(FontAwesomeIcons.userSecret, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Text(
            "Guest Mode",
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: textColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 0, 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? value;
  final VoidCallback onTap;
  final Color? textColor;
  final Color? iconColor;
  final bool hideChevron;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.value,
    required this.onTap,
    this.textColor,
    this.iconColor,
    this.hideChevron = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: (iconColor ?? theme.colorScheme.primary).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: iconColor ?? theme.colorScheme.primary),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: textColor,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null)
            Text(value!, style: TextStyle(color: theme.disabledColor, fontSize: 14)),
          if (!hideChevron) ...[
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, size: 18, color: theme.disabledColor),
          ]
        ],
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
        height: 1,
        thickness: 1,
        indent: 64,
        color: Theme.of(context).dividerColor.withOpacity(0.1)
    );
  }
}