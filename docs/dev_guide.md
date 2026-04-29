# Developer Guide: BROCODE-RS (Quiz Scheduler)

Welcome to the development team! This document is designed to get you up to speed on the architecture, setup process, and core design choices of the BROCODE-RS Quiz Scheduler.

This project is built using **Flutter** for the cross-platform frontend and **Firebase** (Firestore + Cloud Functions) for the backend. It includes deep integrations with the **Google Calendar API** (via OAuth 2.0) and **Firebase Cloud Messaging (FCM)** for push notifications.

---

## 🏗 Architecture & Tech Stack

### Tech Stack
* **Frontend:** Flutter (Dart)
* **Backend Platform:** Firebase (Authentication, Hosting, Cloud Functions)
* **Database:** Firebase Firestore (NoSQL)
* **Backend Logic:** Firebase Cloud Functions (Node.js v18+)
* **Push Notifications:** Firebase Cloud Messaging (FCM) + `flutter_local_notifications`
* **Third-Party APIs:** Google Calendar API v3 (OAuth 2.0)

### Core Design Principles
1.  **Event-Driven Backend:** Almost all backend logic is triggered by Firestore database events (`onDocumentWritten`, `onDocumentCreated`, etc.). The frontend rarely calls functions directly; it just reads/writes to Firestore, and the backend reacts.
2.  **Sync Loop:** The Calendar Sync engine is designed to handle API failures gracefully. If one user's Google token expires (`invalid_grant`), the loop catches the error, disables sync for that specific user, and continues processing the rest of the class.
3.  **Domino-Effect Prevention:** The backend modifies quiz documents to save generated Google Calendar Event IDs. To prevent this silent backend update from triggering "Quiz Updated!" push notifications to students, the notification engine explicitly filters out updates where only the `calendar_event_ids` field changed.

---

## 🚀 Setting Up the Project (From Scratch)

This section covers how to initialize the project after cloning the repository from GitHub. The production database contains dummy data for testing purposes. **You do NOT need to migrate or import any existing database records.** You should set up a completely fresh Firebase environment.

### Phase 1: Prerequisites
1.  Install **Flutter SDK** (v3.19+ recommended).
2.  Install **Node.js** (v18+ or v24+ to match Cloud Functions runtime).
3.  Install **Firebase CLI**: `npm install -g firebase-tools`
4.  Log in to Firebase CLI: `firebase login`

### Phase 2: Firebase Project Configuration
1.  Go to the [Firebase Console](https://console.firebase.google.com/) and create a new project.
2.  Enable the following services:
    * **Firestore Database** (Start in Test Mode, update rules later).
    * **Authentication** (Enable Google Sign-in).
    * **Firebase Hosting** (For deploying the web version of the admin panel).
3.  **Register your Apps:**
    * Add an Android app. Download the `google-services.json` file and place it in the Flutter project at `android/app/google-services.json`.
    * Add a Web app if you intend to run the admin portal on the web.
4.  **Google Cloud Platform Setup (CRITICAL):**
    * Go to the [Google Cloud Console](https://console.cloud.google.com/) for your Firebase project.
    * Search for **"Google Calendar API"** and click **Enable**. *(If you skip this, the calendar sync will silently crash!)*
    * Go to **APIs & Services > Credentials**. Find the automatically generated OAuth 2.0 Web Client ID. Note the Client ID and Client Secret.

### Phase 3: Project Initialization
1.  Clone the repository and navigate into the project directory: 
2.  Initialize Firebase within the directory to link your local code to your new Firebase project:
  
    * Select **Firestore**, **Functions**, and **Hosting**.
    * Select your newly created Firebase project.
    * Use the existing `firestore.rules` and `firestore.indexes.json` files.
    * For Functions, select **JavaScript** and choose **No** to ESLint (unless you want to enforce strict linting). Install dependencies when prompted.
    * For Hosting, set your public directory to `build/web` (this is where Flutter compiles the web app). Configure as a single-page app (Yes). Do not overwrite `index.html`.

### Phase 4: Database Setup & Access Control
Before you can log in and use the app, you must configure the basic access control in Firestore.

1.  Open the Firebase Console and go to **Firestore Database**.
2.  Create a new collection named **`app_settings`**.
3.  Create a document within `app_settings` named **`access_control`**.
4.  Add an array field to this document named **`admin_emails`**.
5.  Add your email address to the array:
    * `admin_emails`: `["rishabhsahusng@gmail.com"]`

### Phase 5: Backend Setup (Cloud Functions)
The Cloud Functions handle all the heavy lifting for Google Calendar and Push Notifications.

1.  Open a terminal and navigate to the `functions` folder:
    ```bash
    cd functions
    npm install
    ```
2.  **Environment Variables:** You MUST configure your secrets. Do not hardcode them!
    Create a file named `.env` in the `functions` directory:
    ```env
    GOOGLE_CLIENT_ID="your-google-oauth-web-client-id"
    GOOGLE_CLIENT_SECRET="your-google-oauth-client-secret"
    ```
3.  Deploy the backend:
    ```bash
    firebase deploy --only functions
    ```
    *(Note: Deploying cron jobs like `sendRoutineReminders` requires your Firebase project to be on the Pay-as-you-go "Blaze" plan).*

### Phase 6: Running the App & Populating Data
1.  Return to the root of the Flutter project.
2.  Fetch dependencies:
    ```bash
    flutter pub get
    ```
3.  Run the app locally (either on an emulator or as a web app):
    ```bash
    flutter run -d chrome  # For Web
    # OR
    flutter run            # For Android Emulator
    ```
4.  **Login as Admin:** Since you added your email to the `access_control` document in Phase 4, you should now be able to log in using Google Sign-In and access the Admin Dashboard.
5.  **Data Population:** Once logged in as an Admin, use the built-in app functionality to upload your Excel files. This will parse the data and automatically create the necessary collections (e.g., `users`, `courses`, `quizzes`) in your Firestore database.

### Phase 7: Hosting the App (Optional)
If you want to deploy the web version of the app to Firebase Hosting:

1.  Build the web release:
    ```bash
    flutter build web
    ```
2.  Deploy to Firebase Hosting:
    ```bash
    firebase deploy --only hosting
    ```

---

## 🗄️ Database Schema Reference (Post-Upload)

After you upload your Excel files via the admin portal, your database should look like this:

### Collection: `users`
Document ID: `userEmail@bits-pilani.ac.in`
```json
{
  "name": "Student Name",
  "fcm_token": "token_string_for_push_notifications",
  "courses": ["CSF111", "CSF003"],
  "calendar_sync_enabled": true,
  "refresh_token": "google_oauth_refresh_token", 
  "server_auth_code": "temporary_code_from_frontend" // Deleted by backend after exchange
}
```

### Collection: `courses`
Document ID: `CSF003`
```json
{
  "course_name": "Software Development for Portable Devices",
  "Professor": ["prof_email@bits-pilani.ac.in"]
}
```
### Collection: quizzes
Document ID: `Auto-generated`

```json
{
  "title": "Midterm Eval",
  "course_id": "CSF003",
  "course_name": "SDPD",
  "date_&_time": [Firestore Timestamp],
  "duration": 60,
  "calendar_event_ids": {
      "student1@gmail.com": "google_calendar_event_id_123"
  }
}
```