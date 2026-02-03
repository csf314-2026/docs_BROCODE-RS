# Sprint Goals – Quiz Scheduler

**Project:** Quiz Scheduler (BITS Goa)  
**Total Timeline:** 8 weeks  

---

## Sprint 1 (Weeks 1–2)

**Theme:** Access & Heatmap Visualization

| Goal # | User Story |
| ------ | ---------- |
| 1 | Professors can securely log in via university SSO and view a student workload heatmap so they can identify dates without evaluation clusters before scheduling. |

**Definition of Done:**

- Professors can sign in using @bits-goa.ac.in Google accounts  
- Authentication state persists across app restarts (SSO Persistence)  
- The dashboard displays a color-coded Calendar Heatmap (Green/Yellow/Red)  
- Heatmap accurately reflects student density from a provided enrollment dataset  

---

## Sprint 2 (Weeks 3–4)

**Theme:** Quiz Management & Timelines

| Goal # | User Story |
| ------ | ---------- |
| 1 | Professors can publish and modify quiz details while students view their specific course timelines so that the academic schedule remains accurate and transparent. |

**Definition of Done:**

- Faculty can input and "Publish" quiz details (Date, Time, Venue)  
- Conflict alerts trigger a warning if a professor selects a date with 2+ existing quizzes  
- Students can log in and see a chronological list of quizzes only for their registered courses  
- Professors can edit existing quizzes, triggering a "Modified" status on the entry  

---

## Sprint 3 (Weeks 5–6)

**Theme:** Real-time Notifications

| Goal # | User Story |
| ------ | ---------- |
| 1 | Students receive push notifications for new quizzes and daily preparation reminders so they never miss a deadline or a sudden change in schedule. |

**Definition of Done:**

- Push notifications are delivered to student devices immediately upon quiz publication  
- Automated "Next-Day" summary notifications are sent at 8:00 PM daily  
- Clicking a notification navigates the user directly to the relevant quiz details  
- Notifications accurately reflect if a quiz was rescheduled (showing old vs. new time)  

---

## Sprint 4 (Weeks 7–8)

**Theme:** External Sync & History Logs

| Goal # | User Story |
| ------ | ---------- |
| 1 | Users can sync quizzes to personal calendars and view modification histories so they stay coordinated across platforms and understand why schedules changed. |

**Definition of Done:**

- Users can export quiz events to Google/Outlook calendars via .ics or direct sync  
- A "Change Log" is visible to students, highlighting exactly what was edited (e.g., Venue change)  
- Final UI/UX polish for both Web (Faculty) and Mobile (Student) platforms  
- All success metrics (e.g., login speed, heatmap accuracy) are verified by the Stakeholder  

---

## Summary

| Sprint | Weeks | Theme | Primary User Value |
| ------ | ----- | ----- | ------------------ |
| 1 | 1–2 | Access & Heatmap | Professors identify free slots visually |
| 2 | 3–4 | Quiz Management | Quizzes are formally scheduled and visible to students |
| 3 | 5–6 | Notifications | Students get proactive alerts and reminders |
| 4 | 7–8 | Sync & History | Unified planning across external calendar tools |

---