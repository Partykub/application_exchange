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
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

class GoogleRegister extends StatefulWidget {
  final String uid, email;
  const GoogleRegister({super.key, required this.uid, required this.email});

  @override
  State<GoogleRegister> createState() => _GoogleRegisterState();
}

class _GoogleRegisterState extends State<GoogleRegister> {
  final addInformationKey = GlobalKey<FormState>();
  final otpFormKey = GlobalKey<FormState>();
  bool loading = false, loadingOTP = false, canRequestOtp = true;
  final auth = FirebaseAuth.instance;
  String? name, phoneNumber, otp, verificationId, imageUrl;
  int _otpCooldown = 120;
  Uint8List? _image;
  Timer? timer;
  var uuid = const Uuid();

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

  void startOtpCooldown() {
    setState(() {
      canRequestOtp = false; // ห้ามกดปุ่มขอ OTP
    });

    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _otpCooldown--;
      });

      if (_otpCooldown == 0) {
        timer.cancel();
        setState(() {
          canRequestOtp = true; // เมื่อครบเวลาให้สามารถขอ OTP ได้ใหม่
          _otpCooldown = 120;
        });
      }
    });
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

  @override
  void dispose() {
    timer?.cancel(); // ยกเลิกการจับเวลาถ้าหน้า State ถูกทำลาย
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
                automaticallyImplyLeading: false,
                title: const Text('เข้าสู่ระบบ'),
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
                      // ! ชื่อผู้ใช้
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
                      // ! เบอร์
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
                  )),
              Form(
                  key: otpFormKey,
                  child: Row(
                    children: [
                      Expanded(
                        // ! OTP
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
                            keyboardType:
                                TextInputType.number, // Changed to number
                            decoration: const InputDecoration(
                              labelText: 'รหัส OTP',
                              hintText: 'รหัส OTP',
                              prefixIcon: Icon(Icons.lock), // Changed icon
                            ),
                          ),
                        ),
                      ),
                      // ! ปุ่ม OTP
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 5, 20, 5),
                        child: ElevatedButton(
                          onPressed: loadingOTP
                              ? null
                              : canRequestOtp
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
                                            FirebaseAuth.instance
                                                .verifyPhoneNumber(
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
                                              codeSent:
                                                  (String verificationIdIn,
                                                      int? resendToken) {
                                                verificationId =
                                                    verificationIdIn;
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
                                                  duration:
                                                      Duration(seconds: 2),
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
                                            print(
                                                "Error แจ้งเตือน เบอร์ซ้ำ: $e");
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
                              : Text(canRequestOtp
                                  ? "ขอ OTP"
                                  : "รอ $_otpCooldown วินาที"),
                        ),
                      )
                    ],
                  )),
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
                                        .validate() &&
                                    otpFormKey.currentState!.validate()) {
                                  addInformationKey.currentState!.save();
                                  otpFormKey.currentState!.save();
                                  try {
                                    setState(() {
                                      loading = true;
                                    });

                                    PhoneAuthProvider.credential(
                                        verificationId: verificationId!,
                                        smsCode: otp!);

                                    await updateProfileImage();

                                    await FirebaseFirestore.instance
                                        .collection('informationUser')
                                        .doc(auth.currentUser!.uid)
                                        .set({
                                      "Email": widget.email,
                                      "Name": name,
                                      "PhoneNumber": phoneNumber,
                                      "profileImageUrl": imageUrl,
                                      "Role": 'User',
                                      "createdAt": FieldValue.serverTimestamp()
                                    });

                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
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
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text('ลงทะเบียนผิดพลาด'),
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
        ));
  }
}

Future<UserCredential?> signInWithGoogle() async {
  final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

  if (googleUser == null) {
    null;
  } else {
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    if (googleAuth.accessToken == null || googleAuth.idToken == null) {
      throw Exception('Missing Google Auth Token');
    }

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return await FirebaseAuth.instance.signInWithCredential(credential);
  }
  return null;
}
