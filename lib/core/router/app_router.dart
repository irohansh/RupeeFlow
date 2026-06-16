import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/shell/shell_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/email_verification_screen.dart';
import '../../features/auth/screens/pin_setup_screen.dart';
import '../../features/auth/screens/pin_lock_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/transactions/screens/transaction_history_screen.dart';
import '../../features/transactions/screens/add_credit_screen.dart';
import '../../features/transactions/screens/add_debit_screen.dart';
import '../../features/transactions/screens/transaction_detail_screen.dart';
import '../../features/debts/screens/debt_tracker_screen.dart';
import '../../features/debts/screens/add_debt_screen.dart';
import '../../features/reminders/screens/reminders_screen.dart';
import '../../features/reminders/screens/add_reminder_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/settings/screens/settings_screen.dart';

// Route names
class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const signup = '/signup';
  static const forgotPassword = '/forgot-password';
  static const emailVerification = '/email-verification';
  static const pinSetup = '/pin-setup';
  static const pinLock = '/pin-lock';
  static const shell = '/app';
  static const dashboard = '/app/dashboard';
  static const transactions = '/app/transactions';
  static const addCredit = '/app/transactions/add-credit';
  static const addDebit = '/app/transactions/add-debit';
  static const transactionDetail = '/app/transactions/:id';
  static const debts = '/app/debts';
  static const addDebt = '/app/debts/add';
  static const reminders = '/app/reminders';
  static const addReminder = '/app/reminders/add';
  static const profile = '/app/profile';
  static const settings = '/app/settings';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final isAuthenticated = authState.valueOrNull != null;
      final isSplash = state.matchedLocation == AppRoutes.splash;
      final isAuthRoute = [
        AppRoutes.login,
        AppRoutes.signup,
        AppRoutes.forgotPassword,
        AppRoutes.emailVerification,
        AppRoutes.pinLock,
      ].contains(state.matchedLocation);

      if (isSplash) return null;
      if (!isAuthenticated && !isAuthRoute) return AppRoutes.login;
      if (isAuthenticated && isAuthRoute && state.matchedLocation != AppRoutes.pinLock) {
        return AppRoutes.dashboard;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.emailVerification,
        builder: (context, state) => const EmailVerificationScreen(),
      ),
      GoRoute(
        path: AppRoutes.pinSetup,
        builder: (context, state) => const PinSetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.pinLock,
        builder: (context, state) => const PinLockScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => ShellScreen(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.transactions,
            builder: (context, state) => const TransactionHistoryScreen(),
            routes: [
              GoRoute(
                path: 'add-credit',
                builder: (context, state) => const AddCreditScreen(),
              ),
              GoRoute(
                path: 'add-debit',
                builder: (context, state) => const AddDebitScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return TransactionDetailScreen(transactionId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.debts,
            builder: (context, state) => const DebtTrackerScreen(),
            routes: [
              GoRoute(
                path: 'add',
                builder: (context, state) => const AddDebtScreen(),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.reminders,
            builder: (context, state) => const RemindersScreen(),
            routes: [
              GoRoute(
                path: 'add',
                builder: (context, state) => const AddReminderScreen(),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
});
