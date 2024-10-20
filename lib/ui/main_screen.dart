import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../providers.dart';
import '../utils.dart';
import '../utils/network_info.dart';
import 'groceries/groceries.dart';
import 'recipes/recipe_list.dart';
import 'theme/colors.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  List<Widget> pageList = <Widget>[];
  static const String prefSelectedIndexKey = 'selectedIndex';
  bool? _previousConnectionState;

  @override
  void initState() {
    super.initState();
    pageList.add(const RecipeList());
    pageList.add(const GroceryList());
    // wrap getCurrentIndex in Future.microtask
    Future.microtask(() async {
      getCurrentIndex();
    });
  }

  void saveCurrentIndex() async {
    final prefs = ref.read(sharedPrefProvider);
    final bottomNavigation = ref.read(bottomNavigationProvider);
    prefs.setInt(prefSelectedIndexKey, bottomNavigation.selectedIndex);
  }

  void getCurrentIndex() async {
    final prefs = ref.read(sharedPrefProvider);
    if (prefs.containsKey(prefSelectedIndexKey)) {
      final index = prefs.getInt(prefSelectedIndexKey);
      if (index != null) {
        ref.read(bottomNavigationProvider.notifier).updateSelectedIndex(index);
      }
    }
  }

  void _onItemTapped(int index) {
    ref.read(bottomNavigationProvider.notifier).updateSelectedIndex(index);
    saveCurrentIndex();
  }

  @override
  Widget build(BuildContext context) {
    final appConfig = ref.watch(appConfigProvider);
    final connectivityStream = ref.watch(connectivityStreamProvider);

    // This line retrieves a stream from connectivityStreamProvider,
    // which continuously emits connectivity status updates over time.
    connectivityStream.when(
      data: (isConnected) {
        if (_previousConnectionState != null) {
          if (!isConnected) {
            Fluttertoast.showToast(
              msg: 'No internet connection',
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.TOP,
              backgroundColor: Colors.red,
              textColor: Colors.white,
              fontSize: 16.0,
            );
          } else if (!_previousConnectionState! && isConnected) {
            // Show toast only when connection is restored
            Fluttertoast.showToast(
              msg: 'Back online',
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.TOP,
              backgroundColor: Colors.green,
              textColor: Colors.white,
              fontSize: 16.0,
            );
          }
        }
        _previousConnectionState = isConnected;
      },
      loading: () {},
      error: (error, stack) {
        Fluttertoast.showToast(
          msg: 'Error checking connection',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      },
    );

    if (isDesktop() || isWeb()) {
      return largeLayout();
    } else {
      return mobileLayout(appConfig.appName);
    }
  }

  Widget largeLayout() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final selectedColor =
        isDarkMode ? darkBackgroundColor : smallCardBackgroundColor;
    return AdaptiveLayout(
      primaryNavigation: SlotLayout(
        config: <Breakpoint, SlotLayoutConfig>{
          Breakpoints.mediumAndUp: SlotLayout.from(
            key: const Key('PrimaryNavigation'),
            builder: (_) {
              return Container(
                decoration: BoxDecoration(color: selectedColor),
                child: AdaptiveScaffold.standardNavigationRail(
                  destinations: getRailNavigations(),
                  onDestinationSelected: (int index) {
                    _onItemTapped(index);
                  },
                  labelType: NavigationRailLabelType.all,
                  selectedIndex:
                      ref.watch(bottomNavigationProvider).selectedIndex,
                  backgroundColor: selectedColor,
                  selectedIconTheme: IconTheme.of(context)
                      .copyWith(color: iconBackgroundColor),
                  unselectedIconTheme:
                      IconTheme.of(context).copyWith(color: Colors.black),
                ),
              );
            },
          )
        },
      ),
      body: SlotLayout(
        config: <Breakpoint, SlotLayoutConfig?>{
          Breakpoints.standard: SlotLayout.from(
            key: const Key('body'),
            builder: (_) {
              return Container(
                color: Colors.white,
                child: IndexedStack(
                  index: ref.watch(bottomNavigationProvider).selectedIndex,
                  children: pageList,
                ),
              );
            },
          ),
        },
      ),
      bottomNavigation: SlotLayout(
        config: <Breakpoint, SlotLayoutConfig?>{
          Breakpoints.small: SlotLayout.from(
              key: const Key('bottomNavigation'),
              builder: (_) => createBottomNavigationBar())
        },
      ),
    );
  }

  List<NavigationRailDestination> getRailNavigations() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final selectedColor = isDarkMode ? Colors.white : Colors.black;
    return [
      NavigationRailDestination(
        icon: SvgPicture.asset(
          'assets/images/icon_recipe.svg',
          colorFilter: ColorFilter.mode(
              ref.watch(bottomNavigationProvider).selectedIndex == 0
                  ? selectedColor
                  : Colors.black,
              BlendMode.srcIn),
          semanticsLabel: 'Recipes',
        ),
        label: const Text(
          'Recipes',
          style: TextStyle(fontSize: 10),
        ),
      ),
      NavigationRailDestination(
        icon: SvgPicture.asset(
          'assets/images/shopping_cart.svg',
          colorFilter: ColorFilter.mode(
              ref.watch(bottomNavigationProvider).selectedIndex == 0
                  ? selectedColor
                  : Colors.black,
              BlendMode.srcIn),
          semanticsLabel: 'Groceries',
        ),
        label: const Text(
          'Groceries',
          style: TextStyle(fontSize: 10),
        ),
      ),
    ];
  }

  Widget mobileLayout(String title) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      bottomNavigationBar: createBottomNavigationBar(),
      body: SafeArea(
        child: IndexedStack(
          index: ref.watch(bottomNavigationProvider).selectedIndex,
          children: pageList,
        ),
      ),
    );
  }

  BottomNavigationBar createBottomNavigationBar() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final selectedColor = isDarkMode ? Colors.white : Colors.black;
    final unSelectedItemColor = isDarkMode ? Colors.white : Colors.grey;
    final backgroundColor =
        isDarkMode ? darkBackgroundColor : smallCardBackgroundColor;
    final bottomNavigationIndex =
        ref.watch(bottomNavigationProvider).selectedIndex;
    return BottomNavigationBar(
      backgroundColor: backgroundColor,
      currentIndex: bottomNavigationIndex,
      selectedItemColor: selectedColor,
      unselectedItemColor: Colors.grey,
      items: [
        BottomNavigationBarItem(
          icon: SvgPicture.asset(
            'assets/images/icon_recipe.svg',
            colorFilter: ColorFilter.mode(
                bottomNavigationIndex == 0
                    ? selectedColor
                    : unSelectedItemColor,
                BlendMode.srcIn),
            semanticsLabel: 'Recipes',
          ),
          label: 'Recipes',
        ),
        BottomNavigationBarItem(
          backgroundColor:
              bottomNavigationIndex == 1 ? iconBackgroundColor : Colors.black,
          icon: SvgPicture.asset(
            'assets/images/shopping_cart.svg',
            colorFilter: ColorFilter.mode(
                // selectedColor,
                bottomNavigationIndex == 1
                    ? selectedColor
                    : unSelectedItemColor,
                BlendMode.srcIn),
            semanticsLabel: 'Groceries',
          ),
          label: 'Groceries',
        ),
      ],
      onTap: _onItemTapped,
    );
  }
}
