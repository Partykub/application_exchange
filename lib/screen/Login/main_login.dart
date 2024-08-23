import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:exchange/screen/Admin/main_admin.dart';
import 'package:exchange/screen/Login/email_login.dart';
import 'package:exchange/screen/Register/google_register.dart';
import 'package:exchange/screen/Login/phone_login.dart';
import 'package:exchange/screen/Register/main_register.dart';
import 'package:exchange/screen/main_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MainLogin extends StatefulWidget {
  const MainLogin({super.key});

  @override
  State<MainLogin> createState() => _MainLoginState();
}

class _MainLoginState extends State<MainLogin> {
  final auth = FirebaseAuth.instance;
  String? email, uid;
  bool obscurePassword = true;
  bool emailPasswordMode = true;
  bool loadingGoogle = false;

  void togglePasswordVisibility() {
    setState(() {
      obscurePassword = !obscurePassword;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(80.0),
          child: Column(
            children: <Widget>[
              AppBar(
                title: const Text('เข้าสู่ระบบ'),
                elevation: 0.0,
              ),
              Divider(
                thickness: 1.0,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    //วรรคจากAppbar
                    SizedBox(
                      height: (MediaQuery.of(context).size.height / 100) * 5,
                    ),
                    // ช่องกรอก input
                    emailPasswordMode
                        ? const EmailPasswordLogin()
                        : const PhoneLogin(),
                    // เข้าสู่ระบบด้วยเบอร์โทร
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                              onPressed: () {
                                setState(() {
                                  emailPasswordMode = !emailPasswordMode;
                                });
                              },
                              child: emailPasswordMode
                                  ? Text(
                                      "เข้าสู่ระบบด้วยเบอร์โทร",
                                      style: TextStyle(
                                          color: Colors.blue[700],
                                          fontSize: 14),
                                    )
                                  : Text(
                                      "เข้าสู่ระบบด้วยอีเมล",
                                      style: TextStyle(
                                          color: Colors.blue[700],
                                          fontSize: 14),
                                    ))
                        ],
                      ),
                    ),
                    // หรือ
                    Text(
                      "หรือ",
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    // เข้าสู่ระบบด้วย google
                    Padding(
                        padding: const EdgeInsets.only(top: 30.0, bottom: 5.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextButton.icon(
                                onPressed: loadingGoogle
                                    ? null
                                    : () async {
                                        setState(() {
                                          loadingGoogle = true;
                                        });
                                        await Future.delayed(
                                            const Duration(seconds: 1));

                                        var userCredential =
                                            await signInWithGoogle();

                                        if (userCredential != null &&
                                            userCredential.user != null) {
                                          if (userCredential
                                              .additionalUserInfo!.isNewUser) {
                                            uid = auth.currentUser!.uid;
                                            email = auth.currentUser!.email;

                                            setState(() {
                                              loadingGoogle = false;
                                            });

                                            if (mounted) {
                                              Navigator.pushReplacement(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        GoogleRegister(
                                                            uid: uid!,
                                                            email: email!),
                                                  ));
                                            }
                                          } else {
                                            final currentUser = FirebaseAuth
                                                .instance.currentUser;
                                            final snapshot =
                                                await FirebaseFirestore.instance
                                                    .collection(
                                                        'informationUser')
                                                    .doc(currentUser!.uid)
                                                    .get();
                                            final snapshotData =
                                                snapshot.data();
                                            final roleData =
                                                snapshotData!['Role'];

                                            setState(() {
                                              loadingGoogle = false;
                                            });

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
                                        } else {
                                          setState(() {
                                            loadingGoogle = false;
                                          });
                                        }
                                      },
                                icon: const Icon(
                                  Icons.g_mobiledata,
                                  size: 30,
                                ),
                                label: loadingGoogle
                                    ? const CircularProgressIndicator(
                                        strokeWidth: 3,
                                        color: Colors.white,
                                      )
                                    : const Text(
                                        'เข้าสู่ระบบด้วย Google',
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700),
                                      ),
                                style: ButtonStyle(
                                  padding: MaterialStateProperty.all<
                                      EdgeInsetsGeometry>(
                                    const EdgeInsets.symmetric(
                                        vertical: 6.0, horizontal: 16.0),
                                  ),
                                  backgroundColor:
                                      MaterialStateProperty.all(Colors.red),
                                  foregroundColor:
                                      MaterialStateProperty.all(Colors.white),
                                  shape: MaterialStateProperty.all<
                                      RoundedRectangleBorder>(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18.0),
                                      side: const BorderSide(color: Colors.red),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          ],
                        )),
                    Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              const Text(
                                "ยังไม่มีปัญชีผู้ใช้?",
                              ),
                              TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const MainRegister(),
                                        ));
                                  },
                                  child: Text(
                                    "สมัครเลย",
                                    style: TextStyle(
                                      color: Colors.blue[700],
                                      decoration: TextDecoration.underline,
                                      decorationColor: Colors.blue[700],
                                    ),
                                  )),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 5, bottom: 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "การติดตั้ง /เข้าใช้งาน Exchaing Application นี้",
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("   ถือว่าคุณตกลงยอมรับ"),
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
            ],
          ),
        ));
  }
}
