const functions = require("firebase-functions/v1");
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

/**
 * Syncs users with role 'doctor' to the 'doctors' collection.
 */
exports.syncDoctorProfile = functions.firestore
  .document("users/{userId}")
  .onWrite(async (change, context) => {
    const userId = context.params.userId;
    const newData = change.after.exists ? change.after.data() : null;

    // If the document was deleted or role is not doctor, skip
    if (!newData || newData.role !== "doctor") {
      return null;
    }

    console.log(`Syncing doctor profile for: ${userId}`);
    const doctorRef = admin.firestore().collection("doctors").doc(userId);

    try {
      const doctorDoc = await doctorRef.get();

      const syncData = {
        userId: userId,
        name: newData.name || "دكتور جديد",
        nameAr: newData.name || "دكتور جديد",
        email: newData.email || "",
        phoneNumber: newData.phoneNumber || "",
        photoUrl: newData.photoUrl || "",
        image: newData.photoUrl || "",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      if (!doctorDoc.exists) {
        // Create new doctor profile with defaults
        console.log(`Creating new profile for ${userId}`);
        return doctorRef.set({
          ...syncData,
          specialty: "General",
          specialtyAr: "عام",
          rating: "4.8",
          reviews: 0,
          patients: "0",
          experience: "1",
          about: "لا توجد تفاصيل حالياً.",
          aboutAr: "لا توجد تفاصيل حالياً.",
          isActive: true,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      } else {
        // Update existing basic info
        console.log(`Updating existing profile for ${userId}`);
        return doctorRef.update(syncData);
      }
    } catch (error) {
      console.error(`Error syncing doctor profile for ${userId}:`, error);
      return null;
    }
  });
