import 'package:flutter/material.dart';

/// A single expense category definition.
class CategoryDef {
  final String key;
  final String label;
  final IconData icon;
  final Color color;

  const CategoryDef({
    required this.key,
    required this.label,
    required this.icon,
    required this.color,
  });
}

/// The fixed list of categories used throughout the app.
/// Each category has a distinct icon and accent colour.
class Categories {
  Categories._();

  static const List<CategoryDef> all = [
    CategoryDef(
      key: 'food',
      label: 'Food',
      icon: Icons.restaurant_rounded,
      color: Color(0xFFFF7043),
    ),
    CategoryDef(
      key: 'fuel',
      label: 'Fuel',
      icon: Icons.local_gas_station_rounded,
      color: Color(0xFF42A5F5),
    ),
    CategoryDef(
      key: 'groceries',
      label: 'Groceries',
      icon: Icons.local_grocery_store_rounded,
      color: Color(0xFF66BB6A),
    ),
    CategoryDef(
      key: 'shopping',
      label: 'Shopping',
      icon: Icons.shopping_bag_rounded,
      color: Color(0xFFEC407A),
    ),
    CategoryDef(
      key: 'bills',
      label: 'Bills',
      icon: Icons.receipt_long_rounded,
      color: Color(0xFFFFCA28),
    ),
    CategoryDef(
      key: 'entertainment',
      label: 'Entertainment',
      icon: Icons.movie_rounded,
      color: Color(0xFFAB47BC),
    ),
    CategoryDef(
      key: 'medical',
      label: 'Medical',
      icon: Icons.medical_services_rounded,
      color: Color(0xFFEF5350),
    ),
    CategoryDef(
      key: 'travel',
      label: 'Travel',
      icon: Icons.flight_takeoff_rounded,
      color: Color(0xFF26C6DA),
    ),
    CategoryDef(
      key: 'pets',
      label: 'Pets',
      icon: Icons.pets_rounded,
      color: Color(0xFF8D6E63),
    ),
    CategoryDef(
      key: 'family',
      label: 'Family',
      icon: Icons.family_restroom_rounded,
      color: Color(0xFF5C6BC0),
    ),
    CategoryDef(
      key: 'recharge',
      label: 'Recharge',
      icon: Icons.smartphone_rounded,
      color: Color(0xFF29B6F6),
    ),
    CategoryDef(
      key: 'education',
      label: 'Education',
      icon: Icons.school_rounded,
      color: Color(0xFF26A69A),
    ),
    CategoryDef(
      key: 'others',
      label: 'Others',
      icon: Icons.category_rounded,
      color: Color(0xFF78909C),
    ),
  ];

  static CategoryDef byKey(String key) {
    return all.firstWhere(
      (c) => c.key == key,
      orElse: () => all.last,
    );
  }
}
