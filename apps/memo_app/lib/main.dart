import 'package:flutter/material.dart';
import 'package:memo/core/startup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(await buildRootWidget());
}
