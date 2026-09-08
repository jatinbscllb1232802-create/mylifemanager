import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService({
    FirebaseAuth? firebaseAuth,
  }) : _auth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  static const String _serverClientId =
      '891664406669-a96bbobeq2o862o2qhrr3dc9o7g53l0e.apps.googleusercontent.com';

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> _initializeGoogleSignIn() async {
    await _googleSignIn.initialize(
      serverClientId: _serverClientId,
    );
  }

  Future<UserCredential> signInWithGoogle() async {
    await _initializeGoogleSignIn();

    if (!_googleSignIn.supportsAuthenticate()) {
      throw StateError(
        'Google Sign-In authentication is not supported on this platform.',
      );
    }

    final googleUser = await _googleSignIn.authenticate();

    final googleAuth = googleUser.authentication;

    final idToken = googleAuth.idToken;

    if (idToken == null) {
      throw StateError(
        'Google Sign-In did not return an ID token.',
      );
    }

    final credential = GoogleAuthProvider.credential(
      idToken: idToken,
    );

    return _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    await _auth.signOut();

    await _initializeGoogleSignIn();

    await _googleSignIn.signOut();
  }

  /// Phone authentication is no longer exposed in the UI.
  /// These methods are retained only for compatibility with existing code.
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(
      String verificationId,
      int? resendToken,
    ) codeSent,
    required void Function(
      FirebaseAuthException e,
    ) verificationFailed,
    required void Function(
      PhoneAuthCredential credential,
    ) verificationCompleted,
    required void Function(
      String verificationId,
    ) codeAutoRetrievalTimeout,
  }) {
    return _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
    );
  }

  Future<UserCredential> signInWithSmsCode({
    required String verificationId,
    required String smsCode,
  }) {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );

    return _auth.signInWithCredential(credential);
  }
}