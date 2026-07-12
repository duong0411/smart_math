# Phase 4 Slice C — Exam Matrices Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans`. Complete **Slices A and B** first. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Teachers fully manage exam matrices (CRUD, outcomes, cells, link assessments, coverage) and tag assessment items to outcomes while authoring.

**Architecture:** New `lib/features/exam_matrices/` feature. Integrate outcome picker into assessment item editor from Slice B. Replace `/exam-matrices` ComingSoon. Teacher hub tile goes live.

**Tech Stack:** Flutter, Riverpod, go_router, `ApiClient`, MockClient tests.

## Global Constraints

- APIs only under `/exam-matrices/*` and `/exam-matrices/item-outcomes`
- Teacher-only (API + route guard)
- No new Workers endpoints
- Commits only if human asks

---

### Task 1: Domain entities + repository

**Files:**
- Create: `lib/features/exam_matrices/domain/entities/exam_matrix.dart`
- Create: `lib/features/exam_matrices/domain/entities/exam_matrix_outcome.dart`
- Create: `lib/features/exam_matrices/domain/entities/exam_matrix_cell.dart`
- Create: `lib/features/exam_matrices/domain/entities/matrix_coverage.dart`
- Create: `lib/features/exam_matrices/domain/repositories/exam_matrices_repository.dart`

**Interfaces:**

```dart
class ExamMatrix {
  const ExamMatrix({
    required this.id,
    required this.ownerId,
    required this.title,
    this.subject,
    this.gradeLevel,
    this.description,
    required this.createdAtUtc,
    required this.updatedAtUtc,
  });
  // fromJson per examMatrixResponseSchema
}

class ExamMatrixOutcome {
  const ExamMatrixOutcome({
    required this.id,
    required this.matrixId,
    required this.code,
    required this.title,
    this.description,
    required this.sortOrder,
    required this.createdAtUtc,
  });
}

class ExamMatrixCell {
  const ExamMatrixCell({
    required this.id,
    required this.matrixId,
    required this.outcomeId,
    required this.itemType, // AssessmentItemType
    required this.targetCount,
    required this.targetPoints,
    required this.sortOrder,
    required this.createdAtUtc,
  });
}

class ExamMatrixDetail {
  const ExamMatrixDetail({
    required this.matrix,
    required this.outcomes,
    required this.cells,
    required this.linkedAssessmentIds,
  });
}

class MatrixCoverageCell {
  const MatrixCoverageCell({
    required this.cellId,
    required this.outcomeId,
    required this.outcomeCode,
    required this.itemType,
    required this.targetCount,
    required this.actualCount,
    required this.targetPoints,
    required this.actualPoints,
    required this.met,
  });
}

class MatrixCoverage {
  const MatrixCoverage({
    required this.matrixId,
    required this.assessmentId,
    required this.cells,
    required this.overallMet,
  });
}

abstract class ExamMatricesRepository {
  Future<Result<List<ExamMatrix>>> list();
  Future<Result<ExamMatrix>> create({
    required String title,
    String? subject,
    int? gradeLevel,
    String? description,
  });
  Future<Result<ExamMatrixDetail>> get(int id);
  Future<Result<ExamMatrix>> update({
    required int id,
    String? title,
    String? subject,
    int? gradeLevel,
    String? description,
  });
  Future<Result<void>> delete(int id);

  Future<Result<ExamMatrixOutcome>> addOutcome({
    required int matrixId,
    required String code,
    required String title,
    String? description,
    int? sortOrder,
  });
  Future<Result<ExamMatrixOutcome>> updateOutcome({
    required int matrixId,
    required int outcomeId,
    String? code,
    String? title,
    String? description,
    int? sortOrder,
  });
  Future<Result<void>> deleteOutcome({
    required int matrixId,
    required int outcomeId,
  });

  Future<Result<ExamMatrixCell>> addCell({
    required int matrixId,
    required int outcomeId,
    required AssessmentItemType itemType,
    int? targetCount,
    double? targetPoints,
    int? sortOrder,
  });
  Future<Result<ExamMatrixCell>> updateCell({
    required int matrixId,
    required int cellId,
    int? outcomeId,
    AssessmentItemType? itemType,
    int? targetCount,
    double? targetPoints,
    int? sortOrder,
  });
  Future<Result<void>> deleteCell({
    required int matrixId,
    required int cellId,
  });

  Future<Result<void>> linkAssessment({
    required int matrixId,
    required int assessmentId,
  });
  Future<Result<void>> unlinkAssessment({
    required int matrixId,
    required int assessmentId,
  });

  Future<Result<MatrixCoverage>> coverage({
    required int matrixId,
    required int assessmentId,
  });

  Future<Result<void>> tagItemOutcome({
    required int assessmentId,
    required int itemId,
    required int outcomeId,
  });
  Future<Result<void>> untagItemOutcome({
    required int assessmentId,
    required int itemId,
    required int outcomeId,
  });
}
```

- [ ] **Step 1: Create all entity + abstract repository files**

- [ ] **Step 2: `dart analyze lib/features/exam_matrices/domain`**

