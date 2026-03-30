import 'package:firebase_core/firebase_core.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'game/fitworld_game.dart';
import 'models/character_model.dart';
import 'services/world_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase.initializeApp() requires google-services.json on Android.
  // In demo mode (no Firebase configured) we skip it gracefully.
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase not configured yet — app runs in demo mode
  }
  runApp(const FitWorldApp());
}

class FitWorldApp extends StatelessWidget {
  const FitWorldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitWorld',
      theme: ThemeData.dark(),
      home: const GameScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late FitWorldGame _game;
  late WorldController _controller;
  bool _controllerReady = false;

  @override
  void initState() {
    super.initState();
    _game = FitWorldGame();
    _controller = WorldController();
    _controller.addListener(() {
      setState(() {
        _controllerReady = _controller.ready;
      });
    });
    // Init after first frame so game size is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.init(_game);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GameWidget(game: _game),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _hudTitle(),
                  if (!_controllerReady) _loadingBar(),
                  const Spacer(),
                  _hudBottom(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hudTitle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'FITWORLD',
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Color(0xFF00FF88),
          letterSpacing: 4,
        ),
      ),
    );
  }

  Widget _loadingBar() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF00FF88),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _controller.status,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: Color(0xFF00FF88),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hudBottom() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _hudButton(
          icon: Icons.fitness_center,
          label: 'ADD\nWARRIOR',
          onTap: () => _game.addCharacterFromWorkout(
            workoutType: WorkoutType.strength,
            intensity: 65,
          ),
        ),
        const SizedBox(width: 8),
        _hudButton(
          icon: Icons.directions_run,
          label: 'ADD\nRANGER',
          onTap: () => _game.addCharacterFromWorkout(
            workoutType: WorkoutType.running,
            intensity: 75,
          ),
        ),
      ],
    );
  }

  Widget _hudButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black54,
          border: Border.all(color: const Color(0xFF00FF88)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF00FF88), size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: Color(0xFF00FF88),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
