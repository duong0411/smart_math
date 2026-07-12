class MediaAsset {
  const MediaAsset({
    required this.id,
    required this.ownerId,
    required this.kind,
    required this.contentType,
    required this.filename,
    required this.sizeBytes,
    required this.status,
    required this.uploadPath,
    required this.contentPath,
    required this.createdAtUtc,
    required this.updatedAtUtc,
  });

  final int id;
  final int ownerId;
  final String kind;
  final String contentType;
  final String filename;
  final int? sizeBytes;
  final String status;
  final String? uploadPath;
  final String? contentPath;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;

  bool get isReady => status == 'ready';
  bool get isImage => contentType.startsWith('image/');
  bool get isPdf =>
      contentType == 'application/pdf' ||
      filename.toLowerCase().endsWith('.pdf');

  factory MediaAsset.fromJson(Map<String, dynamic> json) {
    return MediaAsset(
      id: json['id'] as int,
      ownerId: json['ownerId'] as int,
      kind: json['kind'] as String? ?? 'other',
      contentType: json['contentType'] as String? ?? 'application/octet-stream',
      filename: json['filename'] as String? ?? 'file',
      sizeBytes: json['sizeBytes'] as int?,
      status: json['status'] as String? ?? 'pending',
      uploadPath: json['uploadPath'] as String?,
      contentPath: json['contentPath'] as String?,
      createdAtUtc: DateTime.parse(json['createdAtUtc'] as String),
      updatedAtUtc: DateTime.parse(json['updatedAtUtc'] as String),
    );
  }
}

class UploadMediaInput {
  const UploadMediaInput({
    required this.bytes,
    required this.filename,
    required this.contentType,
    this.kind = 'image',
  });

  final List<int> bytes;
  final String filename;
  final String contentType;
  final String kind;
}
