import 'package:flutter/widgets.dart';

import 'app/app.dart';
import 'core/di/injection.dart';
import 'core/session/session_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  await getIt<SessionManager>().restore();
  runApp(const MolBhavApp());
}
