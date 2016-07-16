# Changelog

## 0.0.1

- Initial version, created by Stagehand

## 0.1.0

- Create new `Server` object to set static handler and add dynamic handlers.

## 0.1.2

- Fixed Issue #1, can now leave Server constructor's parameters empty.

## 0.1.5

- SSL support, setting the `securityContext` property will automatically `bindSecure()` on `start()`.

## 0.2.1

- Fixed server crash when accept-encoding header is not present on incoming `HttpRequest`.
