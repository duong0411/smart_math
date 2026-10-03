import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:pdfrx/pdfrx.dart';

/// Max characters sent to the model from one attached document.
const kMaxExtractedDocumentChars = 60000;

/// Max PDF pages to OCR/extract (keeps latency reasonable).
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

  final cleaned = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n').trim();
  if (cleaned.isEmpty) {
    throw StateError(
      'Không đọc được chữ trong tệp (có thể là PDF scan / ảnh). '
      'Em thử xuất PDF có chữ chọn được, hoặc chụp ảnh đề bài.',
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
  final doc = await PdfDocument.openData(Uint8List.fromList(bytes));
  try {
    final pageCount = doc.pages.length;
    if (pageCount == 0) {
      throw StateError('PDF không có trang.');
    }
    final limit =
        pageCount > kMaxPdfPagesToExtract ? kMaxPdfPagesToExtract : pageCount;
    final buf = StringBuffer();
    for (var i = 0; i < limit; i++) {
      final page = doc.pages[i];
      final raw = await page.loadText();
      final pageText = (raw?.fullText ?? '').trim();
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

String _extractDocx(List<int> bytes) {
  Archive archive;
  try {
    archive = ZipDecoder().decodeBytes(bytes);
  } on Object {
    throw StateError('Không mở được tệp Word (.docx). Em kiểm tra lại tệp nhé.');
  }

  final xmlFile = archive.findFile('word/document.xml');
  if (xmlFile == null) {
    throw StateError('Tệp Word thiếu nội dung (document.xml).');
  }
  final xmlBytes = xmlFile.content;
  if (xmlBytes.isEmpty) {
    throw StateError('Tệp Word không có nội dung chữ.');
  }

  final xml = utf8.decode(xmlBytes, allowMalformed: true);
  // Paragraph breaks → newlines; drop remaining markup.
  var text = xml
      .replaceAll(RegExp(r'</w:p[^>]*>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<w:br[^/]*/>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      .replaceAll(RegExp(r'[ \t]+\n'), '\n')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n');
  return text.trim();
}

String _decodePlainText(List<int> bytes) {
  try {
    return utf8.decode(bytes);
  } on Object {
    return latin1.decode(bytes, allowInvalid: true);
  }
}
