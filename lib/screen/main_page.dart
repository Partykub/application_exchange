import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    FirebaseAuth.instance.signInWithEmailAndPassword(
        email: 'kunratcha45@gmail.com', password: 'Party2545');
    return MaterialApp(
      home: DefaultTabController(
        length: 5,
        child: Scaffold(
          appBar: AppBar(
            title: const Text("ยินดีต้อนรับ"),
            backgroundColor: Colors.white,
          ),
          body: TabBarView(
            children: [
              Container(
                child: Center(
                  child: Column(
                    children: [
                      if (auth.currentUser!.phoneNumber != null) ...{
                        Text(auth.currentUser!.uid),
                        Text(auth.currentUser!.phoneNumber.toString())
                      } else if (auth.currentUser!.email != null) ...{
                        Text(auth.currentUser!.uid),
                        Text(auth.currentUser!.email.toString())
                      }
                    ],
                  ),
                ),
              ),
              Container(
                child: const Text("HI"),
              ),
              Container(
                child: const Text("HI"),
              ),
              Container(
                child: const Text("HI"),
              ),
              Container(
                child: const Text("HI"),
              ),
            ],
          ),
          backgroundColor: Color(0xFFF7F7F7),
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
