import 'package:flutter/material.dart';

import '../../main.dart' as app;
import '../../providers.dart';
import '../app_config.dart';

/*
  main_integration.dart to provide its AppConfig override to the main app
  without creating a new ProviderScope.
  Instead, it adds the appConfigProvider override to the existing set of
  overrides in main.dart.
*/
void main() async {
  final appConfig = AppConfig(
      appName: 'Int',
      flavor: 'integration',
      apiBaseUrl: 'https://api.spoonacular.com/');

  WidgetsFlutterBinding.ensureInitialized();

  // Call the main function from my main app file with the additional override
  await app.main([], externalOverrides: [
    appConfigProvider.overrideWithValue(appConfig),
  ]);
}
