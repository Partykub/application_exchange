import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:exchange/class/information.dart';
import 'package:exchange/class/new_image_profile.dart';
import 'package:exchange/screen/main_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class RegisterScreenPhone extends StatefulWidget {
  final informationUserUID;
  final InformationUserPhone;
  const RegisterScreenPhone(
      {super.key,
      required this.informationUserUID,
      required this.InformationUserPhone});

  @override
  State<RegisterScreenPhone> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreenPhone> {
  final registerFormKey = GlobalKey<FormState>();
  InformationUser informationUser = InformationUser();
  late Future<FirebaseApp> firebase;

  final auth = FirebaseAuth.instance;
  CollectionReference _userCollection =
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
              title: const Text("สมัครสมาชิกด้วยเบอร์โทรศัพท์"),
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
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
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
                        validator: (inputemail) {
                          if (inputemail!.isEmpty) {
                            return "กรุณากรอกอีเมล";
                          } else if (!RegExp(
                                  r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                              .hasMatch(inputemail)) {
                            return "รูปแบบอีเมลไม่ถูกต้อง";
                          }
                          return null;
                        },
                        onSaved: (inputemail) {
                          informationUser.email = inputemail;
                        },
                        keyboardType: TextInputType.text,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'กรอกอีเมลของคุณ',
                          hintText: 'กรอกอีเมลของคุณ',
                        ),
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
                        child: const Text(
                          "ลงทะเบียน",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                        onPressed: () async {
                          if (registerFormKey.currentState!.validate()) {
                            registerFormKey.currentState!.save();
                            try {
                              await _userCollection
                                  .doc(widget.informationUserUID)
                                  .set({
                                "Email": informationUser.email,
                                "Name": informationUser.name,
                                "PhoneNumber": widget.InformationUserPhone
                              });

                              uploadImageToFirebase(
                                  context, widget.informationUserUID);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('ลงทะเบียนสำเร็จ'),
                                  duration: const Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              Navigator.pushReplacement(context,
                                  MaterialPageRoute(
                                builder: (context) {
                                  return const MainScreen();
                                },
                              ));
                            } catch (error) {
                              print('Error: $error');
                            }
                          }
                        },
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
