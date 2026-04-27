import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/donation_service.dart';
import '../../services/firestore_service.dart';
import '../../config/colors.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AddDonationScreen extends StatefulWidget {
  const AddDonationScreen({super.key});

  @override
  State<AddDonationScreen> createState() => _AddDonationScreenState();
}

class _AddDonationScreenState extends State<AddDonationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _quantityController = TextEditingController();
  final _locationController = TextEditingController();
  
  DateTime? _expiryDate;
  File? _imageFile;
  bool _isLoading = false;

  final DonationService _donationService = DonationService();
  final FirestoreService _firestoreService = FirestoreService();
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 90)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _expiryDate) {
      setState(() {
        _expiryDate = picked;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate() || _imageFile == null || _expiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار صورة وتحديد تاريخ الانتهاء', style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // 1. Get doctor profile data
      final doctor = await _firestoreService.getDoctorByUserId(user.uid);
      final doctorName = doctor?.name ?? 'Dr. User';
      final doctorPhoto = doctor?.photoUrl;

      // 2. Upload Image
      final imageUrl = await _donationService.uploadDonationImage(_imageFile!);

      // 3. Create Donation
      await _donationService.createDonation(
        medicineName: _nameController.text.trim(),
        dosage: _dosageController.text.trim(),
        quantity: int.tryParse(_quantityController.text) ?? 1,
        expiryDate: _expiryDate!,
        location: _locationController.text.trim(),
        imageUrl: imageUrl,
        donorName: doctorName,
        donorPhotoUrl: doctorPhoto,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تمت إضافة الدواء بنجاح للمجتمع ✅', style: TextStyle(fontFamily: 'Cairo')),
            backgroundColor: AppColors.primary,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    
    return Scaffold(
      backgroundColor: AppColors.of(context).scaffoldBg,
      appBar: AppBar(
        title: Text(
          isArabic ? 'إضافة دواء جديد' : 'Donate New Medicine',
          style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.premiumHeaderGradient,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Picker
              GestureDetector(
                onTap: () => _showImageSourceActionSheet(context),
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.of(context).cardBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.of(context).border),
                    image: _imageFile != null
                        ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: _imageFile == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_a_photo_rounded, size: 48, color: AppColors.primary),
                            const SizedBox(height: 12),
                            Text(
                              isArabic ? 'صور علبة الدواء' : 'Upload Medicine Box Photo',
                              style: const TextStyle(fontFamily: 'Cairo', color: AppColors.textHint),
                            ),
                          ],
                        )
                      : null,
                ),
              ).animate().fade().scale(),
              
              const SizedBox(height: 24),

              _buildTextField(
                controller: _nameController,
                label: isArabic ? 'اسم الدواء' : 'Medicine Name',
                hint: isArabic ? 'مثال: أوجمنتين' : 'e.g., Augmentin',
                icon: Icons.medication_rounded,
              ),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _dosageController,
                      label: isArabic ? 'التركيز' : 'Dosage',
                      hint: '1000mg',
                      icon: Icons.monitor_heart_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _quantityController,
                      label: isArabic ? 'الكمية' : 'Quantity',
                      hint: isArabic ? 'شريط واحد' : '1 Strip',
                      icon: Icons.numbers_rounded,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _buildTextField(
                controller: _locationController,
                label: isArabic ? 'الموقع' : 'Location',
                hint: isArabic ? 'المهندسين، الجيزة' : 'Mohandessin, Giza',
                icon: Icons.location_on_rounded,
              ),

              const SizedBox(height: 16),

              // Date Picker
              Text(
                isArabic ? 'تاريخ الصلاحية' : 'Expiry Date',
                style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _selectDate(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.of(context).cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.of(context).border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event_available_rounded, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Text(
                        _expiryDate == null
                            ? (isArabic ? 'اختر التاريخ' : 'Select Date')
                            : DateFormat('yyyy-MM-dd').format(_expiryDate!),
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          color: _expiryDate == null ? AppColors.textHint : AppColors.of(context).textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    elevation: 4,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          isArabic ? 'مشاركة الآن' : 'Donate Now',
                          style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ).animate().slide(begin: const Offset(0, 0.1)),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: (v) => v!.isEmpty ? 'مطلوب' : null,
          style: const TextStyle(fontFamily: 'Cairo'),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
            filled: true,
            fillColor: AppColors.of(context).cardBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.of(context).border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.of(context).border),
            ),
          ),
        ),
      ],
    );
  }

  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('الكاميرا', style: TextStyle(fontFamily: 'Cairo')),
              onTap: () {
                _pickImage(ImageSource.camera);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('المعرض', style: TextStyle(fontFamily: 'Cairo')),
              onTap: () {
                _pickImage(ImageSource.gallery);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
