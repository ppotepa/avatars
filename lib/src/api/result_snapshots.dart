import 'dart:typed_data';

import '../constraints/validation.dart';
import '../geometry/avatar_layout.dart';
import '../geometry/avatar_layout_snapshot.dart';
import '../palette/avatar_palette.dart';

AvatarPalette snapshotPalette(AvatarPalette source) => AvatarPalette(
      id: source.id,
      colors: Uint32List.fromList(source.colors),
      roles: Map<String, int>.unmodifiable(source.roles),
    );

ValidationReport snapshotValidation(ValidationReport source) =>
    ValidationReport(List<ValidationEntry>.unmodifiable(source.entries));

AvatarLayout snapshotLayout(AvatarLayout source) => snapshotAvatarLayout(source);
