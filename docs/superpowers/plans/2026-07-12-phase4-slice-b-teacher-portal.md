# Phase 4 Slice B — Teacher Hub + Classrooms + Author/Grade Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans`. Complete **Slice A** first. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Teachers create classrooms, author assessments (all 5 item types), assign to classes, view progress, and manually grade essays.

**Architecture:** `teachers/` hub shell only. Extend `classrooms/` and `assessments/` repos/UI. No new API endpoints. Matrix tile stays Coming Soon until Slice C.

**Tech Stack:** Flutter, Riverpod, go_router, `ApiClient`, MockClient tests.

## Global Constraints

- Teacher-only for create/delete assignments (API already enforces)
- Author item `answerKey` shapes must match `api/src/lib/assessment-grading.ts`:
  - `mcq`: `{ "correctOptionId": "<choiceId>" }` + `options.choices: [{id, text}]`
  - `true_false`: `{ "correct": true|false }`
  - `fill_blank`: `{ "acceptedAnswers": ["..."] }`
  - `matching`: `{ "pairs": { "leftId": "rightId", ... } }` + options for left/right labels as API expects
  - `essay`: `answerKey` empty `{}` or rubric notes only (not auto-graded)
- Commits only if human asks
- VN copy; glass UI

---

### Task 1: Teacher hub page + route guard

**Files:**
- Create: `lib/features/teachers/presentation/pages/teachers_hub_page.dart`
- Modify: `lib/core/routing/app_router.dart`

**Interfaces:**
- Produces: `TeachersHubPage` with tiles navigating to `/classrooms`, `/assessments?tab=owned` or `/teachers/assessments`, `/teachers/grading`, `/exam-matrices` (placeholder)

- [ ] **Step 1: Implement hub**

```dart
class TeachersHubPage extends ConsumerWidget {
  const TeachersHubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // AtmosphericBackground + FeatureTile grid:
    // 1. Lớp học -> context.push('/classrooms')
    // 2. Soạn đề -> context.push('/teachers/assessments')
    // 3. Chấm bài -> context.push('/teachers/grading')
    // 4. Ma trận đề -> context.push('/exam-matrices') // ComingSoon until Slice C
  }
}
```

- [ ] **Step 2: Router**
  - Replace `/teachers` ComingSoon with `TeachersHubPage`
  - Redirect if `user.role != UserRole.teacher` → `/home`
  - Add stub routes `/teachers/assessments`, `/teachers/grading`, `/exam-matrices` pointing to ComingSoon or early shells (filled in later tasks)

- [ ] **Step 3: `dart analyze lib/features/teachers lib/core/routing`**

---

### Task 2: Classrooms teacher repository methods + tests

**Files:**
- Modify: `lib/features/classrooms/domain/repositories/classrooms_repository.dart`
- Create: `lib/features/classrooms/domain/entities/classroom_member.dart`
- Create: `lib/features/classrooms/domain/entities/classroom_assignment.dart`
- Create: `lib/features/classrooms/domain/entities/assignment_progress_row.dart`
- Modify: `lib/features/classrooms/infrastructure/repositories/classrooms_repository_impl.dart`
- Create: `test/features/classrooms/classrooms_teacher_remote_test.dart`

**Interfaces:**
- Extends `ClassroomsRepository`:

```dart
Future<Result<ClassroomSummary>> createClassroom(String name);
Future<Result<ClassroomSummary>> getClassroom(int id);
Future<Result<List<ClassroomMember>>> listMembers(int classroomId);
Future<Result<ClassroomMember>> updateMemberGrade({
  required int classroomId,
  required int userId,
  required int? gradeLevel,
});
Future<Result<void>> removeMember({
  required int classroomId,
  required int userId,
});
Future<Result<List<ClassroomAssignment>>> listAssignments(int classroomId);
Future<Result<ClassroomAssignment>> assignAssessment({
  required int classroomId,
  required int assessmentId,
  DateTime? dueAtUtc,
});
Future<Result<void>> deleteAssignment({
  required int classroomId,
  required int assignmentId,
});
Future<Result<List<AssignmentProgressRow>>> assignmentProgress({
  required int classroomId,
  required int assignmentId,
});
```

