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

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Account Section
        _SectionHeader(title: "Account"),
        _SettingsTile(
          icon: FontAwesomeIcons.user,
          title: "Name",
          subtitle: user?.name ?? "Guest",
          onTap: () {}, // TODO: Edit Profile
        ),

        const SizedBox(height: 24),

        // Appearance Section
        _SectionHeader(title: "Appearance"),
        _SettingsTile(
          icon: _getThemeIcon(themeMode),
          title: "Theme",
          subtitle: _getThemeText(themeMode),
          onTap: () => _showThemeDialog(context, ref, themeMode),
        ),
        _SettingsTile(
          icon: FontAwesomeIcons.language,
          title: "Language",
          subtitle: "English",
          onTap: () {}, // TODO: Language Logic
        ),

        const SizedBox(height: 24),

        // Logout
        _SettingsTile(
          icon: FontAwesomeIcons.rightFromBracket,
          title: "Logout",
          textColor: Colors.red,
          iconColor: Colors.red,
          onTap: () {
            ref.read(authProvider.notifier).logout();
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          },
        ),
      ],
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

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.textColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3), // Subtle background
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: iconColor ?? theme.colorScheme.primary),
        ),
        title: Text(
            title,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: textColor
            )
        ),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        trailing: Icon(Icons.chevron_right, size: 18, color: theme.disabledColor),
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