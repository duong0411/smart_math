# Phase 4 Design: Parent + Teacher Portals

**Date:** 2026-07-12  
**Status:** Approved (conversational design §§1–4)  
**Source plan:** `.claude/plans/eduself-remaining-features.plan.md`  
**PRD:** `spec.jpg`, `spec.docx`

## Goal

Ship Flutter UI for Parent and Teacher portals against **existing** Workers APIs. No new backend endpoints. Sequential mergeable slices with register role picker in Slice A.

## Constraints

- Feature-first Clean Architecture + Riverpod; `ApiClient` only (no Drift)
- Domain owns role/access messaging; widgets call providers/use cases
- Role gates enforced in UI routes; API already enforces in services
- Out of scope: classroom rename/delete, AI essay grading, real PDF export, AI report narrative

## Approach

**Portal hubs (Approach 1):** dedicated `parents/` and `teachers/` (hub shell); extend `classrooms/` and `assessments/`; new `exam_matrices/`. Avoid duplicating student take-flow code under `teachers/`.

## Architecture

| Package | Responsibility |
|---------|----------------|
| `auth` | Register role picker (`student` \| `parent` \| `teacher`) |
| `parents` | Link child, children list, child progress, weekly reports |
| `student` | Parent invite-code generation on profile |
| `teachers` | Hub shell tiles only |
| `classrooms` | Create class, roster, assign/unassign, assignment progress |
| `assessments` | Author (all 5 item types), publish, manual/essay grade |
| `exam_matrices` | Full matrix CRUD, coverage, item-outcome tagging |

### Ship order

1. **Slice A** — Role picker + Parent portal + student invite code  
2. **Slice B** — Teacher hub + classrooms + author all 5 types + assign + grade  
3. **Slice C** — Exam matrices (full depth)

---

## Slice A — Role picker + Parent portal

### Register

- Segmented control / chips: Học sinh · Phụ huynh · Giáo viên
- Pass `role` into existing `AuthRepository.register`
- Role immutable after signup (no change-role UI)

### Student invite code

- Profile (student only): “Mã mời phụ huynh” → `POST /parents/invite-codes`
- Display code + expiry; copy to clipboard; short VN share hint

### Parent hub (`/parents`)

| Screen | APIs |
|--------|------|
| Children list | `GET /parents/children`; unlink `DELETE /parents/children/:studentId` |
| Link child | `POST /parents/link` `{ inviteCode }` |
| Child progress | `GET /progress/summary/:studentId` (optional `from`/`to`) |
| Weekly preview | `GET /reports/weekly?studentId=` (+ optional `weekStartUtc`) |
| Persist report | `POST /reports/weekly` |
| Report history | `GET /reports` |
| Report detail | `GET /reports/:id`; export stub `POST /reports/:id/export` |

### Route guard

- `/parents` → `UserRole.parent` only; others redirect home

### Acceptance (A)

- Register as student/parent/teacher works
- Student invite → parent link → children list
- Parent views child progress + weekly preview/persist/history
- Analyze + remote smoke tests green

---

## Slice B — Teacher hub + classrooms + author/grade

### Teacher hub (`/teachers`)

Glass tiles:

1. Lớp học → `/classrooms`
2. Soạn đề → owned assessments / authoring entry
3. Chấm bài → grading queue via assignment progress
4. Ma trận đề → `/exam-matrices` (placeholder until Slice C)

Route guard: `teacher` only.

### Classrooms (extend)

| Action | API |
|--------|-----|
| Create | `POST /classrooms` `{ name }` → show `joinCode` |
| Detail | `GET /classrooms/:id` |
| Roster | `GET .../members`; `PATCH` grade; `DELETE` member |
| Assignments | `GET/POST/DELETE .../assignments` |
| Progress | `GET .../assignments/:assignmentId/progress` |

Student join flow unchanged. Member goals UI optional / defer if timeboxed.

### Assessment authoring (extend)

| Flow | API |
|------|-----|
| Create draft | `POST /assessments` |
| Metadata | `PATCH /assessments/:id` |
| Items CRUD | `POST/PATCH/DELETE .../items` |
| Publish | `POST .../publish` |

**Item types (all five):** `mcq`, `true_false`, `fill_blank`, `matching`, `essay` — `answerKey` shapes must match API grading lib. Reuse student item widgets where practical; author mode edits keys/options.

### Grading

- Assignment progress → attempt detail `GET /assessments/attempts/:attemptId`
- Manual/essay: `PATCH .../answers/:answerId` `{ pointsAwarded, feedback?, isCorrect? }`
- Objective items auto-graded on submit (existing API)

### Acceptance (B)

- Teacher creates class; student joins; teacher assigns published đề
- Teacher authors all 5 types and publishes
- Teacher grades essays; score updates
- Analyze + tests green

---

## Slice C — Exam matrices (full)

### Feature `exam_matrices/`

| Screen | APIs |
|--------|------|
| List / create | `GET/POST /exam-matrices` |
| Detail / edit / delete | `GET/PATCH/DELETE /exam-matrices/:id` |
| Outcomes | `POST/PATCH/DELETE .../outcomes` |
| Cells | `POST/PATCH/DELETE .../cells` |
| Link assessments | `POST/DELETE .../assessments` |
| Coverage | `GET .../coverage?assessmentId=` |
| Item-outcome tags | `POST/DELETE /exam-matrices/item-outcomes` |

### Authoring integration

- Item editor: optional outcome picker when assessment is linked to a matrix
- Coverage: select linked assessment → show target vs actual / `overallMet`

### Acceptance (C)

- Full matrix CRUD + coverage + item tagging
- Teacher hub matrix tile live
- Analyze + tests green

---

## Phase 4 overall acceptance

- [x] Register role picker (student / parent / teacher)
- [x] Parent: invite → link → children → progress → weekly reports (stub export OK)
- [x] Teacher: create class, roster, assign/unassign, assignment progress
- [x] Teacher: author all 5 item types, publish, grade essays
- [x] Teacher: full exam matrix CRUD + coverage + item-outcome tags
- [x] Role-gated routes; no new API endpoints
- [x] `dart analyze` + targeted remote tests green

## Non-goals

- Classroom rename/delete
- AI essay auto-grading
- Real PDF report export / queue
- AI-generated weekly narrative (server stub OK)
- Curriculum topic create UI (`POST /curriculum/topics`) — not required for Phase 4

## Validation

```bash
cd api && bun run typecheck
cd .. && dart analyze lib test && flutter test
```

## Risks

| Risk | Mitigation |
|------|------------|
| Authoring UI for 5 item types is large | Mirror student item widgets; ship editors alongside take UI shapes |
| Scope creep into goals / curriculum write | Explicitly deferred above |
| Parent/teacher register untested in app | Slice A includes role picker + smoke tests |
| Stub export confuses users | VN copy: “Xuất sẵn (bản xem trước)” — no fake PDF download |
