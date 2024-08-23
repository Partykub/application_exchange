import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:exchange/class/pull_image.dart';
import 'package:exchange/screen/Admin/admin_edit_profile.dart';
import 'package:exchange/screen/Admin/admin_history_post.dart';
import 'package:exchange/screen/profile/post_profile.dart';
import 'package:flutter/material.dart';

class ProfileUser extends StatefulWidget {
  final userId;
  const ProfileUser({super.key, required this.userId});

  @override
  State<ProfileUser> createState() => _ProfileUserState();
}

class _ProfileUserState extends State<ProfileUser> {
  List<bool> historyWithPost = [true, false];

  int calculateStars(int exchangeSuccess, int numberOfPosts) {
    if (numberOfPosts == 0) return 0;
    double rate = (exchangeSuccess / numberOfPosts) * 100;
    if (rate >= 100) return 5;
    if (rate >= 80) return 4;
    if (rate >= 60) return 3;
    if (rate >= 40) return 2;
    if (rate >= 20) return 1;
    return 0;
  }

  List<Widget> buildStars(int stars) {
    List<Widget> starWidgets = [];
    for (int i = 0; i < stars; i++) {
      starWidgets.add(const Icon(
        Icons.star,
        color: Colors.yellow,
        size: 20,
      ));
    }
    for (int i = stars; i < 5; i++) {
      starWidgets.add(const Icon(
        Icons.star_border,
        color: Colors.grey,
        size: 20,
      ));
    }
    return starWidgets;
  }

