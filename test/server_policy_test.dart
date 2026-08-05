import 'package:avatar_genome/avatar_genome_server.dart';
import 'package:test/test.dart';

void main() {
  test('remote binding requires an explicit opt-in', () {
    expect(
      () => ServerConfig.fromArguments(<String>['--host', '0.0.0.0']),
      throwsArgumentError,
    );
    expect(
      ServerConfig.fromArguments(
        <String>['--host', '0.0.0.0', '--allow-remote'],
      ).allowRemote,
      isTrue,
    );
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

  test('origin policy owns an immutable allowlist', () {
    final configured = <String>{'https://editor.example'};
    final policy = OriginPolicy(allowedOrigins: configured);
    configured.clear();

    expect(policy.allowedOrigins, contains('https://editor.example'));
    expect(
      () => policy.allowedOrigins.add('https://other.example'),
      throwsUnsupportedError,
    );
  });

  test('batch policy limits count and rgba memory', () {
    const policy = BatchResourcePolicy(
      maxAvatarCount: 4,
      maxSheetBytes: 1024,
      maxWorkers: 2,
    );
    expect(
      policy.plan(
        columns: 2,
        rows: 2,
        tileSize: 8,
        availableProcessors: 8,
      ).workerCount,
      2,
    );
    expect(
      () => policy.plan(
        columns: 3,
        rows: 2,
        tileSize: 8,
        availableProcessors: 8,
      ),
      throwsArgumentError,
    );
  });
}
