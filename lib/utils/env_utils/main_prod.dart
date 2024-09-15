import 'package:flutter/material.dart';

import '../../main.dart' as app;
import '../../providers.dart';
import '../app_config.dart';

void main() async {
  final appConfig = AppConfig(
      appName: 'Production',
      flavor: 'production',
      apiBaseUrl: 'https://participant.joinallofus.org/');

  WidgetsFlutterBinding.ensureInitialized();

  // Calls the main function from the main app file (main.dart),
  // passing an external override for the appConfigProvider.
  await app.main([], externalOverrides: [
    appConfigProvider.overrideWithValue(appConfig),
  ]);
}
