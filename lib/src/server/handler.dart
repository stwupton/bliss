part of bliss.server;

typedef _TaskWithRequest(Map data, HttpRequest request);
typedef _Task(Map data);

class _Handler {

  String method;
  String path;
  Function task;
  Map dataBuilder;
  RegExp queryRE;

  bool get handlesRequest => task is _TaskWithRequest;

  factory _Handler(String method, String path, Function task) {

    if (_isValid(method, path, task)) 
      return new _Handler.internal(method, path, task);
    else 
      throw new Exception("Failed to create handler with method: $method, path: $path.");

  }

  _Handler.internal(this.method, this.path, this.task) {
    setUp();
  }

  //TODO
  execute(HttpRequest request) {

    if (!isMatch(request.method, request.uri.path)) return;

  }

  // Check to see that 
  bool isMatch(String method, String path) {

    if (method.toLowerCase() != this.method) return false;
    if (!queryRE.hasMatch(path)) return false;
    return true;

  }

  // Set helper and data builder variables to be queried when comparing to request
  void setUp() {

    RegExp singlePartRE = new RegExp(r'^\:(\w+)\/?$');
    RegExp multiPartRE = new RegExp(r'^\:(\w+)\{(\d{1,2})\}\/?$');

    StringBuffer REBuilder = new StringBuffer()..write('^\/');

    List<String> splitPath = path.split('/')..removeAt(0);

    for (String segment in splitPath) {
      if (singlePartRE.hasMatch(segment)) {

        Match m = singlePartRE.firstMatch(segment);
        dataBuilder[m.group(1)] = 1;
        REBuilder.write(r'(\w+)\/');

      } else if (multiPartRE.hasMatch(segment)) {

        Match m = multiPartRE.firstMatch(segment);
        dataBuilder[m.group(1)] = m.group(2);

        for (int i = 0; i < int.parse(m.group(2)); i++) {
          REBuilder.write(r'(\w+)\/');
        }

      } else {

        dataBuilder[segment] = 0;
        REBuilder.write('$segment\/');

      }
    }

    REBuilder.write(r'?$');
    queryRE = new RegExp(REBuilder.toString());

  }

  // Check that all information passed is valid
  static bool _isValid(String method, String path, Function task) {

    // Standardize method and path
    method = method.toLowerCase().trim();
    path = path.trim();
    if (!path.startsWith('/')) path = '/$path';
    
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
    RegExp pathRE = new RegExp(r'^((\/){1}|((\/{1}\:?\w+)+|(\/{1}\:\w+(\{[\.\d]\})))+\/?)$');
    if (!pathRE.hasMatch(path)) return false;

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