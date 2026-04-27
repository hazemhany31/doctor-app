import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/donation.dart';
import '../../services/donation_service.dart';
import '../../config/colors.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'add_donation_screen.dart';

class DonationFeedScreen extends StatefulWidget {
  const DonationFeedScreen({super.key});

  @override
  State<DonationFeedScreen> createState() => _DonationFeedScreenState();
}

class _DonationFeedScreenState extends State<DonationFeedScreen> {
  final DonationService _donationService = DonationService();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: AppColors.of(context).scaffoldBg,
      appBar: AppBar(
        title: Text(
          isArabic ? 'تبرعات المجتمع' : 'Community Donations',
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
      body: StreamBuilder<List<Donation>>(
        stream: _donationService.getDonations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final donations = snapshot.data ?? [];

          if (donations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.volunteer_activism_rounded, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    isArabic ? 'لا توجد تبرعات حالياً' : 'No donations available yet',
                    style: const TextStyle(fontFamily: 'Cairo', color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: donations.length,
            itemBuilder: (context, index) {
              return _buildDonationCard(donations[index], isArabic);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddDonationScreen()),
        ),
        label: Text(
          isArabic ? 'إضافة دواء' : 'Add Medicine',
          style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        icon: const Icon(Icons.add_rounded),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showDeleteConfirmation(String donationId, bool isArabic) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.of(context).cardBg,
        title: Text(isArabic ? 'حذف التبرع' : 'Delete Donation', style: const TextStyle(fontFamily: 'Cairo')),
        content: Text(isArabic ? 'هل أنت متأكد من حذف هذا الدواء نهائياً؟' : 'Are you sure you want to delete this medication permanently?', style: const TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isArabic ? 'إلغاء' : 'Cancel', style: const TextStyle(fontFamily: 'Cairo')),
          ),
          TextButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              try {
                await _donationService.deleteDonation(donationId);
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        isArabic ? 'تم حذف الدواء بنجاح ✅' : 'Medicine deleted successfully ✅',
                        style: const TextStyle(fontFamily: 'Cairo'),
                      ),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Error: $e', style: const TextStyle(fontFamily: 'Cairo')),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text(isArabic ? 'حذف' : 'Delete', style: const TextStyle(fontFamily: 'Cairo', color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildDonationCard(Donation donation, bool isArabic) {
    final isRecommended = donation.verifiedBy.contains(_currentUserId);
    final hasRecommendations = donation.verifiedBy.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.of(context).cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.of(context).cardShadow,
        border: Border.all(color: AppColors.of(context).border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Donor Info
          ListTile(
            leading: CircleAvatar(
              backgroundImage: donation.donorPhotoUrl != null ? CachedNetworkImageProvider(donation.donorPhotoUrl!) : null,
              child: donation.donorPhotoUrl == null ? const Icon(Icons.person) : null,
            ),
            title: Text(
              donation.donorName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
            ),
            subtitle: Text(
              donation.userType == 'doctor' 
                ? (isArabic ? 'طبيب' : 'Doctor') 
                : (isArabic ? 'مريض' : 'Patient'),
              style: TextStyle(color: donation.userType == 'doctor' ? AppColors.primary : AppColors.textHint, fontSize: 12),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: donation.status == 'available' ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                donation.status.toUpperCase(),
                style: TextStyle(
                  color: donation.status == 'available' ? Colors.green : Colors.orange,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Medicine Image or Info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (donation.imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: donation.imageUrl,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  donation.medicineName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                ),
                Text(
                  '${donation.dosage ?? ""} • ${donation.quantity} ${isArabic ? "متبقي" : "Left"}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on_rounded, size: 14, color: AppColors.textHint),
                    const SizedBox(width: 4),
                    Text(donation.location, style: TextStyle(fontSize: 12, color: AppColors.textHint)),
                    const Spacer(),
                    Icon(Icons.event_note_rounded, size: 14, color: AppColors.textHint),
                    const SizedBox(width: 4),
                    Text(
                      'Exp: ${DateFormat('MM/yy').format(donation.expiryDate)}',
                      style: TextStyle(
                        fontSize: 12, 
                        color: donation.expiryDate.isBefore(DateTime.now().add(const Duration(days: 90))) ? Colors.red : AppColors.textHint
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Recommendation Badge
          if (hasRecommendations && donation.userType == 'doctor')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_rounded, color: AppColors.primary, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isArabic ? 'هذا الدواء موصى به من قبل أطباء' : 'Recommended by verified doctors',
                        style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const Divider(),

          // Actions
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    if (isRecommended) {
                      _donationService.unrecommendMedicine(donation.id, _currentUserId);
                    } else {
                      _donationService.recommendMedicine(donation.id, _currentUserId);
                    }
                  },
                  icon: Icon(
                    isRecommended ? Icons.verified_rounded : Icons.verified_outlined,
                    color: isRecommended ? AppColors.primary : AppColors.textHint,
                  ),
                  label: Text(
                    isArabic ? 'توصية طبية' : 'Doctor Recommend',
                    style: TextStyle(
                      color: isRecommended ? AppColors.primary : AppColors.textHint,
                      fontFamily: 'Cairo',
                      fontWeight: isRecommended ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                if (donation.userId == _currentUserId)
                  IconButton(
                    onPressed: () => _showDeleteConfirmation(donation.id, isArabic),
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
