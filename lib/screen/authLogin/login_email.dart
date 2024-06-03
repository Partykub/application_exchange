import 'package:exchange/class/information.dart';
import 'package:exchange/screen/authSignup/main_registor.dart';
import 'package:exchange/screen/main_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EmailAuth extends StatefulWidget {
  const EmailAuth({Key? key}) : super(key: key);

  @override
  State<EmailAuth> createState() => _EmailAuthState();
}

class _EmailAuthState extends State<EmailAuth> {
  InformationUser informationUser = InformationUser();
  final loginEmailFormKey = GlobalKey<FormState>();
  late String eMessage;
  bool _obscurePassword = true;

  void togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: loginEmailFormKey,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
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
                informationUser.email = inputemail;
              },
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                labelText: 'กรอกอีเมลของคุณ',
                hintText: 'กรอกอีเมลของคุณ',
                suffixIcon: const Icon(Icons.person),
              ),
            ),
          ),
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: TextFormField(
              validator: (inputpassword) {
                if (inputpassword!.isEmpty) {
                  return 'กรุณากรอกรหัสผ่าน';
                }
                if (inputpassword.length < 8 || inputpassword.length > 20) {
                  return 'รูปแบบรหัสผ่านไม่ถูกต้อง';
                }

                if (!RegExp(r'^(?=.*[A-Z])').hasMatch(inputpassword)) {
                  return 'รูปแบบรหัสผ่านไม่ถูกต้อง';
                }

                if (!RegExp(r'\d').hasMatch(inputpassword)) {
                  return 'รูปแบบรหัสผ่านไม่ถูกต้อง';
                }

                if (!RegExp(r'[A-Za-z0-9@#$%&*+]').hasMatch(inputpassword)) {
                  return 'รูปแบบรหัสผ่านไม่ถูกต้อง';
                }
                return null;
              },
              onSaved: (inputPass) {
                informationUser.passsword = inputPass;
              },
              obscureText: _obscurePassword,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                labelText: 'กรอกรหัสของคุณ',
                hintText: 'กรอกรหัสของคุณ',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    color: Colors.black,
                  ),
                  onPressed: togglePasswordVisibility,
                ),
              ),
            ),
          ),
          const SizedBox(height: 50),
          ElevatedButton(
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(Colors.black),
              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              fixedSize: MaterialStateProperty.all(const Size(180, 30)),
            ),
            child: const Text(
              "เข้าสู่ระบบ",
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
            onPressed: () async {
              if (loginEmailFormKey.currentState!.validate()) {
                loginEmailFormKey.currentState!.save();
                try {
                  await FirebaseAuth.instance
                      .signInWithEmailAndPassword(
                          email: informationUser.email!,
                          password: informationUser.passsword!)
                      .then((value) {
                    loginEmailFormKey.currentState?.reset();
                    // คำสั่งปิดแป้นพิมพ์
                    FocusManager.instance.primaryFocus?.unfocus();
                    Navigator.pushReplacement(context, MaterialPageRoute(
                      builder: (context) {
                        return const MainScreen();
                      },
                    ));
                  });
                } on FirebaseAuthException catch (error) {
                  if (error.message ==
                      'The supplied auth credential is malformed or has expired.') {
                    eMessage =
                        'ข้อมูลประจำตัวที่ให้มามีรูปแบบไม่ถูกต้องหรือหมดอายุแล้ว';
                  }
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(eMessage),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );

                    Navigator.pushReplacement(context, MaterialPageRoute(
                      builder: (context) {
                        return const RegistorScreen();
                      },
                    ));
                  }
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
