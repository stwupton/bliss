library bliss.server;

import 'dart:io';

part 'handler.dart';
part 'static_handler.dart';

class Server {

  InternetAddress address = InternetAddress.LOOPBACK_IP_V4;
  int port = 4040;

  StaticHandler _staticHandler;
  bool get _hasStaticHandler => _staticHandler != null;

  List<Handler> _handlers = [];
  bool get _hasHandlers => _handlers.isNotEmpty;

  Server([this.address, this.port]);

  /// Starts the server and responds to requests based off the static file handler (if set) and the dynamic handlers.
  void start() {

    HttpServer.bind(address, port).then((HttpServer server) {
      server.listen((HttpRequest request) {
        _handle(request);
      });
    });

  }

  /// Set static file handler.
  /// 
  /// Define the path to the [webDirectory] that contains all static resources. 
  /// [defaults] are the paths of the default files that you want to respond with if the requested path is a directory.
  /// [errorResponses] are the error codes and the path of the file that should respond to that error code. Example: `{404: "404.html"}`
  void setStaticHandler(String webDirectory, 
      {List<String> defaults, 
      Map<int, String> errorResponses}) {

    _staticHandler = new StaticHandler(webDirectory, 
        defaults: defaults ?? ['index.html'], 
        errorResponses: errorResponses ?? {});

  }

  /// Add dynamic handler to run task and/or respond to requests.
  /// 
  /// The [path] can contain variable parts that can be handled with the [task]. These parts can be declared in one of three ways:
  /// 1. `/:single` results in `{"single": ...}`
  /// 2. `/:nParts{2}` results in `{"nParts": ["...", "..."]}`
  /// 3. `/:unknown{.}` results in `{"unknown": [...]}`
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
  ///           ..addHandler('PUT', '/:trail{.}/end', (Map data) => ...)
  ///           ..addHandler('POST', '/example/:numbered{3}', (_, HttpRequest request) => ...)
  ///           ..addHandler('GET', 'test/:single', (Map data, HttpRequest request) => ...);
  /// 
  ///     }
  void addHandler(String method, String path, Function task) {

    final Handler handler = new Handler(method, path, task);
    if (!_isDuplicate(handler)) _handlers.add(handler);

  }

  // Check request against all handlers to exucute appropriate function.
  // TODO
  void _handle(HttpRequest request) {

    

  }

  bool _isDuplicate(Handler newHandler) {

    for (final Handler handler in _handlers) {

      if (newHandler.method == handler.method &&
          newHandler.path == handler.path)
        return false;

    }

    return true;

  }

}