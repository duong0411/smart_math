# Hướng dẫn tạo phần mềm EduSelf AI  
*(Dùng cho hồ sơ dự thi sản phẩm sáng tạo — môn Toán / Địa lí)*

Tài liệu này mô tả **cách viết mã, kiểm thử, build và phát hành ứng dụng** từ mã nguồn Flutter trên GitHub. Bạn có thể in hoặc copy vào thư mục hồ sơ dự thi.

---

## 1. Sản phẩm là gì?

**EduSelf AI** là ứng dụng học tập hỗ trợ học sinh THCS (lớp 6–9) bằng trí tuệ nhân tạo (Gemini):

| Phiên bản | Nhánh GitHub | Nội dung chính |
|-----------|--------------|----------------|
| **EduSelf Toán AI** | `main` | Gia sư Toán, luyện tập, trò chơi toán, giám sát học tập |
| **EduSelf Địa lí AI** | `mon-dia-ly` | Gia sư Địa lí, luyện tập, khám phá địa lí, giám sát học tập |

**Repo:** https://github.com/duong0411/smart_math  

**Ý tưởng dự thi:** biến điện thoại / máy tính thành “gia sư AI” luôn sẵn sàng, bám chương trình GDPT Việt Nam, có game học tập và theo dõi tiến độ — không cần server riêng (API key lưu trên máy học sinh).

---

## 2. Công nghệ đã dùng

| Thành phần | Công nghệ | Vai trò |
|------------|-----------|---------|
| Ngôn ngữ | **Dart** | Viết logic ứng dụng |
| Framework UI | **Flutter** | Một codebase → Android / iOS / Windows |
| Quản lý trạng thái | **Riverpod** | Hồ sơ học sinh, API key, phiên chat… |
| AI | **Google Gemini API** | Gia sư, tạo bài, chấm bài, báo cáo |
| Lưu cục bộ | **SharedPreferences / secure storage** | Hồ sơ, lịch sử học, API key |
| Đọc tài liệu | **pdfrx** (PDF), **archive** (Word `.docx`) | Upload đề / bài làm |
| CI/CD | **GitHub Actions** | Tự build APK, IPA, EXE khi đẩy code |

---

## 3. Các bước tạo phần mềm (từ ý tưởng → sản phẩm)

```
Ý tưởng → Thiết kế chức năng → Cài môi trường → Viết code
    → Kiểm thử (test) → Build thử trên máy → Đẩy lên GitHub
    → GitHub Actions build APK / IPA / EXE → Tải file cài đặt
```

### Bước 1 — Xác định chức năng

Ví dụ môn Toán / Địa lí:

1. **Gia sư AI** — hỏi đáp từng bước, đính kèm ảnh / PDF / Word  
2. **Luyện tập** — AI tạo câu hỏi theo lớp, chấm bài  
3. **Trò chơi** — luyện kiến thức không cần API (offline)  
4. **Giám sát** — thống kê đúng/sai, gợi ý ôn  
5. **Cài đặt** — tên, lớp (6–9), Gemini API key  

### Bước 2 — Cài môi trường lập trình

