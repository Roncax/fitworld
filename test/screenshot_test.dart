import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('fitworld screenshot', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));

    // Simple preview widget (no Flame game, just the HUD layout)
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: Scaffold(
          backgroundColor: const Color(0xFF1E6E1E),
          body: Stack(
            children: [
              // Simulated world background
              Container(color: const Color(0xFF1E6E1E)),
              // Ground
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 200,
                child: Container(color: const Color(0xFF2D5A1B)),
              ),
              // HUD
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
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
                      ),
                      const Spacer(),
                      // Character class legend
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF00FF88)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('PERSONAGGI ATTIVI',
                                style: TextStyle(
                                    color: Color(0xFF00FF88),
                                    fontFamily: 'monospace',
                                    fontSize: 10)),
                            const SizedBox(height: 6),
                            ...[
                              ('⚔', 'Guerriero', 'Forza', Colors.red),
                              ('🏹', 'Ranger', 'Corsa', Colors.green),
                              ('🔮', 'Mago', 'Nuoto', Colors.purple),
                              ('⚡', 'Assassino', 'HIIT', Colors.grey),
                              ('🌿', 'Druido', 'Yoga', Colors.lightGreen),
                            ].map((e) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 2),
                                  child: Row(
                                    children: [
                                      Text(e.$1,
                                          style: const TextStyle(fontSize: 12)),
                                      const SizedBox(width: 6),
                                      Text('${e.$2} (${e.$3})',
                                          style: TextStyle(
                                              color: e.$4,
                                              fontFamily: 'monospace',
                                              fontSize: 11)),
                                    ],
                                  ),
                                )),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _demoButton(Icons.fitness_center, 'ADD\nWARRIOR'),
                          const SizedBox(width: 8),
                          _demoButton(Icons.directions_run, 'ADD\nRANGER'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/fitworld_preview.png'),
    );
  });
}

Widget _demoButton(IconData icon, String label) {
  return Container(
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
  );
}
