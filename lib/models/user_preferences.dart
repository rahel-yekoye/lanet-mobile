class UserPreferences {
  final List<String> selectedLanguages;
  final Map<String, KnowledgeLevel> languageLevels; // language -> level
  final Map<String, String> learningReasons; // language -> reason
  final int dailyGoalMinutes;
  final DateTime? joinedDate;
  final String? userId;
  final String? email;
  final String? name;
  final int? age;
  final String? avatarPath;
  final int totalXP;
  final int currentStreak;
  final DateTime? lastPracticeDate;
  final int totalGems;
  final int commitmentDays; // 7, 14, 30, etc.
  final DateTime? commitmentStartDate;
  final List<String> friendIds;
  final List<String> pendingFriendRequests;

  UserPreferences({
    this.selectedLanguages = const [],
    this.languageLevels = const {},
    this.learningReasons = const {},
    this.dailyGoalMinutes = 10,
    this.joinedDate,
    this.userId,
    this.email,
    this.name,
    this.age,
    this.avatarPath,
    this.totalXP = 0,
    this.currentStreak = 0,
    this.lastPracticeDate,
    this.totalGems = 0,
    this.commitmentDays = 0,
    this.commitmentStartDate,
    this.friendIds = const [],
    this.pendingFriendRequests = const [],
  });

  UserPreferences copyWith({
    List<String>? selectedLanguages,
    Map<String, KnowledgeLevel>? languageLevels,
    Map<String, String>? learningReasons,
    int? dailyGoalMinutes,
    DateTime? joinedDate,
    String? userId,
    String? email,
    String? name,
    int? age,
    String? avatarPath,
    int? totalXP,
    int? currentStreak,
    DateTime? lastPracticeDate,
    int? totalGems,
    int? commitmentDays,
    DateTime? commitmentStartDate,
    List<String>? friendIds,
    List<String>? pendingFriendRequests,
  }) {
    return UserPreferences(
      selectedLanguages: selectedLanguages ?? this.selectedLanguages,
      languageLevels: languageLevels ?? this.languageLevels,
      learningReasons: learningReasons ?? this.learningReasons,
      dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
      joinedDate: joinedDate ?? this.joinedDate,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      name: name ?? this.name,
      age: age ?? this.age,
      avatarPath: avatarPath ?? this.avatarPath,
      totalXP: totalXP ?? this.totalXP,
      currentStreak: currentStreak ?? this.currentStreak,
      lastPracticeDate: lastPracticeDate ?? this.lastPracticeDate,
      totalGems: totalGems ?? this.totalGems,
      commitmentDays: commitmentDays ?? this.commitmentDays,
      commitmentStartDate: commitmentStartDate ?? this.commitmentStartDate,
      friendIds: friendIds ?? this.friendIds,
      pendingFriendRequests: pendingFriendRequests ?? this.pendingFriendRequests,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'selectedLanguages': selectedLanguages,
      'languageLevels': languageLevels.map((k, v) => MapEntry(k, v.toString())),
      'learningReasons': learningReasons,
      'dailyGoalMinutes': dailyGoalMinutes,
      'joinedDate': joinedDate?.toIso8601String(),
      'userId': userId,
      'email': email,
      'name': name,
      'age': age,
      'avatarPath': avatarPath,
      'totalXP': totalXP,
      'currentStreak': currentStreak,
      'lastPracticeDate': lastPracticeDate?.toIso8601String(),
      'totalGems': totalGems,
      'commitmentDays': commitmentDays,
      'commitmentStartDate': commitmentStartDate?.toIso8601String(),
      'friendIds': friendIds,
      'pendingFriendRequests': pendingFriendRequests,
    };
  }

  factory UserPreferences.fromMap(Map<String, dynamic> map) {
    return UserPreferences(
      selectedLanguages: List<String>.from(map['selectedLanguages'] ?? []),
      languageLevels: (map['languageLevels'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, KnowledgeLevel.fromString(v.toString()))) ??
          {},
      learningReasons: Map<String, String>.from(map['learningReasons'] ?? {}),
      dailyGoalMinutes: map['dailyGoalMinutes'] ?? 10,
      joinedDate: map['joinedDate'] != null
          ? DateTime.parse(map['joinedDate'])
          : null,
      userId: map['userId'],
      email: map['email'],
      name: map['name'],
      age: map['age'],
      avatarPath: map['avatarPath'],
      totalXP: map['totalXP'] ?? 0,
      currentStreak: map['currentStreak'] ?? 0,
      lastPracticeDate: map['lastPracticeDate'] != null
          ? DateTime.parse(map['lastPracticeDate'])
          : null,
      totalGems: map['totalGems'] ?? 0,
      commitmentDays: map['commitmentDays'] ?? 0,
      commitmentStartDate: map['commitmentStartDate'] != null
          ? DateTime.parse(map['commitmentStartDate'])
          : null,
      friendIds: List<String>.from(map['friendIds'] ?? []),
      pendingFriendRequests: List<String>.from(map['pendingFriendRequests'] ?? []),
    );
  }
}

enum KnowledgeLevel {
  newToLanguage('New', 'I am new to this language'),
  knowSomeWords('Know Some Words', 'I know some common words'),
  basicConversation('Basic Conversation', 'I can have basic conversations'),
  variousTopics('Various Topics', 'I can talk about various topics'),
  mostTopics('Most Topics', 'I can discuss most topics');

  final String title;
  final String description;

  const KnowledgeLevel(this.title, this.description);

  static KnowledgeLevel fromString(String value) {
    return KnowledgeLevel.values.firstWhere(
      (e) => e.toString() == value || e.title == value,
      orElse: () => KnowledgeLevel.newToLanguage,
    );
  }
}
