import 'package:flutter/foundation.dart'
    show debugPrint, debugPrintStack, kDebugMode;

const bool runtimeDebugMode = kDebugMode;

void runtimeDebugPrint(String message) {
  debugPrint(message);
}

void runtimeDebugPrintStack(StackTrace stackTrace) {
  debugPrintStack(stackTrace: stackTrace);
}
