import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperless_ngx_app/src/app/app.dart';

void main() {
  runApp(const ProviderScope(child: PaperlessNgxApp()));
}
