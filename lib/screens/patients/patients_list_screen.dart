import 'dart:async';
import 'package:flutter/material.dart';
import '../../config/colors.dart';
import '../../models/patient.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/patient_card.dart';
import 'patient_details_screen.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/shimmer_widgets.dart';

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
  
  Timer? _debounce;
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

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchQuery = query.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
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
        elevation: 0,
      ),
      body: Column(
        children: [
          // شريط البحث
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.ptsSearchHint,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          // قائمة المرضى
          Expanded(
            child: _doctorId == null
                ? const ShimmerLoadingList()
                : StreamBuilder<List<Patient>>(
                    stream: _firestoreService.getDoctorPatients(
                      [_doctorId!, _authService.currentUser!.uid],
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const ShimmerLoadingList();
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.people_outline,
                                size: 64,
                                color: AppColors.textHint,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                l10n.ptsNoPatients,
                                style: const TextStyle(
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
                            style: const TextStyle(color: AppColors.textSecondary),
                          ),
                        );
                      }

                      return ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 20),
                        cacheExtent: 800, // 🚀 Performance Fix
                        itemCount: patients.length,
                        itemBuilder: (context, index) {
                          return RepaintBoundary( // 🚀 Performance Fix
                            child: PatientCard(
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
