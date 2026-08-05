import 'dart:io';

import 'package:avatar_genome/avatar_genome_server.dart';
import 'package:test/test.dart';

void main() {
  test('resource policy bounds avatars, memory and workers', () {
    const policy = BatchResourcePolicy(
      maxAvatarCount: 16,
      maxSheetBytes: 16 * 48 * 48 * 4,
      maxWorkers: 4,
    );
    final plan = policy.plan(
      columns: 4,
      rows: 4,
      tileSize: 48,
      availableProcessors: 64,
    );
    expect(plan.avatarCount, 16);
    expect(plan.workerCount, 4);
    expect(
      () => policy.plan(
        columns: 5,
        rows: 4,
        tileSize: 48,
        availableProcessors: 1,
      ),
      throwsArgumentError,
    );
  });

  test('request handler routes all batch artifact endpoints to controller', () {
    final handler =
        File('lib/src/server/server_request_handler.dart').readAsStringSync();
    final controller =
        File('lib/src/server/batch_http_controller.dart').readAsStringSync();
    expect(handler, contains('batches.handles(request)'));
    expect(controller, contains("'/api/export/batch-png'"));
    expect(controller, contains("'/api/export/batch-manifest'"));
    expect(controller, contains("'/api/export/batch-zip'"));
    expect(controller, contains("'X-Avatar-Batch-Id'"));
    expect(controller, contains('includeDiagnostics'));
  });
}
