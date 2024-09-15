import 'package:flutter/material.dart';

import '../../main.dart' as app;
import '../app_config/app_config.dart';
import '../app_config/app_config_notifier.dart';

void main() async {
  final appConfig = AppConfig(
      appName: 'Deployment Staging',
      flavor: 'staging',
      apiBaseUrl: 'https://participant-stg.joinallofus.org/');

  WidgetsFlutterBinding.ensureInitialized();

  // Call the main function from my main app file with the additional override
  await app.main([], externalOverrides: [
    createAppConfigOverride(appConfig),
  ]);
}