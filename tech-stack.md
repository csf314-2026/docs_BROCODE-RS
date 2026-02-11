# Tech Stack

**Team Name:** BROCODE-RS
**Sprint:** Sprint 1
**Date:** 10/02/2026
**GitHub Repo:** [Github](https://github.com/csf314-2026/docs_BROCODE-RS.git)

---

# C4 Model

---

## LEVEL 1: CONTEXT DIAGRAM (CEO / Stakeholder View)

**Audience:** Non-technical stakeholders
**Focus:** Who uses the system and what external systems it depends on.

```mermaid
graph TD
    Student[Student] -- View Timeline & Receive Alerts --> System[Quiz Scheduler System]
    Faculty[Faculty] -- Schedule Quizzes & Import Students --> System
    Admin[System Moderator] -- Proxy Scheduling & Manage Data --> System
    
    System -- Store & Retrieve Data --> Firestore[(Cloud Firestore)]
    System -- Authentication --> FirebaseAuth[Firebase Auth]
    System -- Send Notifications --> NotificationService[Push / Email Service]
```

### What it shows

The **Quiz Scheduler System** acts as the central coordination layer:

* **Students** view their personalized quiz timelines and receive alerts.
* **Faculty** create and manage quizzes and import student data.
* **Admins** oversee scheduling and perform proxy operations when required.
* The system depends on:

  * **Cloud Firestore** for persistent storage.
  * **Firebase Auth** for secure authentication and domain restriction.
  * **Push/Email services** for notifications.

This view avoids technical complexity and communicates value clearly to stakeholders.

---

## LEVEL 2: CONTAINER DIAGRAM (Architect View)

**Audience:** Architects / Dev Leads
**Focus:** Major deployable units and how they interact.

```mermaid
graph TB

    subgraph "Quiz Scheduler System"

        Web[Flutter Web Application<br/>Faculty + Admin Dashboard]
        Mobile[Flutter Mobile App<br/>Student Application]
        API[Node.js Backend Service<br/>Business Logic + Heatmap Engine]
        DB[(Cloud Firestore Database)]
        Auth[Firebase Authentication]
        Notify[Notification Service]

    end

    Faculty --> Web
    Admin --> Web
    Student --> Mobile

    Web <-->|HTTPS / JSON| API
    Mobile <-->|HTTPS / JSON| API

    API <--> DB
    API <--> Auth
    API <--> Notify
```

### What it shows

The system is separated into clear deployable containers:

### 1️⃣ Flutter Web

* Used by Faculty and Admin.
* Provides scheduling dashboard and heatmap visualization.

### 2️⃣ Flutter Mobile

* Used by Students.
* Displays timeline and sends push notifications.

### 3️⃣ Node.js Backend

* Central business logic.
* Handles scheduling, validation, heatmap generation, and imports.
* Ensures consistent API response structure.

### 4️⃣ Firebase Services

* **Firestore** → NoSQL cloud database.
* **Firebase Auth** → Secure SSO + domain restriction.
* **Notification Service** → Push/email alerts.

This separation ensures scalability and clean architectural boundaries.

---

## LEVEL 3: COMPONENT DIAGRAM (Developer View)

**Audience:** Developers
**Focus:** Internal modules inside each container.

---

### 🔹 Node.js Backend – Internal Components

```mermaid
graph TD

subgraph "Node.js Backend"

    %% Entry Layer
    Server[Express App Server]
    Router[Route Layer]
    AuthMiddleware[Authentication Middleware<br/>JWT + Domain Validation]

    %% Controllers
    QuizController[Quiz Controller]
    HeatmapController[Heatmap Controller]
    ImportController[CSV Import Controller]
    UserController[User Controller]
    NotificationController[Notification Controller]

    %% Services
    QuizService[Quiz Service<br/>CRUD Operations]
    HeatmapService[Heatmap Service<br/>Aggregation Logic]
    ImportService[Import Service<br/>Bulk Student Processing]
    UserService[User Service]
    NotificationService[Notification Service]

    %% Core Logic Engines
    ConflictEngine[Conflict Detection Engine]
    DensityEngine[Density Calculation Engine]
    TimeSlotNormalizer[Time Slot Normalizer]
    CSVParser[CSV Parser]
    DataValidator[Schema Validator]

    %% Data Layer
    FirestoreAdapter[Firestore Adapter Layer]
    TransactionManager[Transaction Manager]

    %% Cross-Cutting Concerns
    Logger[Central Logger]
    ErrorHandler[Global Error Handler]
    ApiResponse[Standard API Response Envelope]

end

Server --> Router
Router --> AuthMiddleware

AuthMiddleware --> QuizController
AuthMiddleware --> HeatmapController
AuthMiddleware --> ImportController
AuthMiddleware --> UserController
AuthMiddleware --> NotificationController

QuizController --> QuizService
HeatmapController --> HeatmapService
ImportController --> ImportService
UserController --> UserService
NotificationController --> NotificationService

HeatmapService --> ConflictEngine
HeatmapService --> DensityEngine
HeatmapService --> TimeSlotNormalizer

ImportService --> CSVParser
ImportService --> DataValidator

QuizService --> FirestoreAdapter
HeatmapService --> FirestoreAdapter
ImportService --> FirestoreAdapter
UserService --> FirestoreAdapter
NotificationService --> FirestoreAdapter

FirestoreAdapter --> TransactionManager

QuizController --> ApiResponse
HeatmapController --> ApiResponse
ImportController --> ApiResponse

Server --> Logger
Server --> ErrorHandler
```

---

### 🔹 Flutter Application – Internal Components

```mermaid
graph TD

subgraph "Flutter Application (Web + Mobile)"

    %% Presentation Layer
    LoginScreen[Login Screen]
    FacultyDashboard[Faculty Dashboard Screen]
    StudentTimeline[Student Timeline Screen]
    HeatmapScreen[Heatmap Screen]

    %% UI Components
    CalendarWidget[Calendar Widget]
    HeatmapWidget[Heatmap Visualization Widget]
    QuizCard[Quiz Card Component]
    NotificationBanner[Notification Banner]

    %% State Management
    AppState[Global State<br/>Riverpod / Provider]
    AuthState[Authentication State]
    QuizState[Quiz State]
    HeatmapState[Heatmap State]

    %% Services
    APIClient[API Client Service<br/>HTTPS + JSON]
    AuthService[Firebase Auth Service]
    TokenManager[Access + Refresh Token Manager]
    NotificationClient[Push Notification Client]

    %% Local Persistence
    LocalStorage[SharedPreferences]
    LocalCache[Offline Cache Layer]

    %% Navigation
    AppRouter[Flutter Navigator / GoRouter]

end

LoginScreen --> AuthState
FacultyDashboard --> QuizState
StudentTimeline --> QuizState
HeatmapScreen --> HeatmapState

FacultyDashboard --> CalendarWidget
HeatmapScreen --> HeatmapWidget
StudentTimeline --> QuizCard

AppState --> AuthState
AppState --> QuizState
AppState --> HeatmapState

QuizState --> APIClient
HeatmapState --> APIClient
AuthState --> AuthService

AuthService --> TokenManager
TokenManager --> LocalStorage

APIClient --> TokenManager
NotificationClient --> LocalCache

LoginScreen --> AppRouter
FacultyDashboard --> AppRouter
StudentTimeline --> AppRouter
HeatmapScreen --> AppRouter
```

---

### What This Level 3 Shows

* Clear **layered backend architecture**

  * Router → Middleware → Controllers → Services → Engines → Firestore
* Dedicated **Heatmap computation engines**
* Explicit **validation + response envelope**
* Centralized **logging and error handling**
* Clean Flutter separation:

  * UI Layer
  * State Layer
  * Service Layer
  * Persistence Layer
  * Navigation Layer
* Prepared for:

  * Offline caching
  * Token refresh
  * Future scalability
  * Feature expansion (venue booking, analytics, reports)

---

# Tech Stack Selection Criteria

---

## Functional Requirements

The system must:

* Allow faculty to schedule quizzes.
* Import student data via CSV.
* Generate evaluation heatmaps using aggregated data.
* Provide students with personalized timelines.
* Send notifications for upcoming quizzes.

❌ Eliminated:

* Static HTML-only systems.
* Backend-less client-side aggregation.
* SQL-only rigid schema systems.

---

## Non-Functional Requirements

* Persistent login with refresh tokens.
* 99% uptime during peak exam weeks.
* Strict `@bits-goa.ac.in` domain restriction.
* Secure data isolation between departments.

❌ Eliminated:

* Guest login systems.
* Fully on-device scheduling logic.

---

## Team Capability

* Strong foundation in OOP & SQL.
* Familiarity with JavaScript ecosystem.
* Willingness to learn Flutter & Firebase.

✅ Selected:

* **Frontend:** Flutter (Web + Mobile)
* **Backend:** Node.js (Express)
* **Database:** Cloud Firestore
* **Auth:** Firebase Authentication

---

## Budget & Infrastructure

💰 Estimated Cost: ₹0 (Spark Plan)

* Serverless Firebase infrastructure.
* Minimal DevOps overhead.
* Scalable architecture without upfront hosting cost.

---

## Market Maturity & Support

* **Flutter:** Mature cross-platform framework with strong plugin ecosystem.
* **Node.js:** Large ecosystem for REST APIs, CSV parsing, authentication.
* **Firebase:** Reliable cloud-managed backend services.

---

## Migration & Technical Debt Strategy

* Business logic isolated in Node.js (not embedded in Firestore).
* Clean service-based backend design.
* Modular Flutter architecture.
* Easily migratable to AWS or private BITS infrastructure if needed.

