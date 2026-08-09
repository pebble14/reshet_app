import 'runtime_debug_sink_io.dart'
    if (dart.library.ui) 'runtime_debug_sink_flutter.dart'
    as implementation;

bool get runtimeDebugMode => implementation.runtimeDebugMode;

void runtimeDebugPrint(String message) {
  implementation.runtimeDebugPrint(message);
}

void runtimeDebugPrintStack(StackTrace stackTrace) {
  implementation.runtimeDebugPrintStack(stackTrace);
}
