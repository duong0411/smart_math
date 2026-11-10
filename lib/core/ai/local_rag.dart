import 'dart:convert';

import 'package:flutter/services.dart';

/// Offline RAG nhúng trong app (không gọi HTTP/Mongo).
/// Truy vấn corpus KNTT đóng gói trong [assets/rag/kntt_nguvan_seed.json].
class LocalRag {
  LocalRag._();
  static final LocalRag instance = LocalRag._();

  static const assetPath = 'assets/rag/kntt_nguvan_seed.json';

  List<_RagDoc>? _docs;

  Future<void> ensureLoaded() async {
    if (_docs != null) return;
    final raw = await rootBundle.loadString(assetPath);
    final list = jsonDecode(raw);
    if (list is! List) {
      _docs = const [];
      return;
    }
    _docs = [
      for (final item in list)
        if (item is Map)
          _RagDoc(
            grade: (item['grade'] as num?)?.toInt() ?? 8,
            unit: '${item['unit'] ?? ''}',
            title: '${item['title'] ?? ''}',
            text: '${item['text'] ?? ''}',
          ),
    ];
  }

  Future<String> buildSystemInject({
    required String query,
    int grade = 8,
    int topK = 4,
  }) async {
    await ensureLoaded();
    final docs = _docs ?? const <_RagDoc>[];
    if (docs.isEmpty) return '';

    final qTokens = _tokenize(query);
    final scored = <(_RagDoc, double)>[];
    for (final d in docs) {
      // Ưu tiên đúng lớp; vẫn cho phép doc tổng quát lệch ±1.
      final gradeBoost = d.grade == grade
          ? 1.35
          : ((d.grade - grade).abs() == 1 ? 0.85 : 0.55);
      final score = _score(qTokens, d) * gradeBoost;
      if (score > 0) scored.add((d, score));
    }
    scored.sort((a, b) => b.$2.compareTo(a.$2));
    final hits = scored.take(topK).toList();
    if (hits.isEmpty) {
      // fallback: lấy vài doc đúng lớp
      final fallback = docs.where((d) => d.grade == grade).take(topK).toList();
      if (fallback.isEmpty) return '';
      return _format(fallback.map((d) => (d, 0.0)).toList());
    }
    return _format(hits);
  }

  String _format(List<(_RagDoc, double)> hits) {
    final buf = StringBuffer();
    buf.writeln(
      '## Ngữ liệu RAG (offline trong app – mục lục/ghi chú sư phạm KNTT; '
      'không phải nguyên văn SGK):',
    );
    for (var i = 0; i < hits.length; i++) {
      final d = hits[i].$1;
      buf.writeln('[${i + 1}] (Lớp ${d.grade} · ${d.unit}) ${d.title}');
      buf.writeln(d.text);
      buf.writeln();
    }
    return buf.toString().trim();
  }

  static final _wordRe = RegExp(
    r'[0-9a-zA-ZàáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴÈÉẸẺẼÊỀẾỆỂỄÌÍỊỈĨÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠÙÚỤỦŨƯỪỨỰỬỮỲÝỴỶỸĐ]+',
  );

  static Set<String> _tokenize(String input) {
    final out = <String>{};
    for (final m in _wordRe.allMatches(input.toLowerCase())) {
      final t = m.group(0);
      if (t != null && t.length >= 2) out.add(t);
    }
    return out;
  }

  static double _score(Set<String> q, _RagDoc d) {
    if (q.isEmpty) return 0;
    final hay = _tokenize('${d.unit} ${d.title} ${d.text}');
    if (hay.isEmpty) return 0;
    var hit = 0;
    for (final t in q) {
      if (hay.contains(t)) hit++;
    }
    // Jaccard-ish
    return hit / q.length;
  }
}

class _RagDoc {
  const _RagDoc({
    required this.grade,
    required this.unit,
    required this.title,
    required this.text,
  });

  final int grade;
  final String unit;
  final String title;
  final String text;
}
