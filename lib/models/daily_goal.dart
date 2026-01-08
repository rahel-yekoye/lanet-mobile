class DailyGoal {
  final int minutes;
  final String label;

  const DailyGoal({
    required this.minutes,
    required this.label,
  });

  static const List<DailyGoal> goals = [
    DailyGoal(minutes: 3, label: '3 minutes'),
    DailyGoal(minutes: 5, label: '5 minutes'),
    DailyGoal(minutes: 10, label: '10 minutes'),
    DailyGoal(minutes: 15, label: '15 minutes'),
    DailyGoal(minutes: 20, label: '20 minutes'),
    DailyGoal(minutes: 30, label: '30 minutes'),
  ];
}

class Commitment {
  final int days;
  final String label;
  final String description;

  const Commitment({
    required this.days,
    required this.label,
    required this.description,
  });

  static const List<Commitment> commitments = [
    Commitment(
      days: 7,
      label: '7 Days',
      description: 'A week of consistent learning',
    ),
    Commitment(
      days: 14,
      label: '14 Days',
      description: 'Two weeks to build a habit',
    ),
    Commitment(
      days: 30,
      label: '30 Days',
      description: 'A month of dedication',
    ),
    Commitment(
      days: 60,
      label: '60 Days',
      description: 'Two months of progress',
    ),
    Commitment(
      days: 90,
      label: '90 Days',
      description: 'Three months to mastery',
    ),
  ];
}
