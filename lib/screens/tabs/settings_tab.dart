// [file_path: lib/screens/tabs/settings_tab.dart]
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/app_state.dart';
import '../../core/auth_provider.dart';
import '../login_screen.dart';

class SettingsTab extends ConsumerWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final user = ref.watch(authProvider);
    final theme = Theme.of(context);

    // Logic: Guests usually have empty emails or specific IDs.
    // Based on your User model, checking if email is empty is a safe bet.
    final bool isGuest = user?.email.isEmpty ?? true;
    final String displayName = isGuest ? "Guest User" : (user?.name ?? "User");
    final String displayEmail = isGuest ? "Sign in to save your work" : (user?.email ?? "");

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          children: [
            // --- 1. Profile Header ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.1),
                ),
              ),
              child: Row(
                children: [
                  // Profile Icon Placeholder
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: isGuest
                        ? theme.colorScheme.secondaryContainer
                        : theme.colorScheme.primaryContainer,
                    child: Icon(
                      isGuest ? FontAwesomeIcons.userSecret : FontAwesomeIcons.userLarge,
                      size: 28,
                      color: isGuest
                          ? theme.colorScheme.onSecondaryContainer
                          : theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Text Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          displayEmail,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // --- 2. Account Actions (Sign In vs Logout) ---
            _SectionHeader(title: "Account"),

            if (isGuest)
              _SettingsTile(
                icon: FontAwesomeIcons.rightToBracket,
                title: "Sign In / Register",
                subtitle: "Link your account to save generations",
                iconColor: Colors.white,
                tileColor: theme.colorScheme.primary, // Highlight this button
                textColor: Colors.white,
                onTap: () {
                  // Navigate to Login Screen to upgrade account
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
              )
            else ...[
              // Real User Options
              _SettingsTile(
                icon: FontAwesomeIcons.userPen,
                title: "Edit Profile",
                onTap: () {
                  // TODO: Implement Edit Profile
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Edit Profile coming soon!")),
                  );
                },
              ),
              _SettingsTile(
                icon: FontAwesomeIcons.crown,
                title: "Subscription",
                subtitle: "${user?.credits ?? 0} Credits Available",
                onTap: () {
                  // TODO: Open Purchase Dialog
                },
              ),
            ],

            const SizedBox(height: 24),

            // --- 3. App Settings ---
            _SectionHeader(title: "Preferences"),
            _SettingsTile(
              icon: _getThemeIcon(themeMode),
              title: "Theme",
              subtitle: _getThemeText(themeMode),
              onTap: () => _showThemeDialog(context, ref, themeMode),
            ),
            _SettingsTile(
              icon: FontAwesomeIcons.globe,
              title: "Language",
              subtitle: "English",
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Language selection coming soon!")),
                );
              },
            ),

            const SizedBox(height: 24),

            // --- 4. Danger Zone (Logout for Real Users) ---
            if (!isGuest) ...[
              _SectionHeader(title: "Session"),
              _SettingsTile(
                icon: FontAwesomeIcons.arrowRightFromBracket,
                title: "Logout",
                textColor: theme.colorScheme.error,
                iconColor: theme.colorScheme.error,
                onTap: () async {
                  // Show confirmation dialog
                  final shouldLogout = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Logout?"),
                      content: const Text("Are you sure you want to log out?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text("Logout"),
                        ),
                      ],
                    ),
                  );

                  if (shouldLogout == true) {
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    }
                  }
                },
              ),
            ],

            // Version info at bottom
            const SizedBox(height: 40),
            Center(
              child: Text(
                "Version 1.0.0",
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.disabledColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPERS ---

  String _getThemeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system: return "System Default";
      case ThemeMode.light: return "Light Mode";
      case ThemeMode.dark: return "Dark Mode";
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
      builder: (context) {
        return SimpleDialog(
          title: const Text("Choose Theme"),
          children: [
            _ThemeOption(
              text: "System Default",
              value: ThemeMode.system,
              groupValue: currentMode,
              icon: FontAwesomeIcons.mobileScreen,
              onChanged: (val) {
                ref.read(themeProvider.notifier).setTheme(val);
                Navigator.pop(context);
              },
            ),
            _ThemeOption(
              text: "Light Mode",
              value: ThemeMode.light,
              groupValue: currentMode,
              icon: FontAwesomeIcons.sun,
              onChanged: (val) {
                ref.read(themeProvider.notifier).setTheme(val);
                Navigator.pop(context);
              },
            ),
            _ThemeOption(
              text: "Dark Mode",
              value: ThemeMode.dark,
              groupValue: currentMode,
              icon: FontAwesomeIcons.moon,
              onChanged: (val) {
                ref.read(themeProvider.notifier).setTheme(val);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
}

// --- SMALL WIDGETS ---

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
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

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? textColor;
  final Color? iconColor;
  final Color? tileColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.textColor,
    this.iconColor,
    this.tileColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isHighlighted = tileColor != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: tileColor ?? theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        boxShadow: isHighlighted ? [
          BoxShadow(
            color: tileColor!.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ] : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0), // increased padding
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isHighlighted ? Colors.white.withOpacity(0.2) : theme.colorScheme.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                      icon,
                      size: 18,
                      color: iconColor ?? (isHighlighted ? Colors.white : theme.colorScheme.primary)
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: textColor ?? (isHighlighted ? Colors.white : theme.colorScheme.onSurface),
                          )
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 13,
                            color: isHighlighted
                                ? Colors.white.withOpacity(0.8)
                                : theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
                Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: isHighlighted ? Colors.white.withOpacity(0.5) : theme.disabledColor
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String text;
  final ThemeMode value;
  final ThemeMode groupValue;
  final IconData icon;
  final Function(ThemeMode) onChanged;

  const _ThemeOption({
    required this.text,
    required this.value,
    required this.groupValue,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    return RadioListTile<ThemeMode>(
      value: value,
      groupValue: groupValue,
      onChanged: (v) => onChanged(v!),
      activeColor: Theme.of(context).primaryColor,
      title: Row(
        children: [
          Icon(icon, size: 18, color: isSelected ? Theme.of(context).primaryColor : Colors.grey),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }
}