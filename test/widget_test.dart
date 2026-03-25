import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voice_todo/ui/screens/home_screen.dart';

void main() {
  runApp(const ProviderScope(child: _TestApp()));
}

class _TestApp extends StatelessWidget {
  const _TestApp();
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: HomeScreen());
  }
}

void testWidgets(p0, p1) {}
