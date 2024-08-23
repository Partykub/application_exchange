import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:exchange/class/checkphonenumber_isnew.dart';
import 'package:exchange/class/information.dart';
import 'package:exchange/class/new_image_profile.dart';
import 'package:exchange/class/validator_pass.dart';
import 'package:exchange/screen/authLogin%20Test/login_main.dart';
import 'package:exchange/screen/main_page.dart';
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
  final otpFormKey = GlobalKey<FormState>();
  InformationUser informationUser = InformationUser();
  late Future<FirebaseApp> firebase;
  String? eMessage;
  String? _smsCode;
  String? _verificationId;
  String? _message;

  bool _obscurePassword = true;
  bool isLoading = false;
  bool isLoadingOTP = false;

  final auth = FirebaseAuth.instance;
  final CollectionReference _userCollection =
      FirebaseFirestore.instance.collection('informationUser');

  void togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: registerFormKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
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
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              labelText: 'กรอกอีเมลของคุณ',
              hintText: 'กรอกอีเมลของคุณ',
              suffixIcon: const Icon(Icons.person),
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
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              labelText: 'กรอกเบอร์โทรศัพท์',
              hintText: 'กรอกเบอร์โทรศัพท์',
              suffixIcon: GestureDetector(
                onTap: isLoadingOTP
                    ? null
                    : () async {
                        FocusScope.of(context).unfocus();
                        if (registerFormKey.currentState!.validate()) {
                          registerFormKey.currentState!.save();
                          setState(() {
                            isLoadingOTP = true;
                          });
                          bool isNewPhoneNumber = await checkPhoneNumberIsNew(
                              informationUser.phonenumber.toString());
                          final phoneNumber =
                              "+66${informationUser.phonenumber!.trim()}";
                          if (isNewPhoneNumber) {
                            try {
                              print("เบอร์ที่ลงทะเบียนเป็นเบอร์ใหม่");
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
                                codeSent:
                                    (String verificationId, int? resendToken) {
                                  _verificationId = verificationId;
                                },
                                codeAutoRetrievalTimeout:
                                    (String verificationId) {},
                              );
                            } catch (e) {
                              print("Error ขอ OTP: $e");
                            } finally {
                              setState(() {
                                isLoadingOTP = false;
                              });
                            }
                          } else {
                            setState(() {
                              isLoadingOTP = false;
                            });
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('เบอร์โทรศัพท์นี้ลงทะเบียนแล้ว'),
                                  duration: Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              Timer(const Duration(seconds: 2), () {
                                Navigator.pushReplacement(context,
                                    MaterialPageRoute(
                                  builder: (context) {
                                    return const LoginScreen();
                                  },
                                ));
                              });
                            }
                          }
                        }
                      },
                child: isLoadingOTP
                    ? Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Container(
                          width: 80, // กำหนดความกว้างของปุ่ม
                          height: 5, // กำหนดความสูงของปุ่ม
                          decoration: BoxDecoration(
                            color: Colors.black54, // กำหนดสีพื้นหลังเป็นสีดำ
                            borderRadius: BorderRadius.circular(
                                10), // กำหนดเส้นรอบมุมเป็นวงรี
                          ),
                          child: const Center(
                              child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.white,
                          )),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Container(
                          width: 80, // กำหนดความกว้างของปุ่ม
                          height: 5, // กำหนดความสูงของปุ่ม
                          decoration: BoxDecoration(
                            color: Colors.black54, // กำหนดสีพื้นหลังเป็นสีดำ
                            borderRadius: BorderRadius.circular(
                                10), // กำหนดเส้นรอบมุมเป็นวงรี
                          ),
                          child: const Center(
                            child: Text(
                              'ขอ OTP',
                              style: TextStyle(
                                color:
                                    Colors.white, // กำหนดสีตัวหนังสือเป็นสีขาว
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
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
              style: const TextStyle(color: Colors.red),
            ),
          SizedBox(
            height: MediaQuery.of(context).size.height / 80,
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
            onPressed: isLoading
                ? null
                : () async {
                    FocusScope.of(context).unfocus();
                    if (registerFormKey.currentState!.validate() &&
                        _smsCode != null) {
                      registerFormKey.currentState!.save();
                      bool isNewPhoneNumber = await checkPhoneNumberIsNew(
                          informationUser.phonenumber.toString());
                      print(
                          "${informationUser.email} ${informationUser.passsword} ${informationUser.phonenumber} ${informationUser.name}");
                      if (isNewPhoneNumber) {
                        try {
                          setState(() {
                            isLoading = true;
                          });
                          await FirebaseAuth.instance
                              .createUserWithEmailAndPassword(
                                  email: informationUser.email!,
                                  password: informationUser.passsword!)
                              .then((value) async {
                            FirebaseAuth.instance.signInWithEmailAndPassword(
                                email: informationUser.email!,
                                password: informationUser.passsword!);

                            PhoneAuthProvider.credential(
                                verificationId: _verificationId!,
                                smsCode: _smsCode!);

                            await _userCollection
                                .doc(auth.currentUser!.uid)
                                .set({
                              "Email": auth.currentUser!.email,
                              "Name": informationUser.name,
                              "PhoneNumber": informationUser.phonenumber,
                              "Role": 'User',
                              "createdAt": FieldValue.serverTimestamp()
                            });
                            if (mounted) {
                              uploadImageToFirebase(
                                  context, auth.currentUser!.uid);

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('ลงทะเบียนสำเร็จ'),
                                  duration: Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );

                              Navigator.pushReplacement(context,
                                  MaterialPageRoute(
                                builder: (context) {
                                  return const MainScreen();
                                },
                              ));
                            }
                            registerFormKey.currentState!.reset();
                            //คำสั่งปิดแป้นพิมพ์
                            FocusManager.instance.primaryFocus?.unfocus();
                          });
                        } on FirebaseAuthException catch (error) {
                          if (error.message! ==
                              "The email address is already in use by another account.") {
                            eMessage =
                                "ที่อยู่อีเมลนี้มีการใช้งานแล้วโดยบัญชีอื่น";
                          }
                          print(error.message);
                        } finally {
                          setState(() {
                            isLoading = false;
                          });
                        }
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('เบอร์โทรศัพท์นี้ลงทะเบียนแล้ว'),
                              duration: Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }

                        Timer(
                          const Duration(seconds: 3),
                          () {
                            Navigator.pushReplacement(context,
                                MaterialPageRoute(
                              builder: (context) {
                                return const LoginScreen();
                              },
                            ));
                          },
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('กรุณากรอก OTP'),
                          duration: Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
            child: isLoading
                ? const CircularProgressIndicator(
                    color: Colors.white,
                  )
                : const Text(
                    "ยืนยัน",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
          )
        ],
      ),
    );
  }
}
