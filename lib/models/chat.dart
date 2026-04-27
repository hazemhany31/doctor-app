
import 'package:cloud_firestore/cloud_firestore.dart';

/// نموذج محادثة بين دكتور ومريض
class Chat {
  final String id;
  final String doctorId;
  final String doctorUserId;
  final String doctorName;
  final String patientId;
  final String patientName;
  final String? patientPhotoUrl;
  final String? doctorPhotoUrl;
  final String? doctorSpecialty;
  final String? doctorSpecialtyAr;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCountDoctor;
  final int unreadCountPatient;
  final DateTime createdAt;

  Chat({
    required this.id,
    required this.doctorId,
    required this.doctorUserId,
    required this.doctorName,
    required this.patientId,
    required this.patientName,
    this.patientPhotoUrl,
    this.doctorPhotoUrl,
    this.doctorSpecialty,
    this.doctorSpecialtyAr,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCountDoctor = 0,
    this.unreadCountPatient = 0,
    required this.createdAt,
  });

  /// إنشاء Chat من Firestore DocumentSnapshot
  factory Chat.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Chat.fromMap(doc.id, data);
  }

  /// إنشاء Chat من Map
  factory Chat.fromMap(String id, Map<String, dynamic> map) {
    return Chat(
      id: id,
      doctorId: map['doctorId'] ?? '',
      doctorUserId: map['doctorUserId'] ?? '',
      doctorName: map['doctorName'] ?? '',
      patientId: map['patientId'] ?? '',
      patientName: map['patientName'] ?? '',
      patientPhotoUrl: map['patientPhotoUrl'] ?? map['patientPhotoURL'],
      doctorPhotoUrl: map['doctorPhotoUrl'],
      doctorSpecialty: map['doctorSpecialty'],
      doctorSpecialtyAr: map['doctorSpecialtyAr'],
      lastMessage: map['lastMessage'],
      lastMessageTime: (map['lastMessageTime'] as Timestamp?)?.toDate(),
      unreadCountDoctor: map['unreadCountDoctor'] ?? 0,
      unreadCountPatient: map['unreadCountPatient'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// تحويل Chat إلى Map
  Map<String, dynamic> toMap() {
    return {
      'doctorId': doctorId,
      'doctorUserId': doctorUserId,
      'doctorName': doctorName,
      'patientId': patientId,
      'patientName': patientName,
      'patientPhotoUrl': patientPhotoUrl,
      'doctorPhotoUrl': doctorPhotoUrl,
      'doctorSpecialty': doctorSpecialty,
      'doctorSpecialtyAr': doctorSpecialtyAr,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime != null
          ? Timestamp.fromDate(lastMessageTime!)
          : null,
      'unreadCountDoctor': unreadCountDoctor,
      'unreadCountPatient': unreadCountPatient,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Chat copyWith({
    String? id,
    String? doctorId,
    String? doctorUserId,
    String? doctorName,
    String? patientId,
    String? patientName,
    String? patientPhotoUrl,
    String? doctorPhotoUrl,
    String? doctorSpecialty,
    String? doctorSpecialtyAr,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCountDoctor,
    int? unreadCountPatient,
    DateTime? createdAt,
  }) {
    return Chat(
      id: id ?? this.id,
      doctorId: doctorId ?? this.doctorId,
      doctorUserId: doctorUserId ?? this.doctorUserId,
      doctorName: doctorName ?? this.doctorName,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      patientPhotoUrl: patientPhotoUrl ?? this.patientPhotoUrl,
      doctorPhotoUrl: doctorPhotoUrl ?? this.doctorPhotoUrl,
      doctorSpecialty: doctorSpecialty ?? this.doctorSpecialty,
      doctorSpecialtyAr: doctorSpecialtyAr ?? this.doctorSpecialtyAr,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCountDoctor: unreadCountDoctor ?? this.unreadCountDoctor,
      unreadCountPatient: unreadCountPatient ?? this.unreadCountPatient,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
