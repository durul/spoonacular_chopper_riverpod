import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/models/current_recipe_data.dart';
import 'data/repositories/db_repository.dart';
import 'network/service_interface.dart';
import 'ui/main_screen_state.dart';
import 'utils/app_config/app_config.dart';
import 'utils/app_config/app_config_notifier.dart';

final sharedPrefProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

final bottomNavigationProvider =
    StateNotifierProvider<MainScreenStateProvider, MainScreenState>((ref) {
  return MainScreenStateProvider();
});

final serviceProvider = Provider<ServiceInterface>((ref) {
  throw UnimplementedError();
});

// This provider is not meant to be used directly.
// It's here to satisfy Riverpod's requirements.
final appConfigProvider = NotifierProvider<AppConfigNotifier, AppConfig>(() {
  throw UnimplementedError('appConfigProvider must be overridden before use');
});

// It manages asynchronous state.
final repositoryProvider =
    AsyncNotifierProvider<DBRepository, CurrentRecipeData>(DBRepository.new);
