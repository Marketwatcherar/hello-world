# Data-Driven Education App: Implementation Package

This document provides:
1. A concrete PostgreSQL schema (DDL).
2. A minimal API contract.
3. Exact UI form structures optimized for fast teacher data entry on web + mobile.
4. Beginner-friendly fix for: `rg --files -g 'AGENTS.md'` returning no files.

---

## 1) PostgreSQL Schema (DDL)

> Notes:
> - Uses UUID primary keys.
> - Uses strict constraints for data quality.
> - Separates core entities from event records.
> - Ready for online/offline sync with `client_record_uuid` and timestamps.

```sql
-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =========================
-- Core org/school structure
-- =========================

CREATE TABLE schools (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  timezone TEXT NOT NULL DEFAULT 'UTC',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE classes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  grade_level SMALLINT NOT NULL CHECK (grade_level BETWEEN 1 AND 12),
  school_year TEXT NOT NULL, -- e.g. 2026-2027
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(school_id, name, school_year)
);

CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('teacher','admin','counselor','principal')),
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE teacher_class_assignments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  teacher_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  class_id UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
  subject TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(teacher_id, class_id, subject)
);

-- =========================
-- Student model
-- =========================

CREATE TABLE students (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  external_student_id TEXT NOT NULL,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  date_of_birth DATE,
  gender TEXT,
  language_preference TEXT,
  enrollment_status TEXT NOT NULL DEFAULT 'active' CHECK (enrollment_status IN ('active','inactive','graduated','transferred')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(school_id, external_student_id)
);

CREATE TABLE student_class_enrollments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  class_id UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
  start_date DATE NOT NULL,
  end_date DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(student_id, class_id, start_date)
);

-- =========================
-- Academic model
-- =========================

CREATE TABLE subjects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  code TEXT NOT NULL,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(school_id, code)
);

CREATE TABLE grading_periods (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  label TEXT NOT NULL,              -- Term 1, Semester 1, etc.
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  CHECK (start_date <= end_date),
  UNIQUE(school_id, label, start_date)
);

CREATE TABLE assessments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  class_id UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
  subject_id UUID NOT NULL REFERENCES subjects(id) ON DELETE RESTRICT,
  grading_period_id UUID REFERENCES grading_periods(id) ON DELETE SET NULL,
  assessment_type TEXT NOT NULL CHECK (assessment_type IN ('exam','quiz','homework','project','oral','other')),
  title TEXT NOT NULL,
  max_score NUMERIC(6,2) NOT NULL CHECK (max_score > 0),
  assessment_date DATE NOT NULL,
  created_by UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE grade_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_record_uuid UUID NOT NULL,
  student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  assessment_id UUID NOT NULL REFERENCES assessments(id) ON DELETE CASCADE,
  score NUMERIC(6,2) NOT NULL CHECK (score >= 0),
  comment TEXT,
  entered_by UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  entered_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(student_id, assessment_id),
  UNIQUE(client_record_uuid)
);

CREATE TABLE skill_scores (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_record_uuid UUID NOT NULL,
  student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  grading_period_id UUID NOT NULL REFERENCES grading_periods(id) ON DELETE CASCADE,
  reading_score NUMERIC(5,2) CHECK (reading_score BETWEEN 0 AND 100),
  writing_score NUMERIC(5,2) CHECK (writing_score BETWEEN 0 AND 100),
  listening_score NUMERIC(5,2) CHECK (listening_score BETWEEN 0 AND 100),
  speaking_score NUMERIC(5,2) CHECK (speaking_score BETWEEN 0 AND 100),
  term_average NUMERIC(5,2) CHECK (term_average BETWEEN 0 AND 100),
  entered_by UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  entered_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(student_id, grading_period_id),
  UNIQUE(client_record_uuid)
);

-- =========================
-- Attendance model
-- =========================

CREATE TABLE attendance_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_record_uuid UUID NOT NULL,
  student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  class_id UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
  attendance_date DATE NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('present','absent','tardy')),
  absence_type TEXT CHECK (absence_type IN ('excused','unexcused')),
  minutes_late SMALLINT CHECK (minutes_late >= 0),
  note TEXT,
  entered_by UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  entered_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(student_id, class_id, attendance_date),
  UNIQUE(client_record_uuid)
);

-- =========================
-- Behavior model
-- =========================

CREATE TABLE behavior_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_record_uuid UUID NOT NULL,
  student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  class_id UUID REFERENCES classes(id) ON DELETE SET NULL,
  event_date DATE NOT NULL,
  participation_rating SMALLINT CHECK (participation_rating BETWEEN 1 AND 5),
  attitude_rating SMALLINT CHECK (attitude_rating BETWEEN 1 AND 5),
  punctuality_rating SMALLINT CHECK (punctuality_rating BETWEEN 1 AND 5),
  incident_severity TEXT CHECK (incident_severity IN ('none','minor','moderate','major')),
  incident_context TEXT,
  follow_up_action TEXT,
  entered_by UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  entered_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(client_record_uuid)
);

-- =========================
-- Family feedback model
-- =========================

CREATE TABLE family_feedback (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_record_uuid UUID NOT NULL,
  student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  feedback_date DATE NOT NULL,
  engagement_rating SMALLINT CHECK (engagement_rating BETWEEN 1 AND 5),
  satisfaction_rating SMALLINT CHECK (satisfaction_rating BETWEEN 1 AND 5),
  communication_rating SMALLINT CHECK (communication_rating BETWEEN 1 AND 5),
  open_comment TEXT,
  submitted_by_name TEXT,
  submitted_by_relation TEXT,
  entered_by UUID REFERENCES users(id) ON DELETE SET NULL,
  entered_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(client_record_uuid)
);

-- =========================
-- Sync and audit helpers
-- =========================

CREATE TABLE sync_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id TEXT NOT NULL,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  payload_count INTEGER NOT NULL CHECK (payload_count >= 0),
  success_count INTEGER NOT NULL CHECK (success_count >= 0),
  failed_count INTEGER NOT NULL CHECK (failed_count >= 0),
  synced_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  entity_name TEXT NOT NULL,
  entity_id UUID NOT NULL,
  action TEXT NOT NULL CHECK (action IN ('create','update','delete','view_sensitive')),
  changed_fields JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_attendance_student_date ON attendance_records(student_id, attendance_date);
CREATE INDEX idx_behavior_student_date ON behavior_records(student_id, event_date);
CREATE INDEX idx_grade_student_assessment ON grade_entries(student_id, assessment_id);
CREATE INDEX idx_feedback_student_date ON family_feedback(student_id, feedback_date);
```

