# Phase 4 Slice A — Role Picker + Parent Portal Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans`. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Parents can register, link a student via invite code, view child progress, and generate/list weekly reports; students can mint invite codes; register exposes role picker.

**Architecture:** New `lib/features/parents/` (Clean Architecture + Riverpod). Extend auth register to pass `UserRole`, student profile for invite codes, progress repo for `GET /progress/summary/:id`. Replace `/parents` ComingSoon with gated hub.

**Tech Stack:** Flutter, Riverpod, go_router, `ApiClient`, `Result` / `FailureResult`, MockClient tests.

## Global Constraints

- Wire only existing APIs: `POST /parents/invite-codes`, `POST /parents/link`, `GET /parents/children`, `DELETE /parents/children/:studentId`, `GET /progress/summary/:id`, `GET|POST /reports/weekly`, `GET /reports`, `GET /reports/:id`, `POST /reports/:id/export`
- No Drift; no new Workers routes
- VN copy for parent/student surfaces
- Export is stub: show “Xuất sẵn (bản xem trước)” — do not download a fake PDF
- Commits only if the human requests them

---

### Task 1: Register role picker

**Files:**
- Modify: `lib/features/auth/domain/usecases/register_with_email.dart`
- Modify: `lib/features/auth/presentation/providers/auth_controllers.dart`
- Modify: `lib/features/auth/presentation/pages/register_page.dart`
- Test: `test/features/auth/register_with_email_test.dart` (create if missing)

**Interfaces:**
- Consumes: `AuthRepository.register({ email, password, UserRole role })` (already sends `role.name`)
- Produces: `RegisterWithEmail.call({ ..., required UserRole role })`; `RegisterController.submit({ ..., required UserRole role })`

- [ ] **Step 1: Write failing unit test for role passthrough**

Create `test/features/auth/register_with_email_test.dart`:

```dart
import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/features/auth/domain/entities/user.dart';
import 'package:eduself_study_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:eduself_study_app/features/auth/domain/usecases/register_with_email.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthRepo implements AuthRepository {
  UserRole? lastRole;

  @override
  Future<Result<User>> register({
    required String email,
    required String password,
    UserRole role = UserRole.student,
  }) async {
    lastRole = role;
    return Success(
      User(
        id: 1,
        email: email,
        role: role,
        createdAtUtc: DateTime.utc(2026, 1, 1),
      ),
    );
  }

  @override
  Future<Result<User>> login({
    required String email,
    required String password,
  }) =>
      throw UnimplementedError();

  @override
  Future<Result<User?>> getCurrentUser() => throw UnimplementedError();

  @override
  Future<Result<void>> logout() => throw UnimplementedError();
}

void main() {
  test('RegisterWithEmail passes parent role to repository', () async {
    final repo = _FakeAuthRepo();
    final useCase = RegisterWithEmail(repo);
    final result = await useCase(
      email: 'p@example.com',
      password: 'password1',
      confirmPassword: 'password1',
      role: UserRole.parent,
    );
    expect(result.isSuccess, isTrue);
    expect(repo.lastRole, UserRole.parent);
  });
}
```

If `AuthRepository` has different method names, match the real interface in `lib/features/auth/domain/repositories/auth_repository.dart`.

- [ ] **Step 2: Run test — expect FAIL** (missing `role` param on use case)

Run: `flutter test test/features/auth/register_with_email_test.dart`
Expected: compile/FAIL on `role:` named argument

- [ ] **Step 3: Implement role on use case + controller + UI**

`register_with_email.dart` — add `required UserRole role` to `call` and pass to `_repository.register(..., role: role)`.

`auth_controllers.dart` — `RegisterController.submit` adds `required UserRole role` and forwards it.

`register_page.dart` — add state `UserRole _role = UserRole.student;` and UI before email field:

