class AppConstants {
  // App
  static const appName = 'RupeeFlow';
  static const currencySymbol = '₹';

  // Auth limits
  static const maxFailedLoginAttempts = 5;
  static const loginLockoutMinutes = 15;
  static const maxPasswordResetPerHour = 10;

  // SMS
  static const maxDailySmsImports = 500;

  // Collections
  static const usersCollection = 'users';
  static const transactionsCollection = 'transactions';
  static const loansCollection = 'loans';
  static const remindersCollection = 'reminders';
  static const categoriesCollection = 'categories';
  static const notificationsCollection = 'notifications';

  // Hive boxes
  static const settingsBox = 'settings';
  static const authBox = 'auth';
  static const cacheBox = 'cache';

  // Secure storage keys
  static const pinHashKey = 'pin_hash';
  static const biometricEnabledKey = 'biometric_enabled';
  static const loginAttemptsKey = 'login_attempts';
  static const lockoutTimeKey = 'lockout_time';
  static const smsImportCountKey = 'sms_import_count';
  static const smsImportDateKey = 'sms_import_date';

  // Notification channels
  static const reminderChannelId = 'reminders';
  static const reminderChannelName = 'Reminders';
  static const transactionChannelId = 'transactions';
  static const transactionChannelName = 'Transactions';

  // Transaction types
  static const credit = 'credit';
  static const debit = 'debit';
  static const cash = 'cash';
  static const smsImported = 'sms_imported';

  // Loan types
  static const lent = 'lent';
  static const borrowed = 'borrowed';

  // Loan status
  static const pending = 'pending';
  static const completed = 'completed';
  static const overdue = 'overdue';

  // Categories
  static const List<String> categories = [
    'Food',
    'Transport',
    'Shopping',
    'Salary',
    'Bills',
    'Medical',
    'Education',
    'Entertainment',
    'Other',
  ];
}

class AppStrings {
  static const loginTitle = 'Welcome Back';
  static const loginSubtitle = 'Sign in to manage your finances';
  static const signupTitle = 'Create Account';
  static const signupSubtitle = 'Start tracking your finances today';
  static const forgotPasswordTitle = 'Forgot Password?';
  static const forgotPasswordSubtitle = "Enter your email and we'll send you a reset link";
  static const dashboardTitle = 'Dashboard';
  static const transactionsTitle = 'Transactions';
  static const debtsTitle = 'Debt Tracker';
  static const remindersTitle = 'Reminders';
  static const settingsTitle = 'Settings';
  static const profileTitle = 'Profile';

  // Errors
  static const genericError = 'Something went wrong. Please try again.';
  static const networkError = 'No internet connection. Please check your network.';
  static const authError = 'Authentication failed. Please try again.';
  static const tooManyAttempts = 'Too many failed attempts. Account locked for 15 minutes.';
}
