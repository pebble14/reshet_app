import 'dart:io';

const bool runtimeDebugMode =
    !bool.fromEnvironment('dart.vm.product') &&
    !bool.fromEnvironment('dart.vm.profile');

void runtimeDebugPrint(String message) {
  stderr.writeln(message);
}

void runtimeDebugPrintStack(StackTrace stackTrace) {
  stderr.writeln(stackTrace);
}
