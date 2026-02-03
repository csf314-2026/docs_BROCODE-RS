# Sprint Goals: Quiz Scheduler

## Current Sprint: Sprint 1 (Weeks 1–2)

### **Sprint Goal**
> **"Professors can securely log in and visualize student evaluation density on a calendar so they can identify conflict-free dates for new quizzes."**

### **Definition of Done (Testable Outcomes)**
To consider this sprint successful, the following must be verifiable by the stakeholder:
* **Authentication:** A user can log in using a `@bits-goa.ac.in` Google account and is redirected to a personalized dashboard.
* **Persistence:** A user remains logged into the app/web interface after closing and reopening the browser/application.
* **Heatmap Visualization:** A professor can view a calendar where dates are color-coded (Green/Yellow/Red) based on the number of existing quizzes for a specific student group.
* **Data Integrity:** The heatmap correctly reflects a mock dataset of at least 5 overlapping course schedules.

---

## Future Sprint Roadmap

### **Sprint 2 (Weeks 3–4): Core Action**
**Goal:** "Professors can publish and edit quiz schedules so that students see an up-to-date personal timeline of their upcoming assessments."
* *Focus:* Enabling the "Write" side of the database and the student-facing dashboard.

### **Sprint 3 (Weeks 5–6): Communication & Alerts**
**Goal:** "Students receive automated mobile notifications and 24-hour reminders so they never miss a newly scheduled or upcoming quiz."
* *Focus:* Integrating Firebase Cloud Messaging (FCM) and background cron jobs for reminders.

### **Sprint 4 (Weeks 7–8): Integration & Coordination**
**Goal:** "Users can sync quiz schedules to external calendars and track modification histories so they stay coordinated across all planning tools."
* *Focus:* Exporting .ics files, Google Calendar API integration, and the "Change Log" feature.