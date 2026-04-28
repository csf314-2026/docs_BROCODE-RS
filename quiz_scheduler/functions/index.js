const { onDocumentCreated, onDocumentUpdated, onDocumentWritten } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { setGlobalOptions } = require("firebase-functions/v2");
const admin = require("firebase-admin");
const { google } = require("googleapis");

admin.initializeApp();
setGlobalOptions({ region: "asia-south1" });

// ============================================================================
// CONFIGURATION
// ============================================================================
const CLIENT_ID = process.env.GOOGLE_CLIENT_ID;
const CLIENT_SECRET = process.env.GOOGLE_CLIENT_SECRET;
const oauth2Client = new google.auth.OAuth2(CLIENT_ID, CLIENT_SECRET, "");
const calendar = google.calendar({ version: "v3", auth: oauth2Client });

// ============================================================================
// 1. CALENDAR: AUTH CODE EXCHANGE
// ============================================================================
exports.exchangeAuthCodeForToken = onDocumentUpdated("users/{userEmail}", async (event) => {
    const after = event.data.after.data();
    const userEmail = event.params.userEmail;

    if (after.server_auth_code && !after.refresh_token) {
        console.log(`[AUTH] Starting exchange for ${userEmail}`);
        try {
            const { tokens } = await oauth2Client.getToken(after.server_auth_code);
            if (tokens.refresh_token) {
                await event.data.after.ref.update({
                    refresh_token: tokens.refresh_token,
                    server_auth_code: admin.firestore.FieldValue.delete()
                });
                console.log(`[AUTH] ✅ Success! Refresh token saved for ${userEmail}`);
            }
        } catch (error) {
            console.error(`[AUTH] ❌ Exchange failed:`, error.message);
            await event.data.after.ref.update({ server_auth_code: admin.firestore.FieldValue.delete() });
        }
    }
});

// ============================================================================
// 2. CALENDAR: SYNC ENGINE (BULLETPROOF VERSION)
// ============================================================================
exports.syncCalendarEngine = onDocumentWritten("quizzes/{quizId}", async (event) => {
    const before = event.data.before.exists ? event.data.before.data() : null;
    const after = event.data.after.exists ? event.data.after.data() : null;
    const quizId = event.params.quizId;
    const db = admin.firestore();

    if (before && after) {
        const timeSame = before['date_&_time']?.seconds === after['date_&_time']?.seconds;
        if (before.title === after.title && timeSame && before.duration === after.duration) {
            return; // No human-facing changes, exit silently.
        }
    }

    const quizData = after || before;
    const courseId = quizData.course_id;
    const targetEmailsMap = new Map();

    // 1. Gather Students
    const studentsSnap = await db.collection('users').where('courses', 'array-contains', courseId).where('calendar_sync_enabled', '==', true).get();
    studentsSnap.forEach(doc => targetEmailsMap.set(doc.id, { email: doc.id, ...doc.data() }));

    // 2. Gather Professors (Map prevents duplicates if a prof is also testing as a student)
    const courseSnap = await db.collection('courses').doc(courseId).get();
    if (courseSnap.exists) {
        const profs = courseSnap.data()?.Professor || [];
        for (const email of profs) {
            const pDoc = await db.collection('users').doc(email).get();
            if (pDoc.exists && pDoc.data().calendar_sync_enabled) {
                targetEmailsMap.set(email, { email, ...pDoc.data() });
            }
        }
    }

    const targetEmails = Array.from(targetEmailsMap.values());
    if (targetEmails.length === 0) return;

    let googleEvent = null;
    if (after && after['date_&_time']) {
        const startTime = after['date_&_time'].toDate();
        const endTime = new Date(startTime.getTime() + (after.duration * 60000));
        googleEvent = {
            summary: `${after.title} : ${after.course_name || courseId}`,
            description: `BITS Evals Sync`,
            start: { dateTime: startTime.toISOString(), timeZone: 'Asia/Kolkata' },
            end: { dateTime: endTime.toISOString(), timeZone: 'Asia/Kolkata' }
        };
    }

    const eventIds = quizData.calendar_event_ids || {};

    // 3. BULLETPROOF LOOP
    for (const user of targetEmails) {
        if (!user.refresh_token) continue;
        
        oauth2Client.setCredentials({ refresh_token: user.refresh_token });
        
        // The Try-Catch is now INSIDE the loop. One failure won't stop the others!
        try {
            if (!after && eventIds[user.email]) {
                // DELETE
                await calendar.events.delete({ calendarId: 'primary', eventId: eventIds[user.email] });
            } else if (!before && after) {
                // INSERT NEW
                const res = await calendar.events.insert({ calendarId: 'primary', requestBody: googleEvent });
                eventIds[user.email] = res.data.id;
                console.log(`[SYNC] ✅ Inserted for ${user.email}`);
            } else if (before && after) {
                // UPDATE (Or late insert if they missed the first round)
                if (eventIds[user.email]) {
                    await calendar.events.update({ calendarId: 'primary', eventId: eventIds[user.email], requestBody: googleEvent });
                    console.log(`[SYNC] ✅ Updated for ${user.email}`);
                } else {
                    const res = await calendar.events.insert({ calendarId: 'primary', requestBody: googleEvent });
                    eventIds[user.email] = res.data.id;
                    console.log(`[SYNC] ✅ Late Insert for ${user.email}`);
                }
            }
        } catch (err) {
            console.error(`[SYNC] ❌ ERROR for ${user.email}:`, err.message);
            
            // Auto-clean dead tokens so they don't cause future errors
            if (err.message === "invalid_grant") {
                await db.collection('users').doc(user.email).update({
                    refresh_token: admin.firestore.FieldValue.delete(),
                    calendar_sync_enabled: false
                });
                console.log(`[SYNC] 🧹 Cleaned dead token for ${user.email}`);
            }
        }
    }

    if (after) {
        await event.data.after.ref.update({ calendar_event_ids: eventIds });
    }
});

