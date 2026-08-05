final class BatchResourcePolicy {
  const BatchResourcePolicy({
    this.maxAvatarCount = 1024,
    this.maxSheetBytes = 64 * 1024 * 1024,
    this.maxWorkingBytes = 192 * 1024 * 1024,
    this.maxWorkers = 8,
  });

  final int maxAvatarCount;
  final int maxSheetBytes;
  final int maxWorkingBytes;
  final int maxWorkers;

  BatchPlan plan({
    required int columns,
    required int rows,
    required int tileSize,
    required int availableProcessors,
    bool includeDiagnostics = false,
  }) {
    if (maxAvatarCount < 1 ||
        maxSheetBytes < 1 ||
        maxWorkingBytes < 1 ||
        maxWorkers < 1) {
      throw StateError('Batch resource limits must all be positive.');
    }
    if (columns < 1 || rows < 1 || tileSize < 1) {
      throw ArgumentError('Batch dimensions and tile size must be positive.');
    }
    final count = columns * rows;
    if (count > maxAvatarCount) {
      throw ArgumentError.value(
        count,
        'columns/rows',
        'Batch limit is $maxAvatarCount avatars.',
      );
    }
    final width = columns * tileSize;
    final height = rows * tileSize;
    final rgbaBytes = width * height * 4;
    if (rgbaBytes > maxSheetBytes) {
      throw ArgumentError.value(
        rgbaBytes,
        'sheetBytes',
        'Batch sheet exceeds the $maxSheetBytes byte memory budget.',
      );
    }

    // During assembly the process can hold the final RGBA sheet, all shard
    // outputs and PNG compression buffers at the same time. Diagnostics add a
    // bounded per-avatar estimate for request/genome/validation metadata.
    final metadataBytes = count * (includeDiagnostics ? 16 * 1024 : 512);
    final estimatedWorkingBytes = rgbaBytes * 3 + metadataBytes;
    if (estimatedWorkingBytes > maxWorkingBytes) {
      throw ArgumentError.value(
        estimatedWorkingBytes,
        'workingBytes',
        'Batch exceeds the $maxWorkingBytes byte working-memory budget.',
      );
    }

    final workers = availableProcessors
        .clamp(1, maxWorkers)
        .clamp(1, count)
        .toInt();
    return BatchPlan(
      avatarCount: count,
      sheetWidth: width,
      sheetHeight: height,
      rgbaBytes: rgbaBytes,
      estimatedMetadataBytes: metadataBytes,
      estimatedWorkingBytes: estimatedWorkingBytes,
      workerCount: workers,
    );
  }
}

final class BatchPlan {
  const BatchPlan({
    required this.avatarCount,
    required this.sheetWidth,
    required this.sheetHeight,
    required this.rgbaBytes,
    required this.estimatedMetadataBytes,
    required this.estimatedWorkingBytes,
    required this.workerCount,
  });

  final int avatarCount;
  final int sheetWidth;
  final int sheetHeight;
  final int rgbaBytes;
  final int estimatedMetadataBytes;
  final int estimatedWorkingBytes;
  final int workerCount;

  Map<String, int> toJson() => <String, int>{
        'avatarCount': avatarCount,
        'sheetWidth': sheetWidth,
        'sheetHeight': sheetHeight,
        'rgbaBytes': rgbaBytes,
        'estimatedMetadataBytes': estimatedMetadataBytes,
        'estimatedWorkingBytes': estimatedWorkingBytes,
        'workerCount': workerCount,
      };
}