Entity fields (from API schemas):
- `ClassroomMember`: `id, classroomId, studentId, studentEmail?, gradeLevel?, status, joinedAtUtc`
- `ClassroomAssignment`: match existing assignment response (`id, classroomId, assessmentId, dueAtUtc?, assignedAtUtc, ...`) — read `api/src/schemas/responses/assessment.ts` / classroom assignment schema and mirror exactly
- `AssignmentProgressRow`: `studentId, studentEmail, attemptId?, attemptStatus?, score?, maxScore?, submittedAtUtc?`

- [ ] **Step 1: Failing MockClient tests** for `createClassroom` (POST `/classrooms`), `listMembers` (GET `/classrooms/1/members`), `assignAssessment` (POST `/classrooms/1/assignments` body `{assessmentId, dueAtUtc?}`), `assignmentProgress`.

- [ ] **Step 2: Implement entities + repo methods**

- [ ] **Step 3: `flutter test test/features/classrooms/classrooms_teacher_remote_test.dart` — PASS**

---

### Task 3: Classroom teacher UI

**Files:**
- Modify: `lib/features/classrooms/presentation/pages/classrooms_page.dart`
- Create: `lib/features/classrooms/presentation/pages/classroom_detail_page.dart`
- Create: `lib/features/classrooms/presentation/pages/assignment_progress_page.dart`
- Modify: `lib/features/classrooms/presentation/providers/classrooms_providers.dart`
- Modify: `lib/core/routing/app_router.dart` — `/classrooms/:id`, `/classrooms/:id/assignments/:assignmentId/progress`

**Interfaces:**
- Consumes: extended `ClassroomsRepository`, `authSessionProvider.role`

- [ ] **Step 1: List page role branches**
  - Teacher: FAB “Tạo lớp” → dialog name → `createClassroom` → show join code dialog (copy) → invalidate list
  - Student: keep join dialog (existing)

- [ ] **Step 2: Detail page (teacher)**
  - Tabs or sections: Roster | Assignments
  - Roster: list members; edit grade (GradeLevelSelector); remove with confirm
  - Assignments: list; FAB assign → pick from owned published assessments (`GET /assessments` filtered `status==published`); optional due date; POST assign
  - Row action: Progress → progress page; Delete assignment

- [ ] **Step 3: Progress page**
  - Table/list of `AssignmentProgressRow`
  - If `attemptId != null` and status submitted/graded → navigate to grading (`/teachers/grading/attempts/:attemptId`)

- [ ] **Step 4: Analyze + manual create/join smoke**

---

### Task 4: Assessment authoring repository + tests

**Files:**
- Modify: `lib/features/assessments/domain/repositories/assessments_repository.dart`
- Modify: `lib/features/assessments/infrastructure/repositories/assessments_repository_impl.dart`
- Create: `test/features/assessments/assessments_authoring_remote_test.dart`
- Possibly extend: `lib/features/assessments/domain/entities/assessment_models.dart` if create/update payloads need DTOs

**Interfaces:**

```dart
Future<Result<AssessmentSummary>> createAssessment({
  required String title,
  String? subject,
  int? gradeLevel,
});
Future<Result<AssessmentSummary>> updateAssessment({
  required int id,
  String? title,
  String? subject,
  int? gradeLevel,
});
Future<Result<AssessmentSummary>> publishAssessment(int id);
Future<Result<AssessmentItem>> addItem({
  required int assessmentId,
  required AssessmentItemType itemType,
  required String prompt,
  Map<String, dynamic>? options,
  required Map<String, dynamic> answerKey,
  double? points,
  int? sortOrder,
});
Future<Result<AssessmentItem>> updateItem({
  required int assessmentId,
  required int itemId,
  String? prompt,
  Map<String, dynamic>? options,
  Map<String, dynamic>? answerKey,
  double? points,
  int? sortOrder,
  AssessmentItemType? itemType,
});
Future<Result<void>> deleteItem({
  required int assessmentId,
  required int itemId,
});
Future<Result<AssessmentAttempt>> gradeAnswer({
  required int attemptId,
  required int answerId,
  required double pointsAwarded,
  String? feedback,
  bool? isCorrect,
});
```

