// NB: We need to manually flush stdout after each printf, otherwise nothing will show in the debug console until we close the app.
#ifdef WIN32
   #include <Windows.h>
   #define EXPORT __declspec(dllexport)
#else
   #include <pthread.h>
    // Export C++ functions with C style symbols for use with Dart
   #define EXPORT extern "C" __attribute__((visibility("default"))) __attribute__((used))
#endif

#define EXTERNC extern "C"

#include <cstring>
#include <ctype.h>
#include <stdint.h>
#include <stdio.h>
#include <time.h>

#include "include/dart_api_dl.h" // https://github.com/flutter/flutter/issues/63255

// include folder comes from the dart runtime: https://github.com/dart-lang/sdk/tree/master/runtime/include (local install: G:\flutter\bin\cache\dart-sdk)

// Receives NativePort ID from Flutter code
static Dart_Port_DL dart_port = 0;

EXPORT
void set_dart_port(Dart_Port_DL port)
{
    dart_port = port;
    printf("Port set %lld\n", port);
    fflush(stdout);
}

EXPORT
void InitializeDartApi(void* api) {
   Dart_InitializeApiDL(api);
}

// Sample usage of Dart_PostCObject_DL to post message to Flutter side
void debug_print(const char *message)
{
    if (!dart_port)
        return;
    Dart_CObject msg;
    msg.type = Dart_CObject_kString;
    msg.value.as_string = (char *)message;

    // The function is thread-safe; you can call it anywhere on your C++ code.
    Dart_PostCObject_DL(dart_port, &msg);
}

void SendToPort(int64_t port, int64_t msg) {
   Dart_CObject obj;
   obj.type = Dart_CObject_kInt64;
   obj.value.as_int64 = (int64_t) msg;

   // The function is thread-safe; you can call it anywhere on your C++ code.
   Dart_PostCObject_DL(port, &obj);
}

DWORD WINAPI work(LPVOID pport) {
   // We can't dereference a void pointer
   int64_t *port = (int64_t *) pport;
   // int64_t port = *((int64_t *) pport);

   printf("Thread port set %lld\n", *port);
   fflush(stdout);

	int64_t counter = 0;
	while(1)
   {
		Sleep(10000);
		counter++; 
      printf("CPP: 10 seconds passed. Sending (%lld | %lld, %lld)\n", *port, dart_port, counter);
      debug_print("CPP debug print");
      SendToPort(*port, counter);
	}
}

EXPORT
unsigned long StartWork(int64_t port) {
	printf("CPP: Starting some asynchronous work. Got port %lld\n", port); // Bug here, port is passed on the stack and hwen this function returns, it becomes invalid.
   fflush(stdout);
   setbuf(stdout, NULL); // setvbuf(stdout, NULL, _IONBF, 0);

   // Start new thread or coroutine
   unsigned long threadId = 0;
   #ifdef WIN32
   HANDLE hThread = CreateThread(NULL, 0, &work, &port, 0, &threadId); // Security decriptor THREAD_TERMINATE on by default?
   //WaitForSingleObject(hThread, INFINITE);
   #else
   // NB: change the function prototype to be less Windowsy
   pthread_create(&threadId, NULL, &work, (void *) &port);
   #endif
	printf("CPP: Returning to Dart\n");

   return threadId;
}


// This function makes a call from native code to dart/flutter.
EXTERNC int32_t dart_callback(int32_t i, int32_t (*callback)(void*, int32_t)) 
{
   printf("In dart_callback native: %d\n", i);
   fflush(stdout); 
   i += 1;
   return callback(nullptr, i);
}


EXPORT
int add(int a, int b) {
   printf("adding %d and %d\n", a, b);
   //fprintf(stderr, "Printed immediately. No buffering.\n");
   fflush(stdout); // Will now print everything in the stdout buffer
   //Sleep(5000); // Try uncommeting this sleep to show the blocking problem.
   return a + b;
}


EXPORT
char* capitalize1(char *str, size_t n) {
   *str = (char) toupper(*str);
   return str;
}


EXPORT
char* capitalize2(char *str, size_t n) {
   static char buffer[1024]; // NB: this var must be static or global (variable lifetime)
   strcpy_s(buffer, 1024, str);
   buffer[0] = toupper(buffer[0]);
   //Sleep(5000); // Try uncommeting this sleep to show the blocking problem.
   return buffer;
}
