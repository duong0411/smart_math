import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:pdfrx/pdfrx.dart';

/// Max characters sent to the model from one attached document.
const kMaxExtractedDocumentChars = 60000;

/// Max PDF pages to extract (keeps latency reasonable).
const kMaxPdfPagesToExtract = 40;

class ExtractedStudyDocument {
  const ExtractedStudyDocument({
    required this.filename,
    required this.text,
    required this.truncated,
  });

  final String filename;
  final String text;
  final bool truncated;
}

/// Extracts plain text from PDF / DOCX / TXT / MD bytes for Gemini prompts.
///
/// Old binary `.doc` is not supported — ask the user to save as `.docx` or PDF.
Future<ExtractedStudyDocument> extractStudyDocumentText({
  required String filename,
  required List<int> bytes,
}) async {
  if (bytes.isEmpty) {
    throw StateError('Tệp trống.');
  }

  final lower = filename.toLowerCase();
  final String raw;
  if (lower.endsWith('.pdf')) {
    raw = await _extractPdf(bytes);
  } else if (lower.endsWith('.docx')) {
    raw = _extractDocx(bytes);
  } else if (lower.endsWith('.doc')) {
    throw StateError(
      'Định dạng .doc (Word cũ) chưa hỗ trợ. Em lưu lại thành .docx hoặc PDF rồi thử lại nhé.',
    );
  } else if (lower.endsWith('.txt') || lower.endsWith('.md')) {
    raw = _decodePlainText(bytes);
  } else {
    throw StateError(
      'Định dạng chưa hỗ trợ để đọc nội dung. Em chọn PDF, Word (.docx) hoặc TXT nhé.',
    );
  }

  final cleaned = _normalizeExtractedText(raw);
  if (cleaned.isEmpty) {
    throw StateError(
      'Không đọc được chữ trong tệp (có thể là PDF scan / ảnh, hoặc Word chỉ có phương trình dạng ảnh). '
      'Em thử xuất PDF có chữ chọn được, lưu Word dạng .docx có công thức Office Math, hoặc chụp ảnh đề bài.',
    );
  }

  final truncated = cleaned.length > kMaxExtractedDocumentChars;
  final text = truncated
      ? '${cleaned.substring(0, kMaxExtractedDocumentChars)}\n\n'
          '[…đã cắt bớt vì tệp quá dài…]'
      : cleaned;

  return ExtractedStudyDocument(
    filename: filename,
    text: text,
    truncated: truncated,
  );
}

Future<String> _extractPdf(List<int> bytes) async {
  // Safe even if main() already initialized — pdfrx no-ops when ready.
  await pdfrxFlutterInitialize();
  final PdfDocument doc;
  try {
    doc = await PdfDocument.openData(Uint8List.fromList(bytes));
  } on Object catch (e) {
    throw StateError(
      'Không mở được PDF. Em thử file khác hoặc xuất lại PDF. ($e)',
    );
  }
  try {
    final pageCount = doc.pages.length;
    if (pageCount == 0) {
      throw StateError('PDF không có trang.');
    }
    final limit =
        pageCount > kMaxPdfPagesToExtract ? kMaxPdfPagesToExtract : pageCount;
    final buf = StringBuffer();
    for (var i = 0; i < limit; i++) {
      final pageText = await _extractPdfPageText(doc.pages[i]);
      if (pageText.isEmpty) continue;
      if (buf.isNotEmpty) buf.writeln();
      buf.writeln('--- Trang ${i + 1} ---');
      buf.writeln(pageText);
    }
    if (pageCount > limit) {
      buf.writeln();
      buf.writeln('[…chỉ lấy $limit / $pageCount trang đầu…]');
    }
    return buf.toString();
  } finally {
    await doc.dispose();
  }
}

