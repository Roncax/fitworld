import 'dart:math';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../models/character_model.dart';
import 'components/character_component.dart';
import 'components/interaction_effect.dart';

class FitWorldGame extends FlameGame {
  final List<CharacterModel> initialCharacters;
  final _rng = Random();

  static const int kMaxPerClass = 5;
  static const double kInteractionRadius = 70.0;
  static const double kInteractionCooldown = 12.0; // seconds per pair

  final Map<String, CharacterComponent> _characterComponents = {};

  // Cooldown tracker: key = sorted pair of IDs joined with ':'
  final Map<String, double> _pairCooldowns = {};

  double worldHealth = 80;

  FitWorldGame({this.initialCharacters = const []});

  @override
  Color backgroundColor() {
    final g = (100 + (worldHealth / 100) * 80).round().clamp(0, 255);
    final r = (30 + ((100 - worldHealth) / 100) * 60).round().clamp(0, 255);
    return Color.fromARGB(255, r, g, 60);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _drawWorld();
    for (final model in initialCharacters) {
      _spawnCharacter(model);
    }
    if (initialCharacters.isEmpty) {
      _addDemoCharacters();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _tickCooldowns(dt);
    _checkAllInteractions();
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Spawns a character from a workout. Returns the model if spawned, null if class limit reached.
  CharacterModel? addCharacterFromWorkout({
    required WorkoutType workoutType,
    required double intensity,
  }) {
    final targetClass = CharacterModel.fromWorkout(
      workoutType: workoutType,
      intensity: intensity,
      worldWidth: size.x,
      worldHeight: size.y * 0.75,
    ).characterClass;

    final classCount = _characterComponents.values
        .where((c) => c.model.characterClass == targetClass)
        .length;

    if (classCount >= kMaxPerClass) {
      _boostWeakest(workoutType, intensity);
      return null;
    }

    final model = CharacterModel.fromWorkout(
      workoutType: workoutType,
      intensity: intensity,
      worldWidth: size.x,
      worldHeight: size.y * 0.75,
    );
    _spawnCharacter(model);
    return model;
  }

  void removeCharacter(String id) {
    final comp = _characterComponents[id];
    if (comp != null) {
      comp.playDeathEffect();
      _characterComponents.remove(id);
    }
    _updateWorldHealth();
  }

  void spawnCharacter(CharacterModel model) => _spawnCharacter(model);

  // ---------------------------------------------------------------------------
  // Collision detection — checked every frame
  // ---------------------------------------------------------------------------

  void _checkAllInteractions() {
    final chars = _characterComponents.values.toList();
    for (int i = 0; i < chars.length; i++) {
      for (int j = i + 1; j < chars.length; j++) {
        final a = chars[i];
        final b = chars[j];
        if (a.isFrozen || b.isFrozen) continue;

        final pairKey = _pairKey(a.model.id, b.model.id);
        if (_pairCooldowns.containsKey(pairKey)) continue;

        final dist = (a.position - b.position).length;
        if (dist < kInteractionRadius) {
          _triggerInteraction(a, b);
          _pairCooldowns[pairKey] = kInteractionCooldown;
        }
      }
    }
  }

  void _tickCooldowns(double dt) {
    for (final key in _pairCooldowns.keys.toList()) {
      _pairCooldowns[key] = _pairCooldowns[key]! - dt;
    }
    _pairCooldowns.removeWhere((_, v) => v <= 0);
  }

  void _triggerInteraction(CharacterComponent a, CharacterComponent b) {
    // Characters face each other
    a.faceToward(b.position);
    b.faceToward(a.position);

    final roll = _rng.nextDouble();
    final midpoint = (a.position + b.position) / 2;

    if (roll < 0.40) {
      _doCombat(a, b, midpoint);
    } else if (roll < 0.70) {
      _doTraining(a, b, midpoint);
    }
    // else: neutral pass-by — no effect, just cooldown applied
  }

  void _doCombat(CharacterComponent a, CharacterComponent b, Vector2 midpoint) {
    const freezeDuration = 1.0;
    a.freeze(freezeDuration);
    b.freeze(freezeDuration);
    a.playInteractionEffect();
    b.playInteractionEffect();

    // Particle burst at midpoint
    add(InteractionEffect.combat(midpoint.clone()));

    // Floating label
    add(FloatingLabel(
      position: midpoint + Vector2(0, -20),
      text: '\u2694 SCONTRO!',
      color: const Color(0xFFFF4444),
    ));
  }

  void _doTraining(CharacterComponent a, CharacterComponent b, Vector2 midpoint) {
    const freezeDuration = 1.2;
    a.freeze(freezeDuration);
    b.freeze(freezeDuration);
    a.playInteractionEffect();
    b.playInteractionEffect();

    add(InteractionEffect.training(midpoint.clone()));

    add(FloatingLabel(
      position: midpoint + Vector2(0, -20),
      text: '\uD83D\uDCAA TRAINING!',
      color: const Color(0xFFFFD700),
    ));
  }

  // ---------------------------------------------------------------------------
  // World drawing
  // ---------------------------------------------------------------------------

  void _drawWorld() {
    add(RectangleComponent(
      position: Vector2(0, size.y * 0.75),
      size: Vector2(size.x, size.y * 0.25),
      paint: Paint()..color = const Color(0xFF2D5A1B),
    ));

    for (int i = 0; i < (size.x / 16).ceil(); i++) {
      add(RectangleComponent(
        position: Vector2(i * 16.0, size.y * 0.75 - 4),
        size: Vector2(8, 4),
        paint: Paint()..color = const Color(0xFF4A8F2A),
      ));
    }

    for (int i = 0; i < 5; i++) {
      final x = size.x * (0.1 + i * 0.18);
      _drawPixelTree(x, size.y * 0.6);
    }
  }

  void _drawPixelTree(double x, double y) {
    add(RectangleComponent(
      position: Vector2(x, y),
      size: Vector2(8, 20),
      paint: Paint()..color = const Color(0xFF8B4513),
    ));
    add(RectangleComponent(
      position: Vector2(x - 12, y - 24),
      size: Vector2(32, 28),
      paint: Paint()..color = const Color(0xFF228B22),
    ));
    add(RectangleComponent(
      position: Vector2(x - 6, y - 36),
      size: Vector2(20, 16),
      paint: Paint()..color = const Color(0xFF32CD32),
    ));
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  void _spawnCharacter(CharacterModel model) {
    final comp = CharacterComponent(model);
    _characterComponents[model.id] = comp;
    add(comp);
  }

  void _boostWeakest(WorkoutType type, double intensity) {
    final targetClass = CharacterClass.values[WorkoutType.values.indexOf(type)];
    CharacterComponent? weakest;
    for (final comp in _characterComponents.values) {
      if (comp.model.characterClass == targetClass) {
        if (weakest == null || comp.model.hp < weakest.model.hp) {
          weakest = comp;
        }
      }
    }
    if (weakest != null) {
      weakest.model.hp =
          (weakest.model.hp + intensity * 0.2).round().clamp(0, weakest.model.maxHp);
      weakest.playInteractionEffect();
    }
  }

  void _updateWorldHealth() {
    if (_characterComponents.isEmpty) {
      worldHealth = 10;
      return;
    }
    final avg = _characterComponents.values
            .map((c) => c.model.hp / c.model.maxHp)
            .reduce((a, b) => a + b) /
        _characterComponents.length;
    worldHealth = (avg * 100).clamp(0, 100);
  }

  void _addDemoCharacters() {
    final demos = [
      (WorkoutType.strength, 80.0),
      (WorkoutType.running, 60.0),
      (WorkoutType.strength, 40.0),
      (WorkoutType.hiit, 90.0),
      (WorkoutType.yoga, 50.0),
    ];
    for (final (type, intensity) in demos) {
      final model = CharacterModel.fromWorkout(
        workoutType: type,
        intensity: intensity,
        worldWidth: size.x,
        worldHeight: size.y * 0.75,
      );
      model.posX = 50.0 + _rng.nextDouble() * (size.x - 100);
      model.posY = 80.0 + _rng.nextDouble() * (size.y * 0.65);
      _spawnCharacter(model);
    }
  }

  String _pairKey(String idA, String idB) =>
      idA.compareTo(idB) < 0 ? '$idA:$idB' : '$idB:$idA';
}
