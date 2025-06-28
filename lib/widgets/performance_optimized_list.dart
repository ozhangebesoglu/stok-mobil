import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Context7 optimized list widget with performance enhancements
/// Features: Lazy loading, RepaintBoundary, const constructors, memory management
class PerformanceOptimizedList<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Widget? emptyWidget;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  final String? errorMessage;
  final bool isLoading;
  final bool hasError;
  final Future<void> Function()? onRefresh;
  final VoidCallback? onLoadMore;
  final bool hasMoreItems;
  final EdgeInsetsGeometry? padding;
  final ScrollController? scrollController;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final Widget? header;
  final Widget? footer;
  final double? itemExtent;
  final bool addRepaintBoundaries;
  final bool addAutomaticKeepAlives;
  final bool addSemanticIndexes;
  final double? cacheExtent;

  const PerformanceOptimizedList({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.emptyWidget,
    this.loadingWidget,
    this.errorWidget,
    this.errorMessage,
    this.isLoading = false,
    this.hasError = false,
    this.onRefresh,
    this.onLoadMore,
    this.hasMoreItems = false,
    this.padding,
    this.scrollController,
    this.shrinkWrap = false,
    this.physics,
    this.header,
    this.footer,
    this.itemExtent,
    this.addRepaintBoundaries = true,
    this.addAutomaticKeepAlives = true,
    this.addSemanticIndexes = true,
    this.cacheExtent,
  });

  @override
  State<PerformanceOptimizedList<T>> createState() =>
      _PerformanceOptimizedListState<T>();
}