/// Prefer structured text (reading-order / line breaks) over raw glyph stream.
Future<String> _extractPdfPageText(PdfPage page) async {
  try {
    final structured = await page.loadStructuredText();
    final text = structured.fullText.trim();
    if (text.isNotEmpty) return _normalizePdfMathText(text);
  } on Object {
    // Fall through to raw extraction.
  }
  try {
    final raw = await page.loadText();
    return _normalizePdfMathText((raw?.fullText ?? '').trim());
  } on Object {
    return '';
  }
}

/// Light cleanup for PDF math worksheets without destroying intentional breaks.
String _normalizePdfMathText(String text) {
  var s = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  // Soft hyphen / end-of-line hyphenation common in PDFs.
  s = s.replaceAll(RegExp(r'-\n(?=\S)'), '');
  // Collapse runs of spaces/tabs but keep newlines.
  s = s.replaceAll(RegExp(r'[ \t]{2,}'), ' ');
  s = s.replaceAll(RegExp(r'[ \t]+\n'), '\n');
  s = s.replaceAll(RegExp(r'\n{3,}'), '\n\n');
  // Common glyph glitches in school PDFs.
  s = s
      .replaceAll('×', '×')
      .replaceAll('−', '−')
      .replaceAll(RegExp(r' [?？]'), '?');
  return s.trim();
}

String _extractDocx(List<int> bytes) {
  Archive archive;
  try {
    archive = ZipDecoder().decodeBytes(bytes);
  } on Object {
    throw StateError('Không mở được tệp Word (.docx). Em kiểm tra lại tệp nhé.');
  }

  final parts = <String>[];

  final main = _findDocxPart(archive, endsWith: 'word/document.xml');
  if (main == null) {
    throw StateError('Tệp Word thiếu nội dung (document.xml).');
  }
  final mainBytes = main.content;
  if (mainBytes.isEmpty) {
    throw StateError('Tệp Word không có nội dung chữ.');
  }
  final mainText = _docxXmlToText(
    utf8.decode(mainBytes, allowMalformed: true),
  );
  if (mainText.isNotEmpty) parts.add(mainText);

  // Headers / footers often hold điểm số, tên bài — useful for AI context.
  for (final file in archive.files) {
    if (!file.isFile) continue;
    final name = file.name.replaceAll('\\', '/').toLowerCase();
    final isHeader = name.contains('word/header') && name.endsWith('.xml');
    final isFooter = name.contains('word/footer') && name.endsWith('.xml');
    if (!isHeader && !isFooter) continue;
    final content = file.content;
    if (content.isEmpty) continue;
    final t = _docxXmlToText(utf8.decode(content, allowMalformed: true));
    if (t.isNotEmpty) parts.add(t);
  }

  final text = parts.join('\n\n').trim();
  if (text.isEmpty) {
    throw StateError(
      'Tệp Word không có nội dung chữ đọc được '
      '(có thể chỉ chứa ảnh hoặc phương trình dạng hình).',
    );
  }
  return text;
}

