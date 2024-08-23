import 'package:exchange/firebase_options.dart';
import 'package:exchange/screen/Admin/main_admin.dart';
import 'package:exchange/screen/guest/guest_exchange.dart';
import 'package:exchange/screen/main_page.dart';
import 'package:exchange/theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppThemes.lightTheme,
      home: const AuthCheck(),
    );
  }
}

class AuthCheck extends StatelessWidget {
  const AuthCheck({Key? key}) : super(key: key);

  Future<String?> _getUserRole(String userId) async {
    final DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('informationUser')
        .doc(userId)
        .get();

    return userDoc['Role'] as String?;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData) {
          final User user = snapshot.data!;
          return FutureBuilder<String?>(
            future: _getUserRole(user.uid),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (roleSnapshot.hasData) {
                final String? role = roleSnapshot.data;
                if (role == 'Admin') {
                  return const AdminMain();
                } else {
                  return const MainScreen();
                }
              } else {
                return const GuestExchange();
              }
            },
          );
        } else {
          return const GuestExchange();
        }
      },
    );
  }
}
