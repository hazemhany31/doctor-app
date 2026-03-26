
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/colors.dart';

/// شاشة عرض معلومات التشخيص للدكتور
/// تساعد في تحديد مشكلة عدم ظهور البيانات من تطبيق المريض
class DiagnosticScreen extends StatefulWidget {
  const DiagnosticScreen({super.key});

  @override
  State<DiagnosticScreen> createState() => _DiagnosticScreenState();
}

class _DiagnosticScreenState extends State<DiagnosticScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? _doctorData;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDiagnosticInfo();
  }

  Future<void> _loadDiagnosticInfo() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _error = 'No user logged in';
          _loading = false;
        });
        return;
      }

      // البحث عن بيانات الدكتور
      final querySnapshot = await _firestore
          .collection('doctors')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        setState(() {
          _error = 'Doctor document not found';
          _loading = false;
        });
        return;
      }

      final doctorDoc = querySnapshot.docs.first;
      final doctorData = doctorDoc.data();

      // جلب عدد المحادثات والمواعيد
      final chatsSnapshot = await _firestore
          .collection('chats')
          .where('doctorId', isEqualTo: doctorDoc.id)
          .get();

      final appointmentsSnapshot = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorDoc.id)
          .get();

      setState(() {
        _doctorData = {
          'userId': user.uid,
          'email': user.email,
          'doctorDocumentId': doctorDoc.id,
          'doctorName': doctorData['name'],
          'specialty': doctorData['specialty'],
          'chatsCount': chatsSnapshot.docs.length,
          'appointmentsCount': appointmentsSnapshot.docs.length,
          'rawDoctorData': doctorData,
        };
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _loading = false;
      });
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم نسخ $label'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('معلومات التشخيص'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: TextStyle(fontSize: 16, color: AppColors.error),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loadDiagnosticInfo,
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildInfoCard(
                    'User ID',
                    _doctorData!['userId'],
                    Icons.person,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    'Email',
                    _doctorData!['email'] ?? 'N/A',
                    Icons.email,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    'Doctor Document ID',
                    _doctorData!['doctorDocumentId'],
                    Icons.badge,
                    isImportant: true,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    'Doctor Name',
                    _doctorData!['doctorName'] ?? 'N/A',
                    Icons.medical_services,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    'Specialty',
                    _doctorData!['specialty'] ?? 'N/A',
                    Icons.work,
                  ),
                  const SizedBox(height: 24),
                  _buildStatsCard(),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: Colors.orange.shade700,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'تعليمات',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'يجب استخدام Doctor Document ID (وليس User ID) عند إنشاء المحادثات والمواعيد من تطبيق المريض.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.orange.shade900,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'انسخ Doctor Document ID وتأكد من استخدامه في تطبيق المريض عند إرسال الرسائل أو حجز المواعيد.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.orange.shade900,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard(
    String label,
    String value,
    IconData icon, {
    bool isImportant = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isImportant ? Colors.blue.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isImportant ? Colors.blue.shade200 : Colors.grey.shade200,
          width: isImportant ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primaryBlue),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              if (isImportant) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'مهم',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 20),
                color: AppColors.primaryBlue,
                onPressed: () => _copyToClipboard(value, label),
                tooltip: 'نسخ',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'إحصائيات',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'المحادثات',
                  _doctorData!['chatsCount'].toString(),
                  Icons.chat_bubble,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  'المواعيد',
                  _doctorData!['appointmentsCount'].toString(),
                  Icons.calendar_today,
                  Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String count,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            count,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
}
