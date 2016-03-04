part of bliss.server;

typedef _TaskWithRequest(Map data, HttpRequest request);
typedef _Task(Map data);

class _Handler {

  String method;
  String path;
  Function task;
  Map dataBuilder = {};
  RegExp pathRE;
  List staticSegments = [];

  bool get handlesRequest => task is _TaskWithRequest;

  factory _Handler(String method, String path, Function task) {

    // Standardize method and path
    method = method.toLowerCase().trim();
    path = path.trim();
    if (!path.startsWith('/')) path = '/$path';

    if (isValid(method, path, task)) 
      return new _Handler.internal(method, path, task);
    else 
      throw new Exception("Failed to create handler with method: $method, path: $path.");

  }

  _Handler.internal(this.method, this.path, this.task) {
    init();
  }

  // Close request with reponse payload (if provided)
  void closeRequest(HttpRequest request, [var response]) {

    if (response is Map || response is List) {
      response = JSON.encode(response);
      request.response.headers.contentType = ContentType.JSON;
    }

    request.response
      ..write(response)
      ..close();

  }

  // Collect the data from path and request payload
  Future<Map> collectData(HttpRequest request) async {

    Map data = {};

    // Get payload
    if (request.method.toLowerCase() != 'get') {
      String dataStr = await UTF8.decodeStream(request);

      try {
        data = JSON.decode(dataStr);
      } catch (_) {
        data['${method}_data'] = dataStr;
      }
    }

    // Get all variable values form path
    int varPartCount = 1;
    Match m = pathRE.firstMatch(request.uri.path);
    for (var key in dataBuilder.keys) {

      if (dataBuilder[key] == 1) data[key] = m.group(varPartCount++);
      else if (dataBuilder[key] > 1) {

        List l = [];
        for (int i = 0; i < dataBuilder[key]; i++) 
          l.add(m.group(varPartCount++));

        data[key] = l;

      }

    }

    return data;

  }

  // Execute task and close request with return value (if provided)
  execute(HttpRequest request) async {

    if (!isMatch(request.method, request.uri.path)) {
      request.response
        ..statusCode = HttpStatus.INTERNAL_SERVER_ERROR
        ..close();
    }

    Map data = await collectData(request);

    // Run task
    var response;
    if (this.handlesRequest) response = task(data, request);
    else response = task(data);

    // Check for Future and wait for it to complete
    if (response is Future) response.then((value) =>
        closeRequest(request, value));
    else closeRequest(request, response);

  }

  // Set helpers to be queried when comparing to request and to build data from path and payload
  void init() {

    RegExp singlePartRE = new RegExp(r'^\:(\w+)\/?$');
    RegExp multiPartRE = new RegExp(r'^\:(\w+)\{(\d{1,2})\}\/?$');

    StringBuffer REBuilder = new StringBuffer()..write(r'^\/');

    List<String> splitPath = path.split('/')..removeAt(0);

    int totalSegments = 0;
    for (String segment in splitPath) {

      totalSegments++;

      if (singlePartRE.hasMatch(segment)) {

        Match m = singlePartRE.firstMatch(segment);
        dataBuilder[m.group(1)] = 1;
        REBuilder.write(r'(\w+)\/');

      } else if (multiPartRE.hasMatch(segment)) {

        Match m = multiPartRE.firstMatch(segment);
        dataBuilder[m.group(1)] = int.parse(m.group(2));

        for (int i = 0; i < int.parse(m.group(2)); i++)
          REBuilder.write(r'(\w+)\/');

      } else {

        REBuilder.write('$segment' + r'\/');
        this.staticSegments.add(totalSegments);

      }

    }

    REBuilder.write(r'?$');
    pathRE = new RegExp(REBuilder.toString());

  }

  // Check handler matches method and path
  bool isMatch(String method, String path) { 

    if (method.toLowerCase() != this.method) return false;
    if (!pathRE.hasMatch(path)) return false;
    return true;

  }

  // Check that all information passed is valid
  static bool isValid(String method, String path, Function task) {
    
    // Check method
    switch (method) {

      case 'get':
      case 'post':
      case 'put':
      case 'delete':
        break;
      default:
        return false;

    }

    // Check that the whole path is valid
    RegExp validPathRE = new RegExp(r'^((\/){1}|((\/{1}\:?\w+)+|(\/{1}\:\w+(\{[\.\d]\})))+\/?)$');
    if (!validPathRE.hasMatch(path)) return false;

    // Check that there is no variable parts named '<method>_data'
    RegExp excludedVarPartRE = new RegExp('\:${method}_data');
    if (excludedVarPartRE.hasMatch(path)) return false;

    // Check that there are no duplicate variable parts
    RegExp varPartsRE = new RegExp('\:\w+');
    List<String> varParts = [];
    if (varPartsRE.hasMatch(path)) {

      varPartsRE.allMatches(path)
          .forEach((part) {
            if (varParts.contains(part.group(0))) return false;
            else varParts.add(part.group(0));
          });

    }

    // Check that task accepts correct parameters
    if (task is! _Task && task is! _TaskWithRequest) return false;
    else return true;

  }

}