- [ ] **Step 1: Failing tests** — create assessment POST `/assessments`; addItem POST `/assessments/5/items` with mcq body; publish POST `/assessments/5/publish`; gradeAnswer PATCH `/assessments/attempts/42/answers/7`.

- [ ] **Step 2: Implement methods** — parse responses with existing `fromJson` helpers; for owner detail, `answerKey` is present on items (student view strips it).

- [ ] **Step 3: Tests PASS**

---

### Task 5: Authoring UI (all 5 item types)

**Files:**
- Create: `lib/features/assessments/presentation/pages/teacher_assessments_page.dart`
- Create: `lib/features/assessments/presentation/pages/assessment_editor_page.dart`
- Create: `lib/features/assessments/presentation/widgets/item_editors/` (`mcq_item_editor.dart`, `true_false_item_editor.dart`, `fill_blank_item_editor.dart`, `matching_item_editor.dart`, `essay_item_editor.dart`)
- Modify: `lib/core/routing/app_router.dart` — wire `/teachers/assessments`, `/teachers/assessments/:id/edit`

**Interfaces:**
- Each editor produces `{ itemType, prompt, options?, answerKey, points }` for `addItem`/`updateItem`

- [ ] **Step 1: Teacher assessments list**
  - `listAssessments()` owned only
  - FAB create → dialog title/subject/grade → `createAssessment` → open editor
  - Tile shows status chip (draft/published/archived)

- [ ] **Step 2: Editor page**
  - Load `getAssessment(id)`
  - Edit metadata → `updateAssessment`
  - List items; add via type picker dialog
  - Per-type editors:
    - **MCQ:** N choices with ids `a,b,c,...`; select correct → `correctOptionId`
    - **True/false:** toggle correct bool
    - **Fill blank:** comma/newline accepted answers list
    - **Matching:** editable left/right pairs map
    - **Essay:** prompt + points only; `answerKey: {}`
  - Publish button → `publishAssessment` (API requires ≥1 item); show API error toast if fails
  - Draft only editable; if published, show read-only or limited edit per API behavior

- [ ] **Step 3: Analyze authoring files**

---

### Task 6: Grading UI

**Files:**
- Create: `lib/features/assessments/presentation/pages/teacher_grading_page.dart`
- Create: `lib/features/assessments/presentation/pages/grade_attempt_page.dart`
- Modify: router `/teachers/grading`, `/teachers/grading/attempts/:attemptId`

**Interfaces:**
- Consumes: `assignmentProgress`, `getAttempt`, `gradeAnswer`

- [ ] **Step 1: Grading hub**
  - List teacher classrooms → pick classroom → pick assignment → show progress rows needing grade (`attemptStatus == submitted` or answers with null points)
  - Simpler MVP: entry from assignment progress only + deep link; hub lists recent classrooms with CTA “Chọn lớp → đề”

- [ ] **Step 2: Grade attempt page**
  - `getAttempt(attemptId)` — show each answer
  - Objective: display auto score read-only
  - Essay / null `pointsAwarded`: form score + feedback → `gradeAnswer`
  - After each grade, refresh attempt; show running score/maxScore

- [ ] **Step 3: Tests + analyze**

```bash
dart analyze lib/features/teachers lib/features/classrooms lib/features/assessments
flutter test test/features/classrooms/classrooms_teacher_remote_test.dart test/features/assessments/assessments_authoring_remote_test.dart
```

- [ ] **Step 4: Manual E2E**
  1. Teacher creates class + join code
  2. Student joins
  3. Teacher authors MCQ + essay, publishes, assigns
  4. Student takes + submits
  5. Teacher grades essay; score updates

---

## Slice B acceptance checklist

- [ ] Teacher hub role-gated
- [ ] Create classroom + roster + assign/unassign + progress
- [ ] Author all 5 item types + publish
- [ ] Grade essay via PATCH answers
- [ ] Matrix tile still placeholder until Slice C
- [ ] Analyze + tests green

## After Slice B

Proceed to [`2026-07-12-phase4-slice-c-exam-matrices.md`](./2026-07-12-phase4-slice-c-exam-matrices.md).
