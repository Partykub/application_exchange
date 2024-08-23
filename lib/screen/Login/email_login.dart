import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:exchange/screen/Admin/main_admin.dart';
import 'package:exchange/screen/main_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EmailPasswordLogin extends StatefulWidget {
  const EmailPasswordLogin({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _EmailPasswordLoginState createState() => _EmailPasswordLoginState();
}

class _EmailPasswordLoginState extends State<EmailPasswordLogin> {
  final loginEmailPassFormKey = GlobalKey<FormState>();
  String? email, password;
  bool obscurePassword = true;
  bool loading = false;

  void togglePasswordVisibility() {
    setState(() {
      obscurePassword = !obscurePassword;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: loginEmailPassFormKey,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: TextFormField(
              validator: (value) {
                if (value!.isEmpty) {
                  return 'กรุณากรอกอีเมล';
                } else if (!RegExp(
                        r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                    .hasMatch(value)) {
                  return 'รูปแบบอีเมลไม่ถูกต้อง';
                }
                return null;
              },
              onSaved: (inputemail) {
                email = inputemail;
              },
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'E-mail',
                hintText: 'E-mail',
                prefixIcon: Icon(Icons.person),
              ),
            ),
          ),
          // ช่องกรอก Password
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    validator: (inputpassword) {
                      if (inputpassword == null || inputpassword.isEmpty) {
                        return 'กรุณากรอกรหัสผ่าน';
                      }
                      if (inputpassword.length < 6) {
                        return 'รูปแบบรหัสผ่านไม่ถูกต้อง';
                      }
                      return null;
                    },
                    onSaved: (inputpassword) {
                      password = inputpassword;
                    },
                    obscureText: obscurePassword,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.black,
                        ),
                        onPressed: togglePasswordVisibility,
                      ),
                      labelText: 'รหัสผ่าน',
                      hintText: 'รหัสผ่าน',
                      prefixIcon: const Icon(Icons.person),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    "ลืมรหัสผ่าน?",
                    style: TextStyle(color: Colors.blue[700]),
                  ),
                ),
              ],
            ),
          ),
          // ปุ่มเข้าสู่ระบบ
          Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: Row(
              children: [
                Expanded(
                    child: ElevatedButton(
                        onPressed: () async {
                          FocusScope.of(context).unfocus();
                          if (loginEmailPassFormKey.currentState!.validate()) {
                            loginEmailPassFormKey.currentState!.save();
                          }
                          try {
                            setState(() {
                              loading = true;
                            });
                            await Future.delayed(const Duration(seconds: 3));
                            await FirebaseAuth.instance
                                .signInWithEmailAndPassword(
                                    email: email!, password: password!)
                                .then((value) async {
                              loginEmailPassFormKey.currentState?.reset();
                              final currentUser =
                                  FirebaseAuth.instance.currentUser;
                              final snapshot = await FirebaseFirestore.instance
                                  .collection('informationUser')
                                  .doc(currentUser!.uid)
                                  .get();
                              final snapshotData = snapshot.data();
                              final roleData = snapshotData!['Role'];

                              if (roleData == 'Admin') {
                                if (mounted) {
                                  Navigator.pushReplacement(context,
                                      MaterialPageRoute(
                                    builder: (context) {
                                      return const AdminMain();
                                    },
                                  ));
                                }
                              } else {
                                if (mounted) {
                                  Navigator.pushReplacement(context,
                                      MaterialPageRoute(
                                    builder: (context) {
                                      return const MainScreen();
                                    },
                                  ));
                                }
                              }
                            });
                          } catch (e) {
                            print(e);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'ข้อมูลประจำตัวที่ให้มามีรูปแบบไม่ถูกต้องหรือหมดอายุแล้ว'),
                                  duration: Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );

                              await Future.delayed(const Duration(seconds: 3));
                            }
                            setState(() {
                              loading = false;
                            });
                          } finally {
                            setState(() {
                              loading = false;
                            });
                          }
                        },
                        child: loading
                            ? const CircularProgressIndicator(
                                strokeWidth: 3, color: Colors.white)
                            : const Text(
                                "เข้าสู่ระบบ",
                              )))
              ],
            ),
          ),
        ],
      ),
    );
  }
}
