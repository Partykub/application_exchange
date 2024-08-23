import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:exchange/class/checkphonenumber_isnew.dart';
import 'package:exchange/screen/Admin/main_admin.dart';
import 'package:exchange/screen/main_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class PhoneLogin extends StatefulWidget {
  const PhoneLogin({super.key});

  @override
  State<PhoneLogin> createState() => _PhoneLoginState();
}

class _PhoneLoginState extends State<PhoneLogin> {
  final loginPhoneFormKey = GlobalKey<FormState>();
  String? phoneNumber, verificationId;
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: loginPhoneFormKey,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: TextFormField(
              validator: (value) {
                if (value!.isEmpty) {
                  return 'กรุณากรอกเบอร์โทรศัพท์';
                } else if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                  return 'รูปแบบเบอร์โทรศัพท์ไม่ถูกต้อง';
                }
                return null;
              },
              onSaved: (inputPhone) {
                phoneNumber = inputPhone;
              },
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'เบอร์โทรศัพท์',
                hintText: 'เบอร์โทรศัพท์',
                prefixIcon: Icon(Icons.phone),
              ),
            ),
          ),
          // ปุ่มเข้าสู่ระบบ
          Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: Row(
              children: [
                Expanded(
                    child: ElevatedButton(
                        onPressed: loading
                            ? () => FocusScope.of(context).unfocus()
                            : () async {
                                FocusScope.of(context).unfocus();
                                if (loginPhoneFormKey.currentState!
                                    .validate()) {
                                  loginPhoneFormKey.currentState!.save();
                                  setState(() {
                                    loading = true;
                                  });
                                  await Future.delayed(
                                      const Duration(seconds: 3));
                                  bool isNewPhoneNumber =
                                      await checkPhoneNumberIsNew(
                                          phoneNumber!.toString());
                                  final phonenumber =
                                      "+66${phoneNumber!.trim()}";

                                  if (!isNewPhoneNumber) {
                                    try {
                                      FirebaseAuth.instance.verifyPhoneNumber(
                                        phoneNumber: phonenumber,
                                        verificationCompleted:
                                            (PhoneAuthCredential
                                                credential) async {
                                          await FirebaseAuth.instance
                                              .signInWithCredential(credential);
                                        },
                                        verificationFailed:
                                            (FirebaseException e) {
                                          print(
                                              'Verification Failed: ${e.message}');
                                        },
                                        codeSent: (String verificationIdIn,
                                            int? resendToken) {
                                          verificationId = verificationIdIn;
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  LoginOTPScreen(
                                                verificationId:
                                                    verificationIdIn,
                                                phoneNumber: phoneNumber!,
                                              ),
                                            ),
                                          );
                                        },
                                        codeAutoRetrievalTimeout:
                                            (String verificationId) {},
                                      );
                                    } catch (e) {
                                      print("Error ขอ OTP: $e");
                                    } finally {
                                      setState(() {
                                        loading = false;
                                      });
                                    }
                                  } else {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'ข้อมูลประจำตัวที่ให้มามีรูปแบบไม่ถูกต้องหรือหมดอายุแล้ว'),
                                          duration: Duration(seconds: 2),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );

                                      await Future.delayed(
                                          const Duration(seconds: 3));
                                    }
                                    setState(() {
                                      loading = false;
                                    });
                                  }
                                }
                              },
                        child: loading
                            ? const CircularProgressIndicator(
                                strokeWidth: 3,
                                color: Colors.white,
                              )
                            : const Text(
                                "ถัดไป",
                              )))
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: must_be_immutable
class LoginOTPScreen extends StatefulWidget {
  String verificationId;
  final String phoneNumber;

  LoginOTPScreen({
    required this.verificationId,
    required this.phoneNumber,
    super.key,
  });

  @override
  _LoginOTPScreenState createState() => _LoginOTPScreenState();
}