  Future<void> deleteAccount(String uid) async {
    try {
      // เรียกใช้ฟังก์ชันคลาวด์
      final HttpsCallable callable =
          FirebaseFunctions.instance.httpsCallable('deleteUser');
      final response = await callable.call(<String, dynamic>{
        'uid': uid,
      });

      // ลบเอกสารใน collection 'informationUser'
      await FirebaseFirestore.instance
          .collection('informationUser')
          .doc(uid)
          .delete();

      // ลบเอกสารใน collection 'posts' ที่มี 'UserId' เป็น uid
      QuerySnapshot postsSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('UserId', isEqualTo: uid)
          .get();

      for (QueryDocumentSnapshot doc in postsSnapshot.docs) {
        await doc.reference.delete();
      }

      // ลบเอกสารใน collection 'Chats' ที่มี 'userIds' รวม uid
      QuerySnapshot chatsSnapshot = await FirebaseFirestore.instance
          .collection('Chats')
          .where('userIds', arrayContains: uid)
          .get();

      for (QueryDocumentSnapshot doc in chatsSnapshot.docs) {
        await doc.reference.delete();
      }

      // ลบเอกสารใน collection 'adminChat' ที่มี 'userIds' รวม uid
      QuerySnapshot adminChatsSnapshot = await FirebaseFirestore.instance
          .collection('adminChat')
          .where('userIds', arrayContains: uid)
          .get();

      for (QueryDocumentSnapshot doc in adminChatsSnapshot.docs) {
        await doc.reference.delete();
      }

      QuerySnapshot adminreviewsSnapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where('reviewer', isEqualTo: uid)
          .where('recipientReview', isEqualTo: uid)
          .get();

      for (QueryDocumentSnapshot doc in adminreviewsSnapshot.docs) {
        await doc.reference.delete();
      }

      if (response.data['success']) {
        // การลบสำเร็จ
        print("บัญชีผู้ใช้ถูกลบเรียบร้อยแล้ว");
      } else {
        // การลบล้มเหลว
        print("ไม่สามารถลบบัญชีผู้ใช้ได้");
      }
    } catch (e) {
      print("เกิดข้อผิดพลาดในการเรียกใช้ฟังก์ชัน: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            leading: IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back_ios)),
            title: const Text('โปรไฟล์'),
            backgroundColor: Colors.white,
          ),
          endDrawer: SizedBox(
            width: 200,
            child: Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const DrawerHeader(
                      decoration: BoxDecoration(color: Colors.black54),
                      child: Text(
                        'เมนู',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                        ),
                      )),
                  ListTile(
                    leading: const Icon(Icons.delete_forever_outlined),
                    title: const Text(
                      'ลบบัญชี',
                      style: TextStyle(fontSize: 15),
                    ),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            backgroundColor: Colors.white,
                            title: const Text('ยืนยันการลบ'),
                            content:
                                const Text('คุณแน่ใจหรือว่าต้องการลบบัญชีนี้?'),
                            actions: <Widget>[
                              TextButton(
                                child: const Text(
                                  'ตกลง',
                                  style: TextStyle(color: Colors.red),
                                ),
                                onPressed: () {
                                  try {
                                    deleteAccount(widget.userId);
                                    showDialog(
                                        context: context,
                                        builder: (context) {
                                          return AlertDialog(
                                            backgroundColor: Colors.white,
                                            title: const Text('ลบสำเร็จ'),
                                            content: SizedBox(
                                              height: 140,
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.check_circle_outline,
                                                    color: Colors.green[400],
                                                    size: 100,
                                                  ),
                                                  const Padding(
                                                    padding:
                                                        EdgeInsets.all(8.0),
                                                    child: Text(
                                                        "ลบบัญชีผู้ใช้สำเสร็จ"),
                                                  )
                                                ],
                                              ),
                                            ),
                                            actions: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Expanded(
                                                      child: TextButton(
                                                          onPressed: () {
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                          },
                                                          child: const Text(
                                                            "ตกลง",
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .green),
                                                          )))
                                                ],
                                              )
                                            ],
                                          );
                                        });
                                  } catch (e) {}
                                },
                              ),
                              TextButton(
                                child: const Text('ยกเลิก',
                                    style: TextStyle(color: Colors.black)),
                                onPressed: () {
                                  Navigator.of(context).pop(); // ปิด popup
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                  )
                ],
              ),
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Container(
                  color: Colors.white,
                  child: FutureBuilder(
                    future: pullImage(widget.userId),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Text("Error: ${snapshot.error}");
                      }
                      if (snapshot.hasData) {
                        final imageUrl =
                            snapshot.data!['profileImageUrl'] as String;
                        final exchangeSuccess =
                            snapshot.data!['exchangeSuccess'] ?? 0;
                        final numberOfPosts =
                            snapshot.data!['NumberOfPosts'] ?? 0;
                        final stars =
                            calculateStars(exchangeSuccess, numberOfPosts);
                        return Column(
                          children: [
                            Column(
                              children: [
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height / 55,
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width /
                                          30,
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.black,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: CircleAvatar(
                                        radius: 70,
                                        backgroundImage:
                                            CachedNetworkImageProvider(
                                                imageUrl),
                                        backgroundColor: Colors.white,
                                      ),
                                    ),
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width /
                                          20,
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height /
                                              80,
                                        ),
                                        Text(
                                          snapshot.data!['Name'] as String,
                                          style: const TextStyle(fontSize: 18),
                                        ),
                                        SizedBox(
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.002,
                                        ),
                                        Row(
                                          children: buildStars(stars),
                                        ),
                                        SizedBox(
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.005,
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Text('จำนวนโพสต์'),
                                            SizedBox(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                  20,
                                            ),
                                            const Text("แลกเปลี่ยนสำเร็จ")
                                          ],
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                  13,
                                            ),
                                            SizedBox(
                                              child: numberOfPosts != null
                                                  ? Text(
                                                      numberOfPosts.toString())
                                                  : const Text('0'),
                                            ),
                                            SizedBox(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                  4,
                                            ),
                                            SizedBox(
                                              child: exchangeSuccess != null
                                                  ? Text(exchangeSuccess
                                                      .toString())
                                                  : const Text('0'),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(
                                          height: 20,
                                        ),
                                        Row(
                                          children: [
                                            const SizedBox(width: 30),
                                            ElevatedButton(
                                                style: ButtonStyle(
                                                  backgroundColor:
                                                      MaterialStateProperty.all(
                                                          Colors.black54),
                                                  shape:
                                                      MaterialStateProperty.all<
                                                          RoundedRectangleBorder>(
                                                    RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                    ),
                                                  ),
                                                  fixedSize:
                                                      MaterialStateProperty.all(
                                                          const Size(130, 25)),
                                                ),
                                                onPressed: () {
                                                  Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder: (context) =>
                                                              AdminEditProfile(
                                                                  userId: widget
                                                                      .userId)));
                                                },
                                                child: const Text(
                                                  'แก้ไข',
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                )),
                                          ],
                                        ),
                                        const SizedBox(
                                          height: 25,
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ],
                            ),
                          ],
                        );
                      }
                      return const Center(
                        child: Text(''),
                      );
                    },
                  ),
                ),
                Container(
                  color: Colors.white,
                  child: Row(
                    children: [
                      Expanded(
                        child: ToggleButtons(
                          isSelected: historyWithPost,
                          onPressed: (int index) {
                            setState(() {
                              historyWithPost = [false, false];
                              historyWithPost[index] = true;
                            });
                          },
                          selectedColor: Colors.black,
                          color: Colors.grey[400],
                          fillColor: Colors.transparent,
                          borderRadius: BorderRadius.circular(0),
                          selectedBorderColor: Colors.black,
                          borderColor: Colors.grey[400],
                          borderWidth: 1.0,
                          children: [
                            Container(
                              alignment: Alignment.center,
                              width: ((MediaQuery.of(context).size.width / 2) -
                                  1.5),
                              child: const Text(
                                "โพสต์",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 14.0),
                              ),
                            ),
                            Container(
                              alignment: Alignment.center,
                              width: ((MediaQuery.of(context).size.width / 2) -
                                  1.5),
                              child: const Text(
                                "ประวัติการแลกเปลี่ยน",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 14.0),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                historyWithPost[0]
                    ? PostProfile(userId: widget.userId)
                    : AdminHistoryPost(userId: widget.userId),
              ],
            ),
          )),
    );
  }
}
