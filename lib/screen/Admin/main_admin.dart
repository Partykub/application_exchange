import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:exchange/screen/Admin/admin_chat_list.dart';
import 'package:exchange/screen/Admin/admin_report.dart';
import 'package:exchange/screen/Admin/manage_user_accounts.dart';
import 'package:exchange/screen/exchange/chat/chat_list.dart';
import 'package:exchange/screen/exchange/exchange.dart';
import 'package:exchange/screen/post/post.dart';
import 'package:exchange/screen/post_like/post_like.dart';
import 'package:exchange/screen/profile/profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminMain extends StatefulWidget {
  final int initialTabIndex;
  const AdminMain({Key? key, this.initialTabIndex = 0}) : super(key: key);

  @override
  State<AdminMain> createState() => _AdminMainState();
}

class _AdminMainState extends State<AdminMain> {
  final auth = FirebaseAuth.instance;
  bool admin = true;

  Future getAdminData() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('informationUser')
        .doc(auth.currentUser!.uid)
        .get();
    return snapshot.data();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(40.0),
        child: AppBar(
          elevation: 1,
          toolbarHeight: 100,
          backgroundColor: Colors.white,
          title: Row(
            children: [
              const Text(
                "ผู้ดูแลระบบ",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(right: 8.0),
                    child: Text(
                      "โหมดผู้ดูแลระบบ",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Switch(
                    activeColor: Colors.grey[80],
                    activeTrackColor: Colors.grey[800],
                    // focusColor: Colors.amber,
                    // activeTrackColor: Colors.amber,
                    // hoverColor: Colors.amber,
                    inactiveThumbColor: Colors.grey[800],
                    inactiveTrackColor: Colors.grey[500],
                    value: admin,
                    onChanged: (value) {
                      setState(() {
                        admin = value;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: admin
          ? DefaultTabController(
              length: 3,
              child: Scaffold(
                body: const TabBarView(
                  children: [
                    ManageUserAccounts(),
                    AdminChatList(),
                    AdminReport()
                  ],
                ),
                backgroundColor: Colors.white,
                bottomNavigationBar: SizedBox(
                  height: (MediaQuery.of(context).size.height / 100) * 8,
                  child: const ColoredBox(
                    color: Colors.black,
                    child: TabBar(
                      indicatorColor: Colors.white, // สีของ indicator
                      indicatorWeight: 3.0, // ความหนาของ indicator
                      labelColor:
                          Colors.white, // สีของข้อความใน Tab เมื่อถูกเลือก
                      unselectedLabelColor:
                          Colors.grey, // สีของข้อความใน Tab เมื่อไม่ถูกเลือก
                      tabs: [
                        Tab(
                          child: Text(
                            "บัญชีผู้ใช้",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        Tab(
                          child: Text(
                            "แชทกับผู้ใช้",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        Tab(
                          child: Text(
                            "การรายงาน",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : DefaultTabController(
              initialIndex: widget.initialTabIndex,
              length: 5,
              child: Scaffold(
                body: TabBarView(
                  children: [
                    const SafeArea(child: Exchange()),
                    const PostLike(),
                    const Post(),
                    const ChatList(),
                    Profile(informationUserUID: auth.currentUser!.uid),
                  ],
                ),
                backgroundColor: const Color(0xFFF7F7F7),
                bottomNavigationBar: SizedBox(
                  height: (MediaQuery.of(context).size.height / 100) * 8,
                  child: const ColoredBox(
                    color: Colors.black,
                    child: TabBar(
                      indicatorColor: Colors.white, // สีของ indicator
                      indicatorWeight: 3.0, // ความหนาของ indicator
                      labelColor:
                          Colors.white, // สีของข้อความใน Tab เมื่อถูกเลือก
                      unselectedLabelColor:
                          Colors.grey, // สีของข้อความใน Tab เมื่อไม่ถูกเลือก
                      tabs: [
                        Tab(
                          icon: Icon(
                            Icons.home,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        Tab(
                          icon: Icon(Icons.favorite_rounded,
                              color: Colors.white, size: 30),
                        ),
                        Tab(
                          icon: Icon(Icons.add, color: Colors.white, size: 30),
                        ),
                        Tab(
                          icon: Icon(Icons.chat, color: Colors.white, size: 30),
                        ),
                        Tab(
                          icon: Icon(Icons.account_circle,
                              color: Colors.white, size: 30),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    ));
  }
}
