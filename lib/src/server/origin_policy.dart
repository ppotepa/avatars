import 'dart:io';

final class OriginPolicy {
  const OriginPolicy({this.allowedOrigins = const <String>{}});

  final Set<String> allowedOrigins;

  bool allows(HttpRequest request) {
    final origin = request.headers.value('origin');
    if (origin == null || origin.isEmpty) return true;
    final host = request.headers.value(HttpHeaders.hostHeader);
    if (host != null && _sameOrigin(origin, host)) return true;
    return allowedOrigins.contains(origin);
  }

  void apply(HttpResponse response, String? origin) {
    if (origin != null && allowedOrigins.contains(origin)) {
      response.headers
        ..set(HttpHeaders.accessControlAllowOriginHeader, origin)
        ..set(HttpHeaders.varyHeader, 'origin')
        ..set(
          HttpHeaders.accessControlAllowMethodsHeader,
          'GET, POST, OPTIONS',
        )
        ..set(
          HttpHeaders.accessControlAllowHeadersHeader,
          'content-type, x-avatar-save-token',
        );
    }
  }

  bool _sameOrigin(String origin, String authority) {
    final originUri = Uri.tryParse(origin);
    if (originUri == null || originUri.host.isEmpty) return false;
    final requestUri = Uri.tryParse('http://$authority');
    if (requestUri == null || requestUri.host.isEmpty) return false;
    final originPort = originUri.hasPort
        ? originUri.port
        : originUri.scheme == 'https'
            ? 443
            : 80;
    final requestPort = requestUri.hasPort ? requestUri.port : originPort;
    return originUri.host == requestUri.host && originPort == requestPort;
  }
}
