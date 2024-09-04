import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'main_screen_state.freezed.dart';

// it provides the current selected index of the bottom navigation bar.
@freezed
class MainScreenState with _$MainScreenState {
  const factory MainScreenState({
    @Default(0) int selectedIndex,
  }) = _MainScreenState;
}

// It provides the current state of the MainScreen widget.
class MainScreenStateProvider extends StateNotifier<MainScreenState> {
  MainScreenStateProvider() : super(const MainScreenState());

  // It provides to updated the index.
  void updateSelectedIndex(int index) {
    state = MainScreenState(selectedIndex: index);
  }
}
