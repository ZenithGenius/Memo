import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memo/app.dart';
import 'package:memo/core/bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = await createContainer();
  runApp(
    UncontrolledProviderScope(container: container, child: const MemoApp()),
  );
}
