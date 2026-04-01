const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { setGlobalOptions } = require("firebase-functions/v2");
const admin = require("firebase-admin");

admin.initializeApp();

setGlobalOptions({ region: "asia-south1" });

// ============================================================================
// 1. TRIGGER: WHEN A NEW QUIZ IS CREATED
// ============================================================================
exports.sendNewQuizNotification = onDocumentCreated("quizzes/{quizId}", async (event) => {
  const snap = event.data;
  if (!snap) return;

  const newQuiz = snap.data();
  const courseId = newQuiz.course_id;
  const courseName = newQuiz.course_name || courseId; 
  const title = newQuiz.title;

  const topic = `course_${courseId}`;

  const payload = {
    notification: {
      title: "New Quiz Scheduled! 📝",
      body: `A new quiz '${title}' has been added for ${courseName}. Check your schedule!`,
    },
    topic: topic
  };

  try {
    await admin.messaging().send(payload);
    console.log(`[CREATED] Sent notification to ${topic}`);
  } catch (error) {
    console.error(`Error sending creation notification to ${topic}:`, error);
  }
});

// ============================================================================
// 2. TRIGGER: WHEN AN EXISTING QUIZ IS MODIFIED
// ============================================================================
exports.sendQuizUpdateNotification = onDocumentUpdated("quizzes/{quizId}", async (event) => {
  const snap = event.data;
  if (!snap) return;

  const updatedQuiz = snap.after.data();
  const courseId = updatedQuiz.course_id;
  const courseName = updatedQuiz.course_name || courseId;
  const title = updatedQuiz.title;

  const topic = `course_${courseId}`;

  const payload = {
    notification: {
      title: "Quiz Modified! 📢",
      body: `The details for '${title}' (${courseName}) have been changed. Please check the updated time/date.`,
    },
    topic: topic
  };

  try {
    await admin.messaging().send(payload);
    console.log(`[UPDATED] Sent notification to ${topic}`);
  } catch (error) {
    console.error(`Error sending update notification to ${topic}:`, error);
  }
});

// ============================================================================
// 3. CRON JOB: SMART ROUTINE REMINDERS (Runs ONCE daily)
// ============================================================================
// Currently set to 7:15 AM Asia/Kolkata (IST).
// Later, change "15 7 * * *" to "0 20 * * *" for 8:00 PM.
exports.sendRoutineReminders = onSchedule({
  schedule: "45 7 * * *",
    // schedule: "*/5 * * * *",
  timeZone: "Asia/Kolkata" 
}, async (event) => {
  const db = admin.firestore();
  
  const now = new Date();
  const istTime = new Date(now.toLocaleString('en-US', { timeZone: 'Asia/Kolkata' }));
  const currentDay = istTime.getDay(); // 0 is Sunday, 1 is Monday, etc.

  console.log("Running Daily 7:15 AM Reminder Check...");

  // Find all users who have reminders turned on (Daily OR Weekly)
  const usersSnapshot = await db.collection('users')
      .where('reminder_frequency', 'in', ['Daily', 'Weekly'])
      .get();

  if (usersSnapshot.empty) {
      console.log("No users subscribed to routine reminders.");
      return;
  }

  const promises = [];
  
  usersSnapshot.forEach((userDoc) => {
      const userData = userDoc.data();
      const frequency = userData.reminder_frequency;
      
      // RULES FOR WEEKLY: Only run on Sundays (Day 0)
      // NOTE: If you are testing this today (Wednesday), Weekly users will be skipped.
      if (frequency === 'Weekly' && currentDay !== 0) return; 
      
      if (!userData.fcm_token || !userData.courses || userData.courses.length === 0) return;

      // Set the lookahead window: Daily = 24 hours, Weekly = 7 days (168 hours)
      const lookaheadHours = frequency === 'Daily' ? 24 : 168;
      const windowEnd = new Date(now.getTime() + (lookaheadHours * 60 * 60 * 1000));

      const promise = db.collection('quizzes')
          .where('course_id', 'in', userData.courses)
          .where('date_&_time', '>', now)
          .where('date_&_time', '<=', windowEnd)
          .get()
          .then((quizSnapshot) => {
              const quizzes = [];
              quizSnapshot.forEach(q => quizzes.push(q.data().course_id));

              // We only send a notification if they ACTUALLY have quizzes coming up
              if (quizzes.length > 0) {
                  const timeFrameText = frequency === 'Daily' ? 'tomorrow' : 'this week';
                  const title = `Upcoming Evals Alert! 🚨`;
                  const body = `You have ${quizzes.length} eval(s) ${timeFrameText}: ${quizzes.join(', ')}`;

                  const payload = {
                      token: userData.fcm_token,
                      notification: { title: title, body: body }
                  };

                  return admin.messaging().send(payload).catch(err => {
                      console.error(`Failed to send reminder to ${userData.fcm_token}:`, err);
                  });
              }
              // If quizzes.length == 0, we do nothing to save server bandwidth!
          });

      promises.push(promise);
  });

  await Promise.all(promises);
  console.log("All daily smart reminders processed!");
});