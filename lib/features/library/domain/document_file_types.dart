import 'package:flutter/material.dart';

/// Map file extension → MIME + media kind for uploads.
({String contentType, String kind}) mediaTypeForFilename(String filename) {
  final lower = filename.toLowerCase();
  if (lower.endsWith('.pdf')) {
    return (contentType: 'application/pdf', kind: 'document');
  }
  if (lower.endsWith('.doc')) {
    return (contentType: 'application/msword', kind: 'document');
  }
  if (lower.endsWith('.docx')) {
    return (
      contentType:
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      kind: 'document',
    );
  }
  if (lower.endsWith('.xls')) {
    return (contentType: 'application/vnd.ms-excel', kind: 'document');
  }
  if (lower.endsWith('.xlsx')) {
    return (
      contentType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      kind: 'document',
    );
  }
  if (lower.endsWith('.ppt') || lower.endsWith('.pptx')) {
    return (
      contentType: lower.endsWith('.pptx')
          ? 'application/vnd.openxmlformats-officedocument.presentationml.presentation'
          : 'application/vnd.ms-powerpoint',
      kind: 'document',
    );
  }
  if (lower.endsWith('.txt') || lower.endsWith('.md')) {
    return (contentType: 'text/plain', kind: 'document');
  }
  if (lower.endsWith('.png')) {
    return (contentType: 'image/png', kind: 'image');
  }
  if (lower.endsWith('.webp')) {
    return (contentType: 'image/webp', kind: 'image');
  }
  if (lower.endsWith('.gif')) {
    return (contentType: 'image/gif', kind: 'image');
  }
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
    return (contentType: 'image/jpeg', kind: 'image');
  }
  return (contentType: 'application/octet-stream', kind: 'other');
}

IconData iconForDocumentTitle(String title) {
  final lower = title.toLowerCase();
  if (lower.endsWith('.pdf')) return Icons.picture_as_pdf_rounded;
  if (lower.endsWith('.doc') || lower.endsWith('.docx')) {
    return Icons.description_rounded;
  }
  if (lower.endsWith('.xls') || lower.endsWith('.xlsx')) {
    return Icons.table_chart_rounded;
  }
  if (lower.endsWith('.png') ||
      lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.webp') ||
      lower.endsWith('.gif')) {
    return Icons.image_rounded;
  }
  return Icons.insert_drive_file_rounded;
}

String formatLabelForDocumentTitle(String title) {
  final lower = title.toLowerCase();
  if (lower.endsWith('.pdf')) return 'PDF';
  if (lower.endsWith('.doc') || lower.endsWith('.docx')) return 'Word';
  if (lower.endsWith('.xls') || lower.endsWith('.xlsx')) return 'Excel';
  if (lower.endsWith('.ppt') || lower.endsWith('.pptx')) return 'PowerPoint';
  if (lower.endsWith('.png') ||
      lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.webp') ||
      lower.endsWith('.gif')) {
    return 'Ảnh';
  }
  if (lower.endsWith('.txt') || lower.endsWith('.md')) return 'Văn bản';
  return 'Tệp';
}
