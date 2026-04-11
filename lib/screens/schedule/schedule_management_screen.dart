
import 'package:flutter/material.dart';
import '../../config/colors.dart';
import '../../models/doctor.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

/// شاشة إدارة جدول مواعيد الدكتور
class ScheduleManagementScreen extends StatefulWidget {
  const ScheduleManagementScreen({super.key});

  @override
  State<ScheduleManagementScreen> createState() =>
      _ScheduleManagementScreenState();
}

class _ScheduleManagementScreenState extends State<ScheduleManagementScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  bool _isLoading = true;
  bool _isSaving = false;
  Doctor? _doctor;

  final List<Map<String, String>> _days = [
    {'key': 'saturday', 'name': 'Saturday', 'nameEn': 'Saturday'},
    {'key': 'sunday', 'name': 'Sunday', 'nameEn': 'Sunday'},
    {'key': 'monday', 'name': 'Monday', 'nameEn': 'Monday'},
    {'key': 'tuesday', 'name': 'Tuesday', 'nameEn': 'Tuesday'},
    {'key': 'wednesday', 'name': 'Wednesday', 'nameEn': 'Wednesday'},
    {'key': 'thursday', 'name': 'Thursday', 'nameEn': 'Thursday'},
    {'key': 'friday', 'name': 'Friday', 'nameEn': 'Friday'},
  ];

  // الجدول المؤقت للتعديل
  late Map<String, DaySchedule> _schedule;

  @override
  void initState() {
    super.initState();
    _schedule = {};
    _loadDoctorData();
  }

  Future<void> _loadDoctorData() async {
    final user = _authService.currentUser;
    if (user == null) return;

    final doctor = await _firestoreService.getDoctorByUserId(user.uid);
    if (doctor != null && mounted) {
      setState(() {
        _doctor = doctor;
        // نسخ الجدول الحالي أو إنشاء جدول افتراضي
        _schedule = Map.from(doctor.schedule);
        // التأكد من وجود كل الأيام
        for (var day in _days) {
          if (!_schedule.containsKey(day['key'])) {
            _schedule[day['key']!] = DaySchedule(
              isAvailable: false,
              startTime: '09:00',
              endTime: '17:00',
              slotDuration: 30,
              breakDuration: 0,
            );
          }
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSchedule() async {
    if (_doctor == null) return;

    setState(() => _isSaving = true);

    try {
      // 1. Identify newly closed days to cancel upcoming appointments
      final Map<String, int> weekdayMap = {
        'monday': DateTime.monday,
        'tuesday': DateTime.tuesday,
        'wednesday': DateTime.wednesday,
        'thursday': DateTime.thursday,
        'friday': DateTime.friday,
        'saturday': DateTime.saturday,
        'sunday': DateTime.sunday,
      };

      final List<String> newlyClosedDays = [];
      for (var dayKey in _schedule.keys) {
        final wasAvailable = _doctor!.schedule[dayKey]?.isAvailable ?? false;
        final isNowAvailable = _schedule[dayKey]?.isAvailable ?? false;
        
        if (wasAvailable && !isNowAvailable) {
          newlyClosedDays.add(dayKey);
        }
      }

      // 2. Update the doctor document
      await _firestoreService.updateDoctorSchedule(_doctor!.id, _schedule);

      // 3. Process cancellations if any days were closed
      if (newlyClosedDays.isNotEmpty) {
        debugPrint('📅 Processing bulk cancellations for: $newlyClosedDays');
        for (var dayKey in newlyClosedDays) {
          final weekday = weekdayMap[dayKey];
          if (weekday != null) {
            await _firestoreService.cancelAppointmentsOnDay(
              doctorId: _doctor!.id,
              doctorUserId: _doctor!.userId,
              targetWeekday: weekday,
              reason: 'تم إلغاء المواعيد لأن الطبيب لم يعد يستقبل حجوزات في هذا اليوم من الأسبوع.',
            );
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text(newlyClosedDays.isNotEmpty 
                  ? 'Schedule saved and affected appointments cancelled'
                  : 'Schedule saved successfully'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      
      // Update local doctor data to reflect saved state for future checks
      _loadDoctorData();
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving schedule: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<TimeOfDay?> _pickTime(
    BuildContext context,
    String? currentTime,
  ) async {
    TimeOfDay initialTime = TimeOfDay(hour: 9, minute: 0);
    if (currentTime != null && currentTime.contains(':')) {
      final parts = currentTime.split(':');
      initialTime = TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 9,
        minute: int.tryParse(parts[1]) ?? 0,
      );
    }

    return showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _displayTime(String? time) {
    if (time == null || !time.contains(':')) return '--:--';
    final parts = time.split(':');
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts[1];
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Schedule'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // زر الحفظ
          _isSaving
              ? Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                )
              : IconButton(
                  icon: Icon(Icons.save_rounded),
                  onPressed: _saveSchedule,
                  tooltip: 'Save Schedule',
                ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select your working hours',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Patients can only book appointments during available times',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),

                // قائمة الأيام
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.all(12),
                    itemCount: _days.length,
                    itemBuilder: (context, index) {
                      final day = _days[index];
                      final dayKey = day['key']!;
                      final daySchedule = _schedule[dayKey]!;
                      return _buildDayCard(day, daySchedule, dayKey);
                    },
                  ),
                ),

                // زر الحفظ الكبير
                SafeArea(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveSchedule,
                        icon: _isSaving
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(Icons.save_rounded),
                        label: Text(
                          _isSaving ? 'Saving...' : 'Save Schedule',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 3,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDayCard(
    Map<String, String> day,
    DaySchedule schedule,
    String dayKey,
  ) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      margin: EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: schedule.isAvailable ? Colors.white : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: schedule.isAvailable
              ? AppColors.primaryBlue.withValues(alpha: 0.3)
              : Colors.grey.shade200,
          width: schedule.isAvailable ? 1.5 : 1,
        ),
        boxShadow: schedule.isAvailable
            ? [
                BoxShadow(
                  color: AppColors.primaryBlue.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: Column(
        children: [
          // عنوان اليوم + Toggle
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // أيقونة اليوم
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: schedule.isAvailable
                        ? AppColors.primaryBlue
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      day['name']!.substring(0, 1),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                // اسم اليوم
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        day['name']!,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: schedule.isAvailable
                              ? AppColors.textPrimary
                              : AppColors.textHint,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        schedule.isAvailable
                            ? '${_displayTime(schedule.startTime)} - ${_displayTime(schedule.endTime)}'
                            : 'Closed',
                        style: TextStyle(
                          fontSize: 13,
                          color: schedule.isAvailable
                              ? AppColors.primaryBlue
                              : AppColors.textHint,
                          fontWeight: schedule.isAvailable
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                // Toggle
                Switch.adaptive(
                  value: schedule.isAvailable,
                  onChanged: (value) {
                    setState(() {
                      _schedule[dayKey] = DaySchedule(
                        isAvailable: value,
                        startTime: schedule.startTime ?? '09:00',
                        endTime: schedule.endTime ?? '17:00',
                        slotDuration: schedule.slotDuration ?? 30,
                        breakDuration: schedule.breakDuration ?? 0,
                      );
                    });
                  },
                  activeThumbColor: AppColors.primaryBlue,
                ),
              ],
            ),
          ),

          // تفاصيل الأوقات (فقط عند التفعيل)
          if (schedule.isAvailable)
            Container(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  Divider(height: 1),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      // وقت البداية
                      Expanded(
                        child: _buildTimePicker(
                          label: 'From',
                          time: schedule.startTime,
                          icon: Icons.login_rounded,
                          onTap: () async {
                            final picked = await _pickTime(
                              context,
                              schedule.startTime,
                            );
                            if (picked != null) {
                              setState(() {
                                _schedule[dayKey] = DaySchedule(
                                  isAvailable: true,
                                  startTime: _formatTimeOfDay(picked),
                                  endTime: schedule.endTime,
                                  slotDuration: schedule.slotDuration,
                                  breakDuration: schedule.breakDuration,
                                );
                              });
                            }
                          },
                        ),
                      ),
                      SizedBox(width: 12),
                      // وقت النهاية
                      Expanded(
                        child: _buildTimePicker(
                          label: 'To',
                          time: schedule.endTime,
                          icon: Icons.logout_rounded,
                          onTap: () async {
                            final picked = await _pickTime(
                              context,
                              schedule.endTime,
                            );
                            if (picked != null) {
                              setState(() {
                                _schedule[dayKey] = DaySchedule(
                                  isAvailable: true,
                                  startTime: schedule.startTime,
                                  endTime: _formatTimeOfDay(picked),
                                  slotDuration: schedule.slotDuration,
                                  breakDuration: schedule.breakDuration,
                                );
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  // مدة الكشف
                  _buildSlotDurationSelector(schedule, dayKey),
                  SizedBox(height: 12),
                  // مدة الاستراحة
                  _buildBreakDurationSelector(schedule, dayKey),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimePicker({
    required String label,
    required String? time,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primaryBlue.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primaryBlue),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    _displayTime(time),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.edit, size: 16, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotDurationSelector(DaySchedule schedule, String dayKey) {
    final durations = [15, 20, 30, 45, 60];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Session Duration',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        Row(
          children: durations.map((d) {
            final isSelected = (schedule.slotDuration ?? 30) == d;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _schedule[dayKey] = DaySchedule(
                      isAvailable: true,
                      startTime: schedule.startTime,
                      endTime: schedule.endTime,
                      slotDuration: d,
                      breakDuration: schedule.breakDuration,
                    );
                  });
                },
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  margin: EdgeInsets.symmetric(horizontal: 3),
                  padding: EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryBlue
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryBlue
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$d min',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBreakDurationSelector(DaySchedule schedule, String dayKey) {
    final durations = [0, 5, 10, 15, 30];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Break Duration',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        Row(
          children: durations.map((d) {
            final isSelected = (schedule.breakDuration ?? 0) == d;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _schedule[dayKey] = DaySchedule(
                      isAvailable: true,
                      startTime: schedule.startTime,
                      endTime: schedule.endTime,
                      slotDuration: schedule.slotDuration,
                      breakDuration: d,
                    );
                  });
                },
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  margin: EdgeInsets.symmetric(horizontal: 3),
                  padding: EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.orange.shade500
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? Colors.orange.shade500
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$d min',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
