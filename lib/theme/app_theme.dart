import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {

  static const Color background = Color(0xFFFFFFFF);
  static const Color backgroundSecondary = Color(0xFFFAFAFA);


  static const Color border = Color(0xFFE4E4E7); // zinc-200
  static const Color borderLight = Color(0xFFF4F4F5); // zinc-100


  static const Color foreground = Color(0xFF09090B); // zinc-950
  static const Color foregroundMuted = Color(0xFF71717A); // zinc-500
  static const Color foregroundSubtle = Color(0xFFA1A1AA); // zinc-400


  static const Color primary = Color(0xFF976A60);
  static const Color primaryForeground = Color(0xFFFFFFFF);


  static const Color accent = Color(0xFF946B5C); // Keep the original brand color
  static const Color accentForeground = Color(0xFFFFFFFF);


  static const Color muted = Color(0xFFF4F4F5); // zinc-100
  static const Color mutedForeground = Color(0xFF71717A); // zinc-500


  static const Color card = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFE4E4E7);


  static const Color input = Color(0xFFFFFFFF);
  static const Color inputBorder = Color(0xFFE4E4E7);


  static const Color destructive = Color(0xFFEF4444);
  static const Color destructiveForeground = Color(0xFFFFFFFF);


  static const Color success = Color(0xFF10B981);
  static const Color successForeground = Color(0xFFFFFFFF);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningForeground = Color(0xFFFFFFFF);
}

class AppTheme {
  static ThemeData buildTheme(BuildContext context) {
    final textTheme = GoogleFonts.interTextTheme(Theme.of(context).textTheme).apply(
      bodyColor: AppColors.foreground,
      displayColor: AppColors.foreground,
    );

    return ThemeData(
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      useMaterial3: true,
      textTheme: textTheme,

      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.foreground,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.foreground,
          letterSpacing: -0.5,
        ),
      ),


      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.cardBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),


      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.input,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.inputBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.inputBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.destructive, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.destructive, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(
          color: AppColors.foregroundSubtle,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: GoogleFonts.inter(
          color: AppColors.foregroundMuted,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),


      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.primaryForeground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),


      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.foreground,
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.foreground,
          side: const BorderSide(color: AppColors.border, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.card,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.foregroundSubtle,
        elevation: 0,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 11,
        ),
        type: BottomNavigationBarType.fixed,
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.foreground,
        unselectedLabelColor: AppColors.foregroundMuted,
        indicatorSize: TabBarIndicatorSize.label,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),
        labelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),


      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.primaryForeground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),


      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),


      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),


      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.foreground,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.input,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.inputBorder, width: 1),
          ),
        ),
      ),


      popupMenuTheme: PopupMenuThemeData(
        elevation: 2,
        color: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.foreground,
        ),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        circularTrackColor: AppColors.muted,
        linearTrackColor: AppColors.muted,
      ),


      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.card,
        error: AppColors.destructive,
        onPrimary: AppColors.primaryForeground,
        onSecondary: AppColors.accentForeground,
        onSurface: AppColors.foreground,
        onError: AppColors.destructiveForeground,
      ),
    );
  }

  static InputDecoration dropdownDecoration({
    required String labelText,
    String? hintText,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      filled: true,
      fillColor: AppColors.input,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.inputBorder, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.inputBorder, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.destructive, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.destructive, width: 1.5),
      ),
      labelStyle: GoogleFonts.inter(
        color: AppColors.foregroundMuted,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  static TextStyle dropdownItemStyle({bool isSelected = false}) {
    return GoogleFonts.inter(
      fontSize: 14,
      fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
      color: AppColors.foreground,
    );
  }
}