class _LoginOTPScreenState extends State<LoginOTPScreen> {
  final auth = FirebaseAuth.instance;
  PhoneAuthCredential? credential;
  Timer? _timer;
  int _timeLeft = 120; // 120 วินาที
  bool _isOTPSent = true, loading = false;
  String otp = "";

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          _timer?.cancel();
          _isOTPSent = false;
        }
      });
    });
  }

  Future<void> _submitOTP() async {
    if (otp.length == 6) {
      try {
        credential = PhoneAuthProvider.credential(
            verificationId: widget.verificationId, smsCode: otp);

        print("ยืนยัน OTP สำเร็จ");
        // ทำงานต่อไป เช่นนำทางไปหน้า Home
      } catch (e) {
        print("ยืนยัน OTP ล้มเหลว: $e");
        // แสดง error message
      }
    } else {
      print("กรุณากรอก OTP ให้ครบ 6 ตัว");
    }
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> fetchUserData(
      String uid) async {
    try {
      var docSnapshot = await FirebaseFirestore.instance
          .collection('informationUser')
          .doc(uid)
          .get();

      return docSnapshot;
    } catch (e) {
      print('Error fetching user data: $e');
      throw Exception('Failed to fetch user data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80.0),
        child: Column(
          children: <Widget>[
            AppBar(
              title: const Text('กรอกรหัส OTP'),
              elevation: 0.0,
            ),
            Divider(
              thickness: 1.0,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
      body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 150),
                  child: Text(
                    "เราส่งรหัส OTP ไปยังหมายเลขโทรศัพท์ของคุณ",
                    style: TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 80, bottom: 100),
                  child: PinCodeTextField(
                    length: 6,
                    obscureText: false,
                    animationType: AnimationType.fade,
                    pinTheme: PinTheme(
                      shape: PinCodeFieldShape.box,
                      borderRadius: BorderRadius.circular(5),
                      fieldHeight: 50,
                      fieldWidth: 40,
                      activeFillColor: Colors.white,
                      inactiveFillColor:
                          Colors.grey[200]!, // สีของช่องที่ยังไม่กรอก
                      selectedFillColor:
                          Colors.blue[100]!, // สีของช่องที่กำลังกรอก
                      activeColor:
                          Colors.grey[500]!, // สีของขอบเมื่อกรอกครบแล้ว
                      inactiveColor: Colors.grey, // สีของขอบเมื่อยังไม่กรอก
                      selectedColor:
                          Colors.grey[500]!, // สีของขอบเมื่อกำลังกรอก
                    ),
                    animationDuration: const Duration(milliseconds: 300),
                    backgroundColor: Colors.white,
                    enableActiveFill: true,
                    onCompleted: (v) {
                      setState(() {
                        otp = v;
                      });
                      _submitOTP(); // ยืนยัน OTP อัตโนมัติเมื่อกรอกครบ 6 ตัว
                    },
                    onChanged: (value) {
                      setState(() {
                        otp = value;
                      });
                      print("Value: $value");
                    },
                    appContext: context,
                  ),
                ),
                TextButton(
                  onPressed: _isOTPSent
                      ? null
                      : () async {
                          setState(() {
                            _timeLeft = 120; // ตั้งเวลาจับเวลาใหม่
                            _isOTPSent = true;
                          });
                          _startTimer();

                          // ขอ OTP ใหม่
                          final phonenumber = "+66${widget.phoneNumber.trim()}";
                          await FirebaseAuth.instance.verifyPhoneNumber(
                            phoneNumber: phonenumber,
                            verificationCompleted:
                                (PhoneAuthCredential credential) async {
                              await FirebaseAuth.instance
                                  .signInWithCredential(credential);
                            },
                            verificationFailed: (FirebaseException e) {
                              print('Verification Failed: ${e.message}');
                            },
                            codeSent:
                                (String verificationIdIn, int? resendToken) {
                              setState(() {
                                widget.verificationId = verificationIdIn;
                              });
                            },
                            codeAutoRetrievalTimeout:
                                (String verificationId) {},
                          );
                        },
                  child: Text(
                    _isOTPSent
                        ? "ขอ OTP อีกครั้งใน $_timeLeft วินาที"
                        : "ขอ OTP ใหม่ ",
                    style: TextStyle(color: Colors.blue[700]),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 30),
                        child: ElevatedButton(
                          onPressed: loading
                              ? () => FocusScope.of(context).unfocus()
                              : () async {
                                  FocusScope.of(context).unfocus();
                                  setState(() {
                                    loading = true;
                                  });
                                  try {
                                    _submitOTP();
                                    await FirebaseAuth.instance
                                        .signInWithCredential(credential!);

                                    DocumentSnapshot userData =
                                        await fetchUserData(
                                            auth.currentUser!.uid);
                                    if (!userData.exists ||
                                        (userData.data()
                                                as Map<String, dynamic>?) ==
                                            null ||
                                        !(userData.data()
                                                as Map<String, dynamic>)
                                            .containsKey('Name')) {
                                      print("เบอร์เป็นของบัญชีอื่น");

                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'เบอร์โทรศัพท์ได้ลงทะเบียนไว้กับบัญชีอื่น'),
                                            duration: Duration(seconds: 2),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                        await Future.delayed(
                                            const Duration(seconds: 3));
                                        setState(() {
                                          loading = false;
                                        });
                                        if (mounted) {
                                          Navigator.pop(context);
                                        }
                                      }
                                    } else {
                                      if (mounted) {
                                        final currentUser =
                                            FirebaseAuth.instance.currentUser;
                                        final snapshot = await FirebaseFirestore
                                            .instance
                                            .collection('informationUser')
                                            .doc(currentUser!.uid)
                                            .get();
                                        final snapshotData = snapshot.data();
                                        final roleData = snapshotData!['Role'];

                                        if (roleData == 'Admin') {
                                          setState(() {
                                            loading = false;
                                          });
                                          if (mounted) {
                                            Navigator.pushAndRemoveUntil(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    const AdminMain(),
                                              ),
                                              (Route<dynamic> route) => false,
                                            );
                                          }
                                        } else {
                                          if (mounted) {
                                            setState(() {
                                              loading = false;
                                            });
                                            Navigator.pushAndRemoveUntil(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    const MainScreen(),
                                              ),
                                              (Route<dynamic> route) => false,
                                            );
                                          }
                                        }
                                      }
                                    }
                                  } catch (e) {
                                    setState(() {
                                      loading = false;
                                    });
                                    print('Error submitOTP: $e');
                                  } finally {
                                    setState(() {
                                      loading = false;
                                    });
                                  }
                                },
                          child: loading
                              ? const CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: Colors.white,
                                )
                              : const Text("ยืนยัน"),
                        ),
                      ),
                    )
                  ],
                ),
              ],
            ),
          )),
    );
  }
}