// ============================================================================
// 3. NOTIFICATION: NEW QUIZ
// ============================================================================
exports.sendNewQuizNotification = onDocumentCreated("quizzes/{quizId}", async (event) => {
    const snap = event.data;
    if (!snap) return;
    const newQuiz = snap.data();
    const topic = `course_${newQuiz.course_id}`;
    const payload = {
        notification: {
            title: "New Quiz Scheduled! 📝",
            body: `A new quiz '${newQuiz.title}' has been added for ${newQuiz.course_name || newQuiz.course_id}.`,
        },
        topic: topic
    };
    await admin.messaging().send(payload);
});

// ============================================================================
// 4. NOTIFICATION: QUIZ UPDATED
// ============================================================================
exports.sendQuizUpdateNotification = onDocumentUpdated("quizzes/{quizId}", async (event) => {
    const snap = event.data;
    if (!snap) return;
    
    const before = snap.before.data();
    const after = snap.after.data();

    // 🛑 DOMINO EFFECT PREVENTION 🛑
    // Create copies of the data and remove the calendar_event_ids field.
    // This allows us to check if the human-readable content actually changed.
    const beforeData = { ...before };
    const afterData = { ...after };
    delete beforeData.calendar_event_ids;
    delete afterData.calendar_event_ids;

    // If the data is identical after ignoring calendar IDs, this was just the 
    // syncCalendarEngine saving its data. Do NOT send a push notification.
    if (JSON.stringify(beforeData) === JSON.stringify(afterData)) {
        console.log(`[NOTIFY] Ignored silent backend update for quiz: ${event.params.quizId}`);
        return;
    }

    const topic = `course_${after.course_id}`;
    const payload = {
        notification: {
            title: "Quiz Modified! 📢",
            body: `Details for '${after.title}' have changed. Check the app for updates.`,
        },
        topic: topic
    };
    await admin.messaging().send(payload);
});

// ============================================================================
// 5. CRON: DAILY REMINDERS (Requires Blaze Plan)
// ============================================================================
exports.sendRoutineReminders = onSchedule({
    schedule: "45 7 * * *",
    timeZone: "Asia/Kolkata" 
}, async (event) => {
    const db = admin.firestore();
    const now = new Date();
    const usersSnapshot = await db.collection('users').where('reminder_frequency', 'in', ['Daily', 'Weekly']).get();

    const promises = [];
    usersSnapshot.forEach((userDoc) => {
        const userData = userDoc.data();
        if (!userData.fcm_token || !userData.courses) return;

        const lookaheadHours = userData.reminder_frequency === 'Daily' ? 24 : 168;
        const windowEnd = new Date(now.getTime() + (lookaheadHours * 60 * 60 * 1000));

        const p = db.collection('quizzes')
            .where('course_id', 'in', userData.courses)
            .where('date_&_time', '>', now)
            .where('date_&_time', '<=', windowEnd)
            .get()
            .then(qSnap => {
                if (!qSnap.empty) {
                    return admin.messaging().send({
                        token: userData.fcm_token,
                        notification: { title: "Upcoming Evals Alert! 🚨", body: `You have evals coming up soon. Check your dashboard!` }
                    });
                }
            });
        promises.push(p);
    });
    await Promise.all(promises);
});