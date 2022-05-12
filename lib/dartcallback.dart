// This is how to run Dart methods (callback functions) from native code.
// To achieve this we need to call a native code fuction from Dart
// and pass it a pointer to our Dart callback function.

import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'dart:io' show Platform;

////////////////////// Callback Example 1 //////////////////////////////////////
// This is the callback sort/compar argument in qsort:
// int (*compar)(const void *, const void *)
typedef NativeCompar = Int32 Function(Pointer<Int32>, Pointer<Int32>);

// qsort prototype:
// void qsort(void *base, size_t nmemb, size_t size,
//    int (*compar)(const void *, const void *));
typedef NativeQsort = Void Function(
    Pointer<Int32>, Uint64, Uint64, Pointer<NativeFunction<NativeCompar>>);
typedef DartQsort = void Function(
    Pointer<Int32>, int, int, Pointer<NativeFunction<NativeCompar>>);

////////////////////// Callback Example 2 //////////////////////////////////////
// This is the native callback function prototype to cast a Dart pointer to
// a native code pointer
typedef NativeCallback = Int32 Function(Pointer<Void>, Int32);

typedef NativeDartCallback = Int32 Function(
    Int32 bar, Pointer<NativeFunction<NativeCallback>>);

typedef DartCallback = int Function(
    int bar, Pointer<NativeFunction<NativeCallback>>);

// Class to set up the two example callbacks
class DartCallbackDemo {
  // Standard exception value
  static const except = -1;

  // Load Libc to get "qsort" for example 1
  static final libc = Platform.isMacOS || Platform.isIOS
      ? DynamicLibrary.process() // macos and ios
      : (DynamicLibrary.open(Platform.isWindows // windows
          ? 'msvcrt.dll'
          : 'libc.so.6')); // android and linux

  // Load api to get "dart_callback" for example 2
  static final api = Platform.isMacOS || Platform.isIOS
      ? DynamicLibrary.process() // macos and ios
      : (DynamicLibrary.open(Platform.isWindows // windows
          ? 'api.dll'
          : 'libapi.so.')); // android and linux

  // Callback function 1
  static int compar(Pointer<Int32> rhsPtr, Pointer<Int32> lhsPtr) {
    final rhs = rhsPtr.value;
    final lhs = lhsPtr.value;
    if (rhs > lhs) {
      return 1;
    } else if (rhs < lhs) {
      return -1;
    } else {
      return 0;
    }
  }

  // Callback function 2
  static int callback(Pointer<Void> ptr, int i) {
    print('In Dart callback i=$i');
    return i + 1;
  }

  static Pointer<Int32> intListToArray(List<int> list) {
    final ptr = malloc.allocate<Int32>(sizeOf<Int32>() * list.length);
    for (var i = 0; i < list.length; i++) {
      ptr.elementAt(i).value = list[i];
    }
    return ptr;
  }

  static List<int> arrayToIntList(Pointer<Int32> ptr, int n) {
    final lst = List<int>.filled(n, 0);
    for (var i = 0; i < n; i++) {
      lst[i] = ptr.elementAt(i).value;
    }
    return lst;
  }

  // Example 1: demonstrate a call to stdlib's qsort with a callback function
  // to "compar" in the managed Dart code.
  static List<int> qsortDemo(final List<int> data, _compar) {
    //Convert Dart List to C array
    final dataPtr = intListToArray(data);

    // Get the address of the symbol qsort from libc and
    // convert it to the Dart function
    final qsort = libc
        .lookup<NativeFunction<NativeQsort>>('qsort')
        .asFunction<DartQsort>();

    // Convert Dart function compar to C function pointer
    Pointer<NativeFunction<NativeCompar>> comparFuncPointer =
        Pointer.fromFunction(compar, except);
    // _compar to allow diffrent compare funcs to be used, but fromFunction
    // expects a static.

    // Call qsort in that native code,
    // which will then callback to comparFuncPointer
    qsort(dataPtr, data.length, sizeOf<Int32>(), comparFuncPointer);

    //Convert C array to a Dart list
    return arrayToIntList(dataPtr, data.length);
  }

  // Callback 2: Make a call from dart to api.dll (instead of libc/stdlib),
  // then api will make a call to func callback in dart before returning.
  static int callbackDemo(int i) {
    // Get the function pointer to foo in the native code
    DartCallback dart_callback = api
        .lookup<NativeFunction<NativeDartCallback>>('dart_callback')
        .asFunction();

    // This call foo in the native code, but we pass it out callback "callback"
    return dart_callback(
        i, Pointer.fromFunction<NativeCallback>(callback, except));
  }
}
