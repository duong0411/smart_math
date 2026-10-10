import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:eduself_study_app/shared/utils/extract_study_document_text.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdfrx/pdfrx.dart';

List<int> _minimalDocx(String paragraph) {
  final documentXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    <w:p><w:r><w:t>$paragraph</w:t></w:r></w:p>
  </w:body>
</w:document>''';
  const contentTypes =
      '''<?xml version="1.0" encoding="UTF-8"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/></Types>''';
  const rels =
      '''<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/></Relationships>''';

  final archive = Archive();
  void add(String name, String data) {
    final bytes = utf8.encode(data);
    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  }

  add('[Content_Types].xml', contentTypes);
  add('_rels/.rels', rels);
  add('word/document.xml', documentXml);
  return ZipEncoder().encode(archive)!;
}

/// Minimal valid PDF with one page of Helvetica text.
Uint8List _minimalPdfWithText(String text) {
  // Escape parentheses for PDF string literals.
  final safe = text.replaceAll(r'\', r'\\').replaceAll('(', r'\(').replaceAll(')', r'\)');
  final stream = 'BT /F1 12 Tf 50 750 Td ($safe) Tj ET';
  final streamBytes = utf8.encode(stream);

  final objects = <String>[
    '1 0 obj<< /Type /Catalog /Pages 2 0 R >>endobj\n',
    '2 0 obj<< /Type /Pages /Kids [3 0 R] /Count 1 >>endobj\n',
    '3 0 obj<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] '
        '/Contents 4 0 R /Resources<< /Font<< /F1 5 0 R >> >> >>endobj\n',
    '4 0 obj<< /Length ${streamBytes.length} >>stream\n$stream\nendstream\nendobj\n',
    '5 0 obj<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>endobj\n',
  ];

  final buf = StringBuffer('%PDF-1.4\n');
  final offsets = <int>[0]; // 1-based object offsets
  for (final obj in objects) {
    offsets.add(utf8.encode(buf.toString()).length);
    buf.write(obj);
  }
  final xrefStart = utf8.encode(buf.toString()).length;
  buf.write('xref\n0 ${objects.length + 1}\n');
  buf.write('0000000000 65535 f \n');
  for (var i = 1; i <= objects.length; i++) {
    buf.write('${offsets[i].toString().padLeft(10, '0')} 00000 n \n');
  }
  buf.write(
    'trailer<< /Size ${objects.length + 1} /Root 1 0 R >>\n'
    'startxref\n$xrefStart\n%%EOF\n',
  );
  return Uint8List.fromList(utf8.encode(buf.toString()));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Required before PdfDocument.openData in tests / desktop.
    try {
      await pdfrxFlutterInitialize();
    } on Object {
      // Some platforms expose pdfrxInitialize instead.
      try {
        // ignore: deprecated_member_use
        pdfrxInitialize();
      } on Object {
        // Continue — openData may still work if native lib is present.
      }
    }
  });

  test('DOCX upload extract succeeds', () async {
    final bytes = _minimalDocx('Bai toan: 2x + 3 = 7. Tim x.');
    final result = await extractStudyDocumentText(
      filename: 'bai_tap.docx',
      bytes: bytes,
    );
    expect(result.text, contains('2x + 3 = 7'));
    expect(result.text, contains('Tim x'));
    expect(result.truncated, isFalse);
    // ignore: avoid_print
    print('DOCX OK → "${result.text}"');
  });

  test('PDF upload extract succeeds', () async {
    final bytes = _minimalPdfWithText('Phuong trinh: x = 5');
    final result = await extractStudyDocumentText(
      filename: 'bai_tap.pdf',
      bytes: bytes,
    );
    expect(result.text.toLowerCase(), contains('phuong'));
    expect(result.text, contains('5'));
    // ignore: avoid_print
    print('PDF OK → "${result.text}"');
  });

  test('TXT upload extract succeeds', () async {
    final result = await extractStudyDocumentText(
      filename: 'a.txt',
      bytes: utf8.encode('Phuong trinh: x = 5'),
    );
    expect(result.text, contains('x = 5'));
    // ignore: avoid_print
    print('TXT OK → "${result.text}"');
  });

  test('old .doc is rejected clearly', () async {
    await expectLater(
      extractStudyDocumentText(filename: 'a.doc', bytes: [1, 2, 3]),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('.docx'),
        ),
      ),
    );
  });
}
