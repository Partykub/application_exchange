import 'package:exchange/screen/exchange/chat/chat_list.dart';
import 'package:exchange/screen/exchange/exchange.dart';
import 'package:exchange/screen/post_like/post_like.dart';
import 'package:flutter/material.dart';
import 'package:exchange/screen/post/post.dart';
import 'package:exchange/screen/profile/profile.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MainScreen extends StatefulWidget {
  final int initialTabIndex;

  const MainScreen({Key? key, this.initialTabIndex = 0}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DefaultTabController(
        initialIndex: widget.initialTabIndex,
        length: 5,
        child: Scaffold(
          body: TabBarView(
            children: [
              Container(child: const Exchange()),
              Container(
                child: const PostLike(),
              ),
              Container(
                child: const Post(),
              ),
              Container(
                child: const ChatList(),
              ),
              Container(
                child: Profile(informationUserUID: auth.currentUser!.uid),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFF7F7F7),
          bottomNavigationBar: const SizedBox(
            height: 70, // ปรับความสูงของ TabBar ตามต้องการ
            child: ColoredBox(
              color: Colors.black, // กำหนดสีพื้นหลังของ TabBar
              child: TabBar(
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
    );
  }
}
