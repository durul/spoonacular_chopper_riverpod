import 'package:colorize_lumberdash/colorize_lumberdash.dart';
import 'package:desktop_window/desktop_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart' as system_log;
import 'package:lumberdash/lumberdash.dart';
import 'utils/app_config/app_config_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'application.dart';
import 'network/spoonacular_service.dart';
import 'providers.dart';
import 'utils.dart';

Future<void> main(List<String> args,
    {List<Override>? externalOverrides}) async {
  // This initializes the logging package and allows Chopper to log
  // requests and responses.
  _setupLogging();

  // Sets the app to immersive mode, hiding system UI elements.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

  if (isDesktop()) {
    await DesktopWindow.setWindowSize(const Size(600, 600));
    await DesktopWindow.setMinWindowSize(const Size(260, 600));
  }

  if (isMobile()) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  // Get access to the device's shared preferences.
  final sharedPrefs = await SharedPreferences.getInstance();

  // ProviderContainer allows me to read providers outside of the widget tree.
  final container = ProviderContainer(
    overrides: [
      if (externalOverrides != null) ...externalOverrides,
    ],
  );

  final appConfig = container.read(appConfigProvider);
  final service = SpoonacularService.create(appConfig.apiBaseUrl);
  //final service = await MockService.create();

  final overrides = [
    sharedPrefProvider.overrideWithValue(sharedPrefs),
    serviceProvider.overrideWithValue(service),
  ];

  // If externalOverrides were provided, they are added to the overrides list.
  if (externalOverrides != null) {
    overrides.addAll(externalOverrides);
  }

  runApp(ProviderScope(
    overrides: overrides,
    child: const Application(),
  ));
}

void _setupLogging() {
  putLumberdashToWork(withClients: [
    ColorizeLumberdash(),
  ]);
  system_log.Logger.root.level = system_log.Level.ALL;
  system_log.Logger.root.onRecord.listen((rec) {
    debugPrint('${rec.level.name}: ${rec.time}: ${rec.message}');
  });
}