```dart
Text('Bạn là', style: Theme.of(context).textTheme.titleSmall),
const SizedBox(height: 8),
SegmentedButton<UserRole>(
  segments: const [
    ButtonSegment(value: UserRole.student, label: Text('Học sinh'), icon: Icon(Icons.school_outlined)),
    ButtonSegment(value: UserRole.parent, label: Text('Phụ huynh'), icon: Icon(Icons.family_restroom)),
    ButtonSegment(value: UserRole.teacher, label: Text('Giáo viên'), icon: Icon(Icons.badge_outlined)),
  ],
  selected: {_role},
  onSelectionChanged: (s) => setState(() => _role = s.first),
),
```

Pass `role: _role` into `submit(...)`.

- [ ] **Step 4: Run test — expect PASS**

Run: `flutter test test/features/auth/register_with_email_test.dart`

- [ ] **Step 5: Commit** (only if human asks)

```bash
git add lib/features/auth test/features/auth/register_with_email_test.dart
git commit -m "feat(auth): register role picker for student, parent, teacher"
```

---

### Task 2: Parents domain entities + repository contract

**Files:**
- Create: `lib/features/parents/domain/entities/parent_invite_code.dart`
- Create: `lib/features/parents/domain/entities/linked_child.dart`
- Create: `lib/features/parents/domain/entities/parent_link.dart`
- Create: `lib/features/parents/domain/entities/weekly_report.dart`
- Create: `lib/features/parents/domain/repositories/parents_repository.dart`

**Interfaces:**
- Produces:

```dart
class ParentInviteCode {
  const ParentInviteCode({
    required this.code,
    required this.expiresAtUtc,
    required this.createdAtUtc,
  });
  final String code;
  final DateTime expiresAtUtc;
  final DateTime createdAtUtc;
  factory ParentInviteCode.fromJson(Map<String, dynamic> json) => ParentInviteCode(
        code: json['code'] as String,
        expiresAtUtc: DateTime.parse(json['expiresAtUtc'] as String),
        createdAtUtc: DateTime.parse(json['createdAtUtc'] as String),
      );
}

class LinkedChild {
  const LinkedChild({
    required this.linkId,
    required this.studentId,
    required this.studentEmail,
    this.displayName,
    this.gradeLevel,
    required this.linkedAtUtc,
  });
  final int linkId;
  final int studentId;
  final String studentEmail;
  final String? displayName;
  final int? gradeLevel;
  final DateTime linkedAtUtc;
  factory LinkedChild.fromJson(Map<String, dynamic> json) => LinkedChild(
        linkId: json['linkId'] as int,
        studentId: json['studentId'] as int,
        studentEmail: json['studentEmail'] as String,
        displayName: json['displayName'] as String?,
        gradeLevel: json['gradeLevel'] as int?,
        linkedAtUtc: DateTime.parse(json['linkedAtUtc'] as String),
      );
}

class ParentLink {
  const ParentLink({
    required this.id,
    required this.parentId,
    required this.studentId,
    required this.status,
    required this.linkedAtUtc,
  });
  final int id;
  final int parentId;
  final int studentId;
  final String status; // active | revoked
  final DateTime linkedAtUtc;
  factory ParentLink.fromJson(Map<String, dynamic> json) => ParentLink(
        id: json['id'] as int,
        parentId: json['parentId'] as int,
        studentId: json['studentId'] as int,
        status: json['status'] as String,
        linkedAtUtc: DateTime.parse(json['linkedAtUtc'] as String),
      );
}

class WeeklyReportCharts {
  const WeeklyReportCharts({
    required this.progress,
    required this.attemptCount,
    required this.gradedCount,
    this.avgScorePercent,
    required this.studyMinutesByDay,
  });
  final ProgressSummary progress; // from features/progress
  final int attemptCount;
  final int gradedCount;
  final double? avgScorePercent;
  final List<({String dateUtc, double minutes})> studyMinutesByDay;
  // fromJson: parse charts.progress via ProgressSummary.fromJson;
  // charts.assessments.attemptCount / gradedCount / avgScorePercent;
  // charts.studyMinutesByDay as list of maps
}

class WeeklyReportPreview {
  const WeeklyReportPreview({
    required this.studentId,
    this.studentDisplayName,
    required this.weekStartUtc,
    required this.weekEndUtc,
    required this.charts,
    required this.narrativeText,
    this.persistedReportId,
  });
  final int studentId;
  final String? studentDisplayName;
  final DateTime weekStartUtc;
  final DateTime weekEndUtc;
  final WeeklyReportCharts charts;
  final String narrativeText;
  final int? persistedReportId;
}

class WeeklyReport {
  const WeeklyReport({
    required this.id,
    required this.parentId,
    required this.studentId,
    required this.weekStartUtc,
    required this.weekEndUtc,
    required this.charts,
    required this.narrativeText,
    required this.exportStatus,
    this.exportMediaId,
    required this.createdAtUtc,
    required this.updatedAtUtc,
  });
  final int id;
  final int parentId;
  final int studentId;
  final DateTime weekStartUtc;
  final DateTime weekEndUtc;
  final WeeklyReportCharts charts;
  final String narrativeText;
  final String exportStatus;
  final int? exportMediaId;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;
}

abstract class ParentsRepository {
  Future<Result<ParentInviteCode>> createInviteCode();
  Future<Result<ParentLink>> linkChild(String inviteCode);
  Future<Result<List<LinkedChild>>> listChildren();
  Future<Result<void>> unlinkChild(int studentId);
  Future<Result<WeeklyReportPreview>> previewWeeklyReport({
    required int studentId,
    DateTime? weekStartUtc,
  });
  Future<Result<WeeklyReport>> generateWeeklyReport({
    required int studentId,
    DateTime? weekStartUtc,
  });
  Future<Result<List<WeeklyReport>>> listReports();
  Future<Result<WeeklyReport>> getReport(int id);
  Future<Result<WeeklyReport>> exportReport(int id);
}
```

