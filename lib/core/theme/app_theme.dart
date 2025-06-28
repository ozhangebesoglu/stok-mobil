import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppTheme {
  // Responsive breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;

  // Modern color scheme
  static const ColorScheme _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFFD32F2F),
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFFFDAD6),
    onPrimaryContainer: Color(0xFF410002),
    secondary: Color(0xFF775652),
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFFFDAD6),
    onSecondaryContainer: Color(0xFF2C1512),
    tertiary: Color(0xFF705C2E),
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFFFBDFA6),
    onTertiaryContainer: Color(0xFF251A00),
    error: Color(0xFFBA1A1A),
    errorContainer: Color(0xFFFFDAD6),
    onError: Colors.white,
    onErrorContainer: Color(0xFF410002),
    surface: Color(0xFFFFFBFF),
    onSurface: Color(0xFF201A19),
    surfaceContainerHighest: Color(0xFFF5DDDA),
    onSurfaceVariant: Color(0xFF534341),
    outline: Color(0xFF857371),
    onInverseSurface: Color(0xFFFBEEEC),
    inverseSurface: Color(0xFF362F2E),
    inversePrimary: Color(0xFFFFB4AB),
    shadow: Color(0xFF000000),
    surfaceTint: Color(0xFFD32F2F),
    outlineVariant: Color(0xFFD8C2BE),
    scrim: Color(0xFF000000),
  );

  static const ColorScheme _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFEF5350),
    onPrimary: Colors.black,
    secondary: Color(0xFF757575),
    onSecondary: Colors.black,
    error: Color(0xFFEF5350),
    onError: Colors.black,
    surface: Color(0xFF121212),
    onSurface: Colors.white,
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: _lightColorScheme,

      // AppBar tema - Material Design 3
      appBarTheme: AppBarTheme(
        backgroundColor: _lightColorScheme.primary,
        foregroundColor: _lightColorScheme.onPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: _lightColorScheme.onPrimary,
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
        ),
        iconTheme: IconThemeData(
          color: _lightColorScheme.onPrimary,
          size: 24.w,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(0)),
        ),
      ),

      // Scaffold tema
      scaffoldBackgroundColor: _lightColorScheme.surface,

      // Elevated Button tema - Material Design 3
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _lightColorScheme.primary,
          foregroundColor: _lightColorScheme.onPrimary,
          elevation: 1,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          textStyle: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
          minimumSize: Size(double.infinity, 48.h),
        ),
      ),

      // Filled Button tema - Alternatif primary button
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _lightColorScheme.primary,
          foregroundColor: _lightColorScheme.onPrimary,
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          textStyle: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
          minimumSize: Size(double.infinity, 48.h),
        ),
      ),

      // Outlined Button tema
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _lightColorScheme.primary,
          side: BorderSide(color: _lightColorScheme.primary, width: 1.5.w),
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          textStyle: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
          minimumSize: Size(double.infinity, 48.h),
        ),
      ),

      // Input Decoration tema - Material Design 3
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lightColorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: _lightColorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: _lightColorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: _lightColorScheme.primary, width: 2.w),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: _lightColorScheme.error, width: 2.w),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        labelStyle: TextStyle(
          fontSize: 14.sp,
          color: _lightColorScheme.onSurfaceVariant,
        ),
        hintStyle: TextStyle(
          fontSize: 14.sp,
          color: _lightColorScheme.onSurfaceVariant.withAlpha(179),
        ),
        floatingLabelStyle: TextStyle(
          color: _lightColorScheme.primary,
          fontSize: 14.sp,
        ),
      ),

      // Card tema - Material Design 3
      cardTheme: CardThemeData(
        elevation: 1,
        shadowColor: Colors.transparent,
        surfaceTintColor: _lightColorScheme.surfaceTint,
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // Floating Action Button tema
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _lightColorScheme.primary,
        foregroundColor: _lightColorScheme.onPrimary,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        iconSize: 24.w,
      ),

      // Text tema - Material Design 3 Typography
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 32.sp,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.25,
        ),
        displayMedium: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.w400),
        displaySmall: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.w400),
        headlineLarge: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w600),
        headlineMedium: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
        ),
        titleMedium: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
        titleSmall: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
        bodyLarge: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.15,
        ),
        bodyMedium: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
        ),
        bodySmall: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.4,
        ),
        labelLarge: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
        labelMedium: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        labelSmall: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),

      // Liste öğeleri tema
      listTileTheme: ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        tileColor: _lightColorScheme.surface,
        selectedTileColor: _lightColorScheme.primary.withAlpha(25),
        iconColor: _lightColorScheme.onSurfaceVariant,
        textColor: _lightColorScheme.onSurface,
        minVerticalPadding: 8.h,
      ),

      // Dialog tema
      dialogTheme: DialogThemeData(
        backgroundColor: _lightColorScheme.surface,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        titleTextStyle: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
          color: _lightColorScheme.onSurface,
        ),
        contentTextStyle: TextStyle(
          fontSize: 14.sp,
          color: _lightColorScheme.onSurface,
        ),
      ),

      // Chip tema
      chipTheme: ChipThemeData(
        backgroundColor: _lightColorScheme.outline.withAlpha(51),
        labelStyle: TextStyle(
          color: _lightColorScheme.onSurfaceVariant,
          fontSize: 12.sp,
          fontWeight: FontWeight.w400,
        ),
      ),

      // Bottom Navigation Bar tema
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: _lightColorScheme.surface,
        selectedItemColor: _lightColorScheme.primary,
        unselectedItemColor: _lightColorScheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Tab Bar tema
      tabBarTheme: TabBarThemeData(
        labelColor: _lightColorScheme.onPrimary,
        unselectedLabelColor: _lightColorScheme.onPrimary.withAlpha(179),
        indicatorColor: _lightColorScheme.onPrimary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w400,
        ),
      ),

      // Divider tema
      dividerTheme: DividerThemeData(
        color: _lightColorScheme.outline.withAlpha(51),
        thickness: 1,
        space: 1,
      ),

      // Progress Indicator tema
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: _lightColorScheme.primary,
        linearTrackColor: _lightColorScheme.primary.withAlpha(51),
        circularTrackColor: _lightColorScheme.primary.withAlpha(51),
      ),

      // SnackBar tema
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _lightColorScheme.inverseSurface,
        contentTextStyle: TextStyle(
          color: _lightColorScheme.onInverseSurface,
          fontSize: 14.sp,
        ),
        actionTextColor: _lightColorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        elevation: 3,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: _darkColorScheme,

      appBarTheme: AppBarTheme(
        backgroundColor: _darkColorScheme.surface,
        foregroundColor: _darkColorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: _darkColorScheme.onSurface,
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: _darkColorScheme.onSurface, size: 24.w),
      ),

      scaffoldBackgroundColor: _darkColorScheme.surface,

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _darkColorScheme.primary,
          foregroundColor: _darkColorScheme.onPrimary,
          elevation: 1,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          textStyle: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
          minimumSize: Size(double.infinity, 48.h),
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 1,
        shadowColor: Colors.transparent,
        surfaceTintColor: _darkColorScheme.surfaceTint,
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        color: _darkColorScheme.surface,
      ),
    );
  }

  // Responsive helper methods
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }

  // Padding helpers
  static EdgeInsets get defaultPadding => EdgeInsets.all(16.w);
  static EdgeInsets get smallPadding => EdgeInsets.all(8.w);
  static EdgeInsets get largePadding => EdgeInsets.all(24.w);

  // Responsive padding
  static EdgeInsets responsivePadding(BuildContext context) {
    if (isMobile(context)) return EdgeInsets.all(16.w);
    if (isTablet(context)) return EdgeInsets.all(24.w);
    return EdgeInsets.all(32.w);
  }

  // Responsive spacing
  static double responsiveSpacing(BuildContext context) {
    if (isMobile(context)) return 16.w;
    if (isTablet(context)) return 24.w;
    return 32.w;
  }
}
