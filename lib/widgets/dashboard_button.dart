import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/theme/app_theme.dart';

/// Context7 optimized dashboard button with performance enhancements
/// Features: RepaintBoundary, const constructors, memory management
class DashboardButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final String? badge;
  final bool isEnabled;

  const DashboardButton({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    this.badge,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return RepaintBoundary(
      child: Padding(
        padding: AppTheme.defaultPadding,
        child: Material(
          elevation: 2,
          shadowColor: Colors.transparent,
          borderRadius: BorderRadius.circular(16.r),
          child: InkWell(
            onTap: isEnabled ? onTap : null,
            borderRadius: BorderRadius.circular(16.r),
            child: Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.r),
                color:
                    isEnabled
                        ? colorScheme.surface
                        : colorScheme.surface.withAlpha(51),
                border: Border.all(
                  color: colorScheme.outline.withAlpha(25),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: iconColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      icon,
                      color: isEnabled ? iconColor : iconColor.withAlpha(128),
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color:
                                isEnabled
                                    ? colorScheme.onSurface
                                    : colorScheme.onSurface.withAlpha(128),
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color:
                                isEnabled
                                    ? colorScheme.onSurfaceVariant
                                    : colorScheme.onSurfaceVariant.withAlpha(
                                      128,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (badge != null) ...[
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: iconColor,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        badge!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Alternative compact dashboard button for smaller spaces
class CompactDashboardButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final String? badge;
  final bool isEnabled;

  const CompactDashboardButton({
    super.key,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    this.badge,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.all(4.w),
      child: Material(
        elevation: 1,
        shadowColor: Colors.transparent,
        borderRadius: BorderRadius.circular(12.r),
        child: InkWell(
          onTap: isEnabled ? onTap : null,
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color:
                  isEnabled
                      ? colorScheme.surface
                      : colorScheme.surface.withAlpha(128),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: colorScheme.outline.withAlpha(25),
                width: 1.w,
              ),
            ),
            child: Row(
              children: [
                // Icon with badge
                Stack(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: iconColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        icon,
                        size: 20.w,
                        color: isEnabled ? iconColor : iconColor.withAlpha(128),
                      ),
                    ),
                    if (badge?.isNotEmpty ?? false)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          padding: EdgeInsets.all(2.w),
                          decoration: BoxDecoration(
                            color: colorScheme.error,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          constraints: BoxConstraints(
                            minWidth: 16.w,
                            minHeight: 16.h,
                          ),
                          child: Text(
                            badge!,
                            style: TextStyle(
                              color: colorScheme.onError,
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),

                SizedBox(width: 12.w),

                // Title
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color:
                          isEnabled
                              ? colorScheme.onSurface
                              : colorScheme.onSurface.withAlpha(128),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Arrow icon
                Icon(
                  Icons.chevron_right,
                  size: 20.w,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Dashboard action button with progress indicator
class ActionDashboardButton extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Future<void> Function() onTap;
  final bool isEnabled;

  const ActionDashboardButton({
    super.key,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    this.isEnabled = true,
  });

  @override
  State<ActionDashboardButton> createState() => _ActionDashboardButtonState();
}

class _ActionDashboardButtonState extends State<ActionDashboardButton> {
  bool _isLoading = false;

  Future<void> _handleTap() async {
    if (_isLoading || !widget.isEnabled) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.onTap();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.all(8.w),
      child: Material(
        elevation: 2,
        shadowColor: Colors.transparent,
        borderRadius: BorderRadius.circular(16.r),
        child: InkWell(
          onTap: _handleTap,
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(minHeight: 80.h),
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color:
                  widget.isEnabled && !_isLoading
                      ? widget.iconColor.withAlpha(25)
                      : colorScheme.surface.withAlpha(128),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: widget.iconColor.withAlpha(51),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                // Icon or loading indicator
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: widget.iconColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child:
                      _isLoading
                          ? SizedBox(
                            width: 20.w,
                            height: 20.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.w,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                widget.iconColor,
                              ),
                            ),
                          )
                          : Icon(
                            widget.icon,
                            size: 20.w,
                            color:
                                widget.isEnabled
                                    ? widget.iconColor
                                    : widget.iconColor.withAlpha(128),
                          ),
                ),

                SizedBox(width: 16.w),

                // Title
                Expanded(
                  child: Text(
                    widget.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color:
                          widget.isEnabled && !_isLoading
                              ? colorScheme.onSurface
                              : colorScheme.onSurface.withAlpha(128),
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