---

## 2) Minimal API Contract (REST)

Base URL: `/api/v1`
Auth: `Authorization: Bearer <JWT>`

### 2.1 Common rules

- Every write request includes `client_record_uuid` for idempotency (offline-safe).
- Server responds with `server_received_at`, `record_id`, and validation issues if any.
- Validation errors use `422 Unprocessable Entity`.

Standard error format:

```json
{
  "error": "validation_error",
  "message": "Score must be between 0 and max_score",
  "field_errors": {
    "score": ["must be <= 20"]
  }
}
```

### 2.2 Essential endpoints

#### Auth/User context
- `POST /auth/login`
- `GET /me`

#### Reference data
- `GET /schools/:schoolId/classes?teacher_id=...`
- `GET /schools/:schoolId/students?class_id=...`
- `GET /schools/:schoolId/subjects`
- `GET /schools/:schoolId/grading-periods`

#### Academic
- `POST /assessments`
- `POST /grade-entries/bulk`
- `POST /skill-scores/bulk`

`POST /grade-entries/bulk` request example:
```json
{
  "assessment_id": "5d8e9f53-1d9b-4f95-9a01-2c5eb77ab120",
  "entries": [
    {
      "client_record_uuid": "20ea7459-42d9-4c6f-81d0-0f0e1885c4f1",
      "student_id": "e8eb5cc5-c18b-4f8f-a7f1-3c05e86d1b5f",
      "score": 16.5,
      "comment": "Strong progress"
    }
  ]
}
```

#### Attendance
- `POST /attendance/bulk`
- `GET /attendance?class_id=...&date=...`

