import 'package:flutter/material.dart';

const _wideLayoutLandscapeMinWidth = 800.0;
const _wideLayoutPortraitMinWidth = 1000.0;

bool useWideLayout(BuildContext context) {
  return useWideLayoutForSize(MediaQuery.sizeOf(context));
}

bool useWideLayoutForSize(Size size) {
  final minWidth = size.height >= size.width
      ? _wideLayoutPortraitMinWidth
      : _wideLayoutLandscapeMinWidth;
  return size.width >= minWidth;
}
