# Phase 4 Parent + Teacher Portals — Plan Index

> **For agentic workers:** Execute **one slice plan at a time**. REQUIRED SUB-SKILL: `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans`.

**Goal:** Ship Flutter Parent and Teacher portals against existing Workers APIs (no new endpoints).

**Architecture:** Portal hubs (`parents/`, `teachers/` shell); extend `classrooms/` + `assessments/`; new `exam_matrices/`. Sequential slices A → B → C.

**Tech Stack:** Flutter, Riverpod, go_router, `ApiClient` + `Result`, Cloudflare Workers API (Hono/D1) already deployed.

**Spec:** [`docs/superpowers/specs/2026-07-12-phase4-parent-teacher-portals-design.md`](../specs/2026-07-12-phase4-parent-teacher-portals-design.md)

## Global Constraints

- No Drift / no new API routes — wire existing `/parents`, `/reports`, `/progress`, `/classrooms`, `/assessments`, `/exam-matrices`
- Feature-first Clean Architecture; business rules not in widgets
- VN user-facing copy; glass + M3 patterns from Phases 1–3
- Commit only when the human asks (plan “Commit” steps are optional checkpoints)
- Validate: `dart analyze lib test` and targeted `flutter test test/features/...`

## Slice plans (execute in order)

| Slice | Plan file | Delivers |
|-------|-----------|----------|
| **A** | [`2026-07-12-phase4-slice-a-parent-portal.md`](./2026-07-12-phase4-slice-a-parent-portal.md) | Role picker, invite code, parent link/children/progress/reports |
| **B** | [`2026-07-12-phase4-slice-b-teacher-portal.md`](./2026-07-12-phase4-slice-b-teacher-portal.md) | Teacher hub, classrooms write, author 5 types, assign, grade |
| **C** | [`2026-07-12-phase4-slice-c-exam-matrices.md`](./2026-07-12-phase4-slice-c-exam-matrices.md) | Full exam matrix CRUD, coverage, item-outcome tagging |

## File map (all slices)

### Create
- `lib/features/parents/**` (domain, infrastructure, presentation)
- `lib/features/teachers/presentation/pages/teachers_hub_page.dart` (+ providers if needed)
- `lib/features/exam_matrices/**`
- `test/features/parents/parents_remote_test.dart`
- `test/features/classrooms/classrooms_teacher_remote_test.dart`
- `test/features/assessments/assessments_authoring_remote_test.dart`
- `test/features/exam_matrices/exam_matrices_remote_test.dart`

### Modify
- `lib/features/auth/domain/usecases/register_with_email.dart` — pass `role`
- `lib/features/auth/presentation/providers/auth_controllers.dart` — `submit(..., role:)`
- `lib/features/auth/presentation/pages/register_page.dart` — role chips
- `lib/features/student/presentation/pages/profile_page.dart` — invite code (student)
- `lib/features/progress/domain/repositories/progress_repository.dart` — `getChildSummary`
- `lib/features/progress/infrastructure/repositories/progress_repository_impl.dart`
- `lib/features/classrooms/domain/repositories/classrooms_repository.dart` — teacher methods
- `lib/features/classrooms/infrastructure/repositories/classrooms_repository_impl.dart`
- `lib/features/classrooms/presentation/**` — create/detail/roster/assign
- `lib/features/assessments/domain/repositories/assessments_repository.dart` — author + grade
- `lib/features/assessments/infrastructure/repositories/assessments_repository_impl.dart`
- `lib/features/assessments/presentation/**` — author + grade pages
- `lib/core/routing/app_router.dart` — replace ComingSoon; role redirects
- `.claude/plans/eduself-remaining-features.plan.md` — mark Phase 4 done when C lands

## Execution handoff

Start with **Slice A** only. After A is green, run B, then C.
