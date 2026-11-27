import 'package:material_ui/material_ui.dart';
import 'package:memo/core/startup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(await buildRootWidget());
}
