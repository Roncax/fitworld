import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/character_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('FirestoreService: user not authenticated');
    return uid;
  }
  CollectionReference get _characters =>
      _db.collection('users').doc(_uid).collection('characters');
  DocumentReference get _world =>
      _db.collection('users').doc(_uid).collection('meta').doc('world');

  // ---------------------------------------------------------------------------
  // Auth
  // ---------------------------------------------------------------------------

  Future<void> signInAnonymously() async {
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }
  }

  // ---------------------------------------------------------------------------
  // Characters
  // ---------------------------------------------------------------------------

  Future<List<CharacterModel>> loadCharacters() async {
    final snap = await _characters.get();
    return snap.docs
        .map((d) => CharacterModel.fromFirestore(d.data() as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveCharacter(CharacterModel model) async {
    await _characters.doc(model.id).set(model.toFirestore());
  }

  Future<void> deleteCharacter(String id) async {
    await _characters.doc(id).delete();
  }

  Future<void> updateCharacterPosition(String id, double x, double y) async {
    await _characters.doc(id).update({'posX': x, 'posY': y});
  }

  // ---------------------------------------------------------------------------
  // Processed workout IDs (avoid spawning duplicates)
  // ---------------------------------------------------------------------------

  Future<Set<String>> loadProcessedWorkoutIds() async {
    final doc = await _world.get();
    if (!doc.exists) return {};
    final data = doc.data() as Map<String, dynamic>?;
    final ids = data?['processedWorkoutIds'];
    if (ids == null) return {};
    return Set<String>.from(ids as List);
  }

  Future<void> markWorkoutProcessed(String workoutId) async {
    await _world.set({
      'processedWorkoutIds': FieldValue.arrayUnion([workoutId]),
    }, SetOptions(merge: true));
  }

  // ---------------------------------------------------------------------------
  // FCM token
  // ---------------------------------------------------------------------------

  Future<void> saveFcmToken(String token) async {
    await _world.set({'fcmToken': token}, SetOptions(merge: true));
  }

  // ---------------------------------------------------------------------------
  // World health
  // ---------------------------------------------------------------------------

  Future<void> saveWorldHealth(double health) async {
    await _world.set({'health': health, 'lastUpdated': FieldValue.serverTimestamp()},
        SetOptions(merge: true));
  }

  Future<double> loadWorldHealth() async {
    final doc = await _world.get();
    if (!doc.exists) return 80;
    final data = doc.data() as Map<String, dynamic>?;
    return (data?['health'] as num?)?.toDouble() ?? 80;
  }
}
