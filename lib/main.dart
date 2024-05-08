import 'package:exchange/firebase_options.dart';
import 'package:exchange/screen/authLogin/login_main.dart';
import 'package:exchange/screen/main_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions
        .currentPlatform, // ใช้ DefaultFirebaseOptions.currentPlatform
  );

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // return MaterialApp(home: RegisterScreenGoogle());
    return MaterialApp(
      home: LoginScreen(),
    );
  }
}
