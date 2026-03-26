
import 'package:flutter/material.dart';
import '../config/colors.dart';
import '../models/patient.dart';

/// بطاقة المريض
class PatientCard extends StatelessWidget {
  final Patient patient;
  final VoidCallback? onTap;
  final String? lastVisit;
  final int? totalVisits;

  const PatientCard({
    super.key,
    required this.patient,
    this.onTap,
    this.lastVisit,
    this.totalVisits,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              // صورة المريض
              CircleAvatar(
                radius: 30,
                backgroundImage: patient.photoUrl != null
                    ? NetworkImage(patient.photoUrl!)
                    : null,
                child: patient.photoUrl == null
                    ? Icon(Icons.person, size: 30)
                    : null,
              ),
              SizedBox(width: 16),
              // معلومات المريض
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        if (patient.age != null) ...[
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '${patient.age} سنة',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          SizedBox(width: 12),
                        ],
                        if (patient.gender != null) ...[
                          Icon(
                            patient.gender == 'male'
                                ? Icons.male
                                : Icons.female,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(width: 4),
                          Text(
                            patient.gender == 'male' ? 'ذكر' : 'أنثى',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (lastVisit != null || totalVisits != null) ...[
                      SizedBox(height: 4),
                      Row(
                        children: [
                          if (lastVisit != null) ...[
                            Text(
                              'آخر زيارة: $lastVisit',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textHint,
                              ),
                            ),
                          ],
                          if (totalVisits != null) ...[
                            if (lastVisit != null) Text(' • '),
                            Text(
                              'عدد الزيارات: $totalVisits',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textHint,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // سهم
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
