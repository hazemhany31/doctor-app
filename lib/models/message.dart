
import 'package:cloud_firestore/cloud_firestore.dart';

/// نموذج رسالة في المحادثة
class Message {
  final String id;
  final String senderId;
  final String senderName;
  final String senderType; // 'doctor' أو 'patient'
  final String text;
  final String? imageUrl;
  final String type; // 'text' أو 'image'
  final DateTime sentAt;
  final bool isRead;

  Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderType,
    required this.text,
    this.imageUrl,
    this.type = 'text',
    required this.sentAt,
    this.isRead = false,
  });

  /// إنشاء Message من Firestore DocumentSnapshot
  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Message.fromMap(doc.id, data);
  }

  /// إنشاء Message من Map
  /// Backward-compatible: reads legacy nbig_app fields `messageType` and `imageBase64`
  factory Message.fromMap(String id, Map<String, dynamic> map) {
    // Resolve image URL: prefer `imageUrl` (Storage URL), fallback to `imageBase64` (legacy nbig_app)
    final resolvedImageUrl = map['imageUrl'] ?? map['imageBase64'];
    // Resolve type: prefer `type`, fallback to `messageType` (legacy nbig_app)
    final resolvedType = map['type'] ?? map['messageType'] ?? (resolvedImageUrl != null ? 'image' : 'text');

    return Message(
      id: id,
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      senderType: map['senderType'] ?? 'patient',
      text: map['text'] ?? '',
      imageUrl: resolvedImageUrl,
      type: resolvedType,
      sentAt: (map['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
    );
  }

  /// تحويل Message إلى Map
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'senderType': senderType,
      'text': text,
      'imageUrl': imageUrl,
      'type': type,
      'sentAt': Timestamp.fromDate(sentAt),
      'isRead': isRead,
    };
  }

  Message copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? senderType,
    String? text,
    String? imageUrl,
    String? type,
    DateTime? sentAt,
    bool? isRead,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderType: senderType ?? this.senderType,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      type: type ?? this.type,
      sentAt: sentAt ?? this.sentAt,
      isRead: isRead ?? this.isRead,
    );
  }
}
