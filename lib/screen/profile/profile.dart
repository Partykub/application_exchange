import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:exchange/class/pull_image.dart';
import 'package:exchange/main.dart';
import 'package:exchange/screen/profile/chat_admin.dart';
import 'package:exchange/screen/profile/edit_profile.dart';
import 'package:exchange/screen/profile/history_post.dart';
import 'package:exchange/screen/profile/post_profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class Profile extends StatefulWidget {
  final String informationUserUID;
  const Profile({super.key, required this.informationUserUID});
  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  List<bool> historyWithPost = [true, false];
  bool chatAdminLoading = false;

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

  Future<String> buildChat() async {
    DocumentReference docRef =
        await FirebaseFirestore.instance.collection("adminChat").add({
      'userIds': [widget.informationUserUID, 'wd2xQW3GODRH3AhhDFiVnPHCYim2'],
      'createdAt': FieldValue.serverTimestamp(),
    });
    String docId = docRef.id;
    return docId;
  }

  Future<Map<String, dynamic>> getChat() async {
    var querySnapshot = await FirebaseFirestore.instance
        .collection("adminChat")
        .where('userIds', arrayContains: widget.informationUserUID)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      var docId = querySnapshot.docs.first.id;
      return {
        'found': true,
        'docId': docId,
      }; // คืนค่า true และ doc.id ที่หาเจอ
    } else {
      return {
        'found': false,
      }; // คืนค่า false และไม่มี doc.id
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
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
                    leading: const FaIcon(FontAwesomeIcons.lifeRing),
                    title: const Text(
                      'การช่วยเหลือหรือการสนับสนุน',
                      style: TextStyle(fontSize: 15),
                    ),
                    onTap: chatAdminLoading
                        ? null
                        : () async {
                            try {
                              setState(() {
                                chatAdminLoading = true;
                              });
                              var hasChat = await getChat();
                              if (hasChat['found']) {
                                String docId = hasChat['docId'];
                                if (mounted) {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ChatAdmin(
                                            chatId: docId, name: 'ผู้ดูแลระบบ'),
                                      ));
                                }
                              } else {
                                var docId = await buildChat();
                                if (mounted) {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ChatAdmin(
                                            chatId: docId, name: 'Admin'),
                                      ));
                                }
                              }
                            } catch (e) {
                              print(e);
                            } finally {
                              setState(() {
                                chatAdminLoading = false;
                              });
                            }
                          },
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text(
                      'ออกจากระบบ',
                      style: TextStyle(fontSize: 15),
                    ),
                    onTap: () {
                      FirebaseAuth.instance.signOut();
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MyApp(),
                          ));
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
                    future: pullImage(widget.informationUserUID),
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
                                                            EditProfile(
                                                                informationUserUID:
                                                                    widget
                                                                        .informationUserUID),
                                                      ));
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
                    ? PostProfile(userId: widget.informationUserUID)
                    : HistoryPost(),
              ],
            ),
          )),
    );
  }
}
