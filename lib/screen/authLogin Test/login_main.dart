import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:exchange/class/information.dart';
import 'package:exchange/screen/Admin/main_admin.dart';
import 'package:exchange/screen/Register/google_register.dart';
import 'package:exchange/screen/authLogin%20Test/login_email.dart';
import 'package:exchange/screen/authLogin%20Test/login_google.dart';
import 'package:exchange/screen/authLogin%20Test/login_phone.dart';
import 'package:exchange/screen/authSignup%20Test/main_registor.dart';
import 'package:exchange/screen/authSignup%20Test/registor_from_google.dart';
import 'package:exchange/screen/main_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  InformationUser informationUser = InformationUser();
  String? eMessage;
  List<bool> emailWithPhone = [true, false];
  late Future<FirebaseApp> firebase;
  final auth = FirebaseAuth.instance;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    firebase = Firebase.initializeApp();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: firebase,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print(snapshot.error.toString());
          return Scaffold(
            appBar: AppBar(
              title: const Text("Error"),
            ),
            body: Center(
              child: Text("${snapshot.error}"),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.done) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.white,
              title: const Text("เข้าสู่ระบบ"),
              // leading: IconButton(
              //   icon: const Icon(Icons.arrow_back),
              //   onPressed: () {
              //     Navigator.pop(context);
              //   },
              // ),
            ),
            body: Container(
              color: Colors.white,
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      ToggleButtons(
                        isSelected: emailWithPhone,
                        onPressed: (int index) {
                          setState(() {
                            emailWithPhone = [false, false];
                            emailWithPhone[index] = true;
                          });
                        },
                        selectedColor: Colors.black,
                        color: Colors.grey[400],
                        fillColor: Colors.transparent,
                        borderRadius: BorderRadius.circular(10.0),
                        selectedBorderColor: Colors.black,
                        borderColor: Colors.grey[400],
                        borderWidth: 1.0,
                        children: [
                          Container(
                            height: 40,
                            width: 150,
                            alignment: Alignment.center,
                            child: const Text(
                              "อีเมล",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16.0),
                            ),
                          ),
                          Container(
                            height: 40,
                            width: 150,
                            alignment: Alignment.center,
                            child: const Text(
                              "เบอร์โทรศัพท์",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16.0),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (emailWithPhone[0] == true) ...[EmailAuth()],
                      if (emailWithPhone[1] == true) ...[PhoneAuth()],
                      const SizedBox(height: 20),
                      TextButton.icon(
                        onPressed: isLoading
                            ? null
                            : () async {
                                setState(() {
                                  isLoading = true;
                                });
                                var userCredential = await signInWithGoogle();
                                // ignore: unnecessary_null_comparison
                                if (userCredential != null &&
                                    userCredential.user != null) {
                                  if (userCredential
                                      .additionalUserInfo!.isNewUser) {
                                    // ถ้าเป็นผู้ใช้ใหม่ เพิ่มข้อมูลและไปยังหน้าลงทะเบียน
                                    informationUser.uid = auth.currentUser!.uid;
                                    informationUser.email =
                                        auth.currentUser!.email;

                                    setState(() {
                                      isLoading = false;
                                    });

                                    // ignore: use_build_context_synchronously
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            RegisterScreenGoogle(
                                          informationUserUID:
                                              informationUser.uid,
                                          isFromGoogleLogin:
                                              true, // เพิ่มตัวแปรเพื่อบอกว่าเป็นการลงทะเบียนจาก Google
                                        ),
                                      ),
                                    );
                                  } else {
                                    // ถ้าเป็นผู้ใช้ทั่วไป ไปยังหน้า Main Page
                                    // ignore: use_build_context_synchronously
                                    setState(() {
                                      isLoading = false;
                                    });

                                    final currentUser =
                                        FirebaseAuth.instance.currentUser;
                                    final snapshot = await FirebaseFirestore
                                        .instance
                                        .collection('informationUser')
                                        .doc(currentUser!.uid)
                                        .get();
                                    final snapshotData = snapshot.data();
                                    final roleData = snapshotData!['Role'];

                                    if (roleData! == 'Admin') {
                                      if (mounted) {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const AdminMain(),
                                          ),
                                        );
                                      }
                                    } else {
                                      if (mounted) {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const MainScreen(),
                                          ),
                                        );
                                      }
                                    }
                                  }
                                }
                              },
                        icon: const Icon(Icons.g_mobiledata),
                        label: const Text('เข้าสู่ระบบด้วย Google'),
                        style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all(Colors.red),
                          foregroundColor:
                              MaterialStateProperty.all(Colors.white),
                          shape:
                              MaterialStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18.0),
                              side: const BorderSide(color: Colors.red),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("  ไม่มีสมาชิก?"),
                          TextButton(
                            child: const Text(
                              "ลงทะเบียนที่นี่",
                              style: TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.blue,
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(
                                builder: (context) {
                                  return const RegistorScreen();
                                },
                              ));
                            },
                          ),
                        ],
                      ),
                      const Text(
                          "การติดตั้ง/เข้าใช้งาน Exchaing Application นี้"),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("ถือว่าคุณตกลงยอมรับ"),
                          TextButton(
                            onPressed: () {},
                            child: const Text(
                              "ข้อกำหนดในการให้บริการ",
                              style: TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}
