import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

enum InteractionType { combat, training, neutral }

/// Pixel-art particle burst for character interactions.
class InteractionEffect extends ParticleSystemComponent {
  InteractionEffect.combat(Vector2 position)
      : super(
          position: position,
          particle: _combatParticle(),
        );

  InteractionEffect.training(Vector2 position)
      : super(
          position: position,
          particle: _trainingParticle(),
        );

  // ---------------------------------------------------------------------------
  // Combat: 8 red/orange squares bursting outward
  // ---------------------------------------------------------------------------
  static Particle _combatParticle() {
    return ComposedParticle(
      children: List.generate(8, (i) {
        final angle = i * pi / 4;
        final speed = 60.0 + Random().nextDouble() * 40;
        final color = i.isEven ? const Color(0xFFFF2222) : const Color(0xFFFF8800);
        return AcceleratedParticle(
          acceleration: Vector2(cos(angle) * speed * 2, sin(angle) * speed * 2),
          speed: Vector2(cos(angle) * speed, sin(angle) * speed),
          child: CircleParticle(
            radius: 4,
            paint: Paint()..color = color,
            lifespan: 0.5,
          ),
        );
      }),
    );
  }

  // ---------------------------------------------------------------------------
  // Training: gold/green squares floating upward
  // ---------------------------------------------------------------------------
  static Particle _trainingParticle() {
    final rng = Random();
    return ComposedParticle(
      children: List.generate(10, (i) {
        final offsetX = -30.0 + rng.nextDouble() * 60;
        final color = i.isEven ? const Color(0xFFFFD700) : const Color(0xFF44FF44);
        return AcceleratedParticle(
          acceleration: Vector2(0, -20),
          speed: Vector2(offsetX * 0.5, -40 - rng.nextDouble() * 30),
          child: CircleParticle(
            radius: 3,
            paint: Paint()..color = color,
            lifespan: 0.8,
          ),
        );
      }),
    );
  }
}

/// Floating text label that rises and fades — e.g. "⚔ SCONTRO!"
class FloatingLabel extends PositionComponent {
  final String text;
  final Color color;
  double _opacity = 1.0;
  double _elapsed = 0;
  static const double _duration = 1.2;

  // Cached layout to avoid recreating TextPainter every frame
  late final TextPainter _textPainter;
  late final double _labelW;
  late final double _labelH;

  FloatingLabel({
    required Vector2 position,
    required this.text,
    required this.color,
  }) : super(position: position, anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    _textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    _labelW = _textPainter.width + 8;
    _labelH = _textPainter.height + 4;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    _opacity = (1.0 - _elapsed / _duration).clamp(0.0, 1.0);
    position.y -= 40 * dt;
    if (_elapsed >= _duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final bgPaint = Paint()
      ..color = Colors.black.withValues(alpha: _opacity * 0.6);
    canvas.drawRect(Rect.fromLTWH(-_labelW / 2, -_labelH / 2, _labelW, _labelH), bgPaint);

    // Temporarily repaint with current opacity
    _textPainter.text = TextSpan(
      text: text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: color.withValues(alpha: _opacity),
        letterSpacing: 1,
      ),
    );
    _textPainter.layout();
    _textPainter.paint(canvas, Offset(-_textPainter.width / 2, -_textPainter.height / 2));
  }
}
