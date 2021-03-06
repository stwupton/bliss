library bliss.example;

import 'dart:async';

import 'package:bliss/bliss.dart';

void main() {
  new Server()
    ..setStaticHandler('web', cacheController: defaultCacheController)
    ..addHandler('get', '/api/:example', returnData)

    // Run the server to start listening for requests.
    ..start();
}

// You can use asynchronous function for the handler task's and it will await
// for the response.
Future returnData(data) async => data;
