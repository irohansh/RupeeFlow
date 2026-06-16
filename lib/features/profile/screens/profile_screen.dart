import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/models/user_model.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: userAsync.when(
        data: (user) => _ProfileBody(user: user),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  final UserModel? user;
  const _ProfileBody({this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Avatar
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.secondary, width: 2),
                ),
                child: user?.photoUrl != null
                    ? ClipOval(
                        child: Image.network(user!.photoUrl!, fit: BoxFit.cover))
                    : Center(
                        child: Text(
                          user?.displayName?.isNotEmpty == true
                              ? user!.displayName![0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                              color: AppColors.secondary),
                        ),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            user?.displayName ?? 'User',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            user?.email ?? '',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontFamily: 'Inter'),
          ),
          if (user?.emailVerified == true) ...[
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.credit.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.verified, size: 14, color: AppColors.credit),
                  SizedBox(width: 4),
                  Text('Verified',
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.credit)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 32),
          // Profile options
          Card(
            child: Column(
              children: [
                _ProfileTile(
                  icon: Icons.person_outlined,
                  label: 'Edit Profile',
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 60),
                _ProfileTile(
                  icon: Icons.lock_outlined,
                  label: 'Change Password',
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 60),
                _ProfileTile(
                  icon: Icons.pin_outlined,
                  label: 'Set / Change PIN',
                  onTap: () => context.push(AppRoutes.pinSetup),
                ),
                const Divider(height: 1, indent: 60),
                _ProfileTile(
                  icon: Icons.fingerprint,
                  label: 'Biometric Login',
                  trailing: Switch(
                    value: user?.biometricEnabled ?? false,
                    onChanged: (v) {},
                    activeColor: AppColors.secondary,
                  ),
                  onTap: null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: [
                _ProfileTile(
                  icon: Icons.help_outline,
                  label: 'Help & Support',
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 60),
                _ProfileTile(
                  icon: Icons.privacy_tip_outlined,
                  label: 'Privacy Policy',
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 60),
                _ProfileTile(
                  icon: Icons.info_outline,
                  label: 'App Version',
                  trailing: Text('v1.0.0',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 13)),
                  onTap: null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Logout
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await ref.read(authControllerProvider.notifier).signOut();
                if (context.mounted) context.go(AppRoutes.login);
              },
              icon: const Icon(Icons.logout, color: AppColors.error),
              label: const Text('Sign Out',
                  style: TextStyle(color: AppColors.error)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                minimumSize: const Size(double.infinity, 52),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _ProfileTile({
    required this.icon,
    required this.label,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 22),
      title: Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 14)),
      trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right, size: 18) : null),
      onTap: onTap,
    );
  }
}
