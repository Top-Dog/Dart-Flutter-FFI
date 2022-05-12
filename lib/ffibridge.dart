// This how to call native code from Dart (synchronously).

import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'dart:io' show Platform;

typedef addNativeFunc = Int32 Function(Int32, Int32);
typedef addDartFunc = int Function(int, int);

typedef capNativeFunc = Pointer<Utf8> Function(Pointer<Utf8>, Int32);
typedef capDartFunc = Pointer<Utf8> Function(Pointer<Utf8>, int);

// This is the most simple way to run native code from Dart. The methods run
// in the main Dart isolate, so they block. Try adding a delay to one of these
// methods in native code and notice how the UI does not update while the native
// code blocks.
// All native functions in the Widget's build method run synchronously.
class FFIBridge {
  static late DynamicLibrary nativeApiLib;
  static late Function add;
  static late Function _capitalize1;
  static late Function _capitalize2;

  static bool initialize() {
    // Loads our linked library
    nativeApiLib = Platform.isMacOS || Platform.isIOS
        ? DynamicLibrary.process() // macos and ios
        : (DynamicLibrary.open(Platform.isWindows // windows
            ? 'api.dll'
            : 'libapi.so')); // android and linux

    // Not exposed, but there is a platform indepednat way to load libraries:
    //final nativeApiLib =
    //  dlopenPlatformSpecific("libapi", path: Platform.script.resolve("native/out/").path);

    // Lookup our native functions add and map them to Dart functions
    final _add = nativeApiLib.lookup<NativeFunction<addNativeFunc>>('add');
    add = _add.asFunction<addDartFunc>();

    final _cap1 =
        nativeApiLib.lookup<NativeFunction<capNativeFunc>>('capitalize1');
    _capitalize1 = _cap1.asFunction<capDartFunc>();

    final _cap2 =
        nativeApiLib.lookup<NativeFunction<capNativeFunc>>('capitalize2');
    _capitalize2 = _cap2.asFunction<capDartFunc>();

    return true;
  }

  /* We need a wrapper function to convert a Dart String to Pointer<Utf8>
  when passing our string argument to the native function. 
  And also to convert the returned native string Pointer<Utf8>
  back to a Dart String.
  */
  static String capitalize1(String str) {
    final _str = str.toNativeUtf8();
    final _n = _str.length;
    Pointer<Utf8> res = _capitalize1(_str, _n);

    // We need to copy the value of modfied string before freeing the buffer,
    // since res and _str point to the same memory.
    final proccessedString = res.toDartString();
    calloc.free(_str);

    return proccessedString;
  }

  static String capitalize2(String str) {
    final _str = str.toNativeUtf8();
    final _n = _str.length;
    Pointer<Utf8> res = _capitalize2(_str, _n);
    calloc.free(_str);

    // We can use res since res and _str do not point to the same memory.
    // The res buffer is global (static) in the native code.
    return res.toDartString();
  }
}
