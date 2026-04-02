import 'package:flutter/foundation.dart';
import '../models/character_model.dart';
import '../game/fitworld_game.dart';
import 'firestore_service.dart';
import 'health_service.dart';
import 'notification_service.dart';

/// Orchestrates startup: load persisted characters, sync new workouts, apply decay.
class WorldController extends ChangeNotifier {
  late final FirestoreService _firestore = FirestoreService();
  late final HealthService _health = HealthService();
  late final NotificationService _notifications = NotificationService(_firestore);

  FitWorldGame? game;
  String status = 'Inizializzazione...';
  bool ready = false;

  Future<void> init(FitWorldGame gameInstance) async {
    game = gameInstance;

    try {
      _setStatus('Accesso...');
      await _firestore.signInAnonymously();
      await _notifications.init();

      _setStatus('Caricamento personaggi...');
      final characters = await _firestore.loadCharacters();
      final worldHealth = await _firestore.loadWorldHealth();

      final aliveCharacters = await _applyDecayAndPersist(characters);

      for (final model in aliveCharacters) {
        game!.spawnCharacter(model);
      }
      game!.worldHealth = worldHealth;

      _setStatus('Sincronizzazione allenamenti...');
      await _syncNewWorkouts();

      ready = true;
      _setStatus('Pronto');
      notifyListeners();
    } catch (e, stack) {
      debugPrint('WorldController.init error: $e\n$stack');
      // Display generic message (don't expose paths/IDs in UI)
      _setStatus('Avvio in modalita\' demo');
      ready = true;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------

  Future<List<CharacterModel>> _applyDecayAndPersist(
      List<CharacterModel> characters) async {
    final alive = <CharacterModel>[];
    for (final c in characters) {
      final daysSinceActivity = DateTime.now().difference(c.lastActivityAt).inDays;
      if (daysSinceActivity > 0) {
        final dead = c.applyDecay(decayPerDay: daysSinceActivity * 3);
        if (dead) {
          await _firestore.deleteCharacter(c.id);
          continue;
        }
        await _firestore.saveCharacter(c);
      }
      alive.add(c);
    }
    return alive;
  }

  Future<void> _syncNewWorkouts() async {
    final processedIds = await _firestore.loadProcessedWorkoutIds();
    final since = DateTime.now().subtract(const Duration(days: 30));
    final workouts = await _health.fetchWorkoutsSince(since);

    for (final workout in workouts) {
      if (processedIds.contains(workout.sourceId)) continue;

      // addCharacterFromWorkout now returns the model directly — no race condition
      final newChar = game!.addCharacterFromWorkout(
        workoutType: workout.type,
        intensity: workout.intensity,
      );
      if (newChar != null) {
        await _firestore.saveCharacter(newChar);
      }

      await _firestore.markWorkoutProcessed(workout.sourceId);
    }

    await _firestore.saveWorldHealth(game!.worldHealth);
  }

  void _setStatus(String s) {
    status = s;
    notifyListeners();
  }
}
