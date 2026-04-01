const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendNotificationToPG = functions.https.onCall(async (data, context) => {
  const {pgId, title, body} = data;

  if (!pgId || !title || !body) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "pgId, title, and body are required.",
    );
  }

  try {
    // Get all residents in the specified PG
    const residentsSnapshot = await admin
        .firestore()
        .collection("users")
        .where("pgId", "==", pgId)
        .where("role", "==", "resident")
        .get();

    const tokens = [];

    residentsSnapshot.forEach((doc) => {
      const userData = doc.data();
      if (userData.fcmToken) {
        tokens.push(userData.fcmToken);
      }
    });

    if (tokens.length === 0) {
      console.log(`No tokens found for PG: ${pgId}`);
      return {success: false, message: "No FCM tokens found."};
    }

    const message = {
      notification: {
        title,
        body,
      },
      tokens: tokens,
    };

    const response = await admin.messaging().sendMulticast(message);

    console.log(`Notifications sent: ${response.successCount}`);
    return {
      success: true,
      message: `Notifications sent: ${response.successCount}`,
    };
  } catch (error) {
    console.error("Error sending notification:", error);
    throw new functions.https.HttpsError(
        "internal",
        "Failed to send notifications.",
    );
  }
});
