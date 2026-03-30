import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import '../../models/character_model.dart';

/// Pixel size of each "block" in the 8-bit sprite
const double kPixelSize = 4.0;

/// Colour palettes per class (main body color, accent, outline)
final Map<CharacterClass, List<Color>> kClassColors = {
  CharacterClass.warrior:  [const Color(0xFFB22222), const Color(0xFF8B0000), const Color(0xFF4A0000)],
  CharacterClass.ranger:   [const Color(0xFF228B22), const Color(0xFF006400), const Color(0xFF003200)],
  CharacterClass.knight:   [const Color(0xFF4169E1), const Color(0xFF00008B), const Color(0xFF000050)],
  CharacterClass.mage:     [const Color(0xFF9932CC), const Color(0xFF6A0DAD), const Color(0xFF3A006F)],
  CharacterClass.assassin: [const Color(0xFF2F4F4F), const Color(0xFF1C3333), const Color(0xFF0A1A1A)],
  CharacterClass.druid:    [const Color(0xFF8FBC8F), const Color(0xFF2E8B57), const Color(0xFF145A32)],
};

class CharacterComponent extends PositionComponent with HasGameReference {
  final CharacterModel model;

  // Movement
  late Vector2 _velocity;
  static final _rng = Random();
  double _directionTimer = 0;
  static const double _directionChangeInterval = 2.5;

  // Interaction freeze
  double _freezeTimer = 0;
  bool get isFrozen => _freezeTimer > 0;

  // Death guard — prevents double removeFromParent
  bool _isDead = false;

  // Facing direction: true = facing right
  bool _facingRight = true;

  // HP bar
  late RectangleComponent _hpBar;
  late RectangleComponent _hpBarBg;

  CharacterComponent(this.model)
      : super(
          position: Vector2(model.posX, model.posY),
          size: Vector2(16 * kPixelSize, 20 * kPixelSize),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    _velocity = _randomVelocity();

    _hpBarBg = RectangleComponent(
      size: Vector2(size.x, 4),
      position: Vector2(0, -8),
      paint: Paint()..color = const Color(0xFF333333),
    );
    _hpBar = RectangleComponent(
      size: Vector2(size.x * (model.hp / model.maxHp), 4),
      position: Vector2(0, -8),
      paint: Paint()..color = const Color(0xFF00FF00),
    );

    add(_hpBarBg);
    add(_hpBar);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Decrease freeze timer
    if (_freezeTimer > 0) {
      _freezeTimer -= dt;
      return; // frozen: skip movement
    }

    // Periodically change direction
    _directionTimer += dt;
    if (_directionTimer >= _directionChangeInterval) {
      _directionTimer = 0;
      _velocity = _randomVelocity();
    }

    // Update facing direction
    if (_velocity.x.abs() > 1) {
      _facingRight = _velocity.x > 0;
    }

    // Move
    position += _velocity * dt;

    // Bounce off world edges
    final bounds = game.size;
    if (position.x < size.x / 2) {
      position.x = size.x / 2;
      _velocity.x = _velocity.x.abs();
      _facingRight = true;
    } else if (position.x > bounds.x - size.x / 2) {
      position.x = bounds.x - size.x / 2;
      _velocity.x = -_velocity.x.abs();
      _facingRight = false;
    }
    if (position.y < size.y / 2 + 20) {
      position.y = size.y / 2 + 20;
      _velocity.y = _velocity.y.abs();
    } else if (position.y > bounds.y - size.y / 2) {
      position.y = bounds.y - size.y / 2;
      _velocity.y = -_velocity.y.abs();
    }

    // Sync model position
    model.posX = position.x;
    model.posY = position.y;

    // Update HP bar (guard against maxHp=0)
    final hpFraction = model.maxHp > 0 ? (model.hp / model.maxHp).clamp(0.0, 1.0) : 0.0;
    _hpBar.size.x = size.x * hpFraction;
    _hpBar.paint.color = hpFraction > 0.5
        ? const Color(0xFF00FF00)
        : hpRatio > 0.25
            ? const Color(0xFFFFAA00)
            : const Color(0xFFFF0000);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    _drawPixelSprite(canvas);
  }

