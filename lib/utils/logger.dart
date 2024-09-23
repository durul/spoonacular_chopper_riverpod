import 'package:flutter/foundation.dart';

Dispatcher logHistory = Dispatcher('');

class Dispatcher extends ValueNotifier<String> {
  Dispatcher(super.value);
}

///
/// Log text value and print to console (iff debug)
///
void logText(String? value) {
  var v = value ?? '';
  logHistory.value = '$v\n${logHistory.value}';
  if (kReleaseMode == false) {
    debugPrint(v);
  }
}

///
/// Log error text
///
void logErrorText(String? value) => logText('[ERROR] ${value ?? ''}');

///
/// Log information text
///
void logInfo(String? value) => logText('[INFO] ${value ?? ''}');