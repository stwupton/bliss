part of bliss.server;

class _StaticHandler {

  Directory webRoot;
  List defaults;
  CacheController cacheController;

  bool get hasCacheController => cacheController != null;

  factory _StaticHandler(String webRoot, 
      List defaults, 
      [CacheController cacheController]) {

    webRoot = normalize(webRoot);

    if (isValid(webRoot, defaults)) {

      Directory root = new Directory(webRoot);
      return new _StaticHandler.internal(root, defaults, cacheController);

    } else throw new Exception("Could not create static handler.");

  }

  _StaticHandler.internal(this.webRoot, this.defaults, [this.cacheController]);

  // Respond to request with status code
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
        .typeSync(normalize(webRoot.path + path));

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

    if (!hasResource(request.uri.path) || request.method != 'GET') {
      errorRespond(request.response, HttpStatus.INTERNAL_SERVER_ERROR);
      return;
    }

    String path = normalize(webRoot.path + request.uri.path);

    // Find the default file if path points to directory
    if (FileSystemEntity.isDirectorySync(path)) {

      // Permanently redirect the browser so the directory path ends with '/'
      if (!request.uri.path.endsWith('/')) {

        Uri redirectUri = request.uri.replace(path: request.uri.path + '/');

        request.response.redirect(
            redirectUri, 
            status: HttpStatus.MOVED_PERMANENTLY);

        return;
        
      }

      String file = defaults.firstWhere((String f) => 
        FileSystemEntity.isFileSync(
            normalize(webRoot.path + join(request.uri.path, f))), 
            orElse: () => '');

      path = normalize(webRoot.path + join(request.uri.path, file));

    }

    if (FileSystemEntity.isFileSync(path)) {

      File file = new File(path);

      // Get cache control settings for file
      String cacheControlHeader = 'no-cache';
      if (this.hasCacheController) {

        Duration duration = 
          cacheController(relative(file.path, from: webRoot.path));

        if (duration != null && duration.inSeconds > 0)
          cacheControlHeader = 'public, max-age=${duration.inSeconds}';

      }

      request.response.headers
        ..set(HttpHeaders.CACHE_CONTROL, cacheControlHeader)
        ..set(HttpHeaders.DATE, new DateTime.now());

      // Check if resource has been modified since last request
      if (request.headers.ifModifiedSince != null && 
          !file.lastModifiedSync().isAfter(request.headers.ifModifiedSince)) {

        errorRespond(request.response, HttpStatus.NOT_MODIFIED);
        return;

      }

      request.response.headers
        ..set(HttpHeaders.LAST_MODIFIED, file.lastModifiedSync())
        ..set(HttpHeaders.ACCEPT_RANGES, 'bytes')
        ..set(HttpHeaders.CONTENT_LENGTH, file.lengthSync());

      List<int> buffer = [];
      List<int> response = [];

      // Read file and set content type
      file.openRead().listen((data) {

        if (buffer == null) {

          response.addAll(data);

        } else if (buffer.length >= defaultMagicNumbersMaxLength) {

          buffer.addAll(data);

          ContentType contentType = resolveContentType(file.path, buffer);
          if (contentType != null)
            request.response.headers.contentType = contentType;

          response.addAll(buffer);
          buffer = null;

        } else {

          buffer.addAll(data);

        }

      }, onDone: () {

        if (buffer != null && buffer.length != 0) {

          ContentType contentType = resolveContentType(file.path, buffer);
          if (contentType != null)
            request.response.headers.contentType = contentType;

          response.addAll(buffer);

        }

        // Compress if headers accept gzip encoding
        List acceptEncoding = request.headers
          .value(HttpHeaders.ACCEPT_ENCODING)
          .replaceAll(new RegExp(r'\s.'), '')
          .split(',');

        if (acceptEncoding.contains('gzip')) {
          response = GZIP.encode(response);
          request.response.headers
            ..set(HttpHeaders.CONTENT_ENCODING, 'gzip')
            ..set(HttpHeaders.CONTENT_LENGTH, response.length);
        }

        request.response
          ..add(response)
          ..close();

      });

    } else {

      errorRespond(request.response, HttpStatus.NOT_FOUND);

    }

  }

}