`POST /attendance/bulk` request example:
```json
{
  "class_id": "f8477a6a-3686-4f86-8a1d-6c3378f3ddf8",
  "attendance_date": "2026-09-14",
  "records": [
    {
      "client_record_uuid": "d1f9e4f8-59be-4ad8-8b28-a1b9f0cd4e7d",
      "student_id": "e8eb5cc5-c18b-4f8f-a7f1-3c05e86d1b5f",
      "status": "tardy",
      "absence_type": null,
      "minutes_late": 10,
      "note": "Bus delay"
    }
  ]
}
```

#### Behavior
- `POST /behavior-records`
- `POST /behavior-records/bulk`
- `GET /behavior-records?student_id=...&from=...&to=...`

#### Family feedback
- `POST /family-feedback`
- `GET /family-feedback?student_id=...`

#### Sync
- `POST /sync/push`
- `POST /sync/pull`

`POST /sync/push` request example:
```json
{
  "device_id": "tablet-room-4",
  "last_synced_at": "2026-09-14T08:10:00Z",
  "changes": {
    "attendance_records": [],
    "grade_entries": [],
    "behavior_records": [],
    "family_feedback": []
  }
}
```

---

## 3) Exact UI Form Structure (Teacher Speed: Web + Mobile)

Design objective: complete core classroom entry tasks in <2 minutes/class.

### 3.1 Navigation pattern

- Top-level tabs (both web/mobile):
  1. **Attendance**
  2. **Grades**
  3. **Behavior**
  4. **Family Feedback**
  5. **Sync Status**

- Class selector pinned at top: `School Year` → `Class` → `Subject`.
- Date picker defaults to today.

### 3.2 Attendance form (fast roster mode)

**Layout:** one-row-per-student roster.

Fields per row:
- Student name (read-only)
- Status segmented control: `Present | Absent | Tardy`
- If Absent: absence type chips `Excused | Unexcused`
- If Tardy: numeric input `Minutes late`
- Optional note icon opens short text area

Fast actions:
- `Mark all Present`
- `Apply previous day pattern`
- Keyboard shortcuts (web): `P/A/T`, arrow down next student
- Swipe actions (mobile): right=present, left=absent

Validation:
- `minutes_late` required if status=tardy
- `absence_type` required if status=absent

CTA buttons:
- `Save Draft (offline)`
- `Submit & Sync`

### 3.3 Grades form (assessment + bulk scores)

**Step 1: Assessment header card**
- Subject (dropdown)
- Assessment type (exam/quiz/homework/project/oral/other)
- Title
- Date
- Max score

**Step 2: Student score grid**
Per student row:
- Score input (numeric)
- Quick rubric chips (optional): `Below`, `Basic`, `Proficient`, `Advanced`
- Comment icon for short note

Validation:
- Score must be `0 <= score <= max_score`
- highlight out-of-range instantly

Fast actions:
- Autofill repeated value
- Paste-from-clipboard (web)
- Next-empty navigation

### 3.4 Academic skills form (reading/writing/listening/speaking)

Fields per student:
- Reading score (0–100)
- Writing score (0–100)
- Listening score (0–100)
- Speaking score (0–100)
- Term average (auto-calculated, editable with reason)

Section behavior:
- Collapsible “Skill details” under each student
- Batch mode: apply same score range template if needed

### 3.5 Behavior form

Per student event card:
- Date
- Participation rating (1–5 stars)
- Attitude rating (1–5)
- Punctuality rating (1–5)
- Incident severity (`None/Minor/Moderate/Major`)
- Incident context (short text)
- Follow-up action (short text)

Fast actions:
- “Positive note quick add” template chips
- Duplicate last record for next student

### 3.6 Family feedback form

Fields:
- Student
- Feedback date
- Engagement rating (1–5)
- Satisfaction rating (1–5)
- Communication rating (1–5)
- Open comment
- Submitted by name + relation

Input widgets:
- Sliders or segmented buttons for ratings
- voice-to-text on mobile for comments (optional)

### 3.7 Sync status screen (must-have for offline trust)

