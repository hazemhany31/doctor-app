import 'package:flutter/material.dart';
import '../../config/colors.dart';
import '../../models/patient.dart';
import '../../widgets/patient_info_tab.dart';
import '../../widgets/patient_appointments_tab.dart';
import '../../widgets/patient_medical_records_tab.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200.0,
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
                        SizedBox(height: 60), // مسافة للـ AppBar
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: widget.patient.photoUrl != null
                              ? NetworkImage(widget.patient.photoUrl!)
                              : null,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          child: widget.patient.photoUrl == null
                              ? Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        SizedBox(height: 12),
                        Text(
                          widget.patient.name,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (widget.patient.age != null) ...[
                              _buildInfoChip(
                                '${widget.patient.age} سنة',
                                Icons.cake,
                              ),
                              SizedBox(width: 12),
                            ],
                            if (widget.patient.gender != null)
                              _buildInfoChip(
                                widget.patient.gender == 'male'
                                    ? 'ذكر'
                                    : 'أنثى',
                                widget.patient.gender == 'male'
                                    ? Icons.male
                                    : Icons.female,
                              ),
                            if (widget.patient.bloodType != null) ...[
                              SizedBox(width: 12),
                              _buildInfoChip(
                                widget.patient.bloodType!,
                                Icons.bloodtype,
                              ),
                            ],
                          ],
                        ),
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
                unselectedLabelColor: Colors.white.withOpacity(0.7),
                tabs: [
                  Tab(
                    text: 'معلومات',
                    icon: Icon(Icons.info_outline, size: 20),
                  ),
                  Tab(
                    text: 'مواعيد',
                    icon: Icon(Icons.calendar_today, size: 20),
                  ),
                  Tab(
                    text: 'سجلات طبية',
                    icon: Icon(Icons.medical_services, size: 20),
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
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          SizedBox(width: 4),
          Text(text, style: TextStyle(color: Colors.white, fontSize: 14)),
        ],
      ),
    );
  }
}
