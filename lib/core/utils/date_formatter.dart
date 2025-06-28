import 'package:intl/intl.dart';

/// Context7 optimized date formatting utility
/// Provides consistent date formatting across the application
class DateFormatter {
  // Private constructor to prevent instantiation
  DateFormatter._();

  // Turkish locale for consistent formatting
  static const String _locale = 'tr_TR';
  
  // Standard date formats
  static final DateFormat _displayFormat = DateFormat('dd.MM.yyyy HH:mm', _locale);
  static final DateFormat _displayDateOnly = DateFormat('dd.MM.yyyy', _locale);
  static final DateFormat _displayTimeOnly = DateFormat('HH:mm', _locale);
  static final DateFormat _databaseFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
  static final DateFormat _shortFormat = DateFormat('dd.MM', _locale);
  static final DateFormat _monthYearFormat = DateFormat('MM.yyyy', _locale);
  static final DateFormat _dayMonthFormat = DateFormat('dd MMM', _locale);
  
  /// Format date for database storage (ISO format)
  /// Returns: 2024-01-15 14:30:00
  static String formatForDatabase(DateTime date) {
    return _databaseFormat.format(date);
  }
  
  /// Format date for user display (Turkish format)
  /// Returns: 15.01.2024 14:30
  static String formatDisplayDate(String databaseDate) {
    try {
      final date = DateTime.parse(databaseDate);
      return _displayFormat.format(date);
    } catch (e) {
      // Fallback for invalid dates
      return 'Geçersiz tarih';
    }
  }
  
  /// Format date for user display from DateTime
  /// Returns: 15.01.2024 14:30
  static String formatDisplayDateTime(DateTime date) {
    return _displayFormat.format(date);
  }
  
  /// Format date only (no time)
  /// Returns: 15.01.2024
  static String formatDateOnly(String databaseDate) {
    try {
      final date = DateTime.parse(databaseDate);
      return _displayDateOnly.format(date);
    } catch (e) {
      return 'Geçersiz tarih';
    }
  }
  
  /// Format date only from DateTime
  /// Returns: 15.01.2024
  static String formatDateOnlyFromDateTime(DateTime date) {
    return _displayDateOnly.format(date);
  }
  
  /// Format time only
  /// Returns: 14:30
  static String formatTimeOnly(String databaseDate) {
    try {
      final date = DateTime.parse(databaseDate);
      return _displayTimeOnly.format(date);
    } catch (e) {
      return 'Geçersiz saat';
    }
  }
  
  /// Format time only from DateTime
  /// Returns: 14:30
  static String formatTimeOnlyFromDateTime(DateTime date) {
    return _displayTimeOnly.format(date);
  }
  
  /// Format short date (day.month)
  /// Returns: 15.01
  static String formatShortDate(String databaseDate) {
    try {
      final date = DateTime.parse(databaseDate);
      return _shortFormat.format(date);
    } catch (e) {
      return 'Geçersiz';
    }
  }
  
  /// Format month and year
  /// Returns: 01.2024
  static String formatMonthYear(String databaseDate) {
    try {
      final date = DateTime.parse(databaseDate);
      return _monthYearFormat.format(date);
    } catch (e) {
      return 'Geçersiz';
    }
  }
  
  /// Format day and month with text
  /// Returns: 15 Oca
  static String formatDayMonth(String databaseDate) {
    try {
      final date = DateTime.parse(databaseDate);
      return _dayMonthFormat.format(date);
    } catch (e) {
      return 'Geçersiz';
    }
  }
  
  /// Get current date formatted for display
  /// Returns: 15.01.2024 14:30
  static String now() {
    return _displayFormat.format(DateTime.now());
  }
  
  /// Get current date formatted for database
  /// Returns: 2024-01-15 14:30:00
  static String nowForDatabase() {
    return _databaseFormat.format(DateTime.now());
  }
  
  /// Get today's date only
  /// Returns: 15.01.2024
  static String today() {
    return _displayDateOnly.format(DateTime.now());
  }
  
  /// Check if date is today
  static bool isToday(String databaseDate) {
    try {
      final date = DateTime.parse(databaseDate);
      final now = DateTime.now();
      return date.year == now.year && 
             date.month == now.month && 
             date.day == now.day;
    } catch (e) {
      return false;
    }
  }
  
  /// Check if date is this week
  static bool isThisWeek(String databaseDate) {
    try {
      final date = DateTime.parse(databaseDate);
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(Duration(days: 6));
      
      return date.isAfter(startOfWeek.subtract(Duration(days: 1))) &&
             date.isBefore(endOfWeek.add(Duration(days: 1)));
    } catch (e) {
      return false;
    }
  }
  
  /// Check if date is this month
  static bool isThisMonth(String databaseDate) {
    try {
      final date = DateTime.parse(databaseDate);
      final now = DateTime.now();
      return date.year == now.year && date.month == now.month;
    } catch (e) {
      return false;
    }
  }
  
  /// Get relative time description
  /// Returns: "Bugün", "Dün", "2 gün önce", etc.
  static String getRelativeTime(String databaseDate) {
    try {
      final date = DateTime.parse(databaseDate);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          if (difference.inMinutes == 0) {
            return 'Şimdi';
          }
          return '${difference.inMinutes} dakika önce';
        }
        return '${difference.inHours} saat önce';
      } else if (difference.inDays == 1) {
        return 'Dün';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} gün önce';
      } else if (difference.inDays < 30) {
        final weeks = (difference.inDays / 7).floor();
        return '$weeks hafta önce';
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).floor();
        return '$months ay önce';
      } else {
        final years = (difference.inDays / 365).floor();
        return '$years yıl önce';
      }
    } catch (e) {
      return 'Bilinmeyen';
    }
  }
  
  /// Parse display date back to DateTime
  static DateTime? parseDisplayDate(String displayDate) {
    try {
      return _displayFormat.parse(displayDate);
    } catch (e) {
      return null;
    }
  }
  
  /// Parse database date to DateTime
  static DateTime? parseDatabaseDate(String databaseDate) {
    try {
      return DateTime.parse(databaseDate);
    } catch (e) {
      return null;
    }
  }
  
  /// Format date range
  /// Returns: "15.01.2024 - 20.01.2024"
  static String formatDateRange(String startDate, String endDate) {
    try {
      final start = DateTime.parse(startDate);
      final end = DateTime.parse(endDate);
      
      if (start.year == end.year && start.month == end.month && start.day == end.day) {
        // Same day
        return formatDateOnlyFromDateTime(start);
      } else if (start.year == end.year && start.month == end.month) {
        // Same month
        return '${start.day}-${end.day}.${end.month}.${end.year}';
      } else {
        // Different months/years
        return '${formatDateOnlyFromDateTime(start)} - ${formatDateOnlyFromDateTime(end)}';
      }
    } catch (e) {
      return 'Geçersiz tarih aralığı';
    }
  }
  
  /// Get start of day
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
  
  /// Get end of day
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }
  
  /// Get start of week (Monday)
  static DateTime startOfWeek(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return startOfDay(date.subtract(Duration(days: daysFromMonday)));
  }
  
  /// Get end of week (Sunday)
  static DateTime endOfWeek(DateTime date) {
    final daysToSunday = 7 - date.weekday;
    return endOfDay(date.add(Duration(days: daysToSunday)));
  }
  
  /// Get start of month
  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }
  
  /// Get end of month
  static DateTime endOfMonth(DateTime date) {
    final nextMonth = date.month == 12 
        ? DateTime(date.year + 1, 1, 1)
        : DateTime(date.year, date.month + 1, 1);
    return nextMonth.subtract(Duration(days: 1));
  }
}
