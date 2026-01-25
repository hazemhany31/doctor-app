import 'package:flutter/material.dart';
import '../../config/colors.dart';
import '../../models/doctor.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../auth/login_screen.dart';

/// شاشة الملف الشخصي
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  Doctor? _doctor;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDoctorData();
  }

  Future<void> _loadDoctorData() async {
    try {
      final user = _authService.currentUser;
      if (user == null) return;

      final doctor = await _firestoreService.getDoctorByUserId(user.uid);

      setState(() {
        _doctor = doctor;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تسجيل الخروج'),
        content: Text('هل أنت متأكد من تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text('تسجيل الخروج'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_doctor == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('الملف الشخصي'),
          backgroundColor: AppColors.primaryBlue,
        ),
        body: Center(child: Text('حدث خطأ في تحميل البيانات')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: CustomScrollView(
        slivers: [
          // Profile Header
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primaryBlue,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(gradient: AppColors.primaryGradient),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 40),
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: _doctor!.photoUrl != null
                          ? NetworkImage(_doctor!.photoUrl!)
                          : null,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      child: _doctor!.photoUrl == null
                          ? Icon(Icons.person, size: 50, color: Colors.white)
                          : null,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'د. ${_doctor!.name}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      _doctor!.specialization,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Content
          SliverToBoxAdapter(
            child: Column(
              children: [
                SizedBox(height: 16),
                // معلومات العيادة
                _buildInfoCard('معلومات العيادة', [
                  _buildInfoTile(
                    Icons.local_hospital,
                    'اسم العيادة',
                    _doctor!.clinicInfo.name,
                  ),
                  _buildInfoTile(
                    Icons.location_on,
                    'العنوان',
                    _doctor!.clinicInfo.address,
                  ),
                  _buildInfoTile(
                    Icons.attach_money,
                    'سعر الكشف',
                    '${_doctor!.clinicInfo.fees} جنيه',
                  ),
                ]),
                // معلومات شخصية
                _buildInfoCard('معلومات شخصية', [
                  _buildInfoTile(
                    Icons.email,
                    'البريد الإلكتروني',
                    _doctor!.email,
                  ),
                  _buildInfoTile(Icons.phone, 'رقم الهاتف', _doctor!.phone),
                  _buildInfoTile(
                    Icons.work,
                    'سنوات الخبرة',
                    '${_doctor!.yearsOfExperience} سنة',
                  ),
                ]),
                // الإعدادات
                _buildSettingsCard(),
                SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryBlue),
      title: Text(
        label,
        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      subtitle: Text(
        value,
        style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.settings, color: AppColors.primaryBlue),
            title: Text('الإعدادات'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Navigate to settings
            },
          ),
          Divider(height: 1),
          ListTile(
            leading: Icon(Icons.help_outline, color: AppColors.info),
            title: Text('المساعدة والدعم'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Navigate to help
            },
          ),
          Divider(height: 1),
          ListTile(
            leading: Icon(Icons.logout, color: AppColors.error),
            title: Text(
              'تسجيل الخروج',
              style: TextStyle(color: AppColors.error),
            ),
            onTap: _handleLogout,
          ),
        ],
      ),
    );
  }
}