ArchiveFile? _findDocxPart(Archive archive, {required String endsWith}) {
  final needle = endsWith.toLowerCase().replaceAll('\\', '/');
  for (final file in archive.files) {
    if (!file.isFile) continue;
    final name = file.name.replaceAll('\\', '/').toLowerCase();
    if (name == needle || name.endsWith('/$needle') || name.endsWith(needle)) {
      return file;
    }
  }
  // archive.findFile is exact — try a few common variants.
  for (final candidate in [endsWith, '/$endsWith', endsWith.replaceAll('/', r'\')]) {
    final hit = archive.findFile(candidate);
    if (hit != null) return hit;
  }
  return null;
}

/// Convert WordprocessingML (+ Office Math) into readable plain / LaTeX-ish text.
String _docxXmlToText(String xml) {
  var s = xml;

  // Drop binary / drawing noise early (keep alt text if present later).
  s = s.replaceAll(
    RegExp(r'<w:drawing[\s\S]*?</w:drawing>', caseSensitive: false),
    ' ',
  );
  s = s.replaceAll(
    RegExp(r'<w:pict[\s\S]*?</w:pict>', caseSensitive: false),
    ' ',
  );
  s = s.replaceAll(
    RegExp(r'<w:object[\s\S]*?</w:object>', caseSensitive: false),
    ' ',
  );

  // Convert Office Math (OMML) before stripping tags — otherwise x² becomes "x2".
  s = _convertAllOmml(s);

  // Structural breaks.
  s = s.replaceAll(RegExp(r'</w:p[^>]*>', caseSensitive: false), '\n');
  s = s.replaceAll(RegExp(r'<w:br[^>/]*/?>', caseSensitive: false), '\n');
  s = s.replaceAll(RegExp(r'<w:tab[^>/]*/?>', caseSensitive: false), '\t');
  s = s.replaceAll(RegExp(r'</w:tr[^>]*>', caseSensitive: false), '\n');
  s = s.replaceAll(RegExp(r'</w:tc[^>]*>', caseSensitive: false), '\t');

  // Keep only text-bearing runs: prefer w:t / m:t content order via tag strip.
  s = s.replaceAll(RegExp(r'<[^>]+>'), '');
  s = _decodeXmlEntities(s);
  return _normalizeExtractedText(s);
}

String _convertAllOmml(String xml) {
  // Only convert math islands — never run OMML logic on the whole document body.
  return xml.replaceAllMapped(
    RegExp(
      r'<(m:oMathPara|m:oMath)\b[^>]*>([\s\S]*?)</\1>',
      caseSensitive: false,
    ),
    (m) => ' ${_ommlFragmentToText(m.group(2) ?? '')} ',
  );
}

String _ommlFragmentToText(String fragment) {
  var s = fragment;
  // Inside-out: keep rewriting leaf math structures until stable.
  for (var i = 0; i < 24; i++) {
    final before = s;
    s = _replaceOmmlLeafStructures(s);
    if (s == before) break;
  }
  s = s.replaceAllMapped(
    RegExp(r'<m:t\b[^>]*>([\s\S]*?)</m:t>', caseSensitive: false),
    (m) => m.group(1) ?? '',
  );
  s = s.replaceAll(RegExp(r'<[^>]+>'), '');
  return _decodeXmlEntities(s).trim();
}

String _replaceOmmlLeafStructures(String s) {
  var out = s;

  // Prefer structures that do not nest the same tag (innermost first).
  out = out.replaceAllMapped(
    RegExp(
      r'<m:f\b[^>]*>\s*'
      r'(?:<m:fPr[\s\S]*?</m:fPr>\s*)?'
      r'<m:num\b[^>]*>((?:(?!<m:f\b)[\s\S])*?)</m:num>\s*'
      r'<m:den\b[^>]*>((?:(?!<m:f\b)[\s\S])*?)</m:den>\s*'
      r'</m:f>',
      caseSensitive: false,
    ),
    (m) {
      final num = _ommlStripToText(m.group(1) ?? '');
      final den = _ommlStripToText(m.group(2) ?? '');
      return '($num)/($den)';
    },
  );

  out = out.replaceAllMapped(
    RegExp(
      r'<m:sSup\b[^>]*>\s*'
      r'(?:<m:sSupPr[\s\S]*?</m:sSupPr>\s*)?'
      r'<m:e\b[^>]*>((?:(?!<m:sSup\b)[\s\S])*?)</m:e>\s*'
      r'<m:sup\b[^>]*>((?:(?!<m:sSup\b)[\s\S])*?)</m:sup>\s*'
      r'</m:sSup>',
      caseSensitive: false,
    ),
    (m) {
      final base = _ommlStripToText(m.group(1) ?? '');
      final sup = _ommlStripToText(m.group(2) ?? '');
      return '${base}^{$sup}';
    },
  );

  out = out.replaceAllMapped(
    RegExp(
      r'<m:sSub\b[^>]*>\s*'
      r'(?:<m:sSubPr[\s\S]*?</m:sSubPr>\s*)?'
      r'<m:e\b[^>]*>((?:(?!<m:sSub\b)[\s\S])*?)</m:e>\s*'
      r'<m:sub\b[^>]*>((?:(?!<m:sSub\b)[\s\S])*?)</m:sub>\s*'
      r'</m:sSub>',
      caseSensitive: false,
    ),
    (m) {
      final base = _ommlStripToText(m.group(1) ?? '');
      final sub = _ommlStripToText(m.group(2) ?? '');
      return '${base}_{$sub}';
    },
  );

  out = out.replaceAllMapped(
    RegExp(
      r'<m:sSubSup\b[^>]*>\s*'
      r'(?:<m:sSubSupPr[\s\S]*?</m:sSubSupPr>\s*)?'
      r'<m:e\b[^>]*>([\s\S]*?)</m:e>\s*'
      r'<m:sub\b[^>]*>([\s\S]*?)</m:sub>\s*'
      r'<m:sup\b[^>]*>([\s\S]*?)</m:sup>\s*'
      r'</m:sSubSup>',
      caseSensitive: false,
    ),
    (m) {
      final base = _ommlStripToText(m.group(1) ?? '');
      final sub = _ommlStripToText(m.group(2) ?? '');
      final sup = _ommlStripToText(m.group(3) ?? '');
      return '${base}_{$sub}^{$sup}';
    },
  );

  out = out.replaceAllMapped(
    RegExp(
      r'<m:rad\b[^>]*>\s*'
      r'(?:<m:radPr[\s\S]*?</m:radPr>\s*)?'
      r'<m:deg\b[^>]*>([\s\S]*?)</m:deg>\s*'
      r'<m:e\b[^>]*>([\s\S]*?)</m:e>\s*'
      r'</m:rad>',
      caseSensitive: false,
    ),
    (m) {
      final deg = _ommlStripToText(m.group(1) ?? '').trim();
      final body = _ommlStripToText(m.group(2) ?? '');
      if (deg.isEmpty || deg == '2') return '√($body)';
      return '√[$deg]($body)';
    },
  );

  out = out.replaceAllMapped(
    RegExp(
      r'<m:d\b[^>]*>\s*'
      r'(?:<m:dPr[\s\S]*?</m:dPr>\s*)?'
      r'<m:e\b[^>]*>([\s\S]*?)</m:e>\s*'
      r'</m:d>',
      caseSensitive: false,
    ),
    (m) => '(${_ommlStripToText(m.group(1) ?? '')})',
  );

  return out;
}

String _ommlStripToText(String xml) {
  var s = xml.replaceAllMapped(
    RegExp(r'<m:t\b[^>]*>([\s\S]*?)</m:t>', caseSensitive: false),
    (m) => m.group(1) ?? '',
  );
  s = s.replaceAll(RegExp(r'<[^>]+>'), '');
  return _decodeXmlEntities(s).trim();
}

String _decodeXmlEntities(String input) {
  var s = input
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&#160;', ' ')
      .replaceAll('&#xa0;', ' ')
      .replaceAll('&#xA0;', ' ');

  s = s.replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (m) {
    final code = int.tryParse(m.group(1)!, radix: 16);
    if (code == null) return m.group(0)!;
    return String.fromCharCode(code);
  });
  s = s.replaceAllMapped(RegExp(r'&#([0-9]+);'), (m) {
    final code = int.tryParse(m.group(1)!);
    if (code == null) return m.group(0)!;
    return String.fromCharCode(code);
  });
  return s;
}

String _normalizeExtractedText(String raw) {
  return raw
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .replaceAll(RegExp(r'[ \t]+\n'), '\n')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .replaceAll(RegExp(r'[ \t]{2,}'), ' ')
      .trim();
}

String _decodePlainText(List<int> bytes) {
  try {
    return utf8.decode(bytes);
  } on Object {
    return latin1.decode(bytes, allowInvalid: true);
  }
}
