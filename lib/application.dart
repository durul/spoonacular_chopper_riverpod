import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipes/utils/app_config/app_config_notifier.dart';
import 'providers.dart';
import 'ui/main_screen.dart';
import 'ui/theme/theme.dart';
import 'utils/app_config/app_config.dart';

class Application extends ConsumerStatefulWidget {
  const Application({super.key});

  @override
  ConsumerState<Application> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<Application> {
  ThemeMode currentMode = ThemeMode.light;

  MaterialColor? appConfigColor(AppConfig appConfig) {
    switch (appConfig.flavor) {
      case 'integration':
        return Colors.red;
      case 'qa':
        return Colors.green;
      case 'production':
        return Colors.brown;
      case 'staging':
        return Colors.blue;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final appConfig = ref.watch(appConfigProvider);

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
        home: const MainScreen(),
      ),
    );
  }
}
