import 'package:exchange/class/information.dart';
import 'package:exchange/screen/authLogin/login_google.dart';
import 'package:exchange/screen/authLogin/login_main.dart';
import 'package:exchange/screen/authSignup/registor_email_pass.dart';
import 'package:exchange/screen/authSignup/registor_from_google.dart';
import 'package:exchange/screen/authSignup/registor_phone.dart';
import 'package:exchange/screen/main_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

class RegistorScreen extends StatefulWidget {
  const RegistorScreen({Key? key}) : super(key: key);

  @override
  State<RegistorScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<RegistorScreen> {
  InformationUser informationUser = InformationUser();
  String? eMessage;
  List<bool> emailWithPhone = [true, false];
  late Future<FirebaseApp> firebase;
  final auth = FirebaseAuth.instance;

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
              title: const Text("สมัครสมาชิก"),
            ),
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                    if (emailWithPhone[0] == true) ...[RegistorEmailPass()],
                    if (emailWithPhone[1] == true) ...[RegistorPhone()],
                    const SizedBox(height: 20),
                    TextButton.icon(
                      onPressed: () async {
                        var userCredential = await signInWithGoogle();

                        // ignore: unnecessary_null_comparison
                        if (userCredential != null &&
                            userCredential.user != null) {
                          if (userCredential.additionalUserInfo!.isNewUser) {
                            // ถ้าเป็นผู้ใช้ใหม่ เพิ่มข้อมูลและไปยังหน้าลงทะเบียน
                            informationUser.uid = auth.currentUser!.uid;
                            informationUser.email = auth.currentUser!.email;
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RegisterScreenGoogle(
                                  informationUserUID: informationUser.uid,
                                  isFromGoogleLogin:
                                      true, // เพิ่มตัวแปรเพื่อบอกว่าเป็นการลงทะเบียนจาก Google
                                ),
                              ),
                            );
                          } else {
                            // ถ้าเป็นผู้ใช้ทั่วไป ไปยังหน้า Main Page
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MainScreen(),
                              ),
                            );
                          }
                        }
                      },
                      icon: Icon(Icons.g_mobiledata),
                      label: Text('เข้าสู่ระบบด้วย Google'),
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(Colors.red),
                        foregroundColor:
                            MaterialStateProperty.all(Colors.white),
                        shape:
                            MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18.0),
                            side: BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("  มีสมาชิกแล้ว?"),
                        TextButton(
                          child: const Text(
                            "เข้าสู่ระบบที่นี่",
                            style: TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.blue,
                            ),
                          ),
                          onPressed: () {
                            Navigator.pushReplacement(context,
                                MaterialPageRoute(
                              builder: (context) {
                                return const LoginScreen();
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