  /// Freeze movement for [seconds] seconds (used during interactions).
  void freeze(double seconds) {
    _freezeTimer = seconds;
  }

  /// Face toward another character.
  void faceToward(Vector2 other) {
    _facingRight = other.x > position.x;
  }

  void playInteractionEffect() {
    add(
      ScaleEffect.by(
        Vector2.all(1.3),
        EffectController(duration: 0.15, reverseDuration: 0.15),
      ),
    );
  }

  void playDeathEffect() {
    if (_isDead) return;
    _isDead = true;
    add(
      OpacityEffect.to(
        0,
        EffectController(duration: 1.0),
        onComplete: removeFromParent,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Pixel art sprite (procedurally generated 8-bit look)
  // ---------------------------------------------------------------------------

  void _drawPixelSprite(Canvas canvas) {
    final colors = kClassColors[model.characterClass]!;
    final p = kPixelSize;
    final spriteScale = 0.8 + model.spriteLevel * 0.2;

    canvas.save();

    // Flip horizontally if facing left
    if (!_facingRight) {
      canvas.translate(size.x, 0);
      canvas.scale(-1, 1);
    }

    canvas.scale(spriteScale);

    final main   = Paint()..color = colors[0];
    final accent = Paint()..color = colors[1];
    final dark   = Paint()..color = colors[2];
    final skin   = Paint()..color = const Color(0xFFFFDBAC);

    // Head
    _px(canvas, 6, 0, 4, 4, skin, p);
    // Eyes
    _px(canvas, 7, 1, 1, 1, dark, p);
    _px(canvas, 9, 1, 1, 1, dark, p);

    // Body
    _px(canvas, 5, 4, 6, 6, main, p);
    _px(canvas, 5, 7, 6, 1, accent, p);

    // Arms
    _px(canvas, 3, 4, 2, 5, main, p);
    _px(canvas, 11, 4, 2, 5, main, p);

    // Legs
    _px(canvas, 5, 10, 2, 4, accent, p);
    _px(canvas, 9, 10, 2, 4, accent, p);

    _drawClassDetail(canvas, model.characterClass, p, dark);

    canvas.restore();
  }

  void _drawClassDetail(Canvas canvas, CharacterClass cls, double p, Paint dark) {
    switch (cls) {
      case CharacterClass.warrior:
        _px(canvas, 13, 3, 1, 6, dark, p);
      case CharacterClass.ranger:
        _px(canvas, 13, 2, 1, 8, dark, p);
        _px(canvas, 13, 2, 2, 1, dark, p);
        _px(canvas, 13, 9, 2, 1, dark, p);
      case CharacterClass.knight:
        _px(canvas, 1, 3, 2, 5, dark, p);
      case CharacterClass.mage:
        _px(canvas, 13, 1, 1, 9, dark, p);
        _px(canvas, 12, 1, 3, 1, Paint()..color = const Color(0xFFFFFF00), p);
      case CharacterClass.assassin:
        _px(canvas, 13, 4, 1, 4, dark, p);
        _px(canvas, 2, 4, 1, 4, dark, p);
      case CharacterClass.druid:
        _px(canvas, 5, 2, 1, 1, Paint()..color = const Color(0xFFADFF2F), p);
        _px(canvas, 10, 2, 1, 1, Paint()..color = const Color(0xFFADFF2F), p);
    }
  }

  void _px(Canvas canvas, int gx, int gy, int w, int h, Paint paint, double p) {
    canvas.drawRect(Rect.fromLTWH(gx * p, gy * p, w * p, h * p), paint);
  }

  Vector2 _randomVelocity() {
    final speed = 30.0 + _rng.nextDouble() * 40;
    final angle = _rng.nextDouble() * 2 * pi;
    return Vector2(cos(angle) * speed, sin(angle) * speed);
  }
}
