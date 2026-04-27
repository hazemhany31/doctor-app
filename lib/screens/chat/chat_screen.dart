
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/chat.dart';
import '../../models/message.dart';
import '../../services/chat_service.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../config/colors.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import '../patients/patient_details_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
  final StorageService _storageService = StorageService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;

  bool _isSendingImage = false;

  String _doctorName = '';
  String? _doctorPhotoUrl;
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
        _doctorPhotoUrl = doctor.photoUrl;
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

  void _pickAndSendImage() async {
    final image = await _storageService.pickImageFromGallery();
    if (image == null) return;

    setState(() => _isSendingImage = true);

    try {
      final imageUrl = await _storageService.uploadChatImage(
        chatId: widget.chat.id,
        imageFile: File(image.path),
      );

      if (imageUrl != null) {
        final senderName = _doctorName.isNotEmpty 
            ? _doctorName 
            : (widget.chat.doctorName.isNotEmpty ? widget.chat.doctorName : 'طبيب');

        await _chatService.sendMessage(
          chatId: widget.chat.id,
          senderId: _currentUserId,
          senderName: senderName,
          senderType: 'doctor',
          text: '',
          imageUrl: imageUrl,
        );
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في إرسال الصورة: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingImage = false);
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
                backgroundImage: (widget.chat.patientPhotoUrl != null && 
                                 widget.chat.patientPhotoUrl!.isNotEmpty)
                    ? NetworkImage(widget.chat.patientPhotoUrl!)
                    : null,
                child: (widget.chat.patientPhotoUrl == null || 
                        widget.chat.patientPhotoUrl!.isEmpty)
                    ? Text(
                        widget.chat.patientName.isNotEmpty
                            ? widget.chat.patientName[0].toUpperCase()
                            : 'M',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
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
                        _MessageBubble(
                          message: message, 
                          isDoctor: isDoctor,
                          doctorPhotoUrl: _doctorPhotoUrl,
                          patientPhotoUrl: widget.chat.patientPhotoUrl,
                        ),
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
                  if (_isSendingImage)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.add_a_photo_outlined, color: AppColors.primaryBlue),
                      onPressed: _pickAndSendImage,
                    ),
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

class _MessageBubble extends StatefulWidget {
  final Message message;
  final bool isDoctor;
  final String? doctorPhotoUrl;
  final String? patientPhotoUrl;

  const _MessageBubble({
    required this.message, 
    required this.isDoctor,
    this.doctorPhotoUrl,
    this.patientPhotoUrl,
  });

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _popController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _popController, curve: Curves.easeOutBack),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _popController, curve: Curves.easeOut),
    );
    _popController.forward();
  }

  @override
  void dispose() {
    _popController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final photoUrl = widget.isDoctor ? widget.doctorPhotoUrl : widget.patientPhotoUrl;

    return FadeTransition(
      opacity: _fadeAnim,
      child: ScaleTransition(
        scale: _scaleAnim,
        alignment: widget.isDoctor ? Alignment.bottomRight : Alignment.bottomLeft,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            mainAxisAlignment: widget.isDoctor
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!widget.isDoctor) ...[
                _buildAvatar(photoUrl, widget.message.senderName, 'P'),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Column(
                  crossAxisAlignment: widget.isDoctor 
                      ? CrossAxisAlignment.end 
                      : CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: widget.message.type == 'image' 
                          ? const EdgeInsets.all(4) 
                          : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: widget.isDoctor
                            ? const LinearGradient(
                                colors: [Color(0xFF0B6E6E), Color(0xFF0D9488)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : (isDark
                                ? LinearGradient(
                                    colors: [const Color(0xFF1E293B), const Color(0xFF1E293B).withValues(alpha: 0.95)],
                                  )
                                : LinearGradient(
                                    colors: [Colors.white, Colors.grey.shade50],
                                  )),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(20),
                          topRight: const Radius.circular(20),
                          bottomLeft: Radius.circular(widget.isDoctor ? 20 : 6),
                          bottomRight: Radius.circular(widget.isDoctor ? 6 : 20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: widget.isDoctor
                                ? AppColors.primary.withValues(alpha: 0.2)
                                : Colors.black.withValues(alpha: 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: !widget.isDoctor
                            ? Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : Colors.grey.withValues(alpha: 0.12),
                              )
                            : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.message.type == 'image' && widget.message.imageUrl != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: _buildChatImage(widget.message.imageUrl!),
                            ),
                          if (widget.message.text.isNotEmpty)
                            Padding(
                              padding: widget.message.type == 'image' 
                                  ? const EdgeInsets.only(top: 8, left: 8, right: 8, bottom: 4)
                                  : EdgeInsets.zero,
                              child: Text(
                                widget.message.text,
                                style: TextStyle(
                                  color: widget.isDoctor
                                      ? Colors.white
                                      : (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B)),
                                  fontSize: 15,
                                  height: 1.4,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat('HH:mm').format(widget.message.sentAt),
                          style: TextStyle(
                            color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (widget.isDoctor) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.done_all_rounded,
                            size: 14,
                            color: AppColors.primaryLight.withValues(alpha: 0.7),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (widget.isDoctor) ...[
                const SizedBox(width: 8),
                _buildAvatar(photoUrl, widget.message.senderName, 'D', color: AppColors.primaryBlue),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Builds image widget supporting both Firebase Storage URLs and legacy base64 data.
  Widget _buildChatImage(String imageData) {
    final bool isUrl = imageData.startsWith('http://') || imageData.startsWith('https://');
    if (isUrl) {
      return CachedNetworkImage(
        imageUrl: imageData,
        placeholder: (context, url) => Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: 200,
          height: 150,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image_rounded, color: Colors.grey, size: 40),
              SizedBox(height: 8),
              Text('فشل تحميل الصورة', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
        fit: BoxFit.cover,
      );
    } else {
      // Legacy base64 data from old nbig_app messages
      try {
        return Image.memory(
          base64Decode(imageData),
          fit: BoxFit.cover,
          width: 200,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
        );
      } catch (_) {
        return const Icon(Icons.broken_image, color: Colors.grey);
      }
    }
  }

  Widget _buildAvatar(String? photoUrl, String name, String fallbackInitial, {Color? color}) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: color != null ? color.withValues(alpha: 0.2) : Colors.grey.shade300,
      backgroundImage: (photoUrl != null && photoUrl.isNotEmpty) 
          ? NetworkImage(photoUrl) 
          : null,
      child: (photoUrl == null || photoUrl.isEmpty)
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : fallbackInitial,
              style: TextStyle(fontSize: 12, color: color),
            )
          : null,
    );
  }
}

/// Animated typing indicator with bouncing dots
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _dotControllers;

  @override
  void initState() {
    super.initState();
    _dotControllers = List.generate(3, (i) {
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
      Future.delayed(Duration(milliseconds: i * 180), () {
        if (mounted) controller.repeat(reverse: true);
      });
      return controller;
    });
  }

  @override
  void dispose() {
    for (final c in _dotControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(6),
                bottomRight: Radius.circular(20),
              ),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.grey.withValues(alpha: 0.12),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return AnimatedBuilder(
                  animation: _dotControllers[i],
                  builder: (context, _) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryLight.withValues(
                          alpha: 0.3 + _dotControllers[i].value * 0.7,
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
