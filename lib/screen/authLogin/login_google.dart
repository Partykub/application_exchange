import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

Future<UserCredential?> signInWithGoogle() async {
  // Trigger the authentication flow
  final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

  // Check if googleUser is not null
  if (googleUser == null) {
    // The user canceled the sign-in
    null;
  } else {
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    // Check if both accessToken and idToken are not null
    if (googleAuth.accessToken == null || googleAuth.idToken == null) {
      throw Exception('Missing Google Auth Token');
    }

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Once signed in, return the UserCredential
    return await FirebaseAuth.instance.signInWithCredential(credential);
  }
  return null;
  // Obtain the auth details from the request
}
