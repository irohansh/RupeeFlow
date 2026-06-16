import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Appearance
          _SectionHeader('Appearance'),
          Card(
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.dark_mode_outlined,
                  label: 'Theme',
                  trailing: DropdownButton<ThemeMode>(
                    value: themeMode,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(
                          value: ThemeMode.system, child: Text('System')),
                      DropdownMenuItem(
                          value: ThemeMode.light, child: Text('Light')),
                      DropdownMenuItem(
                          value: ThemeMode.dark, child: Text('Dark')),
                    ],
                    onChanged: (v) {
                      if (v != null)
                        ref.read(themeModeProvider.notifier).setTheme(v);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Security
          _SectionHeader('Security'),
          Card(
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.pin_outlined,
                  label: 'PIN Lock',
                  onTap: () => context.push(AppRoutes.pinSetup),
                ),
                const Divider(height: 1, indent: 60),
                _SettingsTile(
                  icon: Icons.fingerprint,
                  label: 'Biometric Auth',
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Notifications
          _SectionHeader('Notifications'),
          Card(
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.notifications_outlined,
                  label: 'Push Notifications',
                  trailing: Switch(
                    value: true,
                    onChanged: (v) {},
                    activeColor: AppColors.secondary,
                  ),
                ),
                const Divider(height: 1, indent: 60),
                _SettingsTile(
                  icon: Icons.alarm_outlined,
                  label: 'Reminder Alerts',
                  trailing: Switch(
                    value: true,
                    onChanged: (v) {},
                    activeColor: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Data & Privacy
          _SectionHeader('Data & Privacy'),
          Card(
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.sms_outlined,
                  label: 'SMS Import (Android)',
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 60),
                _SettingsTile(
                  icon: Icons.backup_outlined,
                  label: 'Backup to Cloud',
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 60),
                _SettingsTile(
                  icon: Icons.delete_outline,
                  label: 'Clear Cache',
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Account
          _SectionHeader('Account'),
          Card(
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.person_outlined,
                  label: 'Edit Profile',
                  onTap: () => context.push(AppRoutes.profile),
                ),
                const Divider(height: 1, indent: 60),
                _SettingsTile(
                  icon: Icons.logout,
                  label: 'Sign Out',
                  labelColor: AppColors.error,
                  onTap: () async {
                    await ref.read(authControllerProvider.notifier).signOut();
                    if (context.mounted) context.go(AppRoutes.login);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? labelColor;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.onTap,
    this.trailing,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 22, color: labelColor),
      title: Text(
        label,
        style: TextStyle(
            fontFamily: 'Inter', fontSize: 14, color: labelColor),
      ),
      trailing: trailing ??
          (onTap != null ? const Icon(Icons.chevron_right, size: 18) : null),
      onTap: onTap,
    );
  }
}
