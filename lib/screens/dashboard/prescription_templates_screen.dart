import 'package:flutter/material.dart';
import '../../config/colors.dart';
import '../../models/prescription_template.dart';
import '../../models/appointment.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';

class PrescriptionTemplatesScreen extends StatefulWidget {
  const PrescriptionTemplatesScreen({super.key});

  @override
  State<PrescriptionTemplatesScreen> createState() =>
      _PrescriptionTemplatesScreenState();
}

class _PrescriptionTemplatesScreenState
    extends State<PrescriptionTemplatesScreen> {
  final _firestoreService = FirestoreService();
  final _authService = AuthService();
  String? _doctorId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDoctor();
  }

  Future<void> _loadDoctor() async {
    final user = _authService.currentUser;
    if (user != null) {
      final doctor = await _firestoreService.getDoctorByUserId(user.uid);
      if (doctor != null && mounted) {
        setState(() {
          _doctorId = doctor.id;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addOrEditTemplate({PrescriptionTemplate? template}) async {
    if (_doctorId == null) return;
    final navigator = Navigator.of(context);

    final nameController = TextEditingController(text: template?.name ?? '');
    final List<Map<String, TextEditingController>> medicineControllers = [];

    if (template != null) {
      for (var med in template.medicines) {
        medicineControllers.add({
          'name': TextEditingController(text: med.name),
          'dosage': TextEditingController(text: med.dosage),
          'frequency': TextEditingController(text: med.frequency),
          'duration': TextEditingController(text: med.duration),
        });
      }
    } else {
      medicineControllers.add({
        'name': TextEditingController(),
        'dosage': TextEditingController(),
        'frequency': TextEditingController(),
        'duration': TextEditingController(),
      });
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              decoration: BoxDecoration(
                color: AppColors.of(context).scaffoldBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.of(context).cardBg,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(20)),
                      boxShadow: AppColors.of(context).cardShadow,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          template == null
                              ? 'إضافة قالب جديد'
                              : 'تعديل القالب',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.of(context).textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'اسم القالب (مثل: برد، التهاب)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'الأدوية',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                setModalState(() {
                                  medicineControllers.add({
                                    'name': TextEditingController(),
                                    'dosage': TextEditingController(),
                                    'frequency': TextEditingController(),
                                    'duration': TextEditingController(),
                                  });
                                });
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('إضافة دواء'),
                            ),
                          ],
                        ),
                        ...List.generate(medicineControllers.length, (index) {
                          final medVars = medicineControllers[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: medVars['name'],
                                          decoration: const InputDecoration(
                                            labelText: 'اسم الدواء',
                                            isDense: true,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          setModalState(() {
                                            medicineControllers.removeAt(index);
                                          });
                                        },
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: medVars['dosage'],
                                          decoration: const InputDecoration(
                                            labelText: 'الجرعة (مثال: قرص)',
                                            isDense: true,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextField(
                                          controller: medVars['frequency'],
                                          decoration: const InputDecoration(
                                            labelText: 'التكرار (مثال: مرتين)',
                                            isDense: true,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  TextField(
                                    controller: medVars['duration'],
                                    decoration: const InputDecoration(
                                      labelText: 'المدة (مثال: 5 أيام)',
                                      isDense: true,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (nameController.text.trim().isEmpty) return;
                          
                          final medicines = medicineControllers
                              .where((mc) => mc['name']!.text.trim().isNotEmpty)
                              .map((mc) => AppointmentMedicine(
                                    name: mc['name']!.text.trim(),
                                    dosage: mc['dosage']!.text.trim(),
                                    frequency: mc['frequency']!.text.trim(),
                                    duration: mc['duration']!.text.trim(),
                                  ))
                              .toList();

                          final newTemplate = PrescriptionTemplate(
                            id: template?.id ?? '',
                            name: nameController.text.trim(),
                            medicines: medicines,
                            createdAt: template?.createdAt ?? DateTime.now(),
                          );

                          if (template == null) {
                            await _firestoreService.addPrescriptionTemplate(
                                _doctorId!, newTemplate);
                          } else {
                            await _firestoreService.updatePrescriptionTemplate(
                                _doctorId!, newTemplate);
                          }
                          
                          if (mounted) navigator.pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(template == null ? 'حفظ القالب' : 'تحديث القالب'),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_doctorId == null) {
      return const Scaffold(
        body: Center(child: Text('Doctor profile not found')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.of(context).scaffoldBg,
      appBar: AppBar(
        title: const Text('قوالب الوصفات الطبية', style: TextStyle(fontFamily: 'Cairo')),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEditTemplate(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('قالب جديد', style: TextStyle(color: Colors.white)),
      ),
      body: StreamBuilder<List<PrescriptionTemplate>>(
        stream: _firestoreService.getPrescriptionTemplates(_doctorId!),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('خطأ: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final templates = snapshot.data ?? [];

          if (templates.isEmpty) {
            return const Center(
              child: Text(
                'لا توجد قوالب محفوظة.\nانقر على زر الإضافة لإنشاء قالب جديد.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textHint, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final template = templates[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Text(
                    template.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Text('${template.medicines.length} أدوية'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: AppColors.primary),
                        onPressed: () => _addOrEditTemplate(template: template),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: AppColors.error),
                        onPressed: () => _firestoreService.deletePrescriptionTemplate(_doctorId!, template.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
