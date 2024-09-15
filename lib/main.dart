

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import './MainPage.dart';
import 'class/location.dart';


void main() => runApp(ProviderScope(child: new ExampleApplication()));

class ExampleApplication extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue)
      ),
      debugShowCheckedModeBanner: false,
      home: MainPage()
    );
  }
}
