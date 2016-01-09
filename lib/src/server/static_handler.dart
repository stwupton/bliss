part of bliss.server;

class StaticHandler {

  String webDirectory;
  List defaults;
  Map errorResponses;

  StaticHandler(this.webDirectory, {this.defaults, this.errorResponses});

}