---

### Task 2: Repository impl + MockClient tests

**Files:**
- Create: `lib/features/exam_matrices/infrastructure/repositories/exam_matrices_repository_impl.dart`
- Create: `test/features/exam_matrices/exam_matrices_remote_test.dart`

**Interfaces:**
- Consumes: `ApiClient`
- Paths:
  - `GET/POST /exam-matrices`
  - `GET/PATCH/DELETE /exam-matrices/:id`
  - `POST/PATCH/DELETE /exam-matrices/:id/outcomes[/:outcomeId]`
  - `POST/PATCH/DELETE /exam-matrices/:id/cells[/:cellId]`
  - `POST/DELETE /exam-matrices/:id/assessments[/:assessmentId]`
  - `GET /exam-matrices/:id/coverage?assessmentId=`
  - `POST /exam-matrices/item-outcomes` body `{ assessmentId, itemId, outcomeId }`
  - `DELETE /exam-matrices/item-outcomes?assessmentId=&itemId=&outcomeId=`

- [ ] **Step 1: Failing tests** for `list`, `create`, `get` (detail with outcomes/cells/linkedAssessmentIds), `coverage`, `tagItemOutcome`

Example coverage assertion:

```dart
expect(result.valueOrNull!.overallMet, isFalse);
expect(result.valueOrNull!.cells.first.outcomeCode, 'C1');
```

- [ ] **Step 2: Implement `ExamMatricesRepositoryImpl`**

- [ ] **Step 3: Tests PASS**

---

### Task 3: Matrix list + detail editors UI

**Files:**
- Create: `lib/features/exam_matrices/presentation/providers/exam_matrices_providers.dart`
- Create: `lib/features/exam_matrices/presentation/pages/exam_matrices_page.dart`
- Create: `lib/features/exam_matrices/presentation/pages/exam_matrix_detail_page.dart`
- Create: `lib/features/exam_matrices/presentation/pages/matrix_coverage_page.dart`
- Modify: `lib/core/routing/app_router.dart`
- Modify: `lib/features/teachers/presentation/pages/teachers_hub_page.dart` — matrix tile live

**Interfaces:**
- Providers: `examMatricesRepositoryProvider`, `examMatricesProvider`, `examMatrixDetailProvider(id)`

- [ ] **Step 1: List page**
  - `GET` list; FAB create (title, subject, grade, description)
  - Tap → detail; swipe/delete with confirm → `delete`

- [ ] **Step 2: Detail page sections**
  1. Metadata edit → `update`
  2. Outcomes: add/edit/delete (`code`, `title`, `description`)
  3. Cells: add/edit/delete (`outcomeId`, `itemType`, `targetCount`, `targetPoints`)
  4. Linked assessments: multi-select from owned assessments → `linkAssessment` / unlink
  5. Button “Xem độ phủ” → coverage page (require linked assessment picker)

- [ ] **Step 3: Coverage page**
  - Dropdown of `linkedAssessmentIds`
  - Call `coverage(matrixId, assessmentId)`
  - Show rows with met/not met + `overallMet` banner

- [ ] **Step 4: Routes**
  - `/exam-matrices`, `/exam-matrices/:id`, `/exam-matrices/:id/coverage`
  - Redirect non-teachers to `/home`

- [ ] **Step 5: Analyze presentation**

---

### Task 4: Item → outcome tagging in authoring

**Files:**
- Modify: `lib/features/assessments/presentation/pages/assessment_editor_page.dart` (or item editor sheet)
- Modify: item editor widgets as needed
- Optionally: provider to load matrices that link this assessment

**Interfaces:**
- Consumes: `ExamMatricesRepository.tagItemOutcome` / `untagItemOutcome`
- UX: On item tile menu “Gắn chuẩn” → pick matrix (filtered to those linking this assessmentId) → pick outcome → POST tag; show chips of tagged outcomes if known

- [ ] **Step 1: When editing an item on a linked assessment, show outcome picker**
  - Load `list()` matrices, `get(id)` for each or only those with `linkedAssessmentIds.contains(assessmentId)`
  - Tag / untag buttons

- [ ] **Step 2: After tagging, coverage for that assessment should reflect new counts** (manual verify)

- [ ] **Step 3: Analyze + tests**

```bash
dart analyze lib/features/exam_matrices lib/features/assessments lib/features/teachers
flutter test test/features/exam_matrices/exam_matrices_remote_test.dart
```

- [ ] **Step 4: Update plan docs**
  - Mark Phase 4 acceptance in `.claude/plans/eduself-remaining-features.plan.md`
  - Optional: tick overall checklist in design spec

---

## Slice C acceptance checklist

- [ ] Full matrix CRUD + outcomes + cells
- [ ] Link/unlink assessments
- [ ] Coverage view with `overallMet`
- [ ] Item-outcome tagging from authoring
- [ ] Teacher hub matrix tile live; routes role-gated
- [ ] Analyze + tests green

## Phase 4 done when

All checkboxes in design spec “Phase 4 overall acceptance” are satisfied across A+B+C.
