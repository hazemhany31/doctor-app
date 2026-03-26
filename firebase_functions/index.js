const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.sendNotificationOnCreate = functions.firestore
  .document("notifications/{notificationId}")
  .onCreate(async (snap, context) => {
    const notificationData = snap.data();
    
    // We only process 'unread' notifications
    if (notificationData.status !== "unread") {
      console.log("Notification status is not unread, skipping.");
      return null;
    }

    const recipientId = notificationData.recipientId;
    if (!recipientId) {
      console.log("No recipientId found.");
      return null;
    }

    // 1. First, check if recipient is a patient in "users" collection
    let tokenSnapshot = await admin.firestore().collection("users").doc(recipientId).get();
    
    // 2. If not found in users, check if recipient is a doctor in "doctors" collection
    if (!tokenSnapshot.exists || !tokenSnapshot.data().fcmToken) {
      console.log(`Token not found in users collection for ${recipientId}, checking doctors...`);
      tokenSnapshot = await admin.firestore().collection("doctors").doc(recipientId).get();
    }
    
    // 3. One more fallback: Sometimes doctors are saved by userId instead of doc Id
    if (!tokenSnapshot.exists || !tokenSnapshot.data().fcmToken) {
      console.log(`Token not found via docId, checking userId query...`);
      const doctorQuery = await admin.firestore().collection("doctors").where("userId", "==", recipientId).limit(1).get();
      if (!doctorQuery.empty) {
        tokenSnapshot = doctorQuery.docs[0];
      }
    }

    if (!tokenSnapshot.exists || !tokenSnapshot.data().fcmToken) {
      console.log(`No FCM token found for user ID: ${recipientId}.`);
      return null;
    }

    const fcmToken = tokenSnapshot.data().fcmToken;

    const payload = {
      notification: {
        title: notificationData.title || "تحديث جديد",
        body: notificationData.body || "لديك إشعار جديد",
      },
      data: {
        click_action: "FLUTTER_NOTIFICATION_CLICK",
        notificationId: context.params.notificationId,
        type: notificationData.type || "general",
        appointmentId: notificationData.appointmentId || "",
        chatId: notificationData.chatId || "",
      },
      token: fcmToken
    };

    try {
      // Send message to device
      const response = await admin.messaging().send(payload);
      console.log(`Successfully sent notification to ${recipientId}`, response);
      
      // Optionally mark the notification as processed (so we know it was sent via FCM)
      return snap.ref.update({ fcmSent: true });
    } catch (error) {
      console.error(`Error sending notification to ${recipientId}:`, error);
      return null;
    }
  });
