library bliss.server;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:mime/mime.dart';
import 'package:path/path.dart';

part '_handler.dart';
part '_static_handler.dart';

class Server {

  var address;
  int port;
  _StaticHandler _staticHandler;
  List<_Handler> _handlers = [];

  /// Assign a [SecurityContext] object from the 'dart:io' library. The [start()] method
  /// will use [HttpServer.bindSecure] if [securityContext] has been assigned.
  SecurityContext securityContext;

  bool get _hasStaticHandler => _staticHandler != null;
  bool get _hasHandlers => _handlers.isNotEmpty;
  bool get _hasSecurityContext => securityContext != null;

  Server([var address, this.port]) {
    this.address = address ?? InternetAddress.ANY_IP_V6;
  }

  /// Add dynamic handler to run task and/or respond to requests.
  /// 
  /// The [path] can contain variable parts that can be handled with the [task]. These parts can be declared in one of two ways:
  /// 
  /// 1. `/:single` results in `{"single": ...}`
  /// 2. `/:multipleParts{2}` results in `{"multipleParts": [..., ...]}`
  /// 
  /// The [task] can take either two parameters or just one. The first required parameter is of type [Map] which gives the task access to the variables declared in the [path] and/or the payload of the request. The second optional parameter is the [HttpRequest] that the server received. If the payload of the request is not in JSON format, then it gets passed to the task as a [String] with a key depending on what the method is: `{"<method>_data": "..."}`.
  /// 
  /// **Note**: To avoid clashes, if any of the variable parts in the path are named the same as `<method>_data` it will throw an exception and will not be accepted.
  /// 
  /// Example:
  /// 
  ///     void main() {
  ///       
  ///       Server server = new Server()
  ///           ..addHandler('POST', '/example/:multi{3}', (_, HttpRequest request) => ...)
  ///           ..addHandler('GET', 'test/:single', (Map data, HttpRequest request) => ...);
  /// 
  ///     }
  void addHandler(String method, String path, Function task) {

    final _Handler handler = new _Handler(method, path, task);
    if (!_isDuplicate(handler)) _handlers.add(handler);

  }

  // Check request against all handlers to exucute appropriate function.
  void _handle(HttpRequest request) {

    if (_hasHandlers) {
      
      List<_Handler> matches = 
        _handlers.where((h) => h.isMatch(request.method, request.uri.path));

      if (matches.length == 1) {

        return matches.first.execute(request);

      } else if (matches.length > 1) {

        // Reduce iterable down to most accurate path specification
        _Handler match = matches.reduce((h1, h2) {

          if (h1.staticSegments.length > h2.staticSegments.length) {
            return h1;
          } else if (h1.staticSegments.length < h2.staticSegments.length) {
            return h2;
          } else {
            for (int i = 0; i < h1.staticSegments.length; i++)
              if (h1.staticSegments[i] < h2.staticSegments[i]) return h1;
              else if (h1.staticSegments[i] > h2.staticSegments[i]) return h2;
          }

        });

        return match.execute(request);

      }

    }

    if (_hasStaticHandler) {
      if (_staticHandler.hasResource(request.uri.path) && 
          request.method == 'GET') 
        return _staticHandler.serveResource(request);
    }

    request.response
      ..statusCode = HttpStatus.NOT_FOUND
      ..close();

  }

  // Check that there are no other handler with the same method and path
  bool _isDuplicate(_Handler newHandler) {

    for (final _Handler handler in _handlers) {
      if (newHandler.method == handler.method &&
          newHandler.pathRE == handler.pathRE)
        return true;
    }

    return false;

  }

  /// Set static file handler.
  /// 
  /// Define the path to the [webDirectory] that contains all static resources. 
  /// [defaults] are the paths of the default files that you want to respond with if the requested path is a directory.
  void setStaticHandler(String webDirectory, 
      {List<String> defaults: const ['index.html'],
      CacheController cacheController}) {

    _staticHandler = 
      new _StaticHandler(webDirectory, defaults, cacheController);

  }

  /// Starts the server and responds to requests based off the static file handler (if set) and the dynamic handlers.
  Future start() async {

    this.port ??= this._hasSecurityContext ? 443 : 80;

    HttpServer server;

    if (this._hasSecurityContext)
      server = await HttpServer
          .bindSecure(this.address, this.port, this.securityContext);
    else
      server = await HttpServer.bind(this.address, this.port);

    server.listen((HttpRequest request) {

      // Set server header for response
      request.response.headers.set(
          HttpHeaders.SERVER, 
          'Bliss (Dart v${Platform.version.split(' ')[0]})');

      _handle(request);

    });

  }

}