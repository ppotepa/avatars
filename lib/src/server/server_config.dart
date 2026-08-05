import 'dart:io';

final class ServerConfig {
  const ServerConfig({
    this.host = '127.0.0.1',
    this.port = 8080,
    this.allowRemote = false,
    this.enableSave = false,
    this.allowedOrigins = const <String>{},
    this.saveToken,
  });

  factory ServerConfig.fromArguments(List<String> arguments) {
    String? value(String flag) {
      final index = arguments.indexOf(flag);
      if (index < 0 || index + 1 >= arguments.length) return null;
      return arguments[index + 1];
    }

    final host = value('--host') ?? '127.0.0.1';
    final port = int.tryParse(value('--port') ?? '') ?? 8080;
    final origins = <String>{};
    for (var index = 0; index < arguments.length; index++) {
      if (arguments[index] == '--allow-origin' && index + 1 < arguments.length) {
        origins.add(arguments[index + 1]);
      }
    }
    final config = ServerConfig(
      host: host,
      port: port,
      allowRemote: arguments.contains('--allow-remote'),
      enableSave: arguments.contains('--enable-save'),
      allowedOrigins: Set<String>.unmodifiable(origins),
      saveToken: value('--save-token'),
    );
    config.validate();
    return config;
  }

  final String host;
  final int port;
  final bool allowRemote;
  final bool enableSave;
  final Set<String> allowedOrigins;
  final String? saveToken;

  /// `HttpServer.bind` accepts either an address object or a hostname string.
  Object get address => switch (host) {
        'localhost' => InternetAddress.loopbackIPv4,
        '::1' => InternetAddress.loopbackIPv6,
        _ => host,
      };

  bool get isLoopbackHost => <String>{
        '127.0.0.1',
        '::1',
        'localhost',
      }.contains(host);

  void validate() {
    if (port < 0 || port > 65535) {
      throw ArgumentError.value(port, 'port', 'Must be between 0 and 65535.');
    }
    if (!isLoopbackHost && !allowRemote) {
      throw ArgumentError.value(
        host,
        'host',
        'Remote binding requires --allow-remote.',
      );
    }
    if (enableSave && (saveToken == null || saveToken!.length < 16)) {
      throw ArgumentError(
        'Disk writes require --save-token with at least 16 characters.',
      );
    }
  }

  bool authorizesSave(HttpRequest request) {
    if (!enableSave || saveToken == null) return false;
    return request.headers.value('x-avatar-save-token') == saveToken;
  }
}
