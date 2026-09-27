# Smart Math (EduSelf Toán AI)

Ứng dụng AI giám sát và hỗ trợ học sinh học tập môn **Toán**.

Repo: [duong0411/smart_math](https://github.com/duong0411/smart_math)

## Cách dùng nhanh

1. Lấy Gemini API key tại [Google AI Studio](https://aistudio.google.com/apikey)
2. Chạy app: `flutter run`
3. Vào **Cài đặt** → dán API key → Lưu
4. Điền tên & lớp học sinh
5. Dùng:
   - **Gia sư Toán AI** — hỏi đáp từng bước
   - **Luyện tập Toán** — AI tạo bài & chấm
   - **Giám sát học tập** — tiến độ, điểm yếu, kế hoạch ôn AI

API key được lưu trên thiết bị (secure storage), gọi thẳng Gemini — không cần backend.

## Build bằng GitHub Actions

Mỗi lần push lên `main` (hoặc chạy thủ công **Actions → Build APK & iOS → Run workflow**):

| Job | Artifact / Release |
|-----|--------------------|
| Android APK | `app-release.apk` + release tag `android-v1.0.*` |
| iOS IPA | `SmartMath.ipa` (unsigned) + release tag `ios-v1.0.*` |

Tải file ở tab **Actions** (Artifacts) hoặc **Releases**.

> IPA không có chữ ký Apple — chỉ dùng để kiểm thử / sideload, chưa đưa lên App Store.

## Chạy local

```bash
flutter pub get
flutter run
```

Tuỳ chọn pre-fill key qua `assets/env/gemini.env`:

```
GEMINI_API_KEY=your_key_here
```
