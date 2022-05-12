import 'package:flutter/material.dart';
import 'dart:io' show Platform, sleep;
import 'dart:ffi';
import 'dart:isolate';
import 'package:ffi/ffi.dart';

import 'ffibridge.dart';
import 'dartcallback.dart';

// Set a global variable in the native code to store the port number
typedef _SetDartPortType = Void Function(Int64 port);
typedef _SetDartPortFunc = void Function(int port);

// Our native code entry point
typedef StartWorkType = Int64 Function(Int64 port);
typedef StartWorkFunc = int Function(int port);

// Async sleep
Future asyncSleep(int ms) {
  return Future.delayed(Duration(milliseconds: ms));
}

class AsyncCallbackDemo {
  // Load api
  static final lib = Platform.isMacOS || Platform.isIOS
      ? DynamicLibrary.process() // macos and ios
      : (DynamicLibrary.open(Platform.isWindows // windows
          ? 'api.dll'
          : 'libapi.so.')); // android and linux

  static void callback(data) {
    print('Async callback received: "${data}" from api.dll');
  }

  static callbackDemo() async {
    // Dart_InitializeApiDL defined in Dart SDK (dart_api_dl.c)
    final initializeApi = lib.lookupFunction<IntPtr Function(Pointer<Void>),
        int Function(Pointer<Void>)>("InitializeDartApi");
    if (initializeApi(NativeApi.initializeApiDLData) != 0) {
      throw "Failed to initialize Dart API";
    }

    // The set_dart_port function defined on the C++ code above
    final _SetDartPortFunc _setDartPort = lib
        .lookup<NativeFunction<_SetDartPortType>>("set_dart_port")
        .asFunction();

    // The StartWork function which starts work on a new thread or coroutine
    final StartWorkFunc startWork =
        lib.lookup<NativeFunction<StartWorkType>>("StartWork").asFunction();

    // Create a receive port and assign it a callback function
    final interactiveCppRequests = ReceivePort()
      // ..listen((data) {
      //   print('Received: ${data} from api.dll');
      // });
      ..listen(callback);

    final int nativePort = interactiveCppRequests.sendPort.nativePort;

    // Pass the port number of the corresponding SendPort to the native side
    // We can also pass the port number to our native function
    _setDartPort(nativePort);

    // Start the native code, which will callback to Dart. The long running task
    // is started in a new thread/coroutine and will not block the main
    // Dart/Flutter isolate.
    startWork(nativePort);

    // while (true) {
    //   await asyncSleep(1000);
    //   print("Dart: 1 seconds passed");
    // }
  }
}
