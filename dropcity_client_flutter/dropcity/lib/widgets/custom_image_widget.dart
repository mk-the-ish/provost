import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

extension ImageTypeExtension on String {
  ImageType get imageType {
    if (startsWith('http://') || startsWith('https://')) {
      return ImageType.network;
    }
    if (endsWith('.svg')) {
      return ImageType.svg;
    }
    if (startsWith('file://') || startsWith('/') || startsWith(r'C:\')) {
      return ImageType.file;
    }
    return ImageType.png;
  }
}

enum ImageType { svg, png, network, file, unknown }

class CustomImageWidget extends StatelessWidget {
  const CustomImageWidget({
    super.key,
    this.imageUrl,
    this.height,
    this.width,
    this.color,
    this.fit,
    this.alignment,
    this.onTap,
    this.radius,
    this.margin,
    this.border,
    this.placeHolder = 'assets/images/no-image.jpg',
    this.errorWidget,
    this.semanticLabel,
  });

  final String? imageUrl;
  final double? height;
  final double? width;
  final BoxFit? fit;
  final String placeHolder;
  final Color? color;
  final Alignment? alignment;
  final VoidCallback? onTap;
  final BorderRadius? radius;
  final EdgeInsetsGeometry? margin;
  final BoxBorder? border;
  final Widget? errorWidget;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final child = _buildWidget();
    return alignment != null ? Align(alignment: alignment!, child: child) : child;
  }

  Widget _buildWidget() {
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: InkWell(onTap: onTap, child: _buildCircleImage()),
    );
  }

  Widget _buildCircleImage() {
    if (radius == null) {
      return _buildImageWithBorder();
    }
    return ClipRRect(
      borderRadius: radius ?? BorderRadius.zero,
      child: _buildImageWithBorder(),
    );
  }

  Widget _buildImageWithBorder() {
    if (border == null) {
      return _buildImageView();
    }
    return Container(
      decoration: BoxDecoration(border: border, borderRadius: radius),
      child: _buildImageView(),
    );
  }

  Widget _buildImageView() {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return Image.asset(
        placeHolder,
        height: height,
        width: width,
        fit: fit ?? BoxFit.cover,
      );
    }

    switch (imageUrl!.imageType) {
      case ImageType.svg:
        return SizedBox(
          height: height,
          width: width,
          child: SvgPicture.asset(
            imageUrl!,
            height: height,
            width: width,
            fit: fit ?? BoxFit.contain,
            colorFilter: color != null
                ? ColorFilter.mode(color!, BlendMode.srcIn)
                : null,
            semanticsLabel: semanticLabel,
          ),
        );
      case ImageType.file:
        final path = imageUrl!.startsWith('file://')
            ? imageUrl!.replaceFirst('file://', '')
            : imageUrl!;
        return Image.file(
          File(path),
          height: height,
          width: width,
          fit: fit ?? BoxFit.cover,
          color: color,
          semanticLabel: semanticLabel,
        );
      case ImageType.network:
        final widget = CachedNetworkImage(
          height: height,
          width: width,
          fit: fit ?? BoxFit.cover,
          imageUrl: imageUrl!,
          color: color,
          placeholder: (context, _) => SizedBox(
            height: 30,
            width: 30,
            child: LinearProgressIndicator(
              color: Colors.grey.shade200,
              backgroundColor: Colors.grey.shade100,
            ),
          ),
          errorWidget: (context, _, __) =>
              errorWidget ??
              Image.asset(
                placeHolder,
                height: height,
                width: width,
                fit: fit ?? BoxFit.cover,
              ),
        );

        if (semanticLabel == null || semanticLabel!.isEmpty) {
          return widget;
        }

        return Semantics(
          label: semanticLabel,
          image: true,
          child: widget,
        );
      case ImageType.png:
      case ImageType.unknown:
        return Image.asset(
          imageUrl ?? placeHolder,
          height: height,
          width: width,
          fit: fit ?? BoxFit.cover,
          color: color,
          semanticLabel: semanticLabel,
        );
    }
  }
}
