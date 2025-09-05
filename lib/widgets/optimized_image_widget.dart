import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'shimmer_widget.dart';

class OptimizedImageWidget extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Duration fadeInDuration;
  final bool showShimmer;

  const OptimizedImageWidget({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.fadeInDuration = const Duration(milliseconds: 300),
    this.showShimmer = true,
  });

  @override
  State<OptimizedImageWidget> createState() => _OptimizedImageWidgetState();
}

class _OptimizedImageWidgetState extends State<OptimizedImageWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: widget.fadeInDuration,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    // Start the fade-in animation
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Widget _buildShimmerPlaceholder() {
    if (!widget.showShimmer) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: widget.borderRadius,
        ),
        child: const Center(
          child: Icon(Icons.image, color: Colors.grey, size: 48),
        ),
      );
    }

    return ShimmerContainer(
      width: widget.width,
      height: widget.height,
      borderRadius: widget.borderRadius,
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: widget.borderRadius,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, color: Colors.grey.shade400, size: 32),
          const SizedBox(height: 8),
          Text(
            'Failed to load',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildBase64Image() {
    try {
      // Extract Base64 data - same logic as Base64ImageWidget
      final parts = widget.imageUrl.split(',');
      if (parts.length != 2) {
        debugPrint('OptimizedImageWidget: Invalid Base64 format - parts length: ${parts.length}');
        return _buildErrorWidget();
      }

      final base64Data = parts[1];
      debugPrint('OptimizedImageWidget: Base64 data length: ${base64Data.length}');
      final bytes = base64Decode(base64Data);
      debugPrint('OptimizedImageWidget: Decoded bytes length: ${bytes.length}');
      
      return ClipRRect(
        borderRadius: widget.borderRadius ?? BorderRadius.zero,
        child: Image.memory(
          bytes,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('OptimizedImageWidget: Image.memory error: $error');
            return _buildErrorWidget();
          },
        ),
      );
    } catch (e) {
      debugPrint('OptimizedImageWidget: Base64 decode error: $e');
      return _buildErrorWidget();
    }
  }

  Widget _buildNetworkImage() {
    return ClipRRect(
      borderRadius: widget.borderRadius ?? BorderRadius.zero,
      child: CachedNetworkImage(
        imageUrl: widget.imageUrl,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        placeholder: (context, url) => _buildShimmerPlaceholder(),
        errorWidget: (context, url, error) => _buildErrorWidget(),
        fadeInDuration: widget.fadeInDuration,
        fadeOutDuration: const Duration(milliseconds: 100),
        memCacheWidth: widget.width?.toInt(),
        memCacheHeight: widget.height?.toInt(),
        maxWidthDiskCache: 800,
        maxHeightDiskCache: 800,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    if (widget.imageUrl.isEmpty) {
      debugPrint('OptimizedImageWidget: Empty imageUrl');
      imageWidget = _buildErrorWidget();
    } else if (widget.imageUrl.startsWith('data:image/')) {
      debugPrint('OptimizedImageWidget: Base64 image detected: ${widget.imageUrl.substring(0, 50)}...');
      imageWidget = _buildBase64Image();
    } else {
      debugPrint('OptimizedImageWidget: Network image: ${widget.imageUrl}');
      imageWidget = _buildNetworkImage();
    }

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(opacity: _fadeAnimation.value, child: imageWidget);
      },
    );
  }
}

class OptimizedProductImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const OptimizedProductImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return OptimizedImageWidget(
      imageUrl: imageUrl,
      width: width,
      height: height,
      borderRadius: borderRadius ?? BorderRadius.circular(8),
      fit: BoxFit.cover,
      showShimmer: true,
    );
  }
}

class OptimizedAvatar extends StatelessWidget {
  final String imageUrl;
  final double radius;
  final Widget? placeholder;

  const OptimizedAvatar({
    super.key,
    required this.imageUrl,
    this.radius = 20,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey.shade200,
      child: imageUrl.isEmpty
          ? (placeholder ??
                Icon(Icons.person, size: radius, color: Colors.grey.shade400))
          : ClipOval(
              child: OptimizedImageWidget(
                imageUrl: imageUrl,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                showShimmer: false,
                placeholder: placeholder,
              ),
            ),
    );
  }
}
