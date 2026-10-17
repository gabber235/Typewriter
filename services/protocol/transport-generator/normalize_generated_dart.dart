import 'dart:io';

Future<void> main(List<String> paths) async {
  for (final path in paths) {
    final type = await FileSystemEntity.type(path);
    if (type == FileSystemEntityType.directory) {
      await for (final entry in Directory(path).list(recursive: true)) {
        if (entry is File && entry.path.endsWith('.dart')) {
          await entry.normalizeGeneratedStyle();
        }
      }
    } else if (type == FileSystemEntityType.file) {
      await File(path).normalizeGeneratedStyle();
    } else {
      throw FileSystemException('Generated source is absent', path);
    }
  }
}

extension GeneratedDartStyle on File {
  Future<void> normalizeGeneratedStyle() async {
    final source = await readAsString();
    final normalized = source
        .replaceAll(
          '// GENERATED CODE - DO NOT MODIFY BY HAND',
          '// GENERATED CODE. DO NOT MODIFY BY HAND',
        )
        .replaceAllMapped(
          RegExp(r'^\s*///.*$', multiLine: true),
          (match) => match[0]!
              .replaceAll('non-null', 'non null')
              .replaceAll('no-op', 'no operation')
              .replaceAll('as-is', 'as is')
              .replaceAll('A `switch`-like method', 'A method similar to a `switch`')
              .replaceAll(
                'pattern-matching-related',
                'pattern matching related',
              ),
        )
        .replaceAll(RegExp(r'^// -+\r?\n', multiLine: true), '')
        .replaceAll(RegExp(r'[^\S\r\n]+$', multiLine: true), '');
    if (normalized != source) await writeAsString(normalized);
  }
}
