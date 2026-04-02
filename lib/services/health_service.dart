import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import '../models/character_model.dart';

/// Maps Health Connect activity types to FitWorld workout types.
final Map<HealthWorkoutActivityType, WorkoutType> _activityMap = {
  HealthWorkoutActivityType.STRENGTH_TRAINING: WorkoutType.strength,
  HealthWorkoutActivityType.TRADITIONAL_STRENGTH_TRAINING: WorkoutType.strength,
  HealthWorkoutActivityType.FUNCTIONAL_STRENGTH_TRAINING: WorkoutType.strength,
  HealthWorkoutActivityType.WEIGHTLIFTING: WorkoutType.strength,
  HealthWorkoutActivityType.RUNNING: WorkoutType.running,
  HealthWorkoutActivityType.WALKING: WorkoutType.running,
  HealthWorkoutActivityType.HIKING: WorkoutType.running,
  HealthWorkoutActivityType.BIKING: WorkoutType.cycling,
  HealthWorkoutActivityType.SWIMMING: WorkoutType.swimming,
  HealthWorkoutActivityType.HIGH_INTENSITY_INTERVAL_TRAINING: WorkoutType.hiit,
  HealthWorkoutActivityType.MIXED_CARDIO: WorkoutType.hiit,
  HealthWorkoutActivityType.JUMP_ROPE: WorkoutType.hiit,
  HealthWorkoutActivityType.YOGA: WorkoutType.yoga,
  HealthWorkoutActivityType.PILATES: WorkoutType.yoga,
};

class WorkoutSession {
  final WorkoutType type;
  final double intensity; // 0–100
  final DateTime date;
  final String sourceId; // unique ID to avoid duplicate spawns

  const WorkoutSession({
    required this.type,
    required this.intensity,
    required this.date,
    required this.sourceId,
  });
}

class HealthService {
  final Health _health = Health();

  /// Request permissions for reading workout data.
  Future<bool> requestPermissions() async {
    final types = [HealthDataType.WORKOUT];
    final permissions = [HealthDataAccess.READ];
    return _health.requestAuthorization(types, permissions: permissions);
  }

  /// Fetch workout sessions newer than [since].
  Future<List<WorkoutSession>> fetchWorkoutsSince(DateTime since) async {
    final granted = await requestPermissions();
    if (!granted) return [];

    final now = DateTime.now();
    List<HealthDataPoint> points;
    try {
      points = await _health.getHealthDataFromTypes(
        startTime: since,
        endTime: now,
        types: [HealthDataType.WORKOUT],
      );
    } catch (e) {
      debugPrint('HealthService: failed to fetch workouts: $e');
      return [];
    }

    final sessions = <WorkoutSession>[];
    for (final point in points) {
      if (point.value is! WorkoutHealthValue) continue;
      final workout = point.value as WorkoutHealthValue;
      final workoutType = _activityMap[workout.workoutActivityType];
      if (workoutType == null) continue;

      final intensity = _calculateIntensity(workout, workoutType);
      sessions.add(WorkoutSession(
        type: workoutType,
        intensity: intensity,
        date: point.dateFrom,
        sourceId: '${point.sourceId}_${point.dateFrom.millisecondsSinceEpoch}',
      ));
    }

    return sessions;
  }

  /// Normalise raw workout metrics to a 0–100 intensity score.
  double _calculateIntensity(WorkoutHealthValue workout, WorkoutType type) {
    return switch (type) {
      WorkoutType.strength => _kcalIntensity(workout),
      WorkoutType.running  => _distanceIntensity(workout, maxKm: 20),
      WorkoutType.cycling  => _distanceIntensity(workout, maxKm: 60),
      WorkoutType.swimming => _distanceIntensity(workout, maxKm: 3),
      WorkoutType.hiit     => _kcalIntensity(workout),
      WorkoutType.yoga     => _durationIntensity(workout),
    };
  }

  double _kcalIntensity(WorkoutHealthValue workout) {
    final kcal = (workout.totalEnergyBurned ?? 200).toDouble();
    return (kcal / 700 * 100).clamp(10, 100);
  }

  double _distanceIntensity(WorkoutHealthValue workout, {required double maxKm}) {
    final km = ((workout.totalDistance ?? 0) / 1000.0).toDouble();
    return (km / maxKm * 100).clamp(5, 100);
  }

  double _durationIntensity(WorkoutHealthValue workout) {
    final kcal = (workout.totalEnergyBurned ?? 200).toDouble();
    return (kcal / 400 * 100).clamp(10, 100);
  }
}
