import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// 로그인 취소처럼 사용자에게 에러로 보여줄 필요가 없는 경우.
class SignInCanceled implements Exception {}

/// Firebase Auth + Google 로그인.
class AuthService {
  AuthService({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
    : _auth = auth ?? FirebaseAuth.instance,
      _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  Future<void>? _initialization;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// GoogleSignIn은 앱 실행 중 한 번만 초기화해야 한다.
  Future<void> _ensureInitialized() =>
      _initialization ??= _googleSignIn.initialize();

  /// Google 계정 선택 → Firebase 로그인. 사용자가 창을 닫으면 [SignInCanceled].
  Future<User> signInWithGoogle() async {
    await _ensureInitialized();

    final GoogleSignInAccount account;
    try {
      account = await _googleSignIn.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) throw SignInCanceled();
      rethrow;
    }

    final credential = GoogleAuthProvider.credential(
      idToken: account.authentication.idToken,
    );
    final result = await _auth.signInWithCredential(credential);
    return result.user!;
  }

  Future<void> signOut() async {
    await _ensureInitialized();
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
