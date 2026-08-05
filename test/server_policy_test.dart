import 'dart:io';

import 'package:avatar_genome/avatar_genome_server.dart';
import 'package:test/test.dart';

void main() {
  test('remote binding requires an explicit opt-in', () {
    expect(
      () => ServerConfig.fromArguments(<String>['--host', '0.0.0.0']),
      throwsArgumentError,
    );
    final address = ServerConfig.fromArguments(
      <String>['--host', '0.0.0.0', '--allow-remote'],
    );
    expect(address.allowRemote, isTrue);
    expect(address.address, isA<InternetAddress>());
  });

  test('remote hostnames remain hostnames for HttpServer.bind', () {
    final config = ServerConfig.fromArguments(<String>[
      '--host',
      'avatar.internal',
      '--allow-remote',
    ]);

    expect(config.address, 'avatar.internal');
  });

  test('disk writes require a strong token', () {
    expect(
      () => ServerConfig.fromArguments(<String>['--enable-save']),
      throwsArgumentError,
    );
    expect(
      ServerConfig.fromArguments(<String>[
        '--enable-save',
        '--save-token',
        '0123456789abcdef',
      ]).enableSave,
      isTrue,
    );
  });

  test('server config and origin policy own immutable allowlists', () {
    final configured = <String>{'https://EDITOR.example/'};
    final config = ServerConfig(allowedOrigins: configured);
    final policy = OriginPolicy(allowedOrigins: configured);
    configured.clear();

    expect(config.allowedOrigins, contains('https://EDITOR.example/'));
    expect(policy.allowedOrigins, contains('https://editor.example'));
    expect(
      () => config.allowedOrigins.add('https://other.example'),
      throwsUnsupportedError,
    );
    expect(
      () => policy.allowedOrigins.add('https://other.example'),
      throwsUnsupportedError,
    );
  });

  test('origin policy rejects non-origin URLs', () {
    for (final value in <String>[
      'ftp://editor.example',
      'https://editor.example/path',
      'https://user@editor.example',
      'not a uri',
    ]) {
      expect(
        () => OriginPolicy(allowedOrigins: <String>{value}),
        throwsArgumentError,
        reason: value,
      );
    }
  });

  test('batch policy limits count, rgba and total working memory', () {
    const policy = BatchResourcePolicy(
      maxAvatarCount: 4,
      maxSheetBytes: 1024,
      maxWorkingBytes: 128 * 1024,
      maxWorkers: 2,
    );
    final plan = policy.plan(
      columns: 2,
      rows: 2,
      tileSize: 8,
      availableProcessors: 8,
    );
    expect(plan.workerCount, 2);
    expect(
      plan.estimatedMetadataBytes,
      4 * BatchResourcePolicy.estimatedDiagnosticsBytesPerAvatar,
    );
    expect(plan.estimatedWorkingBytes, lessThanOrEqualTo(128 * 1024));

    expect(
      () => policy.plan(
        columns: 3,
        rows: 2,
        tileSize: 8,
        availableProcessors: 8,
      ),
      throwsArgumentError,
    );

    const memoryBound = BatchResourcePolicy(
      maxAvatarCount: 4,
      maxSheetBytes: 1024 * 1024,
      maxWorkingBytes: 32 * 1024,
    );
    expect(
      () => memoryBound.plan(
        columns: 2,
        rows: 2,
        tileSize: 8,
        availableProcessors: 1,
      ),
      throwsArgumentError,
    );
  });
}
