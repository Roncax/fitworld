import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

enum CharacterClass { warrior, ranger, knight, mage, assassin, druid }

enum WorkoutType { strength, running, cycling, swimming, hiit, yoga }

class CharacterModel {
  final String id;
  final CharacterClass characterClass;
  int hp;
  final int maxHp;
  final Map<String, int> stats; // str, spd, dex, will
  final int spriteLevel; // 1=weak, 2=normal, 3=strong
  double posX;
  double posY;
  final DateTime createdAt;
  DateTime lastActivityAt;
  final WorkoutType workoutType;
  final double intensity; // 0–100

  CharacterModel({
    String? id,
    required this.characterClass,
    required this.hp,
    required this.maxHp,
    required this.stats,
    required this.spriteLevel,
    required this.posX,
    required this.posY,
    required this.workoutType,
    required this.intensity,
    DateTime? createdAt,
    DateTime? lastActivityAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        lastActivityAt = lastActivityAt ?? DateTime.now();

  /// Build a CharacterModel from a workout session.
  factory CharacterModel.fromWorkout({
    required WorkoutType workoutType,
    required double intensity, // 0–100
    required double worldWidth,
    required double worldHeight,
  }) {
    final charClass = _classFromWorkout(workoutType);
    final spriteLevel = intensity >= 70 ? 3 : intensity >= 35 ? 2 : 1;
    final maxHp = (50 + intensity * 0.5).round();

    return CharacterModel(
      characterClass: charClass,
      hp: maxHp,
      maxHp: maxHp,
      stats: _statsFromWorkout(workoutType, intensity),
      spriteLevel: spriteLevel,
      posX: worldWidth * 0.1 + (worldWidth * 0.8) * (intensity / 100),
      posY: worldHeight * 0.5,
      workoutType: workoutType,
      intensity: intensity,
    );
  }

  static CharacterClass _classFromWorkout(WorkoutType type) {
    return switch (type) {
      WorkoutType.strength => CharacterClass.warrior,
      WorkoutType.running => CharacterClass.ranger,
      WorkoutType.cycling => CharacterClass.knight,
      WorkoutType.swimming => CharacterClass.mage,
      WorkoutType.hiit => CharacterClass.assassin,
      WorkoutType.yoga => CharacterClass.druid,
    };
  }

  static Map<String, int> _statsFromWorkout(WorkoutType type, double intensity) {
    final base = intensity.round();
    return switch (type) {
      WorkoutType.strength  => {'str': base, 'spd': base ~/ 4, 'dex': base ~/ 3, 'will': base ~/ 2},
      WorkoutType.running   => {'str': base ~/ 4, 'spd': base, 'dex': base ~/ 2, 'will': base ~/ 2},
      WorkoutType.cycling   => {'str': base ~/ 3, 'spd': base, 'dex': base ~/ 3, 'will': base ~/ 2},
      WorkoutType.swimming  => {'str': base ~/ 3, 'spd': base ~/ 2, 'dex': base, 'will': base ~/ 2},
      WorkoutType.hiit      => {'str': base ~/ 2, 'spd': base ~/ 2, 'dex': base, 'will': base ~/ 3},
      WorkoutType.yoga      => {'str': base ~/ 4, 'spd': base ~/ 4, 'dex': base ~/ 2, 'will': base},
    };
  }

  /// Apply daily decay. Returns true if the character should be removed.
  bool applyDecay({int decayPerDay = 3}) {
    hp = (hp - decayPerDay).clamp(0, maxHp);
    return hp <= 0;
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'class': characterClass.name,
      'hp': hp,
      'maxHp': maxHp,
      'stats': stats,
      'spriteLevel': spriteLevel,
      'posX': posX,
      'posY': posY,
      'workoutType': workoutType.name,
      'intensity': intensity,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActivityAt': Timestamp.fromDate(lastActivityAt),
    };
  }

  factory CharacterModel.fromFirestore(Map<String, dynamic> data) {
    return CharacterModel(
      id: data['id'],
      characterClass: CharacterClass.values.byName(data['class']),
      hp: data['hp'],
      maxHp: data['maxHp'],
      stats: Map<String, int>.from(data['stats']),
      spriteLevel: data['spriteLevel'],
      posX: (data['posX'] as num).toDouble(),
      posY: (data['posY'] as num).toDouble(),
      workoutType: WorkoutType.values.byName(data['workoutType']),
      intensity: (data['intensity'] as num).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastActivityAt: (data['lastActivityAt'] as Timestamp).toDate(),
    );
  }
}