1. Cài [Flutter SDK](https://docs.flutter.dev/get-started/install) (ổn định / stable)  
2. Cài **Android Studio** (build APK) và/hoặc Visual Studio (build Windows)  
3. Kiểm tra:

```bash
flutter doctor
```

Các mục quan trọng: Flutter, Android toolchain, (tuỳ chọn) Windows / Xcode.

### Bước 3 — Lấy mã nguồn

```bash
git clone https://github.com/duong0411/smart_math.git
cd smart_math

# Môn Toán
git checkout main

# hoặc môn Địa lí
git checkout mon-dia-ly
```

### Bước 4 — Cài thư viện & chạy thử

```bash
flutter pub get
flutter run
```

Lấy API key tại [Google AI Studio](https://aistudio.google.com/apikey) → mở app → **Cài đặt** → dán key → Lưu.

---

## 4. Cấu trúc mã nguồn (đọc nhanh `main` & thư mục)

```
smart_math/
├── lib/
│   ├── main.dart                 # Điểm vào: khởi tạo app, pdfrx, Riverpod
│   ├── core/                     # Cấu hình, theme, router, AI client
│   ├── features/                 # Từng chức năng (gia sư, luyện tập, game…)
│   └── shared/                   # Widget & tiện ích dùng chung
├── assets/
│   ├── prompts/                  # System prompt cho AI
│   ├── images/                   # Hình giao diện
│   └── env/                      # File môi trường mẫu (API key tuỳ chọn)
├── test/                         # Unit test (câu hỏi game, đọc PDF/DOCX…)
├── android/  ios/  windows/      # Mã nền tảng
├── .github/workflows/
│   └── build-mobile.yml          # CI: build APK + IPA + Windows
├── pubspec.yaml                  # Khai báo package
└── README.md
```

### `lib/main.dart` làm gì?

1. `WidgetsFlutterBinding.ensureInitialized()` — sẵn sàng plugin Flutter  
2. `pdfrxFlutterInitialize()` — đọc PDF khi học sinh upload  
3. `AppConfig.load()` — nạp cấu hình / env  
4. `runApp(ProviderScope(...))` — chạy app với Riverpod  

### Luồng một chức năng (ví dụ Gia sư)

```
Màn hình UI (presentation)
    → gọi askMathAi / GeminiClient (core/ai)
    → Gemini trả lời
    → lưu tin nhắn vào MathLocalStore (local)
    → hiển thị lại trên chat
```

Đây là mô hình **tách lớp**: giao diện → logic/AI → lưu trữ — dễ bảo trì khi dự thi và mở rộng sau này.

---

## 5. Cách viết / chỉnh mã (gợi ý thực hành)

1. **Thêm màn hình mới:** tạo file trong `lib/features/.../presentation/pages/`  
2. **Đăng ký đường dẫn:** thêm `GoRoute` trong `lib/core/routing/app_router.dart`  
3. **Đổi tên app / khẩu hiệu:** sửa `lib/core/config/app_config.dart`  
4. **Đổi cách AI dạy:** sửa `assets/prompts/eduself_system_prompt.md`  
5. **Thêm câu hỏi game offline:** sửa bank câu hỏi trong `lib/features/math_games/`  
6. **Thêm ảnh:** đặt vào `assets/images/` và khai báo trong `pubspec.yaml` nếu cần  

Sau mỗi lần sửa:

```bash
flutter analyze
flutter test
flutter run
```

---

## 6. Kiểm thử (Test code)

### Chạy toàn bộ test

```bash
flutter test
```

### Ví dụ test đã có trong dự án Toán

| File test | Mục đích |
|-----------|----------|
| `test/grade_question_bank_test.dart` | Câu hỏi game lớp 6–9 hợp lệ (có đáp án trong 4 lựa chọn) |
| `test/extract_document_test.dart` | Đọc được chữ từ **DOCX / PDF / TXT** |

### Phân tích tĩnh (bắt lỗi trước khi build)

```bash
flutter analyze
```

**Ý nghĩa trong hồ sơ dự thi:** chứng minh sản phẩm không chỉ “chạy được”, mà còn có **quy trình kiểm chứng chất lượng**.

---

## 7. Build trên máy cá nhân

### Android APK

```bash
flutter build apk --release
```

File ra:

`build/app/outputs/flutter-apk/app-release.apk`

Cài sang điện thoại Android (cho phép nguồn không rõ nếu cần).

### Windows EXE

```bash
flutter config --enable-windows-desktop
flutter build windows --release
```

Thư mục chạy:

`build/windows/x64/runner/Release/`  

→ chạy `eduself_study_app.exe` (**giữ nguyên cả thư mục** DLL + `data`).

### iOS IPA (cần máy Mac + Xcode)

```bash
flutter build ios --release --no-codesign
```

Trên CI, workflow đóng gói thành `SmartMath.ipa` (unsigned — chỉ sideload / kiểm thử).

---

## 8. Build tự động trên GitHub (quan trọng cho hồ sơ)

### Cơ chế

File: `.github/workflows/build-mobile.yml`

Khi **push code** lên nhánh được cấu hình (hoặc bấm **Run workflow** thủ công), GitHub chạy 3 job song song:

| Job | Máy ảo CI | Kết quả |
|-----|-----------|---------|
| Android APK | `ubuntu-latest` | `app-release.apk` |
| iOS IPA | `macos-latest` | `SmartMath.ipa` |
| Windows EXE | `windows-latest` | `SmartMath-windows.zip` |

### Các bước học sinh / nhóm làm

1. Sửa code trên máy → `git add` → `git commit` → `git push`  
2. Vào repo GitHub → tab **Actions**  
3. Chọn workflow **Build APK, iOS & Windows** → xem từng job xanh (success)  
4. Tải bản build:
   - **Artifacts** (trong run Actions), hoặc  
   - **Releases** (tag phát hành)

### Nhánh & tag phát hành

| Sản phẩm | Nhánh | Tag release (ví dụ) |
|----------|-------|---------------------|
| Toán | `main` | `android-v1.0.*`, `ios-v1.0.*`, `windows-v1.0.*` |
| Địa lí | `mon-dia-ly` | `dialy-android-v1.0.*`, `dialy-ios-v1.0.*`, `dialy-windows-v1.0.*` |

### Chạy workflow thủ công

GitHub → **Actions** → **Build APK, iOS & Windows** → **Run workflow** → chọn nhánh → Run.

---

## 9. Quy trình Git gợi ý (làm việc nhóm)

```bash
# Xem thay đổi
git status
git diff

# Lưu phiên bản
git add .
git commit -m "mô tả ngắn: đã làm gì / vì sao"

# Đẩy lên GitHub (kích hoạt CI nếu đúng nhánh)
git push origin main
# hoặc
git push origin mon-dia-ly
```

**Lưu ý:** không commit API key, file `.env` thật, hay thư mục `build/` / `dist-windows/` (đã nằm trong `.gitignore`).

---

## 10. Checklist đưa vào hồ sơ dự thi

In hoặc chụp kèm hồ sơ:

- [ ] Mô tả ý tưởng & đối tượng (học sinh THCS lớp 6–9)  
- [ ] Ảnh / video demo các chức năng chính  
- [ ] Link GitHub mã nguồn  
- [ ] Ảnh màn hình **Actions** (3 job build thành công)  
- [ ] Link **Releases** tải APK / Windows / IPA  
- [ ] Đoạn giải thích công nghệ (bảng mục 2)  
- [ ] Kết quả `flutter test` (chụp terminal)  
- [ ] Hướng dẫn giáo viên / giám khảo cài app thử  

---

## 11. Tóm tắt một dòng

> **Viết app bằng Flutter → kiểm thử bằng `flutter test` → đẩy GitHub → GitHub Actions tự build APK, IPA và EXE → tải về dùng và đưa vào hồ sơ dự thi.**

---

*Tài liệu kỹ thuật đi kèm mã nguồn EduSelf / Smart Math — có thể copy vào thư mục hồ sơ sản phẩm sáng tạo.*
