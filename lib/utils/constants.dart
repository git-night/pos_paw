import 'package:flutter/material.dart';

const MaterialColor primaryPawColor = MaterialColor(
  0xFF946B5C,
  <int, Color>{
    50: Color(0xFFF0EBEA),
    100: Color(0xFFD9CBC6),
    200: Color(0xFFC1A9A1),
    300: Color(0xFFA9887D),
    400: Color(0xFF946B5C),
    500: Color(0xFF835A4A),
    600: Color(0xFF7A5243),
    700: Color(0xFF6F493B),
    800: Color(0xFF644133),
    900: Color(0xFF513226),
  },
);

const Color pawBackgroundColor = Color(0xFFF7F7F7);
const Color pawTextColor = Color(0xFF42332E);
const Color pawBorderColor = Color(0xFFD4C1B8);

enum ActivityType { sale, purchase, returnedSale }

class ActivityViewModel {
  final ActivityType type;
  final DateTime date;
  final String title;
  final String subtitle;
  final String amountText;
  final IconData icon;
  final Color iconColor;

  ActivityViewModel({
    required this.type,
    required this.date,
    required this.title,
    required this.subtitle,
    required this.amountText,
    required this.icon,
    required this.iconColor,
  });
}
