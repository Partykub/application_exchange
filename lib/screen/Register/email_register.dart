import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:exchange/class/checkphonenumber_isnew.dart';
import 'package:exchange/screen/main_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

class EmailPasswordRegister extends StatefulWidget {
  const EmailPasswordRegister({super.key});

  @override
  State<EmailPasswordRegister> createState() => _EmailPasswordRegisterState();
}

class _EmailPasswordRegisterState extends State<EmailPasswordRegister> {
  final loginEmailPassFormKey = GlobalKey<FormState>();
  String? email, password;
  bool obscurePassword = true;

  void togglePasswordVisibility() {
    setState(() {
      obscurePassword = !obscurePassword;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
        key: loginEmailPassFormKey,
        child: SingleChildScrollView(
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
                            return 'รหัสผ่านต้องมีความยาวอย่างน้อย 6 ตัวอักษร';
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
                            onPressed: () {
                              if (loginEmailPassFormKey.currentState!
                                  .validate()) {
                                loginEmailPassFormKey.currentState!.save();

                                try {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            EmailAddInformationRegister(
                                                email: email!,
                                                password: password!),
                                      ));
                                } catch (e) {
                                  print(
                                      "Error ลงทะเบียนด้วย email password :$e");
                                }
                              }
                            },
                            child: const Text(
                              "ลงทะเบียน",
                            )))
                  ],
                ),
              ),
            ],
          ),
        ));
  }
}

class EmailAddInformationRegister extends StatefulWidget {
  final String email, password;
  const EmailAddInformationRegister(
      {super.key, required this.email, required this.password});

  @override
  State<EmailAddInformationRegister> createState() =>
      _EmailAddInformationRegisterState();
}

