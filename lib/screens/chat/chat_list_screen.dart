
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/chat.dart';
import '../../services/chat_service.dart';
import '../../services/firestore_service.dart';
import '../../config/colors.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/shimmer_widgets.dart';
import 'chat_screen.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';

/// شاشة قائمة المحادثات — Premium Redesign
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  final FirestoreService _firestoreService = FirestoreService();

  String? _doctorId;
  bool _isLoadingDoctorId = true;
  Stream<List<Chat>>? _chatsStream;

  @override
  void initState() {
    super.initState();
    _loadDoctorId();
  }

  Future<void> _loadDoctorId() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doctor = await _firestoreService.getDoctorByUserId(user.uid);
        if (doctor != null && mounted) {
          setState(() {
            _doctorId = doctor.id;
            _chatsStream = _chatService
                .getDoctorChats(user.uid, doctor.id)
                .asyncMap((chats) async {
              // Enrich each chat with patient details (Resilient)
              return await Future.wait(chats.map((chat) async {
                final patient = await _firestoreService.getPatient(chat.patientId);
                if (patient != null) {
                  return chat.copyWith(
                    patientName: (chat.patientName.isEmpty ||
                                 chat.patientName.toLowerCase() == 'patient' ||
                                 chat.patientName == 'مريض')
                        ? patient.name
                        : chat.patientName,
                    patientPhotoUrl: patient.photoUrl,
                  );
                }
                return chat;
              }));
            });
            _isLoadingDoctorId = false;
          });
        } else {
          if (mounted) setState(() => _isLoadingDoctorId = false);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingDoctorId = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Column(
        children: [
          // ─── Premium Hero Header ───
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.premiumHeaderGradient,
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.chatTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          Text(
                            'راسل مرضاك مباشرة',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.55),
                              fontSize: 13,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: const Icon(
                        Icons.chat_bubble_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ─── Chat List ───
          Expanded(
            child: _isLoadingDoctorId
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _doctorId == null
                    ? EmptyStateWidget(
                        icon: Icons.error_outline,
                        title: l10n.chatErrorTitle,
                        message: l10n.chatErrorNoDoctor,
                      )
                    : StreamBuilder<List<Chat>>(
                        stream: _chatsStream,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const ShimmerLoadingList();
                          }

                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                '${l10n.chatErrorPrefix}${snapshot.error}',
                              ),
                            );
                          }

                          final chats = snapshot.data ?? [];
                          if (chats.isEmpty) {
                            return EmptyStateWidget(
                              icon: Icons.chat_bubble_outline_rounded,
                              title: l10n.chatNoChatsTitle,
                              message: l10n.chatNoChatsSub,
                            );
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.only(top: 8, bottom: 100),
                            itemCount: chats.length,
                            itemBuilder: (context, index) {
                              return _PremiumChatItem(
                                chat: chats[index],
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ChatScreen(chat: chats[index]),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// ─── Premium Chat List Item ────────────────────────────────────────────────

class _PremiumChatItem extends StatelessWidget {
  final Chat chat;
  final VoidCallback onTap;

  const _PremiumChatItem({required this.chat, required this.onTap});

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inDays == 0) return DateFormat('HH:mm').format(time);
    if (diff.inDays == 1) return 'أمس';
    if (diff.inDays < 7) return DateFormat('EEEE').format(time);
    return DateFormat('dd/MM').format(time);
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = chat.unreadCountDoctor > 0;
    final initials = chat.patientName.isNotEmpty
        ? chat.patientName.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
        : 'P';

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppColors.cardShadow,
          border: Border.all(
            color: hasUnread
                ? AppColors.primary.withValues(alpha: 0.2)
                : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            // Premium avatar with gradient
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.tealGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.20),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: chat.patientPhotoUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(26),
                      child: CachedNetworkImage(
                        imageUrl: chat.patientPhotoUrl!,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Center(
                          child: Text(
                            initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Center(
                          child: Text(
                            initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat.patientName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight:
                                hasUnread ? FontWeight.w800 : FontWeight.w600,
                            color: AppColors.textPrimary,
                            fontFamily: 'Cairo',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatTime(chat.lastMessageTime),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w400,
                          color: hasUnread
                              ? AppColors.primary
                              : AppColors.textHint,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat.lastMessage ?? '',
                          style: TextStyle(
                            fontSize: 13,
                            color: hasUnread
                                ? AppColors.textSecondary
                                : AppColors.textHint,
                            fontFamily: 'Cairo',
                            fontWeight: hasUnread
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: AppColors.tealGradient,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            '${chat.unreadCountDoctor}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
