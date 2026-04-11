const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.sendNotificationOnCreate = functions.firestore
  .document("notifications/{notificationId}")
  .onCreate(async (snap, context) => {
    const notificationId = context.params.notificationId;
    const data = snap.data();

    console.log(`🔔 Processing notification: ${notificationId}`, JSON.stringify(data));

    // Safety: prevent duplicate processing ONLY — do NOT block by status
    if (data.fcmSent === true) {
      console.log(`Skipping: already sent (fcmSent=true)`);
      return null;
    }

    const recipientId = data.recipientId;
    if (!recipientId) {
      console.error(`Error: No recipientId for notification ${notificationId}`);
      return null;
    }

    console.log(`Searching for FCM token for recipient: ${recipientId}`);

    try {
      let fcmToken = null;

      // 1. Primary Lookup: Check "users" collection (fastest, used by both apps)
      const userDoc = await admin.firestore().collection("users").doc(recipientId).get();
      if (userDoc.exists && userDoc.data().fcmToken) {
        fcmToken = userDoc.data().fcmToken;
        console.log(`Found token in 'users' collection.`);
      }

      // 2. Secondary Fallback: Check "doctors" collection by docId
      if (!fcmToken) {
        const doctorDoc = await admin.firestore().collection("doctors").doc(recipientId).get();
        if (doctorDoc.exists && doctorDoc.data().fcmToken) {
          fcmToken = doctorDoc.data().fcmToken;
          console.log(`Found token in 'doctors' (docId).`);
        }
      }

      // 3. Final Fallback: Query "doctors" by userId field
      if (!fcmToken) {
        const doctorQuery = await admin
          .firestore()
          .collection("doctors")
          .where("userId", "==", recipientId)
          .limit(1)
          .get();
        if (!doctorQuery.empty) {
          fcmToken = doctorQuery.docs[0].data().fcmToken;
          console.log(`Found token in 'doctors' (userId query).`);
        }
      }

      if (!fcmToken) {
        console.error(`❌ FAILURE: No FCM token found for user: ${recipientId}`);
        return snap.ref.update({
          fcmError: "Token not found",
          fcmTimestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      const title = data.title || "تحديث جديد";
      const body  = data.body  || "لديك إشعار جديد";

      // ── FCM Message ──
      // Both 'notification' AND 'data' must be present for background display on Android & iOS
      const message = {
        notification: { title, body },
        data: {
          click_action: "FLUTTER_NOTIFICATION_CLICK",
          notificationId: notificationId,
          type: data.type || "general",
          appointmentId: data.appointmentId || "",
          chatId: data.chatId || "",
          // Include title/body in data too so background handler can use them
          title: title,
          body: body,
        },
        token: fcmToken,

        // ── Android: High priority delivery + correct channel ──
        android: {
          priority: "high",
          notification: {
            channelId: "doctor_app_channel",
            sound: "default",
            defaultSound: true,
            defaultVibrateTimings: true,
          },
        },

        // ── iOS: Explicit alert + high priority ──
        apns: {
          headers: {
            "apns-priority": "10",
          },
          payload: {
            aps: {
              alert: { title, body },
              sound: "default",
              badge: 1,
              contentAvailable: true,
            },
          },
        },
      };

      const response = await admin.messaging().send(message);
      console.log(`✅ SUCCESS: Sent to ${recipientId}. MessageId: ${response}`);

      return snap.ref.update({
        fcmSent: true,
        fcmTimestamp: admin.firestore.FieldValue.serverTimestamp(),
        fcmMessageId: response,
      });

    } catch (error) {
      console.error(`❌ CRITICAL ERROR for ${recipientId}:`, error);
      return snap.ref.update({
        fcmError: error.message,
        fcmTimestamp: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  });
