import 'package:firebase_auth/firebase_auth.dart';

class UserHelper {
  const UserHelper._();

  static User? get user => FirebaseAuth.instance.currentUser;

  static String get uid => user?.uid ?? '';

  static Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }
}
