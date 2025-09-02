import 'dart:convert';
import 'package:flutter/material.dart';

class Base64ImageWidget extends StatelessWidget {
  final String base64String;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;

  const Base64ImageWidget({
    super.key,
    required this.base64String,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    if (base64String.isEmpty) {
      return _buildErrorWidget();
    }

    try {
      // Extract Base64 data
      final parts = base64String.split(',');
      if (parts.length != 2) {
        return _buildErrorWidget();
      }

      final base64Data = parts[1];
      final bytes = base64Decode(base64Data);

      Widget image = Image.memory(
        bytes,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorWidget();
        },
      );

      // Apply border radius if specified
      if (borderRadius != null) {
        image = ClipRRect(borderRadius: borderRadius!, child: image);
      }

      return image;
    } catch (e) {
      return _buildErrorWidget();
    }
  }

  Widget _buildErrorWidget() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: borderRadius,
      ),
      child:
          errorWidget ??
          const Center(
            child: Icon(Icons.broken_image, color: Colors.grey, size: 40),
          ),
    );
  }
}

class Base64ImageWithPlaceholder extends StatelessWidget {
  final String base64String;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;

  const Base64ImageWithPlaceholder({
    super.key,
    required this.base64String,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    required this.placeholder,
    this.errorWidget,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    if (base64String.isEmpty) {
      return _buildContainer(placeholder);
    }

    try {
      final parts = base64String.split(',');
      if (parts.length != 2) {
        return _buildContainer(errorWidget ?? placeholder);
      }

      final base64Data = parts[1];
      final bytes = base64Decode(base64Data);

      Widget image = Image.memory(
        bytes,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return _buildContainer(errorWidget ?? placeholder);
        },
      );

      if (borderRadius != null) {
        image = ClipRRect(borderRadius: borderRadius!, child: image);
      }

      return image;
    } catch (e) {
      return _buildContainer(errorWidget ?? placeholder);
    }
  }

  Widget _buildContainer(Widget child) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: borderRadius,
      ),
      child: child,
    );
  }
}
