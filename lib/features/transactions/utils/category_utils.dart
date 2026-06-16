import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class CategoryData {
  final IconData icon;
  final Color color;
  final String label;

  const CategoryData({required this.icon, required this.color, required this.label});
}

class CategoryUtils {
  static const Map<String, CategoryData> _categories = {
    'Food': CategoryData(
      icon: Icons.restaurant_outlined,
      color: Color(0xFFF59E0B),
      label: 'Food',
    ),
    'Transport': CategoryData(
      icon: Icons.directions_car_outlined,
      color: Color(0xFF3B82F6),
      label: 'Transport',
    ),
    'Shopping': CategoryData(
      icon: Icons.shopping_bag_outlined,
      color: Color(0xFF8B5CF6),
      label: 'Shopping',
    ),
    'Salary': CategoryData(
      icon: Icons.account_balance_outlined,
      color: Color(0xFF10B981),
      label: 'Salary',
    ),
    'Bills': CategoryData(
      icon: Icons.receipt_outlined,
      color: Color(0xFFEF4444),
      label: 'Bills',
    ),
    'Medical': CategoryData(
      icon: Icons.local_hospital_outlined,
      color: Color(0xFF06B6D4),
      label: 'Medical',
    ),
    'Education': CategoryData(
      icon: Icons.school_outlined,
      color: Color(0xFF0EA5E9),
      label: 'Education',
    ),
    'Entertainment': CategoryData(
      icon: Icons.movie_outlined,
      color: Color(0xFFEC4899),
      label: 'Entertainment',
    ),
    'Other': CategoryData(
      icon: Icons.more_horiz,
      color: Color(0xFF6B7280),
      label: 'Other',
    ),
  };

  static CategoryData getCategoryData(String category) {
    return _categories[category] ??
        const CategoryData(
          icon: Icons.circle_outlined,
          color: Color(0xFF6B7280),
          label: 'Other',
        );
  }

  static List<String> get allCategories => _categories.keys.toList();
}
