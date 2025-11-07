enum DoctorCheckStatus { pending, checking, success, warning, error }

class DoctorCheck {
  final String title;
  final String description;
  final DoctorCheckStatus status;
  final String? resultMessage;

  const DoctorCheck({
    required this.title,
    required this.description,
    this.status = DoctorCheckStatus.pending,
    this.resultMessage,
  });
}
