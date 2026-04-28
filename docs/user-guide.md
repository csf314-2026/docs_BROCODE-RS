

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
7. [Student Guide: Managing Your Schedule (BITS Goa Evals)](#7-student-guide-managing-your-schedule-bits-goa-evals)
8. [Notifications & Calendar Sync](#8-notifications--calendar-sync)
9. [Tips & FAQ](#9-tips--faq)

---

## 1. What is Quiz Scheduler?

Quiz Scheduler is a centralized platform designed to eliminate "evaluation clusters"—those stressful days when multiple high-stakes quizzes overlap. 

By calculating evaluation density based on real student enrollments, the system provides faculty with a visual heatmap of student workload, ensuring quizzes are placed on optimal dates. Meanwhile, students get a personalized, consolidated timeline of their academic deadlines via the companion mobile app, **BITS Goa Evals**.

**Who is it for?**

| User | Platform | Core Use Case |
|---|---|---|
| 👨‍🏫 **Faculty** | Web Dashboard | Finding clash-free dates via the Heatmap and scheduling quizzes. |
| 🎓 **Students** | Mobile App | Viewing upcoming/past assessments and receiving automated alerts. |
| ⚙️ **Admins** | Web Dashboard | Managing global schedules and resolving cross-department conflicts. |

---

## 2. Before You Start

### Requirements
- A valid **@bits-goa.ac.in** (or institutional) Google account.
- **For Faculty:** A modern web browser on a desktop or tablet.
- **For Students:** An Android or iOS smartphone with the app installed and notifications enabled.

### First Login — Institutional Access
Security and privacy are top priorities. You **must** use your BITS Goa Google account to log in. Personal Gmail accounts will be denied access. This ensures that students only see their enrolled courses and that only verified faculty can schedule evaluations.

---

## 3. Access & Installation

### For Faculty (Web Dashboard)
You do not need to download anything.
1. Open your browser and navigate to the Quiz Scheduler portal.
2. Click **"Sign in with Google"**.
3. Select your `@bits-goa.ac.in` account.

### For Students (Mobile App: BITS Goa Evals)
1. Download the **BITS Goa Evals** app (link provided by the academic office).
2. Open the app and log in with your `@bits-goa.ac.in` account.
3. When prompted, **allow Push Notifications** to receive schedule updates.

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

### Student Mobile App Layout (BITS Goa Evals)

```text
┌──────────────────────────────────────┐
│  BITS Goa Evals             [P] [➔]  │
├──────────────────────────────────────┤
│  My Schedule                         │
│  [ Upcoming ] [ Past ]               │
│                                      │
│  [📖 Computer Programming: Quiz 1] ⏰│ 
│  📅 Wed, Apr 29, 2026  🕒 7:00 AM    │
│  ⏱️ 60 mins                          │
├──────────────────────────────────────┤
│  [📅 Schedule] [📚 Courses] [⚙️ Settings] │
└──────────────────────────────────────┘
```
*(Alarm icon shown as ⏰ in the UI mockup)*

---

## 5. Faculty Guide: Scheduling a Quiz

### Step 1 — Select Your Course
On your dashboard, navigate to **Schedule Quiz**. Select the course you want to schedule a quiz for from the top right dropdown menu.

### Step 2 — Check the Heatmap
You will see a Calendar Heatmap for the month. Dates are color-coded based on your students' existing workloads:
- **Light Gray:** Clear schedule (0 quizzes).
- **Yellow:** Moderate workload (1 quiz).
- **Red:** High density (2+ quizzes). *Avoid these dates.*
- **Gray text:** Holidays, Midsems, or Compre dates.

### Step 3 — Create the Quiz
1. Click on an available date on the calendar.
2. The right panel will display **Free Slots**. Tap a contiguous slot to auto-fill the time.
3. Under **Schedule Quiz Details**, enter your **Quiz Title**.
4. Adjust the **Duration** using the slider if needed.
5. Click **Confirm & Schedule**. 

### Step 4 — Modifying a Quiz
Navigate to **My Quizzes**, click on the existing quiz, and edit the details. Once updated, the heatmap recalculates, and an alert is sent to all enrolled students.

---

## 6. Faculty Guide: Importing Student Lists

To ensure the heatmap accurately reflects your specific class, you must upload your enrollment data.

1. **Download from ERP:** Log into Quanta and download your course's student registration list (CSV).
2. **Navigate to Students:** On the dashboard, go to the **Students/Enrollment** section.
3. **Upload & Sync:** Click **Import from ERP/CSV**, upload the file, and click **Confirm Import**.

---

## 7. Student Guide: Managing Your Schedule (BITS Goa Evals)


The mobile app organizes your academic life into three simple tabs located at the bottom of the screen:

* **📅 Schedule:** This is your main hub. It displays a chronological list of your registered assessments. Toggle between **Upcoming** to see future deadlines and **Past** to review previous quizzes. 
* **⏰ Custom Quiz Alarms:** On the "Upcoming" schedule view, you'll see an orange clock icon next to each quiz card. Tap it to open the **Set Quiz Reminder** menu. Use the slider to select exactly when you want to be alerted (e.g., 45 minutes before the quiz starts) and tap **Set Alarm**. 
* **📚 Courses:** View a complete list of your actively registered courses and their respective course codes.
* **⚙️ Settings:** Manage your notification preferences and calendar integrations here.

---

## 8. Notifications & Calendar Sync


### Notification Preferences
You can control how often you are reminded about upcoming assessments by navigating to the **Settings** tab. 
* Under **Reminder Frequency**, you can select your preferred alert interval (or turn them "Off").
* *Note:* Daily overview notifications are sent at **7:15 AM IST**, and weekly summary overviews are sent on **Sundays**.

### Google Calendar Sync
To see your quizzes alongside your personal events:
1. Go to the **Settings** tab.
2. Locate the **Google Calendar Sync** card.
3. Toggle **Sync Active** to the ON position (green). 
4. Registered quizzes will automatically be added to your primary Google Calendar and will update dynamically if a professor modifies the schedule.

---

## 9. Tips & FAQ
🎓 For Students (BITS Goa Evals App)
Q: I’m a student and my "Courses" tab is missing a subject. Why?

The professor may not have uploaded the enrollment CSV yet. Check back later, or politely remind your instructor to sync the Quanta list.

Q: Can I manually add my own study deadlines or unlisted quizzes to the schedule?

No. To maintain a strict and accurate departmental heatmap, only verified faculty or admins can create and publish official quiz events.

Q: Will the app's custom alarm ring if my phone is on Silent or Do Not Disturb (DND)?

This depends on your phone's OS. To guarantee you hear the alarm, we highly recommend going into your phone's system settings and allowing the BITS Goa Evals app to override DND mode.

Q: What happens to my custom alarm if the professor changes the quiz time?

The app is smart enough to handle this! It will automatically adjust your alarm to match the new schedule while maintaining the relative time gap you chose (e.g., it will still ring exactly 45 minutes before the new start time).

Q: I synced to Google Calendar, but a newly announced quiz isn't showing up there. Why?

Background syncs can sometimes be delayed by your phone's battery-saving features. Simply open the BITS Goa Evals app to trigger an immediate data refresh, which will instantly push the update to your Google Calendar.

Q: Will my mid-semester and comprehensive exams (compres) show up in the app?

The app is primarily designed to stop continuous evaluation clashes (quizzes/assignments). Midsems and compres appear as blocked days on the faculty heatmap, but your specific exam seating and timings for those major exams will still be communicated via the official Timetable Division.

👨‍🏫 For Faculty (Web Dashboard)
Q: The system won't let me schedule a quiz on a specific day. Why?

That specific time slot directly conflicts with another quiz your enrolled students are taking, or the day already has maximum evaluation density (Red status). Please check the heatmap for an alternative date.

Q: How do I handle students who add or drop my course mid-semester?

Simply log into Quanta, download the updated student CSV, and re-upload it via the Students tab on the dashboard. The system will cleanly merge the data, updating the heatmap without creating duplicate profiles.

Q: Can I schedule a quiz if just one or two students have a clash, but the majority are free?

No. The system strictly blocks scheduling if there is a direct time clash for any enrolled student across their registered courses. This hard block ensures zero overlap, forcing a clean schedule for everyone.

Q: Does the Calendar Heatmap take campus holidays into account?

Yes. Official BITS Goa holidays, midsem weeks, and compre dates are hard-coded into the system. These days will appear grayed out and cannot be selected for regular quizzes.

Q: What if a quiz is canceled entirely? Can I delete it?

Yes. Navigate to My Quizzes, click on the specific quiz, and select the 'Delete' option. The heatmap will instantly clear that time slot, and students will receive a push notification that the evaluation has been canceled.

Q: I am a TA for the course. Can I schedule a quiz on behalf of the professor?

Only users with assigned Instructor-in-Charge (IC) privileges for the course in the ERP can create quizzes. If a TA needs to schedule it, they must coordinate with the IC or an Academic Admin who has proxy scheduling rights.

---
