import 'dart:convert';
import 'dart:io';

bool get supportsDesktopSettingsFile =>
    Platform.isWindows || Platform.isLinux || Platform.isMacOS;

Future<File?> _desktopFile() async {
  if (!supportsDesktopSettingsFile) return null;
  try {
    late final Directory base;
    if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA'];
      if (appData == null || appData.isEmpty) return null;
      base = Directory('$appData\\EduSelfToanAI');
    } else if (Platform.isMacOS) {
      final home = Platform.environment['HOME'] ?? '';
      base = Directory('$home/Library/Application Support/EduSelfToanAI');
    } else {
      final home = Platform.environment['HOME'] ?? '';
      base = Directory('$home/.local/share/eduself_toan_ai');
    }
    if (!await base.exists()) {
      await base.create(recursive: true);
    }
    return File('${base.path}${Platform.pathSeparator}settings.json');
  } on Object {
    return null;
  }
}

Future<Map<String, String>> readDesktopSettingsFile() async {
  final file = await _desktopFile();
  if (file == null || !await file.exists()) return <String, String>{};
  try {
    final decoded = jsonDecode(await file.readAsString());
    final map = <String, String>{};
    if (decoded is Map) {
      for (final entry in decoded.entries) {
        final value = entry.value;
        if (value is String && value.trim().isNotEmpty) {
          map['${entry.key}'] = value;
        }
      }
    }
    return map;
  } on Object {
    return <String, String>{};
  }
}

Future<void> writeDesktopSettingsFile(Map<String, String> data) async {
  final file = await _desktopFile();
  if (file == null) return;
  await file.writeAsString(jsonEncode(data), flush: true);
}
