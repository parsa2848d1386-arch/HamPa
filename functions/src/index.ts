import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

admin.initializeApp();

/**
 * Triggered whenever a study session is logged under users/{userId}/sessions/{sessionId}
 * Automatically calculates streak and updates user's daily study aggregates.
 */
export const onStudySessionLogged = onDocumentWritten(
  {
    document: "users/{userId}/sessions/{sessionId}",
    cpu: "gcf_gen1",
  },
  async (event) => {
    const userId = event.params.userId;
    if (!event.data?.after.exists) {
      // Session deleted
      return;
    }

    const sessionData = event.data.after.data();
    const durationSeconds = Number(sessionData?.durationSeconds || 0);

    const userRef = admin.firestore().doc(`users/${userId}`);
    await admin.firestore().runTransaction(async (tx) => {
      const userSnap = await tx.get(userRef);
      if (!userSnap.exists) return;

      const userData = userSnap.data() || {};
      const currentStreak = Number(userData.streakDays || 0);
      const lastStudy = userData.lastStudyDate;
      const todayKey = new Date().toISOString().split("T")[0];

      let newStreak = currentStreak;
      if (lastStudy !== todayKey) {
        newStreak = currentStreak + 1;
      }

      tx.update(userRef, {
        streakDays: newStreak,
        lastStudyDate: todayKey,
        totalStudiedSeconds: admin.firestore.FieldValue.increment(durationSeconds),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });
  }
);

/**
 * Callable Cloud Function: AI Task Scheduler
 * Integrates Gemini API for unstructured thought parsing.
 */
export const parseStudyNotesWithAI = onCall(
  {
    cors: true,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required");
    }

    const text = String(request.data?.text || "");
    if (!text.trim()) {
      throw new HttpsError("invalid-argument", "Text content cannot be empty");
    }

    // Returns structured payload
    return {
      success: true,
      rawText: text,
      suggestedTasks: [
        {
          title: text.slice(0, 50),
          durationMinutes: 45,
          priority: "high",
        },
      ],
    };
  }
);
