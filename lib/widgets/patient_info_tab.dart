
import 'package:flutter/material.dart';
import '../config/colors.dart';
import '../models/patient.dart';
import '../l10n/app_localizations.dart';

/// تبويب معلومات المريض الشخصية
class PatientInfoTab extends StatelessWidget {
  final Patient patient;

  const PatientInfoTab({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16),
          // معلومات الاتصال
          _buildSection(context, l10n.ptInfoContactTitle, [
            _buildInfoRow(Icons.phone, l10n.ptInfoPhone, patient.phone),
            _buildInfoRow(Icons.email, l10n.ptInfoEmail, patient.email),
            if (patient.address != null)
              _buildInfoRow(
                Icons.location_on,
                l10n.ptInfoAddress,
                patient.address!,
              ),
          ]),
          // السجل الطبي
          if (patient.chronicDiseases.isNotEmpty ||
              patient.allergies.isNotEmpty ||
              patient.previousSurgeries.isNotEmpty ||
              patient.currentMedications.isNotEmpty)
            _buildSection(context, l10n.ptInfoMedicalHistory, [
              if (patient.chronicDiseases.isNotEmpty)
                _buildListTile(l10n.ptInfoChronic, patient.chronicDiseases),
              if (patient.allergies.isNotEmpty)
                _buildListTile(l10n.ptInfoAllergies, patient.allergies),
              if (patient.previousSurgeries.isNotEmpty)
                _buildListTile(l10n.ptInfoSurgeries, patient.previousSurgeries),
              if (patient.currentMedications.isNotEmpty)
                _buildListTile(
                  l10n.ptInfoMedications,
                  patient.currentMedications,
                ),
            ]),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
              fontFamily: 'Cairo',
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryBlue, size: 24),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(String title, List<String> items) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: EdgeInsets.only(bottom: 4, right: 8),
              child: Row(
                children: [
                  Icon(Icons.circle, size: 6, color: AppColors.primaryBlue),
                  SizedBox(width: 8),
                  Text(item, style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
