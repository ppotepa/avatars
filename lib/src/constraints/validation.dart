enum ValidationStatus { ok, corrected, violation }
enum ValidationSeverity { info, style, soft, hard }

final class ValidationEntry {
  const ValidationEntry({
    required this.id,
    required this.status,
    required this.severity,
    required this.reason,
    this.before,
    this.after,
  });

  final String id;
  final ValidationStatus status;
  final ValidationSeverity severity;
  final String reason;
  final Object? before;
  final Object? after;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'status': status.name,
        'severity': severity.name,
        'reason': reason,
        if (before != null) 'before': before,
        if (after != null) 'after': after,
      };
}

final class ValidationReport {
  ValidationReport(Iterable<ValidationEntry> entries)
      : entries = List<ValidationEntry>.unmodifiable(entries);

  final List<ValidationEntry> entries;

  int get correctionCount =>
      entries.where((entry) => entry.status == ValidationStatus.corrected).length;
  int get hardViolationCount => entries
      .where((entry) =>
          entry.status == ValidationStatus.violation &&
          entry.severity == ValidationSeverity.hard)
      .length;
  int get softViolationCount => entries
      .where((entry) =>
          entry.status == ValidationStatus.violation &&
          entry.severity == ValidationSeverity.soft)
      .length;
  bool get isValid => hardViolationCount == 0;

  Map<String, Object> toJson() => <String, Object>{
        'isValid': isValid,
        'correctionCount': correctionCount,
        'hardViolationCount': hardViolationCount,
        'softViolationCount': softViolationCount,
        'entries': entries.map((entry) => entry.toJson()).toList(),
      };
}

/// Applies geometry normalization independently from diagnostic collection.
final class ConstraintEngine {
  ConstraintEngine({this.enabled = true});

  final bool enabled;
  final List<ValidationEntry> _entries = <ValidationEntry>[];

  List<ValidationEntry> get entries => List.unmodifiable(_entries);

  void record(ValidationEntry entry) {
    if (enabled) _entries.add(entry);
  }

  void recordAll(Iterable<ValidationEntry> entries) {
    if (enabled) _entries.addAll(entries);
  }

  void info(String id, String reason) {
    record(ValidationEntry(
      id: id,
      status: ValidationStatus.ok,
      severity: ValidationSeverity.info,
      reason: reason,
    ));
  }

  void violation(
    String id,
    String reason, {
    ValidationSeverity severity = ValidationSeverity.hard,
  }) {
    record(ValidationEntry(
      id: id,
      status: ValidationStatus.violation,
      severity: severity,
      reason: reason,
    ));
  }

  T correct<T>(
    String id,
    T before,
    T after,
    String reason, {
    ValidationSeverity severity = ValidationSeverity.soft,
  }) {
    if (before != after) {
      record(ValidationEntry(
        id: id,
        status: ValidationStatus.corrected,
        severity: severity,
        reason: reason,
        before: before,
        after: after,
      ));
    }
    return after;
  }

  ValidationReport report() => ValidationReport(_entries);
}
