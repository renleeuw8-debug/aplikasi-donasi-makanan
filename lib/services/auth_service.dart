import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';

class AuthService {
  AuthService._();
  static final instance = AuthService._();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Stream<User?> get authState => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return cred;
  }

  Future<UserCredential> registerWithEmail({
    required String nama,
    required String email,
    required String password,
    required String peran, // 'donatur' | 'penerima'
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = cred.user!;
    await user.updateDisplayName(nama);
    final profile = UserModel(
      id: user.uid,
      uid: user.uid,
      nama: nama,
      email: email,
      peran: peran,
      fotoProfil: '',
      badge: 'Pemula',
    );
    await _db.collection('users').doc(user.uid).set(profile.toJson());
    return cred;
  }

  Future<UserModel?> getUserData(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromJson(doc.data() ?? {});
    }

    // Kalau document tidak ada, try create dari Firebase Auth user
    final authUser = _auth.currentUser;
    if (authUser != null && authUser.uid == uid) {
      final newProfile = UserModel(
        id: uid,
        uid: uid,
        nama: authUser.displayName ?? 'User',
        email: authUser.email ?? '',
        peran: 'donatur', // Default peran saat auto-create
        fotoProfil: '',
        badge: 'Pemula',
      );
      await _db.collection('users').doc(uid).set(newProfile.toJson());
      return newProfile;
    }

    return null;
  }

  Future<void> signOut() => _auth.signOut();
}
