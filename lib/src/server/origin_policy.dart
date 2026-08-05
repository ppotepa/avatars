import 'dart:io';

final class OriginPolicy {
  OriginPolicy({Set<String> allowedOrigins = const <String>{}})
      : allowedOrigins = Set<String>.unmodifiable(
          allowedOrigins.map(_normalizeOrigin),
        );

  final Set<String> allowedOrigins;

  bool allows(HttpRequest request) {
    final rawOrigin = request.headers.value('origin');
    if (rawOrigin == null || rawOrigin.isEmpty) return true;
    final origin = _tryNormalizeOrigin(rawOrigin);
    if (origin == null) return false;
    final authority = request.headers.value(HttpHeaders.hostHeader);
    if (authority != null && _sameHttpOrigin(origin, authority)) return true;
    return allowedOrigins.contains(origin);
  }

  void apply(HttpResponse response, String? rawOrigin) {
    final origin = rawOrigin == null ? null : _tryNormalizeOrigin(rawOrigin);
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

  bool _sameHttpOrigin(String normalizedOrigin, String authority) {
    final origin = Uri.parse(normalizedOrigin);
    if (origin.scheme != 'http') return false;
    final requestUri = Uri.tryParse('http://$authority');
    if (requestUri == null || requestUri.host.isEmpty) return false;
    final requestPort = requestUri.hasPort ? requestUri.port : 80;
    return origin.host.toLowerCase() == requestUri.host.toLowerCase() &&
        origin.port == requestPort;
  }

  static String _normalizeOrigin(String value) {
    final normalized = _tryNormalizeOrigin(value);
    if (normalized == null) {
      throw ArgumentError.value(value, 'allowedOrigins', 'Invalid origin.');
    }
    return normalized;
  }

  static String? _tryNormalizeOrigin(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        uri.host.isEmpty ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.userInfo.isNotEmpty ||
        (uri.path.isNotEmpty && uri.path != '/') ||
        uri.hasQuery ||
        uri.hasFragment) {
      return null;
    }
    return uri.origin;
  }
}