Panels:
- Connectivity: `Online` / `Offline`
- Queue count by module (Attendance/Grades/Behavior/Feedback)
- Last successful sync timestamp
- Conflict count + “Resolve now” action
- Retry button

Conflict UX:
- Show server vs local value side-by-side
- Button: `Keep Local` / `Keep Server`
- Save resolution to audit log

---

## 4) Beginner-Friendly Fix for `rg --files -g 'AGENTS.md'` returning none

### What this means
This is **not really an error**. It simply means there is currently no file named `AGENTS.md` inside your repository path.

### Step-by-step checks

1. Confirm your current folder:
```bash
pwd
```
You should be in your project root.

2. Check whether any `AGENTS.md` exists in this repo:
```bash
rg --files -g 'AGENTS.md'
```
If it prints nothing, none exists here.

3. Search one level above (if instructions might be outside repo):
```bash
find .. -maxdepth 3 -name 'AGENTS.md'
```

4. If you need one, create it in the repo root:
```bash
cat > AGENTS.md <<'EOF'
# AGENTS.md
Project-specific instructions for coding agents.
EOF
```

5. Verify again:
```bash
rg --files -g 'AGENTS.md'
```
Now it should return `AGENTS.md`.

### Common beginner mistakes
- Running the command from the wrong directory.
- Typo in filename (`Agent.md`, `agents.md`, etc.).
- Expecting every repo to already include an `AGENTS.md`.

---

## 5) Suggested next implementation order (1 week sprint)

1. Create DB with DDL above.
2. Implement auth + reference endpoints.
3. Implement attendance bulk endpoint + roster UI.
4. Implement grades assessment + bulk entry.
5. Add local storage queue + `/sync/push`.
6. Add behavior/family forms.
7. Add sync status + conflict UI.
8. Add audit logging + role restrictions.


---

## 6) Next Steps to Visualize the App and Test It (Beginner-Friendly)

This section assumes you want the **fastest path** to actually see screens running and test end-to-end.

### 6.1 Choose a starter stack (simple and practical)

Use this stack first:
- Frontend (web + mobile-friendly): **React + Vite + PWA**
- Backend API: **Node.js + Express + TypeScript**
- Database: **PostgreSQL**
- Local tools: **Docker Desktop** + **VS Code**

Why this stack?
- Easy to start.
- Huge tutorials/community.
- Works well with offline-first patterns.

### 6.2 Install required tools (one-time setup)

1. Install **Git**.
2. Install **Node.js LTS** (includes npm).
3. Install **Docker Desktop**.
4. Install **VS Code**.
5. Optional but useful: install **Postman** (for API testing).

Quick checks (run in terminal):
```bash
git --version
node --version
npm --version
docker --version
```

If any command fails, install that tool first and retry.

### 6.3 Create project folders

From your project root:
```bash
mkdir -p app/frontend app/backend app/infra
```

Result:
- `app/frontend` for React UI
- `app/backend` for API
- `app/infra` for Docker + DB setup

### 6.4 Start PostgreSQL with Docker (local database)

Create file: `app/infra/docker-compose.yml`

```yaml
version: '3.9'
services:
  postgres:
    image: postgres:16
    container_name: edu_postgres
    environment:
      POSTGRES_USER: edu_user
      POSTGRES_PASSWORD: edu_pass
      POSTGRES_DB: edu_db
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
```

Start database:
```bash
cd app/infra
docker compose up -d
docker compose ps
```

You should see container `edu_postgres` running.

### 6.5 Apply the schema (DDL)

1. Copy the SQL DDL section (from this document) into `app/infra/schema.sql`.
2. Run:
```bash
docker exec -i edu_postgres psql -U edu_user -d edu_db < app/infra/schema.sql
```

Verify tables created:
```bash
docker exec -it edu_postgres psql -U edu_user -d edu_db -c "\dt"
```

### 6.6 Build and run backend API

Create backend app:
```bash
cd /workspace/hello-world/app/backend
npm init -y
npm install express cors helmet pg zod dotenv
npm install -D typescript ts-node-dev @types/node @types/express
npx tsc --init
```

