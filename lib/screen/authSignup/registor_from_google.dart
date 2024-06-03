import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:exchange/class/checkphonenumber_isnew.dart';
import 'package:exchange/class/information.dart';
import 'package:exchange/class/new_image_profile.dart';
import 'package:exchange/screen/authLogin/login_main.dart';
import 'package:exchange/screen/main_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class RegisterScreenGoogle extends StatefulWidget {
  final informationUserUID;
  const RegisterScreenGoogle(
      {super.key,
      required this.informationUserUID,
      required bool isFromGoogleLogin});

  @override
  State<RegisterScreenGoogle> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreenGoogle> {
  final registerFormKey = GlobalKey<FormState>();
  InformationUser informationUser = InformationUser();
  late Future<FirebaseApp> firebase;
  String? eMessage;
  String? _verificationId;
  String? _smsCode;
  String? _message;
  bool isLoading = false;
  bool isLoadingPhone = false;

  final auth = FirebaseAuth.instance;
  final CollectionReference _userCollection =
      FirebaseFirestore.instance.collection('informationUser');

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
        //ตรวจสอบ การเชื่อมต่อว่ามีerrorไหม
        if (snapshot.hasError) {
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
              title: const Text("สมัครสมาชิกด้วยบัญชี Google"),
            ),
            body: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(15.0),
                child: Form(
                  key: registerFormKey,
                  child: Column(
                    children: [
                      TextFormField(
                        validator: (inputname) {
                          if (inputname!.isEmpty) {
                            return "กรุณากรอกชื่อ";
                          } else if (!RegExp(r'^[a-zA-Z0-9]{3,10}$')
                              .hasMatch(inputname)) {
                            return "ชื่อผู้ใช้ไม่ถูกต้อง";
                          }
                          return null;
                        },
                        onSaved: (inputname) {
                          informationUser.name = inputname;
                        },
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          labelText: 'กรอกชื่อของคุณ',
                          hintText: 'กรอกชื่อของคุณ',
                        ),
                      ),
                      const SizedBox(
                        height: 25,
                      ),
                      // InputPhoneNumber
                      // InputPhoneNumber
                      TextFormField(
                        validator: (inputnumber) {
                          if (inputnumber!.isEmpty) {
                            return "กรุณากรอกเบอร์โทรศัพท์";
                          } else if (!RegExp(r'^0[0-9]{9}$')
                              .hasMatch(inputnumber)) {
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
                              borderRadius: BorderRadius.circular(12)),
                          labelText: 'กรอกเบอร์โทรศัพท์',
                          hintText: 'กรอกเบอร์โทรศัพท์',
                          suffixIcon: GestureDetector(
                            onTap: isLoadingPhone
                                ? null
                                : () async {
                                    if (registerFormKey.currentState!
                                        .validate()) {
                                      registerFormKey.currentState!.save();
                                      final phoneNumber =
                                          "+66${informationUser.phonenumber!.trim()}";
                                      bool isNewPhoneNumber =
                                          await checkPhoneNumberIsNew(
                                              informationUser.phonenumber
                                                  .toString());
                                      if (isNewPhoneNumber) {
                                        try {
                                          print("เป็นเบอร์ใหม่");
                                          setState(() {
                                            isLoading = true;
                                          });
                                          FirebaseAuth.instance
                                              .verifyPhoneNumber(
                                            phoneNumber: phoneNumber,
                                            verificationCompleted:
                                                (PhoneAuthCredential
                                                    credential) async {
                                              await FirebaseAuth.instance
                                                  .signInWithCredential(
                                                      credential);
                                            },
                                            verificationFailed:
                                                (FirebaseException e) {
                                              print(
                                                  'Verifivation Failed: ${e.message}');
                                            },
                                            codeSent: (String verificationId,
                                                int? resendToken) {
                                              _verificationId = verificationId;
                                            },
                                            codeAutoRetrievalTimeout:
                                                (String verificationId) {},
                                          );
                                        } catch (e) {
                                          print("Error Google NewUser: $e");
                                        } finally {
                                          setState(() {
                                            isLoading = false;
                                          });
                                        }
                                      } else {
                                        User? user =
                                            FirebaseAuth.instance.currentUser;
                                        await user!.delete();

                                        if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'เบอร์โทรศัพท์ได้ลงทะเบียนแล้ว'),
                                              duration: Duration(seconds: 2),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                            ),
                                          );
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    const LoginScreen()),
                                          );
                                        }
                                      }
                                    }
                                  },
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Container(
                                width: 80, // กำหนดความกว้างของปุ่ม
                                height: 5, // กำหนดความสูงของปุ่ม
                                decoration: BoxDecoration(
                                  color:
                                      Colors.black54, // กำหนดสีพื้นหลังเป็นสีดำ
                                  borderRadius: BorderRadius.circular(
                                      10), // กำหนดเส้นรอบมุมเป็นวงรี
                                ),
                                child: Center(
                                  child: isLoadingPhone
                                      ? SizedBox(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              20,
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height /
                                              40,
                                          child:
                                              const CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : const Text(
                                          'ขอ OTP',
                                          style: TextStyle(
                                            color: Colors
                                                .white, // กำหนดสีตัวหนังสือเป็นสีขาว
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 25,
                      ),
                      TextFormField(
                        keyboardType: TextInputType.number,
                        onChanged: (value) => _smsCode = value,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
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
                      const SizedBox(
                        height: 25,
                      ),
                      ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor:
                              const MaterialStatePropertyAll(Colors.black),
                          shape:
                              MaterialStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          fixedSize:
                              MaterialStateProperty.all(const Size(180, 30)),
                        ),
                        onPressed: isLoading
                            ? null
                            : () async {
                                if (registerFormKey.currentState!.validate()) {
                                  if (_smsCode != null) {
                                    setState(() {
                                      isLoading = true;
                                    });
                                    registerFormKey.currentState!.save();
                                    try {
                                      PhoneAuthProvider.credential(
                                          verificationId: _verificationId!,
                                          smsCode: _smsCode!);

                                      await _userCollection
                                          .doc(auth.currentUser!.uid)
                                          .set({
                                        "Email": auth.currentUser!.email,
                                        "Name": informationUser.name,
                                        "PhoneNumber":
                                            informationUser.phonenumber
                                      });

                                      // ignore: use_build_context_synchronously
                                      await uploadImageToFirebase(
                                          context, auth.currentUser!.uid);

                                      // ignore: use_build_context_synchronously
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text('ลงทะเบียนสำเร็จ'),
                                          duration: Duration(seconds: 2),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                      // ignore: use_build_context_synchronously
                                      Navigator.pushReplacement(context,
                                          MaterialPageRoute(
                                        builder: (context) {
                                          return const MainScreen();
                                        },
                                      ));
                                    } catch (error) {
                                      print('Error: $error');
                                    } finally {
                                      setState(() {
                                        isLoading = false;
                                      });
                                    }
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('กรุณากรอก รหัส OTP'),
                                        duration: Duration(seconds: 2),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                }
                              },
                        child: isLoading
                            ? SizedBox(
                                width: MediaQuery.of(context).size.width / 20,
                                height: MediaQuery.of(context).size.height / 40,
                                child: const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                "ยืนยัน",
                                style: TextStyle(
                                  fontSize:
                                      MediaQuery.of(context).size.height / 60,
                                  color: Colors.white,
                                ),
                              ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          );
        }
        // รอการเชื่อมต่อ
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}
