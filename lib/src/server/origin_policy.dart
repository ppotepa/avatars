import 'dart:io';

final class OriginPolicy {
  const OriginPolicy({this.allowedOrigins = const <String>{}});

  final Set<String> allowedOrigins;

  bool allows(HttpRequest request) {
    final origin = request.headers.value(HttpHeaders.originHeader);
    if (origin == null || origin.isEmpty) return true;
    final host = request.headers.value(HttpHeaders.hostHeader);
    if (host != null && _sameOrigin(origin, host)) return true;
    return allowedOrigins.contains(origin);
  }

  void apply(HttpResponse response, String? origin) {
    if (origin != null && allowedOrigins.contains(origin)) {
      response.headers
        ..set(HttpHeaders.accessControlAllowOriginHeader, origin)
        ..set(HttpHeaders.varyHeader, HttpHeaders.originHeader)
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

  bool _sameOrigin(String origin, String host) {
    final uri = Uri.tryParse(origin);
    if (uri == null || uri.host.isEmpty) return false;
    final originPort = uri.hasPort
        ? uri.port
        : uri.scheme == 'https'
            ? 443
            : 80;
    final requestHost = host.contains(':') ? host.split(':').first : host;
    final requestPort = host.contains(':')
        ? int.tryParse(host.split(':').last)
        : originPort;
    return uri.host == requestHost && originPort == requestPort;
  }
}
