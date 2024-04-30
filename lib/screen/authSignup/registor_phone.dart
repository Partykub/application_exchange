import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:exchange/screen/authSignup/register_from_phone.dart';
import 'package:exchange/screen/main_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RegistorPhone extends StatefulWidget {
  const RegistorPhone({Key? key}) : super(key: key);

  @override
  State<RegistorPhone> createState() => _RegistorPhoneState();
}

class _RegistorPhoneState extends State<RegistorPhone> {
  TextEditingController phoneController = TextEditingController();
  final loginPhoneFormKey = GlobalKey<FormState>();

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
            onPressed: () async {
              if (loginPhoneFormKey.currentState!.validate()) {
                print("Phone Controller : ${phoneController.text}");
                final phoneNumber = "+66${phoneController.text.trim()}";
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
                  codeSent: (String verificationId, int? resendToken) {
                    // ส่งผู้ใช้ไปหน้ากรอก OTP
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => OTPScreen(
                                verificationId: verificationId,
                                phoneController: phoneController.text)));
                  },
                  codeAutoRetrievalTimeout: (String verificationId) {},
                );
              }
            },
            child: const Text(
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
            onPressed: () async {
              try {
                PhoneAuthCredential credential = PhoneAuthProvider.credential(
                    verificationId: widget.verificationId,
                    smsCode: otpController.text);

                await auth.signInWithCredential(credential);

                // Check if the phone number is new
                bool isNewPhoneNumber =
                    await checkPhoneNumberIsNew(widget.phoneController);

                DocumentSnapshot userData =
                    await fetchUserData(auth.currentUser!.uid);

                if (isNewPhoneNumber) {
                  //ถ้าไม่มีเบอร์อยู่เหมือนกันอยู่ใน field
                  // Phone number is new: Redirect to register screen
                  print("uid ของ phone : ${auth.currentUser!.uid}");
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => RegisterScreenPhone(
                            informationUserUID: auth.currentUser!.uid,
                            InformationUserPhone: widget.phoneController)),
                  );
                } else {
                  //ถ้ามีเบอร์เหมือนกันอยู่ใน field แต่ ไม่มี field name
                  if (!userData.exists ||
                      (userData.data() as Map<String, dynamic>?) == null ||
                      !(userData.data() as Map<String, dynamic>)
                          .containsKey('Name')) {
                    print('มีเบอร์เหมือนกันอยู่ใน field แต่ ไม่มี field name');
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => RegisterScreenPhone(
                              informationUserUID: auth.currentUser!.uid,
                              InformationUserPhone: widget.phoneController)),
                    );
                  } else {
                    print('มีเบอร์เหมือนกันอยู่ในfield แล้วก็มี field name');
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => MainScreen()),
                    );
                  }
                }
              } catch (ex) {
                print('Error signing in with phone auth credential: $ex');
              }
            },
            child: const Text(
              "สมัครสมาชิก",
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          )
        ],
      ),
    );
  }
}

Future<bool> checkPhoneNumberIsNew(String phoneNumber) async {
  try {
    QuerySnapshot<Map<String, dynamic>> querySnapshot = await FirebaseFirestore
        .instance
        .collection('informationUser')
        .where('PhoneNumber', isEqualTo: phoneNumber)
        .get();

    return querySnapshot.docs.isEmpty;
  } catch (e) {
    print('Error checking phone number: $e');
    return false;
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
