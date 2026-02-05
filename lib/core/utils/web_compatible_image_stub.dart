import 'package:flutter/material.dart';

class WebCompatibleImage extends StatelessWidget {
  const WebCompatibleImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit,
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit? fit;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
    );
  }
}
