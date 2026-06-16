import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../providers/auth_provider.dart';

class PinLockScreen extends ConsumerStatefulWidget {
  const PinLockScreen({super.key});

  @override
  ConsumerState<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends ConsumerState<PinLockScreen> {
  String _pin = '';
  String? _error;

  void _onDigit(String d) {
    if (_pin.length < 4) {
      setState(() {
        _pin += d;
        _error = null;
      });
      if (_pin.length == 4) _verify();
    }
  }

  void _onDelete() {
    if (_pin.isNotEmpty) setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _verify() async {
    final ok = await ref.read(authControllerProvider.notifier).verifyPin(_pin);
    if (ok && mounted) {
      context.go(AppRoutes.dashboard);
    } else {
      setState(() {
        _error = 'Incorrect PIN. Try again.';
        _pin = '';
      });
    }
  }

  Future<void> _biometric() async {
    final ok = await ref.read(authControllerProvider.notifier).authenticateWithBiometrics();
    if (ok && mounted) context.go(AppRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 64),
            const Icon(Icons.lock_outlined, size: 56),
            const SizedBox(height: 16),
            Text('Enter PIN',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (_error != null)
              Text(_error!,
                  style: const TextStyle(
                      color: Color(0xFFEF4444), fontFamily: 'Inter'))
            else
              Text('Enter your 4-digit PIN',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                4,
                (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < _pin.length
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 48),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 48),
                childAspectRatio: 1.4,
                children: [
                  ...[
                    '1', '2', '3',
                    '4', '5', '6',
                    '7', '8', '9',
                    'bio', '0', 'del',
                  ].map(
                    (d) {
                      if (d == 'del') {
                        return IconButton(
                          onPressed: _onDelete,
                          icon: const Icon(Icons.backspace_outlined),
                          iconSize: 28,
                        );
                      } else if (d == 'bio') {
                        return IconButton(
                          onPressed: _biometric,
                          icon: const Icon(Icons.fingerprint),
                          iconSize: 32,
                          color: Theme.of(context).colorScheme.primary,
                        );
                      }
                      return TextButton(
                        onPressed: () => _onDigit(d),
                        child: Text(d,
                            style: const TextStyle(
                                fontSize: 28, fontWeight: FontWeight.w400)),
                      );
                    },
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () async {
                await ref.read(authControllerProvider.notifier).signOut();
                if (mounted) context.go(AppRoutes.login);
              },
              child: const Text('Sign out'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
