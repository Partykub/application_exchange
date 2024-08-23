import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:exchange/screen/Admin/profile_user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ManageUserAccounts extends StatefulWidget {
  const ManageUserAccounts({super.key});

  @override
  State<ManageUserAccounts> createState() => _ManageUserAccountsState();
}

// Future getInformationUser() async{
//    final snapshot = await FirebaseFirestore.instance
//         .collection('informationUser').sna
//     return snapshot.data();
// }

class _ManageUserAccountsState extends State<ManageUserAccounts> {
  final auth = FirebaseAuth.instance;
  String searchQuery = '';
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'ค้นหา...',
                    hintStyle: const TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: Colors.grey, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: Colors.grey, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: Colors.grey, width: 1),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        body: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          color: Colors.grey[200],
          child: StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection('informationUser')
                .snapshots(),
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(
                      color: Colors.black,
                    ),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Container(
                  color: Colors.grey[200],
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.camera_alt_outlined,
                          size: 50,
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height / 130,
                        ),
                        const Text(
                          "ยังไม่มีโพสต์",
                          style: TextStyle(fontSize: 20),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final users = snapshot.data!.docs.where((doc) {
                return doc.id != auth.currentUser!.uid &&
                    doc['Name'].toString().contains(searchQuery);
              }).toList();

              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  final userName = user['Name'];
                  final image = user['profileImageUrl'];
                  final userId = user.id;
                  final createdAt = user.data().containsKey('createdAt') &&
                          user['createdAt'] != null
                      ? (user['createdAt'] as Timestamp).toDate()
                      : DateTime.now();

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(0, 1, 0, 0),
                    child: Container(
                      color: Colors.white,
                      child: ListTile(
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfileUser(userId: userId),
                            )),
                        title: Row(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundImage: CachedNetworkImageProvider(
                                image,
                              ),
                              backgroundColor: Colors.white,
                            ),
                            SizedBox(
                              width:
                                  (MediaQuery.of(context).size.width / 100) * 3,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName,
                                  style: const TextStyle(fontSize: 18),
                                ),
                                Text(
                                  "สร้างเมื่อ ${DateFormat('dd/MM/yyyy HH:mm').format(createdAt)}",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
