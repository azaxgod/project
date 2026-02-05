import 'dart:ui_web' as ui;


import 'package:flutter/material.dart';

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class WebCompatibleImage extends StatefulWidget {
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
  State<WebCompatibleImage> createState() => _WebCompatibleImageState();
}

class _WebCompatibleImageState extends State<WebCompatibleImage> {
  late final String _viewType;
  bool _registered = false;

  @override
  void initState() {
    super.initState();
    _viewType = 'web-compatible-img-${widget.url.hashCode}-${DateTime.now().microsecondsSinceEpoch}';
    _register();
  }

  void _register() {
    if (_registered) return;
    _registered = true;

    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final img = html.ImageElement()
        ..src = widget.url
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = _toObjectFit(widget.fit);

      return img;
    });
  }

  String _toObjectFit(BoxFit? fit) {
    switch (fit) {
      case BoxFit.contain:
        return 'contain';
      case BoxFit.cover:
        return 'cover';
      case BoxFit.fill:
        return 'fill';
      case BoxFit.fitHeight:
        return 'contain';
      case BoxFit.fitWidth:
        return 'contain';
      case BoxFit.none:
        return 'none';
      case BoxFit.scaleDown:
        return 'scale-down';
      case null:
        return 'contain';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: HtmlElementView(viewType: _viewType),
    );
  }
}
