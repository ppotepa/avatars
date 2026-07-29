import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final source = File('tool/catalog_v41.json');
  final target = File('lib/src/catalog/generated_catalog_json.dart');
  final decoded = jsonDecode(await source.readAsString());
  final normalized = const JsonEncoder.withIndent('  ').convert(decoded);
  if (normalized.contains("'''")) {
    throw StateError('Catalog contains the Dart raw-string delimiter.');
  }
  await target.writeAsString(
    '// GENERATED FROM tool/catalog_v41.json. Do not edit manually.\n'
    "const String kV41CatalogJson = r'''\n$normalized\n''';\n",
  );
  stdout.writeln('Generated ${target.path}.');
}
