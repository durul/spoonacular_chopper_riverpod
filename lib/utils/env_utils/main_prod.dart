import 'package:flutter/material.dart';

import '../../main.dart' as app;
import '../app_config/app_config.dart';
import '../app_config/app_config_notifier.dart';

void main() async {
  final appConfig = AppConfig(
      appName: 'Production',
      flavor: 'production',
      apiBaseUrl: 'https://participant.joinallofus.org/');

  WidgetsFlutterBinding.ensureInitialized();

  // Calls the main function from the main app file (main.dart),
  // passing an external override for the appConfigProvider.
  await app.main([], externalOverrides: [
    createAppConfigOverride(appConfig),
  ]);
}
