part of bliss.server;

class _StaticHandler {

  Directory webRoot;
  List defaults;

  factory _StaticHandler(String webRoot, List defaults) {

    if (isValid(webRoot, defaults)) {

      Directory _root = new Directory(webRoot);
      return new _StaticHandler.internal(_root, defaults);
      
    } else throw new Exception("Could not create static handler.");

  }

  _StaticHandler.internal(this.webRoot, this.defaults);

  // Rspond to request with status code
  void errorRespond(HttpResponse response, int status) {

    response
      ..statusCode = status
      ..close();

  }

  ContentType resolveContentType(String path, List<int> bytes) {

    String mimeType = lookupMimeType(path, headerBytes: bytes);
    return mimeType != null ? ContentType.parse(mimeType) : null;

  }

  // Check that static resource exists
  bool hasResource(String path) {

    FileSystemEntityType type = FileSystemEntity
        .typeSync(webRoot.path + path);

    if (type == FileSystemEntityType.FILE || 
        type == FileSystemEntityType.DIRECTORY)
      return true;
    else return false;

  }

  // Check that root and default file passed are valid
  static bool isValid(String root, List defaults) {

    // Check that root exists
    if (!FileSystemEntity.isDirectorySync(root)) return false;

    // Make sure there are no duplicate files in defaults
    List l = [];
    for (String file in defaults) {
      if (l.contains(file)) return false;
      else l.add(file);
    }

    return true;

  }

  // Serve request with static resource
  void serveResource(HttpRequest request) {

    if (!hasResource(request.uri.path) || request.method != 'GET')
      return errorRespond(request.response, HttpStatus.INTERNAL_SERVER_ERROR);

    String path = webRoot.path + request.uri.path;

    if (FileSystemEntity.isDirectorySync(path)) {
      path += defaults.firstWhere((String file) => 
          FileSystemEntity.isFileSync(path + file), orElse: () => '');
    }

    if (FileSystemEntity.isFileSync(path)) {

      File file = new File(path);

      request.response.headers.set(HttpHeaders.ACCEPT_RANGES, 'bytes');
      request.response.headers.set(HttpHeaders.CONTENT_LENGTH, file.lengthSync());

      List<int> buffer = [];

      // Read file and set content type
      file.openRead().listen((data) {

        if (buffer == null) {

          request.response.add(data);

        } else if (buffer.length >= defaultMagicNumbersMaxLength) {

          buffer.addAll(data);

          ContentType contentType = resolveContentType(file.path, buffer);
          if (contentType != null)
            request.response.headers.contentType = contentType;

          request.response.add(buffer);
          buffer = null;

        } else {

          buffer.addAll(data);

        }

      }, onDone: () {

        if (buffer != null && buffer.length != 0) {

          ContentType contentType = resolveContentType(file.path, buffer);
          if (contentType != null)
            request.response.headers.contentType = contentType;

          request.response.add(buffer);

        }

        request.response.close();

      });

    }

  }

}