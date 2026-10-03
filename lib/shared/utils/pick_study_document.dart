import 'package:eduself_study_app/shared/widgets/app_toast.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

/// Shared document extensions accepted by Tài liệu / Gia sư attach.
const kDocumentExtensions = <String>[
  'pdf',
  'doc',
  'docx',
  'xls',
  'xlsx',
  'ppt',
  'pptx',
  'txt',
  'md',
  'png',
  'jpg',
  'jpeg',
  'webp',
  'gif',
];

/// PDF / Word / text for Math AI (tutor + practice) local extraction.
const kMathAiDocumentExtensions = <String>[
  'pdf',
  'doc',
  'docx',
  'txt',
  'md',
];

bool isAllowedStudyDocument(String filename) {
  final dot = filename.lastIndexOf('.');
  if (dot < 0 || dot == filename.length - 1) return false;
  final ext = filename.substring(dot + 1).toLowerCase();
  return kDocumentExtensions.contains(ext);
}

/// Opens the system file picker for one study document.
///
/// Pass [context] so we can show a short tip before leaving the app.
/// Returns `null` if the user cancels (system Back / gesture).
Future<({String name, List<int> bytes})?> pickStudyDocument(
  BuildContext context,
) async {
  final proceed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Chọn tài liệu'),
      content: const Text(
        'Sắp mở trình chọn tệp của hệ thống.\n\n'
        '• Chọn PDF, Word, Excel, PowerPoint, ảnh hoặc txt\n'
        '• Bấm Back / Hủy để quay lại app',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Mở chọn tệp'),
        ),
      ],
    ),
  );
  if (proceed != true) return null;
  if (!context.mounted) return null;

  final FilePickerResult? result;
  try {
    result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: kDocumentExtensions,
      withData: true,
      allowMultiple: false,
    );
  } on Object catch (e) {
    AppToast.error('Không mở được bộ chọn tệp: $e');
    return null;
  }

  if (result == null || result.files.isEmpty) return null;

  final file = result.files.single;
  final name = file.name;
  if (!isAllowedStudyDocument(name)) {
    AppToast.error(
      'Định dạng chưa hỗ trợ. Em chọn PDF, Word, Excel, PowerPoint, ảnh hoặc txt nhé.',
    );
    return null;
  }

  final bytes = file.bytes;
  if (bytes == null || bytes.isEmpty) {
    AppToast.error('Không đọc được tệp. Em thử lại nhé.');
    return null;
  }
  return (name: name, bytes: bytes);
}

/// File picker for Math AI: PDF, Word (.docx), TXT/MD only.
Future<({String name, List<int> bytes})?> pickMathAiDocument(
  BuildContext context,
) async {
  final proceed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Chọn PDF / Word'),
      content: const Text(
        'Sắp mở trình chọn tệp của hệ thống.\n\n'
        '• Chọn PDF, Word (.docx) hoặc TXT chứa đề / bài làm\n'
        '• App sẽ đọc chữ trong tệp rồi gửi cho AI\n'
        '• Bấm Back / Hủy để quay lại app',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Mở chọn tệp'),
        ),
      ],
    ),
  );
  if (proceed != true) return null;
  if (!context.mounted) return null;

  final FilePickerResult? result;
  try {
    result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: kMathAiDocumentExtensions,
      withData: true,
      allowMultiple: false,
    );
  } on Object catch (e) {
    AppToast.error('Không mở được bộ chọn tệp: $e');
    return null;
  }

  if (result == null || result.files.isEmpty) return null;

  final file = result.files.single;
  final name = file.name;
  final lower = name.toLowerCase();
  final ok =
      kMathAiDocumentExtensions.any((ext) => lower.endsWith('.$ext'));
  if (!ok) {
    AppToast.error('Em chọn PDF, Word (.docx) hoặc TXT nhé.');
    return null;
  }

  final bytes = file.bytes;
  if (bytes == null || bytes.isEmpty) {
    AppToast.error('Không đọc được tệp. Em thử lại nhé.');
    return null;
  }
  if (bytes.length > 25 * 1024 * 1024) {
    AppToast.error('Tệp tối đa 25MB.');
    return null;
  }
  return (name: name, bytes: bytes);
}
