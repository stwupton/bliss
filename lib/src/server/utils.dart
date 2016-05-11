part of bliss.server;

typedef Duration CacheController(String filePath);

Map<String, Duration> _cacheDurations = {
  r'^.*\.html$': new Duration(days: 5),
  r'^.*\.css$': new Duration(days: 14),
  r'^.*\.js$': new Duration(days: 5),
  r'^.*$': new Duration(days: 14)
};

/// A default cache controller to use for static handler.
Duration defaultCacheController(String filePath) {

  for (String key in _cacheDurations.keys) {

    String fileName = basename(filePath);
    RegExp re = new RegExp(key);

    if (re.firstMatch(fileName)?.group(0) == fileName)
      return _cacheDurations[key];

  }

  return new Duration(seconds: 0);

}