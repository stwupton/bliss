# Changelog

## 0.0.1

- Initial version, created by Stagehand

## 0.1.0

- Create new `Server` object to set static handler and add dynamic handlers.

## 0.1.2

- Fixed Issue #1, can now leave Server constructor's parameters empty.

## 0.1.5

- SSL support, setting the `securityContext` property will automatically `bindSecure()` on `start()`.

## 0.2.0

- The static handler now supports three more optional parameters;
  - **cacheController**: A function to determine the maximum duration for the browser to cache a static resource.
  - **errorResponses**: A map specifying what static resources to repond with when the server responds with a error code.
  - **spaDefault**: Added for the purpose of serving single page applications. If the server cannot find a resource and `spaDefault` is defined, it will respond with the `spaDefault` file instead and let the client handle the routing.

## 0.2.1

- Fixed server crash when accept-encoding header is not present on incoming `HttpRequest`.
