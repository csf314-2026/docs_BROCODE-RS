const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { setGlobalOptions } = require("firebase-functions/v2");
const admin = require("firebase-admin");

admin.initializeApp();

// Force the function to deploy to the exact same region as your Firestore database
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
    console.log(`[CREATED] Sent notification to ${topic} for quiz ${title}`);
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

  // We can look at the data AFTER the edit
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
    console.log(`[UPDATED] Sent notification to ${topic} for quiz ${title}`);
  } catch (error) {
    console.error(`Error sending update notification to ${topic}:`, error);
  }
});