# Bliss

An easy to learn server side framework for Dart.

## Purpose

The purpose of this package is to be used internally at Indecks, but to also be extendable enough to be used in other projects. It can be used for serving static files and/or handling dynamic requests.

## Usage

A simple use case example:

```dart
import 'package:bliss/bliss.dart';

main() {
  new Server()
    ..setStaticHandler('web', defaults: ['index.html'])
    ..addHandler('GET', '/api/user/:id', (Map data) {
      Map user = {};
      // query database with `data['id']` and assign it to `user`
      return user;
    })
    ..addHandler('POST', '/api/post', (Map postData, HttpRequest request) async {
      // store `postData` into database
      // add cookie to `request`
    })
    ..start();
}
```

## Planned Features
- [x] SSL support
- [ ] Define specific codec for request payloads
- [ ] WebSocket handlers

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/stwupton/bliss/issues

## Contribute

Feel free to fork and make a pull request. Please stick to the [Dart Style Guide][styleguide]

[styleguide]: https://www.dartlang.org/effective-dart/style/
