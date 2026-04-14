import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat.dart';
import '../models/message.dart';

/// خدمة إدارة المحادثات والرسائل
class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// دمج stream'ين من Firestore مع إزالة التكرار بالـ ID
  Stream<List<Chat>> _mergeChatsStreams(
    Stream<QuerySnapshot> s1,
    Stream<QuerySnapshot> s2,
  ) {
    StreamSubscription<QuerySnapshot>? sub1;
    StreamSubscription<QuerySnapshot>? sub2;
    final Map<String, Chat> cache1 = {};
    final Map<String, Chat> cache2 = {};

    late final StreamController<List<Chat>> controller;

    void emit() {
      if (controller.isClosed) return;
      final merged = <String, Chat>{};
      merged.addAll(cache1);
      merged.addAll(cache2);
      final chats = merged.values.toList();
      chats.sort((a, b) {
        // Use lastMessageTime, fallback to createdAt (for new chats) or now (for pending writes)
        final aTime = a.lastMessageTime ?? a.createdAt;
        final bTime = b.lastMessageTime ?? b.createdAt;
        return bTime.compareTo(aTime);
      });
      controller.add(chats);
    }

    controller = StreamController<List<Chat>>.broadcast(
      onListen: () {
        sub1 = s1.listen((snap) {
          cache1.clear();
          for (var doc in snap.docs) {
            try { cache1[doc.id] = Chat.fromFirestore(doc); } catch(_) {}
          }
          emit();
        }, onError: (e) {
          if (!controller.isClosed) controller.addError(e);
        });
        sub2 = s2.listen((snap) {
          cache2.clear();
          for (var doc in snap.docs) {
            try { cache2[doc.id] = Chat.fromFirestore(doc); } catch(_) {}
          }
          emit();
        }, onError: (e) {
          if (!controller.isClosed) controller.addError(e);
        });
      },
      onCancel: () {
        sub1?.cancel();
        sub2?.cancel();
      },
    );

    return controller.stream;
  }

  /// جلب جميع محادثات الدكتور
  /// يبحث بـ doctorUserId (Auth UID) أساساً، ثم بـ doctorId كـ fallback للشاتات القديمة
  Stream<List<Chat>> getDoctorChats(String doctorAuthUid, String doctorFirestoreId) {
    // Stream 1: بـ doctorUserId (Auth UID) — الطريقة الصحيحة الجديدة
    final byUserId = _firestore
        .collection('chats')
        .where('doctorUserId', isEqualTo: doctorAuthUid)
        .snapshots();

    // Stream 2: بـ doctorId (Firestore profile ID) — للشاتات القديمة
    final byDocId = _firestore
        .collection('chats')
        .where('doctorId', isEqualTo: doctorFirestoreId)
        .snapshots();

    return _mergeChatsStreams(byUserId, byDocId);
  }

  /// جلب رسائل محادثة معينة
  Stream<List<Message>> getChatMessages(String chatId, {int limit = 50}) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('sentAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          final messages = snapshot.docs
              .map((doc) => Message.fromFirestore(doc))
              .toList();

          return messages;
        });
  }

  /// إرسال رسالة جديدة
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String senderType,
    required String text,
    String? imageUrl,
  }) async {
    try {
      final type = imageUrl != null ? 'image' : 'text';
      final message = Message(
        id: '',
        senderId: senderId,
        senderName: senderName,
        senderType: senderType,
        text: text,
        imageUrl: imageUrl,
        type: type,
        sentAt: DateTime.now(),
        isRead: false,
      );

      // إضافة الرسالة
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(message.toMap());

      // تحديث آخر رسالة وعدد الرسائل غير المقروءة باستخدام merge لتجنب الفشل الصامت
      final chatRef = _firestore.collection('chats').doc(chatId);
      
      // Determine display text for last message
      String lastMsgText = text;
      if (type == 'image' && text.isEmpty) {
        lastMsgText = '📷 صورة';
      } else if (type == 'image') {
        lastMsgText = '📷 $text';
      }

      final updates = <String, dynamic>{
        'lastMessage': lastMsgText,
        'lastMessageTime': FieldValue.serverTimestamp(),
      };

      // زيادة عدد الرسائل غير المقروءة للطرف الآخر
      if (senderType == 'doctor') {
        updates['unreadCountPatient'] = FieldValue.increment(1);
      } else {
        updates['unreadCountDoctor'] = FieldValue.increment(1);
      }

      await chatRef.set(updates, SetOptions(merge: true));

      // Trigger notification for the patient if sender is doctor
      if (senderType == 'doctor') {
        final chatDoc = await chatRef.get();
        if (chatDoc.exists) {
          final patientId = chatDoc.data()?['patientId'] ?? '';
          await _triggerPatientNotification(
            chatId: chatId,
            recipientId: patientId,
            senderName: senderName,
            text: text,
          );
        }
      }
    } catch (e) {
      debugPrint('❌ خطأ في إرسال الرسالة: $e');
      rethrow;
    }
  }

  /// تحديد الرسائل كمقروءة
  Future<void> markMessagesAsRead(String chatId, String userType) async {
    try {
      final chatRef = _firestore.collection('chats').doc(chatId);

      // إعادة تعيين عدد الرسائل غير المقروءة
      if (userType == 'doctor') {
        await chatRef.update({'unreadCountDoctor': 0});
      } else {
        await chatRef.update({'unreadCountPatient': 0});
      }

      // تحديد جميع الرسائل كمقروءة
      final messagesSnapshot = await chatRef
          .collection('messages')
          .where('isRead', isEqualTo: false)
          .where('senderType', isNotEqualTo: userType)
          .get();

      final batch = _firestore.batch();
      for (var doc in messagesSnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('❌ خطأ في تحديد الرسائل كمقروءة: $e');
    }
  }

  /// جلب إجمالي عدد الرسائل غير المقروءة للدكتور
  Stream<int> getTotalUnreadCount(String doctorAuthUid, String doctorFirestoreId) {
    return getDoctorChats(doctorAuthUid, doctorFirestoreId).map((chats) {
      int total = 0;
      for (var chat in chats) {
        total += chat.unreadCountDoctor;
      }
      return total;
    });
  }

  /// جلب محادثة معينة
  Future<Chat?> getChat(String chatId) async {
    try {
      final doc = await _firestore.collection('chats').doc(chatId).get();
      if (doc.exists) {
        return Chat.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('❌ خطأ في جلب المحادثة: $e');
      return null;
    }
  }

  /// جلب أو إنشاء محادثة بين دكتور ومريض
  /// [doctorUserId] هو Firebase Auth UID بتاع الدكتور — ضروري للـ Security Rules
  Future<Chat> getOrCreateChat({
    required String doctorId,
    required String doctorUserId,
    required String doctorName,
    required String patientId,
    required String patientName,
  }) async {
    try {
      // البحث عن محادثة موجودة — بـ doctorUserId أولاً (الأدق والأسرع)
      final byUserId = await _firestore
          .collection('chats')
          .where('doctorUserId', isEqualTo: doctorUserId)
          .where('patientId', isEqualTo: patientId)
          .limit(1)
          .get();

      if (byUserId.docs.isNotEmpty) {
        // تحديث doctorId لو ناقص في الوثيقة القديمة
        final existing = Chat.fromFirestore(byUserId.docs.first);
        if (existing.doctorId.isEmpty) {
          await byUserId.docs.first.reference.update({'doctorId': doctorId});
        }
        return existing;
      }

      // بحث ثانوي بـ doctorId للشاتات القديمة (قبل إضافة doctorUserId)
      final byDocId = await _firestore
          .collection('chats')
          .where('doctorId', isEqualTo: doctorId)
          .where('patientId', isEqualTo: patientId)
          .limit(1)
          .get();

      if (byDocId.docs.isNotEmpty) {
        // رفّع الوثيقة القديمة بإضافة doctorUserId
        await byDocId.docs.first.reference
            .update({'doctorUserId': doctorUserId}, );
        final updated = await byDocId.docs.first.reference.get();
        return Chat.fromFirestore(updated);
      }

      // إنشاء محادثة جديدة مع كل الحقول المطلوبة
      final newChatRef = await _firestore.collection('chats').add({
        'doctorId': doctorId,
        'doctorUserId': doctorUserId,
        'doctorName': doctorName,
        'patientId': patientId,
        'patientName': patientName,
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCountDoctor': 0,
        'unreadCountPatient': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final newDoc = await newChatRef.get();
      return Chat.fromFirestore(newDoc);
    } catch (e) {
      debugPrint('❌ خطأ في getOrCreateChat: $e');
      rethrow;
    }
  }

  /// Trigger a bilingual notification document for the patient
  Future<void> _triggerPatientNotification({
    required String chatId,
    required String recipientId,
    required String senderName,
    required String text,
  }) async {
    try {
      if (recipientId.isEmpty) return;

      // Fetch patient's language preference from Firestore
      final bool isArabicPatient = await _getPatientLanguage(recipientId);

      final title = isArabicPatient
          ? 'رسالة جديدة من د. $senderName'
          : 'New message from Dr. $senderName';

      await _firestore.collection('notifications').add({
        'recipientId': recipientId,
        'title': title,
        'body': text,
        'type': 'new_message',
        'chatId': chatId,
        'status': 'unread',
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('🔔 Chat notification triggered for patient: $recipientId [isArabic=$isArabicPatient]');
    } catch (e) {
      debugPrint('⚠️ Failed to trigger chat notification: $e');
    }
  }

  /// جلب لغة المريض من Firestore — إذا لم تُحدَّد يُفترض العربية
  Future<bool> _getPatientLanguage(String patientId) async {
    if (patientId.isEmpty) return true;
    try {
      final doc = await _firestore.collection('users').doc(patientId).get();
      if (doc.exists) {
        final lang = doc.data()?['language']?.toString() ?? 'ar';
        return lang == 'ar';
      }
    } catch (_) {}
    return true; // default: Arabic
  }
}