- [ ] **Step 1: Create entity files + repository abstract class** as above (split charts parsing carefully; import `ProgressSummary` from `features/progress`).

- [ ] **Step 2: `dart analyze lib/features/parents`** — expect no issues.

- [ ] **Step 3: Commit** (optional / if asked)

---

### Task 3: ParentsRepositoryImpl + MockClient tests

**Files:**
- Create: `lib/features/parents/infrastructure/repositories/parents_repository_impl.dart`
- Create: `test/features/parents/parents_remote_test.dart`

**Interfaces:**
- Consumes: `ApiClient.get/post/delete`
- Produces: `ParentsRepositoryImpl({required ApiClient api})`

- [ ] **Step 1: Write failing tests**

```dart
import 'dart:convert';
import 'package:eduself_study_app/core/network/api_client.dart';
import 'package:eduself_study_app/features/parents/infrastructure/repositories/parents_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

ApiClient _api(Future<http.Response> Function(http.Request) handler) {
  return ApiClient(
    resolveBaseUrl: () => 'http://localhost:8787',
    readAccessToken: () async => 'token',
    readRefreshToken: () async => 'refresh',
    persistTokens: (_) async {},
    clearTokens: () async {},
    httpClient: MockClient(handler),
  );
}

void main() {
  test('listChildren parses linked children', () async {
    final repo = ParentsRepositoryImpl(
      api: _api((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/parents/children');
        return http.Response(
          jsonEncode({
            'data': [
              {
                'linkId': 1,
                'studentId': 9,
                'studentEmail': 'hs@example.com',
                'displayName': 'An',
                'gradeLevel': 6,
                'linkedAtUtc': '2026-01-01T00:00:00.000Z',
              }
            ]
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    final result = await repo.listChildren();
    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull!.first.studentId, 9);
    expect(result.valueOrNull!.first.displayName, 'An');
  });

  test('linkChild posts invite code', () async {
    final repo = ParentsRepositoryImpl(
      api: _api((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/parents/link');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['inviteCode'], 'ABCD12');
        return http.Response(
          jsonEncode({
            'data': {
              'id': 3,
              'parentId': 2,
              'studentId': 9,
              'status': 'active',
              'linkedAtUtc': '2026-01-01T00:00:00.000Z',
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    final result = await repo.linkChild('ABCD12');
    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull!.studentId, 9);
  });

  test('createInviteCode posts to invite-codes', () async {
    final repo = ParentsRepositoryImpl(
      api: _api((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/parents/invite-codes');
        return http.Response(
          jsonEncode({
            'data': {
              'code': 'XYZ999',
              'expiresAtUtc': '2026-01-08T00:00:00.000Z',
              'createdAtUtc': '2026-01-01T00:00:00.000Z',
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    final result = await repo.createInviteCode();
    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull!.code, 'XYZ999');
  });
}
```

