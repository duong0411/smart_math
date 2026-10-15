# EduSelf Ngữ Văn AI

Ứng dụng AI giám sát và hỗ trợ học sinh học tập môn **Ngữ văn** THCS (**lớp 6–9**).

Nhánh: `ngu-van` · Repo: [duong0411/smart_math](https://github.com/duong0411/smart_math)

## Cách dùng nhanh

1. Lấy Gemini API key tại [Google AI Studio](https://aistudio.google.com/apikey)
2. Chạy app: `flutter run`
3. Vào **Cài đặt** → dán API key → Lưu
4. Điền tên & lớp học sinh (6–9)
5. Dùng:
   - **Gia sư Ngữ văn AI** — hỏi đáp, phân tích văn bản, hướng dẫn làm văn
   - **Luyện tập Ngữ văn** — AI tạo đề & chấm bài
   - **Giải trí Ngữ văn** — chọn lớp 6–9 · kho báu, boss, tên lửa (không cần API)
   - **Giám sát học tập** — tiến độ, điểm yếu, kế hoạch ôn AI

API key được lưu trên thiết bị, gọi thẳng Gemini — không cần backend.

App dùng chuỗi model ưu tiên độ ổn định và **tự chuyển model** khi bị rate-limit / hết quota:

`gemini-2.5-flash` → `gemini-2.0-flash` → `gemini-2.5-flash-lite` → `gemini-2.5-pro`

## Build bằng GitHub Actions

Mỗi lần push lên `ngu-van` hoặc `main` (hoặc chạy thủ công **Actions → Build APK, iOS & Windows → Run workflow**):

| Job | Artifact / Release |
|-----|--------------------|
| Android APK | `app-release.apk` + tag `nguvan-android-v1.0.*` |
| iOS IPA | `EduSelfNguVan.ipa` (unsigned) + tag `nguvan-ios-v1.0.*` |
| Windows EXE | `EduSelfNguVan-windows.zip` + tag `nguvan-windows-v1.0.*` |

Tải file ở tab **Actions** (Artifacts) hoặc **Releases**.

> IPA không có chữ ký Apple — chỉ dùng để kiểm thử / sideload.  
> Windows: giải nén cả zip rồi chạy `eduself_study_app.exe` (giữ nguyên thư mục DLL + `data`).

## Chạy local

```bash
flutter pub get
flutter run
```

Tuỳ chọn pre-fill key qua `assets/env/gemini.env`:

```
GEMINI_API_KEY=your_key_here
```
