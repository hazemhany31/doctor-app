import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

/// خدمة Firebase Storage للتعامل مع رفع الصور والملفات
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

  /// اختيار صورة من المعرض
  Future<XFile?> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      debugPrint('❌ خطأ في اختيار الصورة: $e');
      return null;
    }
  }

  /// التقاط صورة من الكاميرا
  Future<XFile?> pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      debugPrint('❌ خطأ في التقاط الصورة: $e');
      return null;
    }
  }

  /// رفع صورة الملف الشخصي إلى Firebase Storage
  /// Returns: URL الصورة المرفوعة
  Future<String?> uploadProfileImage({
    required String userId,
    required File imageFile,
    Function(double)? onProgress,
  }) async {
    try {
      debugPrint('📤 بدء رفع الصورة الشخصية...');

      // إنشاء مسار فريد للصورة
      final String fileName =
          'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef = _storage.ref().child(
        'doctors/profiles/$fileName',
      );

      // قراءة الملف كبايتات لتجنب مشاكل putFile على الـ iOS محاكي 
      final Uint8List fileBytes = await imageFile.readAsBytes();

      // رفع الملف مع تتبع التقدم
      final UploadTask uploadTask = storageRef.putData(
        fileBytes,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'userId': userId,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // تتبع التقدم
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        }, onError: (e) {
          debugPrint('⚠️ Stream error in uploadProfileImage: $e');
        });
      }

      // انتظار اكتمال الرفع
      final TaskSnapshot snapshot = await uploadTask.timeout(
        const Duration(seconds: 20),
        onTimeout: () => throw TimeoutException('Upload timed out'),
      );

      // الحصول على رابط التحميل
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('✅ تم رفع الصورة بنجاح: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ خطأ في رفع الصورة: $e');
      return null;
    }
  }

  /// حذف صورة من Storage
  Future<bool> deleteImage(String imageUrl) async {
    try {
      debugPrint('🗑️ حذف الصورة: $imageUrl');

      // الحصول على reference من URL
      final Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();

      debugPrint('✅ تم حذف الصورة بنجاح');
      return true;
    } catch (e) {
      debugPrint('❌ خطأ في حذف الصورة: $e');
      return false;
    }
  }

  /// رفع صور متعددة (للعيادة مثلاً)
  Future<List<String>> uploadMultipleImages({
    required String userId,
    required List<File> imageFiles,
    required String folder,
    Function(int, double)? onProgress,
  }) async {
    final List<String> uploadedUrls = [];

    try {
      for (int i = 0; i < imageFiles.length; i++) {
        final File imageFile = imageFiles[i];
        final String fileName =
            '${folder}_${userId}_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final Reference storageRef = _storage.ref().child(
          'doctors/$folder/$fileName',
        );

        final Uint8List fileBytes = await imageFile.readAsBytes();

        final UploadTask uploadTask = storageRef.putData(
          fileBytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );

        // تتبع التقدم
        if (onProgress != null) {
          uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
            final progress = snapshot.bytesTransferred / snapshot.totalBytes;
            onProgress(i, progress);
          }, onError: (e) {
            debugPrint('⚠️ Stream error in uploadMultipleImages: $e');
          });
        }

        final TaskSnapshot snapshot = await uploadTask;
        final String downloadUrl = await snapshot.ref.getDownloadURL();
        uploadedUrls.add(downloadUrl);
      }

      debugPrint('✅ تم رفع ${uploadedUrls.length} صورة بنجاح');
      return uploadedUrls;
    } catch (e) {
      debugPrint('❌ خطأ في رفع الصور: $e');
      return uploadedUrls;
    }
  }

  /// الحصول على حجم الملف بالميجابايت
  double getFileSizeInMB(File file) {
    final int bytes = file.lengthSync();
    return bytes / (1024 * 1024);
  }

  /// رفع سجل طبي لمريض (صورة أو PDF)
  Future<String?> uploadMedicalRecord({
    required String patientId,
    required String fileName,
    required Uint8List fileBytes,
    required String contentType,
  }) async {
    try {
      debugPrint('📤 جاري رفع ملف طبي للمريض: $patientId');
      
      final Reference storageRef = _storage.ref().child(
        'medical_records/$patientId/$fileName',
      );

      final UploadTask uploadTask = storageRef.putData(
        fileBytes,
        SettableMetadata(
          contentType: contentType,
          customMetadata: {
            'patientId': patientId,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      debugPrint('✅ تم رفع الملف الطبي بنجاح: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ خطأ في رفع الملف الطبي: $e');
      return null;
    }
  }

  /// رفع صورة في محادثة
  Future<String?> uploadChatImage({
    required String chatId,
    required File imageFile,
  }) async {
    try {
      debugPrint('📤 جاري رفع صورة في المحادثة: $chatId');
      
      final String fileName = 
          'img_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef = _storage.ref().child(
        'chats/$chatId/$fileName',
      );

      final Uint8List fileBytes = await imageFile.readAsBytes();

      final UploadTask uploadTask = storageRef.putData(
        fileBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      debugPrint('✅ تم رفع صورة المحادثة بنجاح: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ خطأ في رفع صورة المحادثة: $e');
      return null;
    }
  }
}

