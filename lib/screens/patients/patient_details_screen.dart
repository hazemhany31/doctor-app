
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../config/colors.dart';
import '../../models/patient.dart';
import '../../services/chat_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/patient_info_tab.dart';
import '../../widgets/patient_appointments_tab.dart';
import '../../widgets/patient_medical_records_tab.dart';
import '../../l10n/app_localizations.dart';
import '../chat/chat_screen.dart';

/// شاشة تفاصيل المريض مع Tabs
class PatientDetailsScreen extends StatefulWidget {
  final Patient patient;

  const PatientDetailsScreen({super.key, required this.patient});

  @override
  State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _chatService = ChatService();
  final _firestoreService = FirestoreService();

  int _previousTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabSelection);
  }

  void _handleTabSelection() {
    if (_tabController.index == 3) {
      _openChat();
      // Revert to the previous tab index to avoid showing an empty tab if chat is dismissed
      _tabController.animateTo(_previousTabIndex);
    } else {
      _previousTabIndex = _tabController.index;
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openChat() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doctor = await _firestoreService.getDoctorByUserId(user.uid);
      if (doctor == null || !mounted) return;

      final chat = await _chatService.getOrCreateChat(
        doctorId: doctor.id,
        doctorUserId: user.uid,
        doctorName: doctor.name,
        patientId: widget.patient.id,
        patientName: widget.patient.name,
      );

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(builder: (_) => ChatScreen(chat: chat)),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening chat: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 280.0,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.primaryBlue,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 48),
                        CircleAvatar(
                          radius: 46,
                          backgroundImage: widget.patient.photoUrl != null
                              ? NetworkImage(widget.patient.photoUrl!)
                              : null,
                          backgroundColor: Colors.white.withValues(alpha: 0.3),
                          child: widget.patient.photoUrl == null
                              ? const Icon(Icons.person, size: 46, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.patient.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (widget.patient.age != null) ...[
                              _buildInfoChip(
                                l10n.ptDetailAgeYears(widget.patient.age.toString()),
                                Icons.cake,
                              ),
                              const SizedBox(width: 8),
                            ],
                            if (widget.patient.gender != null)
                              _buildInfoChip(
                                widget.patient.gender == 'male'
                                    ? l10n.ptDetailGenderMale
                                    : l10n.ptDetailGenderFemale,
                                widget.patient.gender == 'male'
                                    ? Icons.male
                                    : Icons.female,
                              ),
                            if (widget.patient.bloodType != null) ...[
                              const SizedBox(width: 8),
                              _buildInfoChip(widget.patient.bloodType!, Icons.bloodtype),
                            ],
                          ],
                        ),
                        const SizedBox(height: 32), // Extra space for TabBar
                      ],
                    ),
                  ),
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
                labelStyle: const TextStyle(fontSize: 11, fontFamily: 'Cairo'),
                tabs: [
                  Tab(
                    text: l10n.ptDetailTabInfo,
                    icon: const Icon(Icons.info_outline, size: 18),
                  ),
                  Tab(
                    text: l10n.ptDetailTabAppointments,
                    icon: const Icon(Icons.calendar_today, size: 18),
                  ),
                  Tab(
                    text: l10n.ptDetailTabRecords,
                    icon: const Icon(Icons.medical_services, size: 18),
                  ),
                  const Tab(
                    text: 'Chat',
                    icon: Icon(Icons.chat_bubble_outline_rounded, size: 18),
                  ),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            PatientInfoTab(patient: widget.patient),
            PatientAppointmentsTab(patientId: widget.patient.id),
            PatientMedicalRecordsTab(patientId: widget.patient.id),
            // ─── Chat Tab ───
            const _ChatTabView(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'Cairo')),
        ],
      ),
    );
  }
}

/// تبويب الشات — واجهة انتظار خفيفة اثناء فتح المحادثة
class _ChatTabView extends StatelessWidget {
  const _ChatTabView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
        ],
      ),
    );
  }
}
