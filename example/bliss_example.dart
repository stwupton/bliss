library bliss.example;

import 'dart:async';

import 'package:bliss/bliss.dart';

void main() {
  
  Server server = new Server()
    ..setStaticHandler('web')
    ..addHandler('get', '/api/:example', returnData)
    ..start(); // Run the server to start listening for requests

}

// You can use asynchronous function for the handler task's and it will await 
// for the response.
Future returnData(data) async => data;