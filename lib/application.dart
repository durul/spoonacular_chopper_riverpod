import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';
import 'ui/connection_status/no_internet_screen.dart';
import 'ui/main_screen.dart';
import 'ui/theme/theme.dart';
import 'utils/network_info.dart';
import 'utils/logger.dart';

class Application extends ConsumerStatefulWidget {
  const Application({super.key});

  @override
  ConsumerState<Application> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<Application> {
  ThemeMode currentMode = ThemeMode.light;
  late final AppLifecycleListener _lifecycleListener;
  late AppLifecycleState? _currentState;
  bool? _initialConnectionStatus;

  @override
  void initState() {
    super.initState();
    _currentState = SchedulerBinding.instance.lifecycleState;
    _checkInitialConnection();

    _lifecycleListener = AppLifecycleListener(
      onShow: () => _handleState('show'),
      onResume: () => _handleState('resume'),
      onHide: () => _handleState('hide'),
      onInactive: () => _handleState('inactive'),
      onPause: () => _handleState('pause'),
      onDetach: () => _handleState('detach'),
      onRestart: () => _handleState('restart'),
      onStateChange: _handleStateChange,
    );
  }

  Future<void> _checkInitialConnection() async {
    final connectionStatus = ref.read(networkInfoProvider);
    _initialConnectionStatus = await connectionStatus.isConnected();
    setState(() {});
  }

  void _handleState(String state) {
    setState(() {
      logInfo('Current state: $state');
    });
  }

  void _handleStateChange(AppLifecycleState state) {
    setState(() {
      _currentState = state;
      logInfo('State changed to: $state');
    });
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appConfig = ref.watch(appConfigProvider);
    final connectivityStream = ref.watch(connectivityStreamProvider);

    logInfo('Current app lifecycle state: $_currentState');

    return PlatformMenuBar(
      menus: [
        PlatformMenu(label: 'File', menus: [
          PlatformMenuItem(
              label: 'Dark Mode',
              onSelected: () {
                setState(() {
                  currentMode = ThemeMode.dark;
                });
              }),
          PlatformMenuItem(
              label: 'Light Mode',
              onSelected: () {
                setState(() {
                  currentMode = ThemeMode.light;
                });
              }),
          PlatformMenuItem(
            label: 'Quit',
            onSelected: () {
              setState(() {
                SystemNavigator.pop();
              });
            },
            shortcut:
                const SingleActivator(LogicalKeyboardKey.keyQ, meta: true),
          ),
        ])
      ],
      child: MaterialApp(
        title: appConfig.appName,
        debugShowCheckedModeBanner: false,
        themeMode: currentMode,
        theme: ThemeData(useMaterial3: true, colorScheme: lightColorScheme),
        darkTheme: ThemeData(useMaterial3: true, colorScheme: darkColorScheme),
        home: _initialConnectionStatus == null
            ? const CircularProgressIndicator()
            : _initialConnectionStatus!
                ? const MainScreen()
                : connectivityStream.when(
                    data: (isConnected) {
                      return isConnected
                          ? const MainScreen()
                          : const NoInternetScreen();
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (_, __) => const Text('Error checking connection'),
                  ),
      ),
    );
  }
}
