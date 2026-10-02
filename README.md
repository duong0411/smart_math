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
   - **Giải trí Toán 8** — kho báu, boss, tên lửa theo SGK *Kết nối tri thức* tập 1+2 (không cần API)
   - **Giám sát học tập** — tiến độ, điểm yếu, kế hoạch ôn AI

API key được lưu trên thiết bị (secure storage), gọi thẳng Gemini — không cần backend.

App dùng chuỗi model ưu tiên độ chính xác và **tự chuyển model** khi bị rate-limit / hết quota:

`gemini-2.5-pro` → `gemini-2.5-flash` → `gemini-2.0-flash` → `gemini-2.5-flash-lite`

## Build bằng GitHub Actions

Mỗi lần push lên `main` (hoặc chạy thủ công **Actions → Build APK, iOS & Windows → Run workflow**):

| Job | Artifact / Release |
|-----|--------------------|
| Android APK | `app-release.apk` + tag `android-v1.0.*` |
| iOS IPA | `SmartMath.ipa` (unsigned) + tag `ios-v1.0.*` |
| Windows EXE | `SmartMath-windows.zip` + tag `windows-v1.0.*` |

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