- [ ] **Step 2: Run tests — expect FAIL** (impl missing)

Run: `flutter test test/features/parents/parents_remote_test.dart`

- [ ] **Step 3: Implement repository**

```dart
class ParentsRepositoryImpl implements ParentsRepository {
  ParentsRepositoryImpl({required this._api});
  final ApiClient _api;

  @override
  Future<Result<ParentInviteCode>> createInviteCode() async {
    final result = await _api.post('/parents/invite-codes', body: {});
    return switch (result) {
      Success(:final value) => Success(
          ParentInviteCode.fromJson(value['data'] as Map<String, dynamic>),
        ),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  @override
  Future<Result<ParentLink>> linkChild(String inviteCode) async {
    final result = await _api.post(
      '/parents/link',
      body: {'inviteCode': inviteCode.trim()},
    );
    return switch (result) {
      Success(:final value) => Success(
          ParentLink.fromJson(value['data'] as Map<String, dynamic>),
        ),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  @override
  Future<Result<List<LinkedChild>>> listChildren() async {
    final result = await _api.get('/parents/children');
    return switch (result) {
      Success(:final value) => Success(
          (value['data'] as List<dynamic>)
              .map((e) => LinkedChild.fromJson(e as Map<String, dynamic>))
              .toList(growable: false),
        ),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  @override
  Future<Result<void>> unlinkChild(int studentId) async {
    final result = await _api.delete('/parents/children/$studentId');
    return switch (result) {
      Success() => const Success(null),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  // previewWeeklyReport: GET /reports/weekly?studentId=&weekStartUtc=
  // generateWeeklyReport: POST /reports/weekly { studentId, weekStartUtc? }
  // listReports: GET /reports
  // getReport: GET /reports/:id
  // exportReport: POST /reports/:id/export
}
```

Match `ApiClient.delete` signature used elsewhere in the project. If delete returns `Map`, unwrap `data` the same way as other repos.

- [ ] **Step 4: Run tests — expect PASS**

- [ ] **Step 5: Commit** (optional)

---

### Task 4: Progress child summary

**Files:**
- Modify: `lib/features/progress/domain/repositories/progress_repository.dart`
- Modify: `lib/features/progress/infrastructure/repositories/progress_repository_impl.dart`
- Modify: `test/features/progress/*` or add `test/features/progress/progress_remote_test.dart`

**Interfaces:**
- Produces: `Future<Result<ProgressSummary>> getChildSummary(int studentId, {DateTime? from, DateTime? to})`
- API: `GET /progress/summary/:id?from=&to=`

- [ ] **Step 1: Failing test** — MockClient expects path `/progress/summary/9`, returns ProgressSummary JSON shape matching existing `ProgressSummary.fromJson`.

- [ ] **Step 2: Add method to interface + impl** — build query string only when `from`/`to` non-null (ISO-8601).

- [ ] **Step 3: `flutter test` for progress test — PASS**

---

### Task 5: Parents providers + pages + routes

