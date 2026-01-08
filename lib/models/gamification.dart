class Hearts {
  static const int maxHearts = 5;
  static const int heartRegenMinutes = 15; // Minutes to regenerate 1 heart
  
  final int current;
  final DateTime? lastHeartLossTime;
  final DateTime? lastRegenTime;

  Hearts({
    this.current = maxHearts,
    this.lastHeartLossTime,
    this.lastRegenTime,
  });

  Hearts loseHeart() {
    return Hearts(
      current: (current > 0) ? current - 1 : 0,
      lastHeartLossTime: DateTime.now(),
      lastRegenTime: lastRegenTime ?? DateTime.now(),
    );
  }

  Hearts regenerate(DateTime now) {
    if (current >= maxHearts) return this;
    
    if (lastRegenTime == null) {
      return Hearts(
        current: current,
        lastHeartLossTime: lastHeartLossTime,
        lastRegenTime: now,
      );
    }

    final minutesSinceRegen = now.difference(lastRegenTime!).inMinutes;
    final heartsToRegen = (minutesSinceRegen / heartRegenMinutes).floor();
    
    if (heartsToRegen > 0) {
      return Hearts(
        current: (current + heartsToRegen).clamp(0, maxHearts),
        lastHeartLossTime: lastHeartLossTime,
        lastRegenTime: now,
      );
    }

    return this;
  }

  bool get isFull => current >= maxHearts;
  bool get isEmpty => current <= 0;
}

class Streak {
  final int current;
  final DateTime? lastPracticeDate;
  final DateTime? freezeDate; // Streak freeze if user misses

  Streak({
    this.current = 0,
    this.lastPracticeDate,
    this.freezeDate,
  });

  Streak increment(DateTime practiceDate) {
    if (lastPracticeDate == null) {
      return Streak(
        current: 1,
        lastPracticeDate: practiceDate,
      );
    }

    final daysDifference = practiceDate.difference(lastPracticeDate!).inDays;
    
    if (daysDifference == 0) {
      // Same day, don't increment
      return this;
    } else if (daysDifference == 1) {
      // Consecutive day
      return Streak(
        current: current + 1,
        lastPracticeDate: practiceDate,
      );
    } else {
      // Broken streak
      return Streak(
        current: 1,
        lastPracticeDate: practiceDate,
      );
    }
  }

  bool willBreakIfNotPracticedTomorrow(DateTime now) {
    if (lastPracticeDate == null) return false;
    
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final daysSinceLastPractice = tomorrow.difference(lastPracticeDate!).inDays;
    
    return daysSinceLastPractice >= 1;
  }

  Streak checkAndReset(DateTime now) {
    if (lastPracticeDate == null) return this;
    
    final daysSinceLastPractice = now.difference(lastPracticeDate!).inDays;
    
    if (daysSinceLastPractice > 1) {
      // Streak broken
      return Streak(current: 0, lastPracticeDate: null);
    }
    
    return this;
  }
}

class Reward {
  final String id;
  final String title;
  final String description;
  final int gemsCost;
  final RewardType type;
  final bool isClaimed;

  Reward({
    required this.id,
    required this.title,
    required this.description,
    required this.gemsCost,
    required this.type,
    this.isClaimed = false,
  });

  Reward copyWith({bool? isClaimed}) {
    return Reward(
      id: id,
      title: title,
      description: description,
      gemsCost: gemsCost,
      type: type,
      isClaimed: isClaimed ?? this.isClaimed,
    );
  }
}

enum RewardType {
  streakFreeze,
  heartsRefill,
  avatarItem,
  theme,
  badge,
}

class XPProgress {
  final int currentXP;
  final int level;
  final int xpForCurrentLevel;
  final int xpForNextLevel;

  XPProgress({
    required this.currentXP,
    required this.level,
    required this.xpForCurrentLevel,
    required this.xpForNextLevel,
  });

  int get xpInCurrentLevel => currentXP - xpForCurrentLevel;
  int get xpNeededForNextLevel => xpForNextLevel - currentXP;
  
  double get progress => (xpInCurrentLevel / (xpForNextLevel - xpForCurrentLevel)).clamp(0.0, 1.0);

  static int calculateLevel(int totalXP) {
    // Level calculation: each level requires more XP
    // Level 1: 0-100 XP
    // Level 2: 100-250 XP
    // Level 3: 250-450 XP
    // etc.
    int level = 1;
    int xpRequired = 0;
    
    while (totalXP >= xpRequired) {
      level++;
      xpRequired += 100 + (level - 2) * 50;
    }
    
    return level - 1;
  }

  static XPProgress fromTotalXP(int totalXP) {
    final level = calculateLevel(totalXP);
    final xpForCurrentLevel = _getXPForLevel(level);
    final xpForNextLevel = _getXPForLevel(level + 1);
    
    return XPProgress(
      currentXP: totalXP,
      level: level,
      xpForCurrentLevel: xpForCurrentLevel,
      xpForNextLevel: xpForNextLevel,
    );
  }

  static int _getXPForLevel(int level) {
    if (level <= 1) return 0;
    int xp = 0;
    for (int i = 2; i <= level; i++) {
      xp += 100 + (i - 2) * 50;
    }
    return xp;
  }
}
