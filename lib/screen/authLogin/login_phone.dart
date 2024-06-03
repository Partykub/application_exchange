import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:exchange/class/checkphonenumber_isnew.dart';
import 'package:exchange/screen/authLogin/login_main.dart';
import 'package:exchange/screen/authSignup/main_registor.dart';
import 'package:exchange/screen/main_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PhoneAuth extends StatefulWidget {
  const PhoneAuth({Key? key}) : super(key: key);

  @override
  State<PhoneAuth> createState() => _PhoneAuthState();
}

class _PhoneAuthState extends State<PhoneAuth> {
  TextEditingController phoneController = TextEditingController();
  final loginPhoneFormKey = GlobalKey<FormState>();
  bool isLoading = false;

  FirebaseAuth auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: loginPhoneFormKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: TextFormField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value!.isEmpty) {
                  return 'กรุณากรอกเบอร์โทรศัพท์';
                } else if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                  return 'รูปแบบเบอร์โทรศัพท์ไม่ถูกต้อง';
                }
                return null;
              },
              decoration: InputDecoration(
                hintText: "กรอกเบอร์โทรศัพท์ของคุณ",
                suffixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 50,
          ),
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
            onPressed: isLoading
                ? null
                : () async {
                    if (loginPhoneFormKey.currentState!.validate()) {
                      setState(() {
                        isLoading = true;
                      });
                      print("Phone Controller : ${phoneController.text}");
                      final phoneNumber = "+66${phoneController.text.trim()}";
                      bool isNewPhoneNumber =
                          await checkPhoneNumberIsNew(phoneController.text);

                      if (isNewPhoneNumber) {
                        // ignore: use_build_context_synchronously
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'ข้อมูลประจำตัวที่ให้มามีรูปแบบไม่ถูกต้องหรือหมดอายุแล้ว'),
                              duration: Duration(seconds: 3),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const RegistorScreen()),
                          );
                        }
                      } else {
                        print("เป็นเบอร์ที่มีในระบบแล้ว");
                        try {
                          await FirebaseAuth.instance.verifyPhoneNumber(
                            phoneNumber: phoneNumber,
                            verificationCompleted:
                                (PhoneAuthCredential credential) async {
                              await FirebaseAuth.instance
                                  .signInWithCredential(credential);
                            },
                            verificationFailed: (FirebaseAuthException e) {
                              print('Verification Failed: ${e.message}');
                            },
                            codeSent:
                                (String verificationId, int? resendToken) {
                              // ส่งผู้ใช้ไปหน้ากรอก OTP
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => OTPScreen(
                                          verificationId: verificationId,
                                          phoneController:
                                              phoneController.text)));
                            },
                            codeAutoRetrievalTimeout:
                                (String verificationId) {},
                          );
                        } catch (e) {
                          print("Error login phonenumber $e");
                        } finally {
                          setState(() {
                            isLoading = false;
                          });
                        }
                      }
                    }
                  },
            child: isLoading
                ? const CircularProgressIndicator(
                    color: Colors.white,
                  )
                : const Text(
                    "ถัดไป",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
          ),
        ],
      ),
    );
  }
}

class OTPScreen extends StatefulWidget {
  final String verificationId;
  final String phoneController;
  const OTPScreen(
      {super.key, required this.verificationId, required this.phoneController});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  TextEditingController otpController = TextEditingController();
  FirebaseAuth auth = FirebaseAuth.instance;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // แก้ไขเพิ่ม Scaffold ให้มีโครงสร้างหน้าจอครบถ้วน
      appBar: AppBar(
        title: const Text('OTP Verification'),
      ),
      body: Column(
        children: [
          const SizedBox(
            height: 50,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                  hintText: "Enter The OTP",
                  suffixIcon: const Icon(Icons.message),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12))),
            ),
          ),
          const SizedBox(
            height: 50,
          ),
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
            onPressed: isLoading
                ? null
                : () async {
                    try {
                      setState(() {
                        isLoading = true;
                      });
                      PhoneAuthCredential credential =
                          PhoneAuthProvider.credential(
                              verificationId: widget.verificationId,
                              smsCode: otpController.text);

                      await auth.signInWithCredential(credential);

                      DocumentSnapshot userData =
                          await fetchUserData(auth.currentUser!.uid);

                      if (!userData.exists ||
                          (userData.data() as Map<String, dynamic>?) == null ||
                          !(userData.data() as Map<String, dynamic>)
                              .containsKey('Name')) {
                        User? user = FirebaseAuth.instance.currentUser;
                        await user!.delete();
                        print("เบอร์เป็นของบัญชีอื่น");
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'เบอร์โทรศัพท์ได้ลงทะเบียนไว้กับบัญชีอื่น'),
                              duration: Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                            (Route<dynamic> route) => false,
                          );
                        }
                      } else {
                        if (mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MainScreen(),
                            ),
                            (Route<dynamic> route) => false,
                          );
                        }
                      }
                    } catch (e) {
                      print("Error OTP Login $e");
                    } finally {
                      setState(() {
                        isLoading = false;
                      });
                    }
                  },
            child: isLoading
                ? const CircularProgressIndicator(
                    color: Colors.white,
                  )
                : const Text(
                    "เข้าสู่ระบบ",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
          )
        ],
      ),
    );
  }
}

Future<DocumentSnapshot<Map<String, dynamic>>> fetchUserData(String uid) async {
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
