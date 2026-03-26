import 'appointment.dart';

/// Model representing all data needed for the Dashboard screen in one package
class DashboardData {
  final int todayPatients;
  final int pendingAppointments;
  final int upcomingAppointments;
  final int totalPatients;
  final List<Appointment> todayAppointments;

  DashboardData({
    required this.todayPatients,
    required this.pendingAppointments,
    required this.upcomingAppointments,
    required this.totalPatients,
    required this.todayAppointments,
  });

  factory DashboardData.empty() => DashboardData(
    todayPatients: 0,
    pendingAppointments: 0,
    upcomingAppointments: 0,
    totalPatients: 0,
    todayAppointments: [],
  );

  DashboardData copyWith({
    int? todayPatients,
    int? pendingAppointments,
    int? upcomingAppointments,
    int? totalPatients,
    List<Appointment>? todayAppointments,
  }) {
    return DashboardData(
      todayPatients: todayPatients ?? this.todayPatients,
      pendingAppointments: pendingAppointments ?? this.pendingAppointments,
      upcomingAppointments: upcomingAppointments ?? this.upcomingAppointments,
      totalPatients: totalPatients ?? this.totalPatients,
      todayAppointments: todayAppointments ?? this.todayAppointments,
    );
  }
}
