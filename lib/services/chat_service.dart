import 'package:flutter/foundation.dart';


import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat.dart';
import '../models/message.dart';

/// خدمة إدارة المحادثات والرسائل
class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// جلب جميع محادثات الدكتور
  Stream<List<Chat>> getDoctorChats(List<String> doctorIds) {
    // Ensure unique IDs
    final uniqueIds = doctorIds.toSet().toList();
    if (uniqueIds.isEmpty) return Stream.value([]);

    return _firestore
        .collection('chats')
        .where('doctorId', whereIn: uniqueIds)
        .snapshots()
        .map((snapshot) {
          final chats = snapshot.docs
              .map((doc) => Chat.fromFirestore(doc))
              .toList();

          debugPrint('✅ Parsed ${chats.length} chats');
          for (var chat in chats) {
            debugPrint('  💬 Chat with ${chat.patientName}');
            debugPrint('     Last message: ${chat.lastMessage}');
            debugPrint('     Unread count: ${chat.unreadCountDoctor}');
          }

          // ترتيب المحادثات حسب آخر رسالة (الأحدث أولاً)
          chats.sort((a, b) {
            final aTime = a.lastMessageTime ?? DateTime(2000);
            final bTime = b.lastMessageTime ?? DateTime(2000);
            return bTime.compareTo(aTime);
          });
          return chats;
        });
  }

  /// جلب رسائل محادثة معينة
  Stream<List<Message>> getChatMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('sentAt', descending: false)
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
  }) async {
    try {
      final message = Message(
        id: '',
        senderId: senderId,
        senderName: senderName,
        senderType: senderType,
        text: text,
        sentAt: DateTime.now(),
        isRead: false,
      );

      // إضافة الرسالة
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(message.toMap());

      // تحديث آخر رسالة وعدد الرسائل غير المقروءة
      final chatRef = _firestore.collection('chats').doc(chatId);
      final chatDoc = await chatRef.get();

      if (chatDoc.exists) {
        final updates = {
          'lastMessage': text,
          'lastMessageTime': Timestamp.fromDate(DateTime.now()),
        };

        // زيادة عدد الرسائل غير المقروءة للطرف الآخر
        if (senderType == 'doctor') {
          updates['unreadCountPatient'] = FieldValue.increment(1);
        } else {
          updates['unreadCountDoctor'] = FieldValue.increment(1);
        }

        await chatRef.update(updates);

        // Trigger notification for the patient if sender is doctor
        if (senderType == 'doctor') {
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
  Stream<int> getTotalUnreadCount(List<String> doctorIds) {
    // Ensure unique IDs
    final uniqueIds = doctorIds.toSet().toList();
    if (uniqueIds.isEmpty) return Stream.value(0);

    return _firestore
        .collection('chats')
        .where('doctorId', whereIn: uniqueIds)
        .snapshots()
        .map((snapshot) {
          int total = 0;
          for (var doc in snapshot.docs) {
            final data = doc.data();
            total += (data['unreadCountDoctor'] ?? 0) as int;
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
  Future<Chat> getOrCreateChat({
    required String doctorId,
    required String doctorName,
    required String patientId,
    required String patientName,
  }) async {
    try {
      // البحث عن محادثة موجودة
      final existing = await _firestore
          .collection('chats')
          .where('doctorId', isEqualTo: doctorId)
          .where('patientId', isEqualTo: patientId)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        return Chat.fromFirestore(existing.docs.first);
      }

      // إنشاء محادثة جديدة
      final newChatRef = await _firestore.collection('chats').add({
        'doctorId': doctorId,
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

  /// Trigger a notification document for the patient
  Future<void> _triggerPatientNotification({
    required String chatId,
    required String recipientId,
    required String senderName,
    required String text,
  }) async {
    try {
      if (recipientId.isEmpty) return;

      await _firestore.collection('notifications').add({
        'recipientId': recipientId,
        'title': 'رسالة جديدة من د. $senderName',
        'body': text,
        'type': 'new_message',
        'chatId': chatId,
        'status': 'unread',
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('🔔 Chat notification triggered for patient: $recipientId');
    } catch (e) {
      debugPrint('⚠️ Failed to trigger chat notification: $e');
    }
  }
}

