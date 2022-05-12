# port_native_code_ffi

A new Flutter project based on the default start up application.

This project contains code to demonstrate the Foreign Function Interface (FFI) between Dart and native (C/C++) code.

## Main Project files to have a look at
1. windows/runner/CMakeLists.txt
2. lib/ (contains the modules listed below and a Flutter app)
3. libs/include/ (this is copied from the Dart runtime SDK e.g. G:\flutter\bin\cache\dart-sdk)
4. libs/exports.def
5. libs/api.cpp

## 1. Call native code from Dart

## 2. Call backs to Dart code from native code

## 3. Asynchronous call backs to Dart from native code

TODOs: fix bug in the async demo method "StartWork", integrate the call back examples with the Flutter UI.


This codebase was tested with a Windows app, for details about other platforms: https://levelup.gitconnected.com/port-an-existing-c-c-app-to-flutter-with-dart-ffi-8dc401a69fd7

Useful resources:
async callbacks in go https://github.com/mraleph/go_dart_ffi_example/tree/master/dart_api_dl/include and https://github.com/flutter/flutter/issues/63255 and https://gist.github.com/espresso3389/be5674ab4e3154f0b7c43715dcef3d8d
general examples: https://github.com/dart-lang/sdk/tree/master/samples/ffi with the native code here https://github.com/dart-lang/sdk/tree/2.12.0-21.0.dev/runtime/bin/ffi_test (ffi_test_functions.cc and ffi_test_functions_vmspecific.cc)
https://linuxtut.com/en/fb2878de50bcf759a2c8/
