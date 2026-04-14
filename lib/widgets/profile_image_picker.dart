

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/colors.dart';
import '../services/storage_service.dart';
import '../utils/permission_helper.dart';

/// Widget لاختيار ورفع صورة الملف الشخصي
class ProfileImagePicker extends StatefulWidget {
  final String? initialImageUrl;
  final Function(String? imageUrl, File? imageFile) onImageSelected;
  final bool isRequired;

  const ProfileImagePicker({
    super.key,
    this.initialImageUrl,
    required this.onImageSelected,
    this.isRequired = false,
  });

  @override
  State<ProfileImagePicker> createState() => _ProfileImagePickerState();
}

class _ProfileImagePickerState extends State<ProfileImagePicker> {
  final StorageService _storageService = StorageService();
  File? _selectedImage;
  String? _imageUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _imageUrl = widget.initialImageUrl;
  }

  Future<void> _pickImage(ImageSource source) async {
    // Request permissions first using our helper
    bool hasPermission = false;
    if (source == ImageSource.camera) {
      hasPermission = await PermissionHelper.requestCameraPermission(context);
    } else {
      hasPermission = await PermissionHelper.requestPhotosPermission(context);
    }

    if (!hasPermission) return;

    setState(() => _isLoading = true);

    try {
      final pickedFile = source == ImageSource.camera
          ? await _storageService.pickImageFromCamera()
          : await _storageService.pickImageFromGallery();

      if (pickedFile != null) {
        final file = File(pickedFile.path);

        // التحقق من حجم الملف (أقل من 5MB)
        final fileSizeMB = _storageService.getFileSizeInMB(file);
        if (fileSizeMB > 5) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'حجم الصورة كبير جداً. يرجى اختيار صورة أصغر من 5 ميجابايت',
                ),
                backgroundColor: AppColors.error,
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }

        setState(() {
          _selectedImage = file;
          _imageUrl = null;
        });

        widget.onImageSelected(_imageUrl, _selectedImage);
      }
    } catch (e) {
      debugPrint('❌ خطأ في اختيار الصورة: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ في اختيار الصورة'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt, color: AppColors.primaryBlue),
                title: Text('التقاط صورة'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.photo_library,
                  color: AppColors.primaryBlue,
                ),
                title: Text('اختيار من المعرض'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_selectedImage != null || _imageUrl != null)
                ListTile(
                  leading: Icon(Icons.delete, color: AppColors.error),
                  title: Text('إزالة الصورة'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedImage = null;
                      _imageUrl = null;
                    });
                    widget.onImageSelected(null, null);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // عنوان
        if (widget.isRequired)
          Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'الصورة الشخصية *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),

        // الصورة
        GestureDetector(
          onTap: _isLoading ? null : _showImageSourceDialog,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              border: Border.all(color: AppColors.primaryBlue, width: 3),
            ),
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryBlue,
                    ),
                  )
                : Stack(
                    children: [
                      // عرض الصورة
                      ClipOval(
                        child: _selectedImage != null
                            ? Image.file(
                                _selectedImage!,
                                width: 140,
                                height: 140,
                                fit: BoxFit.cover,
                              )
                            : _imageUrl != null
                            ? CachedNetworkImage(
                                imageUrl: _imageUrl!,
                                width: 140,
                                height: 140,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                errorWidget: (context, url, error) => _buildPlaceholder(),
                              )

                            : _buildPlaceholder(),
                      ),

                      // أيقونة الكاميرا
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),

        // نص توضيحي
        SizedBox(height: 12),
        Text(
          widget.isRequired
              ? 'اضغط لإضافة صورتك'
              : 'اضغط لإضافة صورتك (اختياري)',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryBlue.withValues(alpha: 0.1),
      ),
      child: Icon(
        Icons.person,
        size: 60,
        color: AppColors.primaryBlue.withValues(alpha: 0.5),
      ),
    );
  }
}

enum ImageSource { camera, gallery }
