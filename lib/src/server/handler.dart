part of bliss.server;

typedef TaskWithRequest(Map data, HttpRequest request);
typedef Task(Map data);

class Handler {

  String method;
  String path;
  Function task;

  bool get _handlesRequest => task is TaskWithRequest;

  factory Handler(String method, String path, Function task) {

    if (_isValid(method, path, task)) 
        return new Handler._internal(method, path, task);
    else 
        throw new Exception("Failed to create handler with method: $method, path: $path.");

  }

  Handler._internal(this.method, this.path, this.task);

}

// Check that all information passed is valid
bool _isValid(String method, String path, Function task) {
  
  // Check method
  switch (method.toLowerCase().trim()) {

    case 'get':
    case 'post':
    case 'put':
    case 'delete':
      break;
    default:
      return false;

  }

  // Compare path to regex
  if (path[0] != '/') path = "/$path";
  RegExp pathRegex = new RegExp(r'^((\/){1}|((\/{1}\:?\w+)+|(\/{1}\:\w+(\{[\.\d]\})+))+\/?)$');
  if (!pathRegex.hasMatch(path)) return false;

  // Check that task accepts correct parameters
  if (task is! Task && task is! TaskWithRequest) return false;
  else return true;

}