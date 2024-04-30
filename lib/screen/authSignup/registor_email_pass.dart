import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:exchange/class/information.dart';
import 'package:exchange/class/validator_pass.dart';
import 'package:exchange/screen/authLogin/login_main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class RegistorEmailPass extends StatefulWidget {
  const RegistorEmailPass({super.key});

  @override
  State<RegistorEmailPass> createState() => _RegistorEmailPassState();
}

class _RegistorEmailPassState extends State<RegistorEmailPass> {
  final registerFormKey = GlobalKey<FormState>();
  InformationUser informationUser = InformationUser();
  late Future<FirebaseApp> firebase;
  String? eMessage;
  String? _smsCode;
  String? _verificationId;
  String? _message;

  final auth = FirebaseAuth.instance;
  CollectionReference _userCollection =
      FirebaseFirestore.instance.collection('informationUser');

  @override
  Widget build(BuildContext context) {
    return Form(
      key: registerFormKey,
      child: Column(
        children: [
          // InputEmail
          TextFormField(
            validator: (value) {
              if (value!.isEmpty) {
                return 'กรุณาระบุอีเมล';
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
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'อีเมล',
              hintText: 'อีเมล',
            ),
          ),

          const SizedBox(
            height: 15,
          ),

          // InputPassword
          TextFormField(
            validator: validatorPassword,
            onSaved: (inputPass) {
              informationUser.passsword = inputPass;
            },
            obscureText: true,
            keyboardType: TextInputType.text,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'รหัสผ่าน',
              hintText: 'รหัสผ่าน',
            ),
          ),

          const SizedBox(
            height: 15,
          ),

          TextFormField(
            validator: (inputname) {
              if (inputname!.isEmpty) {
                return "กรุณากรอกชื่อ";
              } else if (!RegExp(r'^[a-zA-Z0-9]{3,10}$').hasMatch(inputname)) {
                return "ข้อมูลไม่ถูกต้อง";
              }
              return null;
            },
            onSaved: (inputname) {
              informationUser.name = inputname;
            },
            keyboardType: TextInputType.text,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'กรอกชื่อของคุณ',
              hintText: 'กรอกชื่อของคุณ',
            ),
          ),

          const SizedBox(
            height: 15,
          ),

          // Inputphoenumber
          TextFormField(
            validator: (inputnumber) {
              if (inputnumber!.isEmpty) {
                return "กรุณากรอกเบอร์โทรศัพท์";
              } else if (!RegExp(r'^0[0-9]{9}$').hasMatch(inputnumber)) {
                return "รูปแบบหมายเลขโทรศัพท์ไม่ถูกต้อง";
              }
              return null;
            },
            onSaved: (inputphonenumber) {
              informationUser.phonenumber = inputphonenumber;
            },
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'กรอกเบอร์โทรศัพท์',
              hintText: 'กรอกเบอร์โทรศัพท์',
              suffixIcon: GestureDetector(
                onTap: () {
                  if (registerFormKey.currentState!.validate()) {
                    registerFormKey.currentState!.save();
                    final phoneNumber =
                        "+66${informationUser.phonenumber!.trim()}";
                    FirebaseAuth.instance.verifyPhoneNumber(
                      phoneNumber: phoneNumber,
                      verificationCompleted:
                          (PhoneAuthCredential credential) async {
                        await FirebaseAuth.instance
                            .signInWithCredential(credential);
                      },
                      verificationFailed: (FirebaseException e) {
                        print('Verifivation Failed: ${e.message}');
                      },
                      codeSent: (String verificationId, int? resendToken) {
                        _verificationId = verificationId;
                      },
                      codeAutoRetrievalTimeout: (String verificationId) {},
                    );
                  }
                },
                child: Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Container(
                    width: 80, // กำหนดความกว้างของปุ่ม
                    height: 5, // กำหนดความสูงของปุ่ม
                    decoration: BoxDecoration(
                      color: Colors.black54, // กำหนดสีพื้นหลังเป็นสีดำ
                      borderRadius:
                          BorderRadius.circular(10), // กำหนดเส้นรอบมุมเป็นวงรี
                    ),
                    child: Center(
                      child: Text(
                        'ขอ OTP',
                        style: TextStyle(
                          color: Colors.white, // กำหนดสีตัวหนังสือเป็นสีขาว
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 15,
          ),
          TextFormField(
            keyboardType: TextInputType.number,
            onChanged: (value) => _smsCode = value,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'กรอก OTP',
              hintText: 'กรอก OTP ที่ได้รับ',
            ),
            onSaved: (smsOTP) {
              _smsCode = smsOTP;
            },
          ),
          // เช็คว่าข้อความเกี่ยวกับการยืนยันมีการเปลี่ยนแปลงหรือไม่
          if (_message != null)
            Text(
              _message!,
              style: TextStyle(color: Colors.red),
            ),
          const SizedBox(
            height: 25,
          ),
          ElevatedButton(
            style: ButtonStyle(
              backgroundColor: const MaterialStatePropertyAll(Colors.black),
              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              fixedSize: MaterialStateProperty.all(const Size(180, 30)),
            ),
            child: const Text(
              "ยืนยัน",
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
            onPressed: () async {
              if (registerFormKey.currentState!.validate()) {
                registerFormKey.currentState!.save();
                print(
                    "${informationUser.email} ${informationUser.passsword} ${informationUser.phonenumber} ${informationUser.name}");
                try {
                  await FirebaseAuth.instance
                      .createUserWithEmailAndPassword(
                          email: informationUser.email!,
                          password: informationUser.passsword!)
                      .then((value) async {
                    FirebaseAuth.instance.signInWithEmailAndPassword(
                        email: informationUser.email!,
                        password: informationUser.passsword!);

                    PhoneAuthProvider.credential(
                        verificationId: _verificationId!, smsCode: _smsCode!);

                    await _userCollection.doc(auth.currentUser!.uid).set({
                      "Email": auth.currentUser!.email,
                      "Name": informationUser.name,
                      "PhoneNumber": informationUser.phonenumber
                    });

                    registerFormKey.currentState!.reset();
                    //คำสั่งปิดแป้นพิมพ์
                    FocusManager.instance.primaryFocus?.unfocus();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('ลงทะเบียนสำเร็จ'),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    Navigator.pushReplacement(context, MaterialPageRoute(
                      builder: (context) {
                        return const LoginScreen();
                      },
                    ));
                  });
                } on FirebaseAuthException catch (error) {
                  if (error.message! ==
                      "The email address is already in use by another account.") {
                    eMessage = "ที่อยู่อีเมลนี้มีการใช้งานแล้วโดยบัญชีอื่น";
                  }
                  // print(error.message);

                  print(error.message);
                  // ignore: use_build_context_synchronously
                }
              }
            },
          )
        ],
      ),
    );
  }
}
