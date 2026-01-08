class LearningReason {
  final String id;
  final String title;
  final String description;
  final String icon;

  const LearningReason({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
  });

  static const List<LearningReason> reasons = [
    LearningReason(
      id: 'fun',
      title: 'For Fun',
      description: 'Learning for enjoyment and personal interest',
      icon: '🎮',
    ),
    LearningReason(
      id: 'travel',
      title: 'Prepare for Travel',
      description: 'Getting ready for a trip or vacation',
      icon: '✈️',
    ),
    LearningReason(
      id: 'connect',
      title: 'Connect with People',
      description: 'Building relationships with speakers',
      icon: '👥',
    ),
    LearningReason(
      id: 'work',
      title: 'For Work',
      description: 'Career or professional development',
      icon: '💼',
    ),
    LearningReason(
      id: 'school',
      title: 'For School',
      description: 'Academic requirements or studies',
      icon: '📚',
    ),
    LearningReason(
      id: 'culture',
      title: 'Explore Culture',
      description: 'Understanding culture and heritage',
      icon: '🌍',
    ),
    LearningReason(
      id: 'family',
      title: 'Family & Friends',
      description: 'Communicating with loved ones',
      icon: '❤️',
    ),
    LearningReason(
      id: 'brain',
      title: 'Brain Training',
      description: 'Mental exercise and cognitive benefits',
      icon: '🧠',
    ),
  ];
}