class _PerformanceOptimizedListState<T>
    extends State<PerformanceOptimizedList<T>> {
  late ScrollController _scrollController;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();

    // Add scroll listener for pagination
    if (widget.onLoadMore != null) {
      _scrollController.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    // Only dispose if we created the controller
    if (widget.scrollController == null) {
      _scrollController.dispose();
    } else if (widget.onLoadMore != null) {
      _scrollController.removeListener(_onScroll);
    }
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200.h) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !widget.hasMoreItems || widget.onLoadMore == null) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    try {
      widget.onLoadMore!();
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Error state
    if (widget.hasError) {
      return _buildErrorWidget();
    }

    // Loading state (initial load)
    if (widget.isLoading && widget.items.isEmpty) {
      return _buildLoadingWidget();
    }

    // Empty state
    if (widget.items.isEmpty && !widget.isLoading) {
      return _buildEmptyWidget();
    }

    // Main list with refresh capability
    Widget listWidget = _buildOptimizedList();

    if (widget.onRefresh != null) {
      listWidget = RefreshIndicator(
        onRefresh: widget.onRefresh!,
        child: listWidget,
      );
    }

    return listWidget;
  }

  Widget _buildOptimizedList() {
    // Calculate total item count including header, footer, and load more indicator
    int totalItemCount = widget.items.length;

    if (widget.header != null) totalItemCount++;
    if (widget.footer != null || _isLoadingMore) totalItemCount++;

    return ListView.builder(
      controller: _scrollController,
      padding: widget.padding,
      shrinkWrap: widget.shrinkWrap,
      physics: widget.physics ?? const AlwaysScrollableScrollPhysics(),
      itemCount: totalItemCount,
      itemExtent: widget.itemExtent,
      addRepaintBoundaries: widget.addRepaintBoundaries,
      addAutomaticKeepAlives: widget.addAutomaticKeepAlives,
      addSemanticIndexes: widget.addSemanticIndexes,
      cacheExtent: widget.cacheExtent,
      itemBuilder: (context, index) {
        return _buildListItem(context, index);
      },
    );
  }

  Widget _buildListItem(BuildContext context, int index) {
    int adjustedIndex = index;

    // Handle header
    if (widget.header != null) {
      if (index == 0) {
        return RepaintBoundary(child: widget.header!);
      }
      adjustedIndex--;
    }

    // Handle footer or loading more indicator
    if (adjustedIndex >= widget.items.length) {
      if (_isLoadingMore) {
        return _buildLoadMoreIndicator();
      } else if (widget.footer != null) {
        return RepaintBoundary(child: widget.footer!);
      }
      return const SizedBox.shrink();
    }

    // Handle regular items with performance optimizations
    final item = widget.items[adjustedIndex];

    Widget itemWidget = widget.itemBuilder(context, item, adjustedIndex);

    // Wrap with RepaintBoundary for performance
    if (widget.addRepaintBoundaries) {
      itemWidget = RepaintBoundary(child: itemWidget);
    }

    return itemWidget;
  }

  Widget _buildLoadMoreIndicator() {
    return Container(
      padding: EdgeInsets.all(16.w),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20.w,
            height: 20.w,
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12.w),
          Text(
            'Daha fazla yükleniyor...',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    if (widget.loadingWidget != null) {
      return widget.loadingWidget!;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          SizedBox(height: 16.h),
          Text(
            'Yükleniyor...',
            style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    if (widget.errorWidget != null) {
      return widget.errorWidget!;
    }

    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48.w, color: Colors.red),
            SizedBox(height: 16.h),
            Text(
              'Bir hata oluştu',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            if (widget.errorMessage != null) ...[
              SizedBox(height: 8.h),
              Text(
                widget.errorMessage!,
                style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
            if (widget.onRefresh != null) ...[
              SizedBox(height: 16.h),
              ElevatedButton.icon(
                onPressed: widget.onRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Tekrar Dene'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    if (widget.emptyWidget != null) {
      return widget.emptyWidget!;
    }

    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 48.w, color: Colors.grey[400]),
            SizedBox(height: 16.h),
            Text(
              'Henüz veri yok',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Veriler yüklendiğinde burada görünecek',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Optimized card widget with const constructor and RepaintBoundary
class OptimizedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final double? elevation;
  final ShapeBorder? shape;
  final VoidCallback? onTap;
  final bool addRepaintBoundary;

  const OptimizedCard({
    super.key,
    required this.child,
    this.margin,
    this.padding,
    this.color,
    this.elevation,
    this.shape,
    this.onTap,
    this.addRepaintBoundary = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget cardWidget = Card(
      margin: margin,
      color: color,
      elevation: elevation,
      shape: shape,
      child: padding != null ? Padding(padding: padding!, child: child) : child,
    );

    if (onTap != null) {
      cardWidget = InkWell(
        onTap: onTap,
        borderRadius:
            shape is RoundedRectangleBorder
                ? (shape as RoundedRectangleBorder).borderRadius
                    as BorderRadius?
                : BorderRadius.circular(4.r),
        child: cardWidget,
      );
    }

    if (addRepaintBoundary) {
      cardWidget = RepaintBoundary(child: cardWidget);
    }

    return cardWidget;
  }
}

/// Optimized list tile with performance enhancements
class OptimizedListTile extends StatelessWidget {
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isThreeLine;
  final EdgeInsetsGeometry? contentPadding;
  final bool addRepaintBoundary;

  const OptimizedListTile({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.isThreeLine = false,
    this.contentPadding,
    this.addRepaintBoundary = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget tileWidget = ListTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      onTap: onTap,
      isThreeLine: isThreeLine,
      contentPadding: contentPadding,
    );

    if (addRepaintBoundary) {
      tileWidget = RepaintBoundary(child: tileWidget);
    }

    return tileWidget;
  }
}

/// Memory-efficient image widget with caching
class OptimizedImage extends StatelessWidget {
  final String? imageUrl;
  final String? assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool addRepaintBoundary;

  const OptimizedImage({
    super.key,
    this.imageUrl,
    this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.addRepaintBoundary = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    if (assetPath != null) {
      imageWidget = Image.asset(
        assetPath!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ?? _buildDefaultErrorWidget();
        },
      );
    } else if (imageUrl != null) {
      imageWidget = Image.network(
        imageUrl!,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ?? _buildDefaultPlaceholder();
        },
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ?? _buildDefaultErrorWidget();
        },
      );
    } else {
      imageWidget = _buildDefaultErrorWidget();
    }

    if (addRepaintBoundary) {
      imageWidget = RepaintBoundary(child: imageWidget);
    }

    return imageWidget;
  }

  Widget _buildDefaultPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildDefaultErrorWidget() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: Icon(
        Icons.error_outline,
        color: Colors.grey[400],
        size:
            (width != null && height != null)
                ? (width! < height! ? width! * 0.5 : height! * 0.5)
                : 24.w,
      ),
    );
  }
}
