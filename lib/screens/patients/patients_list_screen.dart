
import 'package:flutter/material.dart';
import '../../config/colors.dart';
import '../../models/patient.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/patient_card.dart';
import 'patient_details_screen.dart';
import '../../l10n/app_localizations.dart';

/// شاشة قائمة المرضى
class PatientsListScreen extends StatefulWidget {
  const PatientsListScreen({super.key});

  @override
  State<PatientsListScreen> createState() => _PatientsListScreenState();
}

class _PatientsListScreenState extends State<PatientsListScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  final _searchController = TextEditingController();

  String? _doctorId;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadDoctorId();
  }

  Future<void> _loadDoctorId() async {
    final user = _authService.currentUser;
    if (user == null) return;

    final doctor = await _firestoreService.getDoctorByUserId(user.uid);
    if (!mounted) return;
    if (doctor != null) {
      setState(() => _doctorId = doctor.id);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.ptsTitle),
        backgroundColor: AppColors.primaryBlue,
      ),
      body: Column(
        children: [
          // شريط البحث
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.ptsSearchHint,
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
            ),
          ),
          // قائمة المرضى
          Expanded(
            child: _doctorId == null
                ? Center(child: CircularProgressIndicator())
                : StreamBuilder<List<Patient>>(
                    stream: _firestoreService.getDoctorPatients(
                      [_doctorId!, _authService.currentUser!.uid],
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 64,
                                color: AppColors.textHint,
                              ),
                              SizedBox(height: 16),
                              Text(
                                l10n.ptsNoPatients,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // تصفية المرضى حسب البحث
                      var patients = snapshot.data!;
                      if (_searchQuery.isNotEmpty) {
                        patients = patients
                            .where(
                              (patient) => patient.name.toLowerCase().contains(
                                _searchQuery,
                              ),
                            )
                            .toList();
                      }

                      if (patients.isEmpty) {
                        return Center(
                          child: Text(
                            l10n.ptsNoResults,
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: patients.length,
                        itemBuilder: (context, index) {
                          return PatientCard(
                            patient: patients[index],
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PatientDetailsScreen(
                                    patient: patients[index],
                                  ),
                                ),
                              );
                            },
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
