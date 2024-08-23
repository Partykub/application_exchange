import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:exchange/screen/Admin/main_admin.dart';
import 'package:exchange/screen/Register/email_register.dart';
import 'package:exchange/screen/Register/google_register.dart';
import 'package:exchange/screen/Register/phone_register.dart';
import 'package:exchange/screen/main_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MainRegister extends StatefulWidget {
  const MainRegister({super.key});

  @override
  State<MainRegister> createState() => _MainRegisterState();
}

class _MainRegisterState extends State<MainRegister> {
  final auth = FirebaseAuth.instance;
  bool loadingGoogle = false;
  String? email, uid;
  bool emailPasswordMode = true;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(80.0),
          child: Column(
            children: <Widget>[
              AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                title: const Text('ลงทะเบียน'),
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
                        ? const EmailPasswordRegister()
                        : const PhoneRegister(),
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
                                      "ลงทะเบียนด้วยเบอร์โทร",
                                      style: TextStyle(
                                          color: Colors.blue[700],
                                          fontSize: 14),
                                    )
                                  : Text(
                                      "ลงทะเบียนด้วยอีเมล",
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
                                "มีปัญชีผู้ใช้แล้ว?",
                              ),
                              TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: Text(
                                    "เข้าสู่ระบบ",
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
