import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';
import 'app_config.dart';

class AppConfigNotifier extends Notifier<AppConfig> {
  final AppConfig _initialConfig;

  AppConfigNotifier(this._initialConfig);

  @override
  AppConfig build() {
    return _initialConfig;
  }
}

// Helper function to create an override for the appConfigProvider
Override createAppConfigOverride(AppConfig config) {
  return appConfigProvider.overrideWith(() => AppConfigNotifier(config));
}
