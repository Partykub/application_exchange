import 'dart:async';
import 'dart:io';

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
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:uuid/uuid.dart';

class PhoneRegister extends StatefulWidget {
  const PhoneRegister({super.key});

  @override
  State<PhoneRegister> createState() => _PhoneRegisterState();
}

class _PhoneRegisterState extends State<PhoneRegister> {
  final registerPhoneFormKey = GlobalKey<FormState>();
  String? phoneNumber, verificationId;
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: registerPhoneFormKey,
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
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'เบอร์โทรศัพท์',
                hintText: 'เบอร์โทรศัพท์',
                prefixIcon: Icon(Icons.phone),
              ),
            ),
          ),
          // ปุ่มถัดไป
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
                                if (registerPhoneFormKey.currentState!
                                    .validate()) {
                                  registerPhoneFormKey.currentState!.save();
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
                                  if (isNewPhoneNumber) {
                                    try {
                                      await FirebaseAuth.instance
                                          .verifyPhoneNumber(
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
                                              builder: (context) => OTPScreen(
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
                                    // แสดง SnackBar แจ้งเตือนเบอร์ซ้ำ
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              "เบอร์โทรศัพท์นี้ลงทะเบียนแล้ว"),
                                          duration: Duration(seconds: 2),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                    await Future.delayed(
                                        const Duration(seconds: 3));
                                    if (mounted) {
                                      Navigator.pop(context);
                                    }
                                    setState(() {
                                      loading = false;
                                    });
                                  }
                                }
                              },
                        child: loading
                            ? const CircularProgressIndicator(
                                strokeWidth: 3, color: Colors.white)
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
class OTPScreen extends StatefulWidget {
  String verificationId;
  final String phoneNumber;

  OTPScreen({
    required this.verificationId,
    required this.phoneNumber,
    super.key,
  });

  @override
  _OTPScreenState createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  PhoneAuthCredential? credential;
  Timer? _timer;
  int _timeLeft = 120; // 120 วินาที
  bool _isOTPSent = true;
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
                          onPressed: () {
                            try {
                              _submitOTP();
                            } catch (e) {
                              print('Error submitOTP: $e');
                            } finally {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        PhoneAddInformationRegister(
                                            phoneNumber: widget.phoneNumber,
                                            credential: credential!),
                                  ));
                            }
                          },
                          child: const Text("ยืนยัน"),
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

// กรอกข้อมูลเพิ่มเติม
class PhoneAddInformationRegister extends StatefulWidget {
  final PhoneAuthCredential credential;
  final String phoneNumber;
  const PhoneAddInformationRegister(
      {super.key, required this.phoneNumber, required this.credential});

  @override
  State<PhoneAddInformationRegister> createState() =>
      _PhoneAddInformationRegisterState();
}

class _PhoneAddInformationRegisterState
    extends State<PhoneAddInformationRegister> {
  final addInformationKey = GlobalKey<FormState>();
  String? name, email, imageUrl;
  final auth = FirebaseAuth.instance;
  var uuid = const Uuid();
  Uint8List? _image;
  bool loading = false;

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
        } else {
          print('No image selected.');
        }
      } catch (error) {
        print('Error updating image: $error');
      }
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
          Form(
              key: addInformationKey,
              child: Column(
                children: [
                  // inputEmail
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 5, 20, 5),
                    child: TextFormField(
                      validator: (inputEmail) {
                        if (inputEmail!.isEmpty) {
                          return 'กรุณากรอกอีเมล';
                        } else if (!RegExp(
                                r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                            .hasMatch(inputEmail)) {
                          return 'รูปแบบอีเมลไม่ถูกต้อง';
                        }
                        return null;
                      },
                      onSaved: (inputEmail) {
                        email = inputEmail;
                      },
                      keyboardType: TextInputType.text, // Changed to text
                      decoration: const InputDecoration(
                        labelText: 'E-mail',
                        hintText: 'E-mail',
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 5, 20, 5),
                    child: TextFormField(
                      validator: (inputName) {
                        if (inputName == null || inputName.isEmpty) {
                          return 'กรุณากรอกชื่อผู้ใช้';
                        }
                        if (inputName.length < 6) {
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
                                    if (addInformationKey.currentState!
                                        .validate()) {
                                      addInformationKey.currentState!.save();
                                      try {
                                        setState(() {
                                          loading = true;
                                        });
                                        await Future.delayed(
                                            const Duration(seconds: 3));

                                        await FirebaseAuth.instance
                                            .signInWithCredential(
                                                widget.credential);

                                        await updateProfileImage();

                                        await FirebaseFirestore.instance
                                            .collection('informationUser')
                                            .doc(auth.currentUser!.uid)
                                            .set({
                                          "Email": email,
                                          "Name": name,
                                          "PhoneNumber": widget.phoneNumber,
                                          "profileImageUrl": imageUrl,
                                          "Role": 'User',
                                          "createdAt":
                                              FieldValue.serverTimestamp()
                                        });
                                      } catch (e) {
                                        setState(() {
                                          loading = false;
                                        });
                                        print("Error register Phone: $e");
                                      } finally {
                                        setState(() {
                                          loading = false;
                                        });
                                        if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text('ลงทะเบียนสำเร็จ'),
                                              duration: Duration(seconds: 2),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                            ),
                                          );
                                          await Future.delayed(
                                              const Duration(seconds: 3));

                                          if (mounted) {
                                            Navigator.pushReplacement(context,
                                                MaterialPageRoute(
                                              builder: (context) {
                                                return const MainScreen();
                                              },
                                            ));
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
              ))
        ],
      )),
    );
  }
}