Create `.env` in `app/backend`:
```env
PORT=4000
DATABASE_URL=postgresql://edu_user:edu_pass@localhost:5432/edu_db
JWT_SECRET=replace_me
```

Create minimal server file (`src/server.ts`) with:
- `GET /api/v1/health` → returns `{ ok: true }`
- `POST /api/v1/attendance/bulk`
- `POST /api/v1/grade-entries/bulk`

Run backend:
```bash
npm run dev
```

If no script exists, add to `package.json`:
```json
"scripts": {
  "dev": "ts-node-dev --respawn --transpile-only src/server.ts"
}
```

Test health endpoint:
```bash
curl http://localhost:4000/api/v1/health
```

### 6.7 Build and run frontend (visualize the app)

Create frontend app:
```bash
cd /workspace/hello-world/app/frontend
npm create vite@latest . -- --template react-ts
npm install
npm install react-router-dom
```

Start frontend:
```bash
npm run dev
```

Open browser at the URL shown (usually `http://localhost:5173`).

Create first screens:
- `/attendance`
- `/grades`
- `/behavior`
- `/family-feedback`
- `/sync-status`

For each screen, start with static form fields exactly as defined in Section 3.

### 6.8 Connect frontend to backend

1. In frontend, create an API service file (example: `src/services/api.ts`).
2. Set backend base URL to `http://localhost:4000/api/v1`.
3. On attendance form submit:
   - collect rows
   - call `POST /attendance/bulk`
4. Show success message if HTTP 200/201.
5. Show inline error messages for HTTP 422.

### 6.9 Add basic offline mode (first working version)

Beginner approach:
1. If API call fails (network issue), store payload in IndexedDB.
2. Show badge in UI: “Pending sync: X”.
3. Add “Sync now” button in Sync Status screen.
4. When online, send queued payloads to `/sync/push`.

Test offline flow:
- Turn off Wi-Fi.
- Submit attendance.
- Confirm record saved locally (queue count increases).
- Turn Wi-Fi on.
- Press “Sync now”.
- Confirm queue decreases to zero.

### 6.10 Manual testing checklist (beginner-friendly)

Run these tests in order:

1. **Database test**
   - Can connect to PostgreSQL.
   - `\dt` lists expected tables.

2. **API health test**
   - `GET /health` returns ok.

3. **Attendance API test**
   - Submit one valid payload.
   - Confirm row appears in `attendance_records`.

4. **Validation test**
   - Send invalid status (e.g. `lateeee`).
   - Confirm API returns 422 and error message.

5. **Frontend visual test**
   - Screen loads.
   - Fields are visible and grouped correctly.

6. **Frontend submit test**
   - Submit form; confirm success toast/message.

7. **Offline queue test**
   - Submit while offline.
   - Confirm pending count.
   - Reconnect and sync.

8. **Conflict test (later)**
   - Edit same record on two devices.
   - Confirm conflict appears in Sync Status.

### 6.11 SQL checks to confirm data really saved

Attendance by date:
```sql
SELECT student_id, class_id, attendance_date, status, absence_type, minutes_late
FROM attendance_records
ORDER BY attendance_date DESC
LIMIT 50;
```

Grades by assessment:
```sql
SELECT student_id, assessment_id, score
FROM grade_entries
ORDER BY entered_at DESC
LIMIT 50;
```

### 6.12 Common beginner errors and fixes

1. **Backend can’t connect to DB**
   - Check container is running: `docker compose ps`
   - Check `DATABASE_URL` values.

2. **CORS error in browser**
   - Enable CORS middleware in Express.

3. **Frontend says Network Error**
   - Confirm backend port is 4000 and running.
   - Confirm base URL is correct.

4. **SQL schema fails**
   - Ensure `pgcrypto` extension line is included.
   - Re-run on a clean database if needed.

5. **No data after submit**
   - Check API logs.
   - Run SQL query directly to verify insert.

### 6.13 Definition of “ready for pilot”

You are ready to pilot in one classroom when:
- Attendance for a full class can be submitted in <2 minutes.
- Grade bulk entry works for at least 30 students.
- Offline save + later sync works reliably.
- Validation catches bad inputs in real time.
- Teacher can complete daily workflow without developer help.
