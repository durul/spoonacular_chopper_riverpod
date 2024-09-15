import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../main.dart' as app;
import '../../providers.dart';
import '../app_config.dart';

void main() async {
  final appConfig = AppConfig(
      appName: 'Deployment Staging',
      flavor: 'staging',
      apiBaseUrl: 'https://participant-stg.joinallofus.org/');

  WidgetsFlutterBinding.ensureInitialized();

  // Call the main function from my main app file with the additional override
  await app.main([], externalOverrides: [
    appConfigProvider.overrideWithValue(appConfig),
  ]);
}