class _EmailAddInformationRegisterState
    extends State<EmailAddInformationRegister> {
  final addInformationKey = GlobalKey<FormState>();
  final otpFormKey = GlobalKey<FormState>();
  String? name, phoneNumber, otp, imageUrl, verificationId;
  Uint8List? _image;
  var uuid = const Uuid();
  bool loading = false, loadingOTP = false;
  final auth = FirebaseAuth.instance;

  int _otpCooldown = 120; // ระยะเวลาในวินาทีที่ต้องรอก่อนขอ OTP ใหม่
  Timer? _timer;
  bool _canRequestOtp = true; // เริ่มต้นให้สามารถขอ OTP ได้

  Future<void> pickImage() async {
    if (Platform.isAndroid) {
      if (!await Permission.storage.request().isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('การอนุญาตถูกปฏิเสธในการเข้าถึงที่เก็บข้อมูล')),
          );
        }
      }
      {
        null;
      }
    }
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _image = File(pickedImage.path).readAsBytesSync();
      });
    }
  }

  Future<void> updateProfileImage() async {
    if (_image == null || _image!.isEmpty) {
      final Directory tempDir = await getTemporaryDirectory();
      final File tempFile = File('${tempDir.path}/temp.jpg');
      final ByteData data = await rootBundle.load('lib/images/UserProfile.jpg');
      final Uint8List bytes = data.buffer.asUint8List();
      await tempFile.writeAsBytes(bytes); // บันทึกไฟล์รูปภาพไว้ในโฟลเดอร์ temp

      FirebaseStorage storage = FirebaseStorage.instance;
      Reference ref = storage.ref().child('User Profile/${uuid.v4()}');
      await ref.putFile(tempFile); // อัปโหลดไฟล์รูปภาพ

      imageUrl = await ref.getDownloadURL();
    } else {
      try {
        if (_image != null) {
          FirebaseStorage storage = FirebaseStorage.instance;
          Reference ref = storage.ref().child('User Profile/${uuid.v4()}.jpg');

          await ref.putData(_image!);

          imageUrl = await ref.getDownloadURL();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image updated successfully'),
                duration: Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else {
          print('No image selected.');
        }
      } catch (error) {
        print('Error updating image: $error');
      }
    }
  }

  Future<void> saveImagePathToFirestore(
      String imageUrl, String informationUserUID) async {
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      DocumentReference userRef =
          firestore.collection('informationUser').doc(informationUserUID);
      await userRef.update({'profileImageUrl': imageUrl});
      print("Image URL saved to Firestore successfully!");
    } catch (error) {
      print("Error saving image URL: $error");
    }
  }

  void startOtpCooldown() {
    setState(() {
      _canRequestOtp = false; // ห้ามกดปุ่มขอ OTP
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _otpCooldown--;
      });

      if (_otpCooldown == 0) {
        timer.cancel();
        setState(() {
          _canRequestOtp = true; // เมื่อครบเวลาให้สามารถขอ OTP ได้ใหม่
          _otpCooldown = 120;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // ยกเลิกการจับเวลาถ้าหน้า State ถูกทำลาย
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80.0),
        child: Column(
          children: <Widget>[
            AppBar(
              title: const Text('กรอกโปรไฟล์ของคุณให้สมบูรณ์'),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // รูปโปรไฟล์
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 40, 16, 40),
              child: Container(
                color: Colors.white,
                child: Center(
                  child: InkWell(
                    onTap: pickImage,
                    child: CircleAvatar(
                      radius: 100,
                      backgroundColor: Colors.grey[200],
                      backgroundImage:
                          _image != null ? MemoryImage(_image!) : null,
                      child: _image == null
                          ? Icon(
                              Icons.add_a_photo,
                              size: 30,
                              color: Colors.grey[600],
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),
            // กรอกชื่อผู้ใช้
            Form(
              key: addInformationKey,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 5, 20, 5),
                    child: TextFormField(
                      validator: (inputName) {
                        if (inputName == null || inputName.isEmpty) {
                          return 'กรุณากรอกชื่อผู้ใช้';
                        } else if (inputName.length < 6) {
                          return 'ต้องมีตัวอักษรอย่างน้อย 6 ตัวอักษร';
                        }
                        return null;
                      },
                      onSaved: (inputName) {
                        name = inputName;
                      },
                      keyboardType: TextInputType.text, // Changed to text
                      decoration: const InputDecoration(
                        labelText: 'ชื่อผู้ใช้',
                        hintText: 'ชื่อผู้ใช้',
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 5, 20, 5),
                    child: TextFormField(
                      validator: (inputPhone) {
                        String pattern = r'^0\d{9}$';
                        RegExp regExp = RegExp(pattern);
                        if (inputPhone == null || inputPhone.isEmpty) {
                          return 'กรุณากรอกหมายเลขโทรศัพท์';
                        }
                        if (!regExp.hasMatch(inputPhone)) {
                          return 'รูปแบบหมายเลขโทรศัพท์ไม่ถูกต้อง';
                        }
                        return null;
                      },
                      onSaved: (inputPhone) {
                        phoneNumber = inputPhone;
                      },
                      keyboardType: TextInputType.phone, // Changed to phone
                      decoration: const InputDecoration(
                        labelText: 'หมายเลขโทรศัพท์',
                        hintText: 'หมายเลขโทรศัพท์',
                        prefixIcon: Icon(Icons.phone), // Changed icon
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // กรอก OTP
            Form(
              key: otpFormKey,
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 5, 20, 5),
                      child: TextFormField(
                        validator: (inputOtp) {
                          if (inputOtp == null || inputOtp.isEmpty) {
                            return 'กรุณากรอกรหัส OTP';
                          }
                          return null;
                        },
                        onSaved: (inputOtp) {
                          otp = inputOtp;
                        },
                        keyboardType: TextInputType.number, // Changed to number
                        decoration: const InputDecoration(
                          labelText: 'รหัส OTP',
                          hintText: 'รหัส OTP',
                          prefixIcon: Icon(Icons.lock), // Changed icon
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 5, 20, 5),
                    child: ElevatedButton(
                      onPressed: loadingOTP
                          ? null
                          : _canRequestOtp
                              ? () async {
                                  FocusScope.of(context).unfocus();
                                  if (addInformationKey.currentState!
                                      .validate()) {
                                    setState(() {
                                      loadingOTP = true;
                                    });
                                    await Future.delayed(
                                        const Duration(seconds: 3));
                                    addInformationKey.currentState!.save();
                                    otpFormKey.currentState!.save();
                                    bool isNewPhoneNumber =
                                        await checkPhoneNumberIsNew(
                                            phoneNumber!.toString());
                                    final phonenumber =
                                        "+66${phoneNumber!.trim()}";
                                    if (isNewPhoneNumber) {
                                      try {
                                        startOtpCooldown(); // เริ่มจับเวลาหลังจากขอ OTP
                                        FirebaseAuth.instance.verifyPhoneNumber(
                                          phoneNumber: phonenumber,
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
                                          codeSent: (String verificationIdIn,
                                              int? resendToken) {
                                            verificationId = verificationIdIn;
                                          },
                                          codeAutoRetrievalTimeout:
                                              (String verificationId) {},
                                        );
                                      } catch (e) {
                                        print("Error ขอ OTP: $e");
                                      } finally {
                                        setState(() {
                                          loadingOTP = false;
                                        });
                                      }
                                    } else {
                                      try {
                                        setState(() {
                                          loadingOTP = true;
                                        });
                                        // แสดง SnackBar
                                        if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  "เบอร์โทรศัพท์นี้ลงทะเบียนแล้ว"),
                                              duration: Duration(seconds: 2),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                        await Future.delayed(
                                            const Duration(seconds: 3));
                                        if (mounted) {
                                          Navigator.pop(context);
                                          Navigator.pop(context);
                                        }
                                      } catch (e) {
                                        print("Error แจ้งเตือน เบอร์ซ้ำ: $e");
                                      } finally {
                                        setState(() {
                                          loadingOTP = false;
                                        });
                                      }
                                    }
                                  } else {
                                    setState(() {
                                      loadingOTP = false;
                                    });
                                  }
                                }
                              : null,
                      child: loadingOTP
                          ? const CircularProgressIndicator(
                              strokeWidth: 3, color: Colors.white)
                          : Text(_canRequestOtp
                              ? "ขอ OTP"
                              : "รอ $_otpCooldown วินาที"),
                    ),
                  )
                ],
              ),
            ),
// ปุ่มยืนยัน
            Row(
              children: [
                Expanded(
                    child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 50, 20, 0),
                  child: ElevatedButton(
                      onPressed: loading
                          ? () => FocusScope.of(context).unfocus()
                          : () async {
                              FocusScope.of(context).unfocus();
                              if (addInformationKey.currentState!.validate() &&
                                  otpFormKey.currentState!.validate()) {
                                addInformationKey.currentState!.save();
                                otpFormKey.currentState!.save();
                                try {
                                  setState(() {
                                    loading = true;
                                  });

                                  await FirebaseAuth.instance
                                      .createUserWithEmailAndPassword(
                                          email: widget.email,
                                          password: widget.password)
                                      .then((value) async {
                                    //เข้าสู่ระบบหลังจากสมัคร Auth
                                    FirebaseAuth.instance
                                        .signInWithEmailAndPassword(
                                            email: widget.email,
                                            password: widget.password);

                                    PhoneAuthProvider.credential(
                                        verificationId: verificationId!,
                                        smsCode: otp!);

                                    await updateProfileImage();

                                    await FirebaseFirestore.instance
                                        .collection('informationUser')
                                        .doc(auth.currentUser!.uid)
                                        .set({
                                      "Email": auth.currentUser!.email,
                                      "Name": name,
                                      "PhoneNumber": phoneNumber,
                                      "profileImageUrl": imageUrl,
                                      "Role": 'User',
                                      "createdAt": FieldValue.serverTimestamp()
                                    });
                                  });
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('ลงทะเบียนสำเร็จ'),
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
                                      Navigator.pushReplacement(context,
                                          MaterialPageRoute(
                                        builder: (context) {
                                          return const MainScreen();
                                        },
                                      ));
                                    }
                                  }
                                } catch (e) {
                                  print("Error Email/Pass : $e");
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text('E-mail นี้ลงทะเบียนไปแล้ว'),
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
                                      Navigator.pop(context);
                                    }
                                  }
                                }
                              }
                            },
                      child: loading
                          ? const CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.white,
                            )
                          : const Text("ยืนยัน")),
                )),
              ],
            )
          ],
        ),
      ),
    );
  }
}
