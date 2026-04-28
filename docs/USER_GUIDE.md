**TL;DR:** I have updated the Quiz Scheduler User Guide to entirely remove all references to venue booking, aligning it perfectly with the faculty dashboard UI you provided.

Here is the revised user guide with those corrections applied.

***

# 📅 Quiz Scheduler — User Guide

> **Smart Academic Scheduling for BITS Pilani Goa Campus**

---

## Table of Contents

1. [What is Quiz Scheduler?](#1-what-is-quiz-scheduler)
2. [Before You Start](#2-before-you-start)
3. [Access & Installation](#3-access--installation)
4. [App Overview](#4-app-overview)
5. [Faculty Guide: Scheduling a Quiz](#5-faculty-guide-scheduling-a-quiz)
6. [Faculty Guide: Importing Student Lists](#6-faculty-guide-importing-student-lists)
7. [Student Guide: Managing Your Timeline](#7-student-guide-managing-your-timeline)
8. [Notifications & Calendar Sync](#8-notifications--calendar-sync)
9. [Tips & FAQ](#9-tips--faq)

---

## 1. What is Quiz Scheduler?

Quiz Scheduler is a centralized platform designed to eliminate "evaluation clusters"—those stressful days when multiple high-stakes quizzes overlap. 

By calculating evaluation density based on real student enrollments, the system provides faculty with a visual heatmap of student workload, ensuring quizzes are placed on optimal dates. Meanwhile, students get a personalized, consolidated timeline of their academic deadlines.

**Who is it for?**

| User | Platform | Core Use Case |
|---|---|---|
| 👨‍🏫 **Faculty** | Web Dashboard | Finding clash-free dates via the Heatmap and scheduling quizzes. |
| 🎓 **Students** | Mobile App | Viewing a chronological list of their upcoming quizzes and getting alerts. |
| ⚙️ **Admins** | Web Dashboard | Managing global schedules and resolving cross-department conflicts. |

---

## 2. Before You Start

### Requirements
- A valid **@bits-goa.ac.in** (or institutional) Google account.
- **For Faculty:** A modern web browser (Chrome, Firefox, Safari) on a desktop or tablet.
- **For Students:** An Android or iOS smartphone with the app installed and notifications enabled.

### First Login — Institutional Access
Security and privacy are top priorities. You **must** use your BITS Goa Google account to log in. Personal Gmail accounts will be denied access. This ensures that students only see their enrolled courses and that only verified faculty can schedule evaluations.

---

## 3. Access & Installation

### For Faculty (Web Dashboard)
You do not need to download anything.
1. Open your browser and navigate to the Quiz Scheduler portal (e.g., `scheduler.bits-goa.ac.in`).
2. Click **"Sign in with Google"**.
3. Select your `@bits-goa.ac.in` account.
4. You will be immediately redirected to your Faculty Dashboard, pre-populated with the courses you are teaching.

### For Students (Mobile App)
The app is available for smartphones to ensure you get real-time push notifications.
1. Download the **Quiz Scheduler App** (link provided by the academic office).
2. Open the app and tap **"Continue with Google"**.
3. Select your `@bits-goa.ac.in` account.
4. When prompted, **allow Push Notifications**. This is critical for receiving next-day reminders and alerts about rescheduled quizzes.

---

## 4. App Overview

### Faculty Web Dashboard Layout

```text
┌──────────────────────────────────────────────────────────┐
│  BITS Goa | Quiz Scheduler            [👤 Prof. ▾] [Logout]│
├──────────────┬───────────────────────────────────────────┤
│ 📅 Schedule  │                                           │
│    Quiz      │          [ Calendar Heatmap ]             │
│ 📋 My        │                                           │
│    Quizzes   │       [ 1-Hour Free Slots List ]          │
│              │                                           │
│              │        [ Confirm & Schedule ]             │
└──────────────┴───────────────────────────────────────────┘
```

### Student Mobile App Layout

```text
┌────────────────────────────┐
│ 📅 My Timeline             │
├────────────────────────────┤
│  Tomorrow                  │
│  [📕 EEE F211 - Quiz 1]    │
│  4:00 PM - 5:00 PM         │
├────────────────────────────┤
│  Next Week                 │
│  [📘 CS F301 - Midterm]    │
│  Monday | 10:00 AM         │
├────────────────────────────┤
│  [ Sync to Calendar 🔗 ]   │
└────────────────────────────┘
```

---

## 5. Faculty Guide: Scheduling a Quiz

### Step 1 — Select Your Course
On your dashboard, navigate to **Schedule Quiz**. Select the course you want to schedule a quiz for from the top right dropdown menu (e.g., "Computer Programming").

### Step 2 — Check the Heatmap
You will see a Calendar Heatmap for the month. Dates are color-coded based on your students' existing workloads:
- **Green:** Clear schedule (0 quizzes).
- **Yellow:** Moderate workload (1 quiz).
- **Red:** High density (2+ quizzes). *Avoid these dates.*
- **Gray text/No interaction:** Holidays, Midsems, or Compre dates.

### Step 3 — Create the Quiz
1. Click on an available date on the calendar.
2. The right panel will display **Free Slots** (e.g., 6 AM - 7 AM). Tap a contiguous slot to auto-fill the time.
3. Under **Schedule Quiz Details**, enter your **Quiz Title**.
4. Adjust the **Duration** using the slider if needed.
5. Click **Confirm & Schedule**. 

> [!IMPORTANT]
> **Conflict Alert:** If you attempt to schedule on a "Red" date or pick a time that directly conflicts with another quiz for your enrolled students, the system will block the scheduling and display a warning.

### Step 4 — Modifying a Quiz
If you need to change a date or time, simply navigate to **My Quizzes**, click on the existing quiz, and edit the details. Once you click Update, the heatmap will recalculate automatically, and a "Revision Alert" will be sent to all enrolled students.

---

## 6. Faculty Guide: Importing Student Lists

To ensure the heatmap accurately reflects your specific class, you must upload your enrollment data.

1. **Download from ERP:** Log into Quanta (ERP) and download your course's student registration list as a CSV file.
2. **Navigate to Students:** On the Quiz Scheduler dashboard, go to the **Students/Enrollment** section.
3. **Upload CSV:** Click **Import from ERP/CSV** and upload the file.
4. **Validate & Sync:** The system will preview the `@bits-goa.ac.in` emails. Click **Confirm Import**. The students are now linked to your course and will contribute to the heatmap logic.

---

## 7. Student Guide: Managing Your Timeline

Once logged in, the mobile app does the heavy lifting for you. 

* **Chronological View:** Your home screen displays a unified list of every upcoming quiz, midterm, and deadline across all your registered courses.
* **Change Logs:** If a professor reschedules a quiz, the app highlights the changes. You will see the old time crossed out and the new time highlighted in red, so there's no confusion.
* **Privacy:** You will *only* see evaluations for courses you are actively enrolled in.

---

## 8. Notifications & Calendar Sync

### Real-Time Push Alerts
You don't need to constantly refresh the app. You will receive an immediate push notification the moment:
* A new quiz is published for your course.
* An existing quiz date or time is modified.

### Daily Summary Reminders
Every evening at **8:00 PM**, the app checks your schedule. If you have an evaluation the following day, you will receive a single "Next-Day Summary" notification to help you finalize your prep.

### Sync to External Calendars
Want to see your quizzes alongside your personal events? 
1. Open the app and go to your Timeline.
2. Tap the **Sync to Calendar** button at the bottom.
3. The app will generate an `.ics` file or directly prompt you to add the events to Google Calendar or Apple Calendar.

---

## 9. Tips & FAQ

**Q: I’m a student and I don’t see a quiz that my professor announced in class. Why?**
> The professor may not have uploaded the enrollment CSV yet, or they haven't officially published the quiz in the system. Check back later, or politely remind your instructor to sync the Quanta list!

**Q: I’m a professor. The system won't let me schedule a quiz on a specific Thursday. Why?**
> That specific time slot directly conflicts with another quiz your enrolled students are taking, or the day already has maximum evaluation density (Red status). Please check the heatmap for an alternative date.

**Q: I changed a quiz time. Do I need to email my students?**
> No! The moment you hit "Update" on a quiz, the system automatically sends a push notification to every enrolled student detailing the exact time changes. 

**Q: Can a club or department use this for non-academic events?**
> Currently, the Quiz Scheduler is strictly integrated with the academic ERP to prevent high-stakes academic clashes. Non-academic events are out of scope.

---

Would you like me to refine the "My Quizzes" section as well, assuming it's the next tab on the sidebar?