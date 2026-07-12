import 'package:flutter/services.dart';

/// Maps image_picker platform failures to short VN copy.
String imagePickerErrorMessage(Object error) {
  if (error is PlatformException) {
    if (error.code == 'channel-error' ||
        (error.message?.contains('Unable to establish connection') ?? false)) {
      return 'Camera/thư viện chưa sẵn sàng. Em Stop app rồi chạy lại '
          '(không dùng Hot Reload sau khi thêm image_picker).';
    }
    if (error.code == 'camera_access_denied' ||
        error.code == 'photo_access_denied') {
      return 'Em cần cho phép quyền Camera/Ảnh trong Cài đặt thiết bị.';
    }
    return 'Không chọn được ảnh: ${error.message ?? error.code}';
  }
  return 'Không chọn được ảnh: $error';
}
