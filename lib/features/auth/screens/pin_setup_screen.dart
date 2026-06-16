import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../providers/auth_provider.dart';

class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  String _pin = '';
  String _confirmPin = '';
  bool _confirming = false;

  void _onDigit(String digit) {
    setState(() {
      if (!_confirming) {
        if (_pin.length < 4) _pin += digit;
        if (_pin.length == 4) {
          _confirming = true;
        }
      } else {
        if (_confirmPin.length < 4) _confirmPin += digit;
        if (_confirmPin.length == 4) _verify();
      }
    });
  }

  void _onDelete() {
    setState(() {
      if (_confirming) {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        }
      } else {
        if (_pin.isNotEmpty) {
          _pin = _pin.substring(0, _pin.length - 1);
        }
      }
    });
  }

  Future<void> _verify() async {
    if (_pin == _confirmPin) {
      await ref.read(authControllerProvider.notifier).setPin(_pin);
      if (mounted) context.go(AppRoutes.dashboard);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PINs do not match. Please try again.'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
      setState(() {
        _pin = '';
        _confirmPin = '';
        _confirming = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPin = _confirming ? _confirmPin : _pin;
    return Scaffold(
      appBar: AppBar(
        title: Text(_confirming ? 'Confirm PIN' : 'Set PIN'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 48),
            Icon(Icons.lock_outlined,
                size: 56, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 24),
            Text(
              _confirming ? 'Confirm your PIN' : 'Create a 4-digit PIN',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              _confirming
                  ? 'Enter the same PIN again'
                  : 'This PIN will protect your app',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 48),
            // PIN dots
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
                    color: i < currentPin.length
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 48),
            // Keypad
            Expanded(child: _buildKeypad()),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => context.go(AppRoutes.dashboard),
              child: const Text('Skip for now'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 48),
      childAspectRatio: 1.4,
      children: [
        ...[
          '1', '2', '3',
          '4', '5', '6',
          '7', '8', '9',
          '', '0', 'del',
        ].map(
          (d) => d == ''
              ? const SizedBox()
              : d == 'del'
                  ? IconButton(
                      onPressed: _onDelete,
                      icon: const Icon(Icons.backspace_outlined),
                      iconSize: 28,
                    )
                  : TextButton(
                      onPressed: () => _onDigit(d),
                      child: Text(d,
                          style: const TextStyle(
                              fontSize: 28, fontWeight: FontWeight.w400)),
                    ),
        ),
      ],
    );
  }
}
