library bliss.example;

import 'dart:async';

import 'package:bliss/bliss.dart';

void main() {
  
  Server server = new Server('localhost', 4040)

      ..addHandler('gEt', '/card/:id/:name{2}', collate)

      ..start();

}

Future collate(data) async {
  return "${data['name'][0]} ${data['name'][1]}: has id ${data['id']}";
}