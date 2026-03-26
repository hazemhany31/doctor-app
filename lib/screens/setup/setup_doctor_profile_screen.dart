
import 'dart:io';
import 'package:flutter/material.dart';
import '../../config/colors.dart';
import '../../models/doctor.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/profile_image_picker.dart';
import '../../widgets/progress_stepper.dart';

/// شاشة إعداد الملف الشخصي للدكتور - Wizard متعدد الخطوات
class SetupDoctorProfileScreen extends StatefulWidget {
  final Doctor? doctor; // للتعديل

  const SetupDoctorProfileScreen({super.key, this.doctor});

  @override
  State<SetupDoctorProfileScreen> createState() =>
      _SetupDoctorProfileScreenState();
}

class _SetupDoctorProfileScreenState extends State<SetupDoctorProfileScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  final _storageService = StorageService();

  // Page Controller
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 3;

  // Form Keys
  final _step1FormKey = GlobalKey<FormState>();
  final _step2FormKey = GlobalKey<FormState>();
  final _step3FormKey = GlobalKey<FormState>();

  // Step 1: الصورة الشخصية والمعلومات الأساسية
  File? _profileImage;
  String? _profileImageUrl;
  final _nameController = TextEditingController();
  final _specializationController = TextEditingController();
  String? _selectedEnglishSpecialty;

  // Step 2: معلومات العيادة
  final _clinicNameController = TextEditingController();
  final _clinicAddressController = TextEditingController();
  final _clinicPhoneController = TextEditingController();
  final _clinicFeesController = TextEditingController();
  final _clinicHoursController = TextEditingController();

  // Step 3: معلومات إضافية
  final _phoneController = TextEditingController();
  final _yearsController = TextEditingController();
  final _bioController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  double _uploadProgress = 0.0;

  final List<Map<String, String>> _specializations = [
    {'en': 'Internal Medicine', 'ar': 'باطنة'},
    {'en': 'Pediatrics', 'ar': 'أطفال'},
    {'en': 'Obstetrics & Gynecology', 'ar': 'نساء وتوليد'},
    {'en': 'General Surgery', 'ar': 'جراحة عامة'},
    {'en': 'Orthopedics', 'ar': 'عظام'},
    {'en': 'Cardiology', 'ar': 'قلب'},
    {'en': 'ENT', 'ar': 'أنف وأذن وحنجرة'},
    {'en': 'Dermatology', 'ar': 'جلدية'},
    {'en': 'Ophthalmology', 'ar': 'عيون'},
    {'en': 'Dentistry', 'ar': 'أسنان'},
    {'en': 'Neurology', 'ar': 'مخ وأعصاب'},
    {'en': 'Psychiatry', 'ar': 'نفسية'},
    {'en': 'Other', 'ar': 'أخرى'},
  ];

  String _getArabicSpecialty(String englishKey) {
    final spec = _specializations.firstWhere(
      (s) => s['en'] == englishKey,
      orElse: () => {'en': englishKey, 'ar': englishKey},
    );
    return spec['ar']!;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _specializationController.dispose();
    _clinicNameController.dispose();
    _clinicAddressController.dispose();
    _clinicPhoneController.dispose();
    _clinicFeesController.dispose();
    _clinicHoursController.dispose();
    _phoneController.dispose();
    _yearsController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // تحميل البيانات إذا كان في وضع التعديل
    if (widget.doctor != null) {
      _loadDoctorData();
    }
  }

  void _loadDoctorData() {
    final doctor = widget.doctor!;

    // Step 1: المعلومات الأساسية
    _nameController.text = doctor.name;
    // Store English key in memory, but show Arabic in the field when displaying if needed.
    // However, it's easier to just store English in the controller and use a variable for English
    // Let's store English key in a variable and show Arabic in controller.
    _selectedEnglishSpecialty = doctor.specialization;
    _specializationController.text = _getArabicSpecialty(doctor.specialization);
    _profileImageUrl = doctor.photoUrl;

    // Step 2: معلومات العيادة
    _clinicNameController.text = doctor.clinicInfo.name;
    _clinicAddressController.text = doctor.clinicInfo.address;
    _clinicPhoneController.text = doctor.clinicInfo.phone ?? '';
    _clinicFeesController.text = doctor.clinicInfo.fees > 0
        ? doctor.clinicInfo.fees.toStringAsFixed(0)
        : '';
    _clinicHoursController.text = doctor.clinicInfo.workingHours ?? '';

    // Step 3: معلومات إضافية
    _phoneController.text = doctor.phone;
    _yearsController.text = doctor.yearsOfExperience > 0
        ? doctor.yearsOfExperience.toString()
        : '';
    _bioController.text = doctor.bio ?? '';
  }

  void _nextStep() {
    // Validate current step
    if (!_validateCurrentStep()) {
      return;
    }

    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // آخر خطوة - حفظ البيانات
      _saveProfile();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // إكمال لاحقاً - حفظ البيانات الجزئية
      _saveProfile();
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _step1FormKey.currentState?.validate() ?? false;
      case 1:
        return _step2FormKey.currentState?.validate() ?? false;
      case 2:
        // الخطوة 3 كلها اختيارية
        return true;
      default:
        return false;
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _uploadProgress = 0.0;
    });

    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('لم يتم تسجيل الدخول');
      }

      // رفع الصورة الشخصية إن وجدت
      String? uploadedPhotoUrl;
      if (_profileImage != null) {
        setState(() => _uploadProgress = 0.1);
        uploadedPhotoUrl = await _storageService.uploadProfileImage(
          userId: user.uid,
          imageFile: _profileImage!,
          onProgress: (progress) {
            if (mounted) setState(() => _uploadProgress = 0.1 + (progress * 0.3));
          },
        );
        if (uploadedPhotoUrl == null) {
          throw Exception('فشل رفع الصورة الشخصية. يرجى التحقق من اتصالك بالإنترنت والمحاولة مجدداً.');
        }
      }

      setState(() => _uploadProgress = 0.5);

      // تجهيز معلومات العيادة
      final clinicInfo = {
        'name': _clinicNameController.text.trim(),
        'address': _clinicAddressController.text.trim(),
        'phone': _clinicPhoneController.text.trim(),
        'workingHours': _clinicHoursController.text.trim(),
        'fees': double.tryParse(_clinicFeesController.text.trim()) ?? 0.0,
        'photos': [],
      };

      debugPrint('📋 البيانات المُرسلة:');
      debugPrint('   name: ${_nameController.text.trim()}');
      debugPrint('   specialization: ${_specializationController.text.trim()}');
      debugPrint('   phone: ${_phoneController.text.trim()}');
      debugPrint(
        '   yearsOfExperience: ${int.tryParse(_yearsController.text.trim())}',
      );
      debugPrint('   photoUrl: ${uploadedPhotoUrl ?? _profileImageUrl}');
      debugPrint('   clinicInfo: $clinicInfo');

      setState(() => _uploadProgress = 0.7);

      // إنشاء أو تحديث الملف الشخصي في Firestore
      if (widget.doctor != null) {
        // وضع التعديل - تحديث البيانات الحالية
        await _firestoreService.updateDoctorProfile(
          doctorId: widget.doctor!.id,
          name: _nameController.text.trim(),
          specialization: _selectedEnglishSpecialty ?? _specializationController.text.trim(),
          phone: _phoneController.text.trim(),
          yearsOfExperience: int.tryParse(_yearsController.text.trim()),
          bio: _bioController.text.trim(),
          photoUrl: uploadedPhotoUrl ?? _profileImageUrl,
          clinicInfo: clinicInfo,
        );
        debugPrint('✅ تم تحديث الملف الشخصي بنجاح');
      } else {
        // وضع الإنشاء - إنشاء ملف جديد
        final docId = await _firestoreService.createDoctorProfile(
          userId: user.uid,
          name: _nameController.text.trim(),
          specialization: _selectedEnglishSpecialty ?? _specializationController.text.trim(),
          email: user.email ?? '',
          phoneNumber: _phoneController.text.trim(),
          yearsOfExperience: int.tryParse(_yearsController.text.trim()),
          about: _bioController.text.trim(),
          photoUrl: uploadedPhotoUrl ?? _profileImageUrl,
          clinicInfo: clinicInfo,
        );
        debugPrint('✅ تم إنشاء الملف الشخصي بنجاح - Doctor ID: $docId');
      }

      setState(() => _uploadProgress = 1.0);

      // انتظار قليلاً للتأكد من حفظ البيانات في Firestore
      await Future.delayed(Duration(milliseconds: 500));

      if (!mounted) return;

      // عرض رسالة النجاح
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ تم حفظ الملف الشخصي بنجاح!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // انتظار ظهور الرسالة ثم العودة
      await Future.delayed(Duration(milliseconds: 500));

      if (!mounted) return;

      // العودة للصفحة السابقة (Dashboard) مع refresh
      Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint('❌ خطأ في حفظ الملف الشخصي: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'حدث خطأ في حفظ البيانات. يرجى المحاولة مرة أخرى.';
      });
    }
  }

  void _showSpecializationPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          height: 300,
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Text(
                'اختر التخصص',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _specializations.length,
                  itemBuilder: (context, index) {
                    final spec = _specializations[index];
                    return ListTile(
                      title: Text(spec['ar']!),
                      onTap: () {
                        setState(() {
                          _selectedEnglishSpecialty = spec['en'];
                          _specializationController.text = spec['ar']!;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Text('إعداد الملف الشخصي'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Progress Stepper
          ProgressStepper(
            totalSteps: _totalSteps,
            currentStep: _currentStep,
            stepTitles: [
              'المعلومات الأساسية',
              'معلومات العيادة',
              'معلومات إضافية',
            ],
          ),

          // PageView
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() => _currentStep = index);
              },
              children: [_buildStep1(), _buildStep2(), _buildStep3()],
            ),
          ),

          // Navigation Buttons
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  // الخطوة 1: الصورة الشخصية والمعلومات الأساسية
  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Form(
        key: _step1FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // رسالة ترحيبية
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.primaryBlue,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'مرحباً! لنبدأ بإضافة معلوماتك الأساسية',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),

            // الصورة الشخصية
            ProfileImagePicker(
              initialImageUrl: _profileImageUrl,
              onImageSelected: (url, file) {
                setState(() {
                  _profileImageUrl = url;
                  _profileImage = file;
                });
              },
            ),
            SizedBox(height: 32),

            // حقل الاسم
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'الاسم الكامل *',
                hintText: 'Doctor Ahmed / د. أحمد',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'يرجى إدخال الاسم';
                }
                return null;
              },
            ),
            SizedBox(height: 16),

            // حقل التخصص
            TextFormField(
              controller: _specializationController,
              readOnly: true,
              onTap: _showSpecializationPicker,
              decoration: InputDecoration(
                labelText: 'التخصص *',
                hintText: 'اختر التخصص',
                prefixIcon: Icon(Icons.medical_services_outlined),
                suffixIcon: Icon(Icons.arrow_drop_down),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'يرجى اختيار التخصص';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  // الخطوة 2: معلومات العيادة
  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Form(
        key: _step2FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // اسم العيادة
            TextFormField(
              controller: _clinicNameController,
              decoration: InputDecoration(
                labelText: 'اسم العيادة *',
                hintText: 'Clinic / عيادة',
                prefixIcon: Icon(Icons.local_hospital_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'يرجى إدخال اسم العيادة';
                }
                return null;
              },
            ),
            SizedBox(height: 16),

            // العنوان
            TextFormField(
              controller: _clinicAddressController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'عنوان العيادة *',
                hintText: 'شارع، مدينة، محافظة',
                prefixIcon: Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'يرجى إدخال العنوان';
                }
                return null;
              },
            ),
            SizedBox(height: 16),

            // رقم هاتف العيادة
            TextFormField(
              controller: _clinicPhoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'رقم هاتف العيادة',
                hintText: '01234567890',
                prefixIcon: Icon(Icons.phone_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            SizedBox(height: 16),

            // رسوم الكشف
            TextFormField(
              controller: _clinicFeesController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'رسوم الكشف *',
                hintText: '200',
                prefixIcon: Icon(Icons.attach_money),
                suffixText: 'جنيه',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'يرجى إدخال رسوم الكشف';
                }
                if (double.tryParse(value) == null) {
                  return 'يرجى إدخال رقم صحيح';
                }
                return null;
              },
            ),
            SizedBox(height: 16),

            // ساعات العمل
            TextFormField(
              controller: _clinicHoursController,
              decoration: InputDecoration(
                labelText: 'ساعات العمل',
                hintText: 'السبت-الخميس 9ص-5م',
                prefixIcon: Icon(Icons.access_time),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // الخطوة 3: معلومات إضافية
  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Form(
        key: _step3FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // رسالة توضيحية
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'جميع الحقول في هذه الخطوة اختيارية. يمكنك إكمالها لاحقاً.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // رقم الهاتف الشخصي
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'رقم الهاتف الشخصي',
                hintText: '01234567890',
                prefixIcon: Icon(Icons.phone_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            SizedBox(height: 16),

            // سنوات الخبرة
            TextFormField(
              controller: _yearsController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'سنوات الخبرة',
                hintText: '5',
                prefixIcon: Icon(Icons.work_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (value != null &&
                    value.isNotEmpty &&
                    int.tryParse(value) == null) {
                  return 'يرجى إدخال رقم صحيح';
                }
                return null;
              },
            ),
            SizedBox(height: 16),

            // نبذة عن الدكتور
            TextFormField(
              controller: _bioController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'نبذة عنك',
                hintText: 'اكتب نبذة مختصرة عن خبراتك...',
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 60),
                  child: Icon(Icons.description_outlined),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // رسالة خطأ
          if (_errorMessage != null)
            Container(
              padding: EdgeInsets.all(12),
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: AppColors.error, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: AppColors.error, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),

          // Progress bar أثناء الرفع
          if (_isLoading && _uploadProgress > 0)
            Column(
              children: [
                LinearProgressIndicator(
                  value: _uploadProgress,
                  backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primaryBlue,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'جاري الحفظ... ${(_uploadProgress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 16),
              ],
            ),

          // الأزرار
          Row(
            children: [
              // زر السابق
              if (_currentStep > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _previousStep,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: AppColors.primaryBlue),
                    ),
                    child: Text(
                      'السابق',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                ),

              if (_currentStep > 0) SizedBox(width: 12),

              // زر التخطي (فقط في الخطوة 3)
              if (_currentStep == 2)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _skipStep,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: AppColors.textSecondary),
                    ),
                    child: Text(
                      'إكمال لاحقاً',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),

              if (_currentStep == 2) SizedBox(width: 12),

              // زر التالي/حفظ
              Expanded(
                flex: _currentStep == 0 ? 1 : 1,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          _currentStep == _totalSteps - 1
                              ? 'حفظ والمتابعة'
                              : 'التالي',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