**Files:**
- Create: `lib/features/parents/presentation/providers/parents_providers.dart`
- Create: `lib/features/parents/presentation/pages/parents_hub_page.dart`
- Create: `lib/features/parents/presentation/pages/link_child_page.dart` (or dialog on hub)
- Create: `lib/features/parents/presentation/pages/child_detail_page.dart`
- Create: `lib/features/parents/presentation/pages/weekly_report_detail_page.dart`
- Modify: `lib/core/routing/app_router.dart`
- Modify: `lib/features/student/presentation/pages/profile_page.dart`

**Interfaces:**
- Consumes: `ParentsRepository`, `ProgressRepository.getChildSummary`, `authSessionProvider`
- Produces: `parentsRepositoryProvider`, `linkedChildrenProvider`, routes `/parents`, `/parents/children/:studentId`, `/parents/reports/:id`

- [ ] **Step 1: Providers**

```dart
final parentsRepositoryProvider = Provider<ParentsRepository>((ref) {
  return ParentsRepositoryImpl(api: ref.watch(apiClientProvider));
});

final linkedChildrenProvider =
    FutureProvider.autoDispose<List<LinkedChild>>((ref) async {
  final result = await ref.watch(parentsRepositoryProvider).listChildren();
  return switch (result) {
    Success(:final value) => value,
    FailureResult(:final failure) => throw failure,
  };
});
```

Wire `apiClientProvider` the same way as other features.

- [ ] **Step 2: `ParentsHubPage`**
  - Watch `linkedChildrenProvider`
  - Empty: CTA “Liên kết học sinh” → push link flow
  - List tiles: displayName ?? email, grade; tap → child detail
  - Unlink: confirm dialog → `unlinkChild` → invalidate provider
  - FAB or AppBar action: link child
  - Use `FeatureListScaffold` / glass patterns from assessments/classrooms

- [ ] **Step 3: Link child**
  - TextField invite code → `linkChild` → toast success → pop + invalidate

- [ ] **Step 4: Child detail**
  - Section Progress: `getChildSummary(studentId)` — reuse progress row widgets if any; else simple stats cards (totalEvents, duration, bySubject)
  - Section Reports: button “Xem tuần này” → `previewWeeklyReport` then “Lưu báo cáo” → `generateWeeklyReport` → navigate to detail; list history via `listReports` filtered by `studentId` client-side

- [ ] **Step 5: Report detail**
  - Show narrative + chart summary numbers
  - Export button → `exportReport` → SnackBar: `Xuất sẵn (bản xem trước)` + show `exportStatus`

- [ ] **Step 6: Student invite on profile**
  - If `authSessionProvider` role is `student`, show GlassCard “Mã mời phụ huynh” with button generating code via `parentsRepositoryProvider.createInviteCode()`, display code + expiry, `Clipboard.setData`

- [ ] **Step 7: Router**
  - Replace ComingSoon at `/parents` with `ParentsHubPage`
  - Add child + report routes
  - In `redirect`, if path starts with `/parents` and `user.role != UserRole.parent`, return `/home`

- [ ] **Step 8: Analyze + tests**

```bash
dart analyze lib/features/parents lib/features/auth lib/features/student lib/core/routing
flutter test test/features/parents test/features/auth/register_with_email_test.dart
```

Expected: no errors; tests PASS

- [ ] **Step 9: Manual smoke**
  1. Register parent + student
  2. Student generates invite on profile
  3. Parent links and sees child
  4. Preview + persist weekly report

- [ ] **Step 10: Commit** (optional)

```bash
git add lib/features/parents lib/features/progress lib/features/student lib/core/routing/app_router.dart test/features/parents
git commit -m "feat(parents): link children, progress, and weekly reports"
```

---

## Slice A acceptance checklist

- [ ] Role picker registers student/parent/teacher
- [ ] Student invite code on profile
- [ ] Parent link / list / unlink
- [ ] Child progress via `/progress/summary/:id`
- [ ] Weekly preview, generate, history, stub export
- [ ] `/parents` role-gated
- [ ] Analyze + remote tests green

## After Slice A

Proceed to [`2026-07-12-phase4-slice-b-teacher-portal.md`](./2026-07-12-phase4-slice-b-teacher-portal.md).
