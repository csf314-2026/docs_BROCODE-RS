# App Requirements

**Project Name: Quiz Scheduler**

**Team Members & Roles:**

1. Rishabh Sahu : SPOC
2. Apoorv Dubey : Scrum Master
3. Parth Langar : Lead Developer
4. Gaurav Srinivas : UX/Documentation
5. Abhinandan Jain : Quality and Testing

**Stakeholder Name & Contact: Prof Arun Raman (araman@goa.bits-pilani.ac.in)**

**Submission Date:**  2026-01-27

## 1. Problem Statement

Currently, faculty members schedule quizzes independently, often leading to "evaluation clusters" where students face multiple high-stakes assessments on a single day. This lack of cross-departmental visibility causes significant student burnout and suboptimal academic performance. There is no centralized system to visualize student workload before a quiz is finalized.

## 2. Stakeholders & Users

| Stakeholder Type | Name / Role | Key Goals | Constraints |
|------------------|-------------|-----------|-------------|
| Primary User     | Faculty / Professors |  Schedule quizzes without clashes; view student availability.  |  Must be faster than manual email coordination.  |
| Secondary User   | Students | View an aggregated timeline of all upcoming evals. |  Privacy: Should only see their own course evals.  |
| Administrator   | Academic Admin | Oversee department-wide evaluation density. | Data Security: Need to verify data about the enrolments into courses. |

## 3. User Personas

### Persona 1: Prof Arun - Professor Department of EEE 

- Role/Context: Course Instructor for a 300-student EEE course.
- Background: Wants to maintain high standards but notices student performance drops when they have other midterms on the same day.
- Goals: Find the "path of least resistance" for a quiz date.
- Tech Comfort: Moderate; prefers clean, web-based dashboards.
- Device & Connectivity: Has a good internet connection and multiple devices on various platforms.
- Pain Point: Receiving dozens of emails from students asking to reschedule because of "clashes."

### Persona 2: Ram - Student at BITS Pilani KK Birla Goa Campus

- Role/Context: 2nd Year Engineering Student taking 8 courses.
- Background: Balances club activities with a heavy academic load.
- Goals: To see all deadlines in one place to plan study sessions.
- Tech Comfort: High; expects mobile-friendly views and notifications.
- Device & Connectivity: Has a Laptop and a smartphone with good internet access.
- Pain Point: Finding out about a "surprise" or newly scheduled quiz only 48 hours in advance. Also has to coordinate with professors about quiz clashes.


## 4. Core User Scenarios

### Scenario 1: Scheduling a Quiz 

- When: Two weeks before the intended quiz date, in the professor's office.
- Who: Prof Arun
- Goal: Select a Tuesday slot that doesn't overlap with already scheduled quizes of other CDCs and electives.

Steps:  

1. logs in and selects "Create New Quiz."
2. selects her course "CS F301" and the specific student section.
3. he app displays a Calendar Heatmap. Tuesday the 10th is "Red" (2 quizzes already scheduled). Wednesday the 11th is "Green" (0 quizzes).
4. selects Wednesday, enters the time (4:00 PM), and hits "Publish."
(Add more if required.)

Why this matters: It prevents the professor from unintentionally causing a student "meltdown" and reduces the need for rescheduling later.

### Scenario 2: Student viewing upcoming quizzes

- When: At the start of the week
- Who: Aarav (Student)
- Goal: Understand upcoming academic workload

Steps:

1. Student logs in
2. Views a consolidated list/calendar of quizzes
3. Identifies busy days

Why this matters: Helps students plan study time and reduce anxiety.

### Scenario 3: Admin importing enrollment data

- When: At the beginning of a semester
- Who: Academic Admin
- Goal: Ensure correct course-student mappings

Steps:

1. Admin uploads enrollment data
2. System validates and stores the data securely
3. App updates access and visibility accordingly

Why this matters: Ensures accuracy and data privacy across the system.


## 5. Functional Requirements (User Stories)

### Story 1 (High): Dashboard Visualization

As a professor, I want to see a calendar view of my students' existing quizzes so that I can identify free slots.

Acceptance Criteria:  

- [ ] Given a selected student section, when I view the calendar, then I should see color-coded indicators of quiz density per day.

### Story 2 (High): Quiz Creation
As a professor, I want to input quiz details (Date, Time, Duration, Venue) to the system.

Acceptance Criteria:

- [ ] Given valid details, when I click 'Submit', then the event is saved and visible to all associated students and faculty.

### Story 3 (Med): Conflict Alert
As a professor, I want the system to warn me if I try to schedule a quiz on a day that already has 2+ evaluations.

Acceptance Criteria:

- [ ] Given a date with 2 existing evals, when I attempt to save a 3rd, then a warning pop-up appears.

### Story 4 (High): Student Personal Timeline
As a student, I want to see an aggregated list of quizzes only for the courses I am registered in.

Acceptance Criteria:

- [ ] Given a student login, when they open the app, then they see a chronological list of their specific upcoming quizzes.

### Story 5 (Low): Export to Calendar
As a user, I want to sync these quizzes to my Google/Outlook calendar.

Acceptance Criteria:

- [ ] Given a quiz entry, when I click 'Sync', then an .ics file is generated or a direct API sync is triggered.

## 6. Non‑Functional Requirements

| Attribute      | Requirement | Rationale |
|----------------|-------------|-----------|
| Performance    |      Calendar should load in < 2 seconds.       |     Professors will stop using it if it's slow during meetings.      |
| Reliability    |      99 % uptime during mid-term and end-term weeks.      |     Critical periods where scheduling is most frequent.      |
| Security       |      Only authenticated faculty can edit/add quizzes.       |     Prevent unauthorized changes or "prank" quiz entries.      |
| Accessibility  |      Mobile-friendly UI       |      Faculty on the move     |
|Scalability| Support multiple departments |	Future expansion |
| Usability |	Minimal steps for key tasks |	Busy faculty users |

## 7. Out of Scope

1. Grading/LMS: The app will not host quiz questions or store grades.

2. Attendance: No tracking of student attendance during the quiz.

3. Proctoring: No features for online exam monitoring.

4. Venue Booking: The app shows the venue but does not handle the physical booking/locking of classrooms.