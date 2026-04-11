
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/chat.dart';
import '../../models/message.dart';
import '../../services/chat_service.dart';
import '../../services/firestore_service.dart';
import '../../config/colors.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import '../patients/patient_details_screen.dart';

/// شاشة المحادثة مع مريض
class ChatScreen extends StatefulWidget {
  final Chat chat;

  const ChatScreen({super.key, required this.chat});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;

  String _doctorName = '';
  late Stream<List<Message>> _messagesStream;

  // Anti-spam variables
  DateTime? _lastMessageTime;
  int _rapidMessageCount = 0;

  @override
  void initState() {
    super.initState();
    // تحديد الرسائل كمقروءة عند فتح المحادثة
    _chatService.markMessagesAsRead(widget.chat.id, 'doctor');
    _loadDoctorName();
    _messagesStream = _chatService.getChatMessages(widget.chat.id);
  }

  Future<void> _loadDoctorName() async {
    final doctor = await _firestoreService.getDoctorByUserId(_currentUserId);
    if (doctor != null) {
      setState(() {
        _doctorName = doctor.name;
      });
    }
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    
    // --- Anti-Spam Check ---
    final now = DateTime.now();
    if (_lastMessageTime != null) {
      if (now.difference(_lastMessageTime!).inSeconds < 1) {
        _rapidMessageCount++;
        if (_rapidMessageCount >= 3) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('الرجاء الانتظار قليلاً لتجنب إرسال رسائل متكررة'),
                duration: Duration(seconds: 2),
              ),
            );
          }
          return;
        }
      } else {
        _rapidMessageCount = 0;
      }
    }
    _lastMessageTime = now;
    // -----------------------
    
    _messageController.clear(); // Clear immediately for better UX
    _scrollToBottom();
    
    final senderName = _doctorName.isNotEmpty 
        ? _doctorName 
        : (widget.chat.doctorName.isNotEmpty ? widget.chat.doctorName : 'طبيب');

    try {
      await _chatService.sendMessage(
        chatId: widget.chat.id,
        senderId: _currentUserId,
        senderName: senderName,
        senderType: 'doctor',
        text: text,
      );

      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.chatDetailSendError}$e')),
        );
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          0.0, // Because reversed list, latest messages are at the start
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () async {
            final navigator = Navigator.of(context);
            final scaffoldMessenger = ScaffoldMessenger.of(context);

            // Show loading indicator
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.white)),
            );
            
            try {
              final patient = await _firestoreService.getPatient(widget.chat.patientId);
              if (mounted) {
                navigator.pop(); // Close loading
                if (patient != null) {
                  navigator.push(
                    MaterialPageRoute(
                      builder: (context) => PatientDetailsScreen(patient: patient),
                    ),
                  );
                } else {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('لم يتم العثور على بيانات المريض')),
                  );
                }
              }
            } catch (e) {
              if (mounted) {
                navigator.pop(); // Close loading
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('حدث خطأ أثناء تحميل بيانات المريض')),
                );
              }
            }
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white.withValues(alpha: 0.3),
                child: Text(
                  widget.chat.patientName.isNotEmpty
                      ? widget.chat.patientName[0].toUpperCase()
                      : 'M',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(widget.chat.patientName),
            ],
          ),
        ),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // قائمة الرسائل
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  final l10n = AppLocalizations.of(context)!;
                  return Center(
                    child: Text('${l10n.chatErrorPrefix}${snapshot.error}'),
                  );
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  final l10n = AppLocalizations.of(context)!;
                  return Center(
                    child: Text(
                      l10n.chatDetailStartPlaceholder,
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                  reverse: true, // Auto scrolls to bottom natively
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isDoctor = message.senderType == 'doctor';
                    // Since it's reversed, the "previous" chronological message is at index + 1
                    final showDate =
                        index == messages.length - 1 ||
                        !_isSameDay(messages[index + 1].sentAt, message.sentAt);

                    return Column(
                      children: [
                        if (showDate)
                          _buildDateDivider(context, message.sentAt),
                        _MessageBubble(message: message, isDoctor: isDoctor),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // حقل إدخال الرسالة
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(
                            context,
                          )!.chatDetailInputHint,
                          border: InputBorder.none,
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppColors.primaryBlue,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Widget _buildDateDivider(BuildContext context, DateTime date) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final difference = now.difference(date);
    String dateText;

    if (_isSameDay(date, now)) {
      dateText = l10n.chatDetailToday;
    } else if (difference.inDays == 1) {
      dateText = l10n.chatDetailYesterday;
    } else {
      final locale = Localizations.localeOf(context).languageCode;
      dateText = DateFormat('dd MMMM yyyy', locale).format(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey.shade300)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              dateText,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey.shade300)),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isDoctor;

  const _MessageBubble({required this.message, required this.isDoctor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isDoctor
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isDoctor) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.shade300,
              child: Text(
                message.senderName.isNotEmpty
                    ? message.senderName[0].toUpperCase()
                    : 'P',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isDoctor ? AppColors.primaryBlue : Colors.grey.shade200,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isDoctor ? 16 : 4),
                  bottomRight: Radius.circular(isDoctor ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: isDoctor ? Colors.white : Colors.black87,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('HH:mm').format(message.sentAt),
                    style: TextStyle(
                      color: isDoctor
                          ? Colors.white.withValues(alpha: 0.7)
                          : Colors.grey.shade600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isDoctor) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.2),
              child: Text(
                message.senderName.isNotEmpty
                    ? message.senderName[0].toUpperCase()
                    : 'D',
                style: TextStyle(fontSize: 12, color: AppColors.primaryBlue),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
