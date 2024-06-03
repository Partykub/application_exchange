import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:exchange/screen/exchange/visit_detail_post.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Category extends StatefulWidget {
  final String category;
  const Category({super.key, required this.category});

  @override
  State<Category> createState() => _CategoryState();
}

class _CategoryState extends State<Category> {
  final auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      color: Colors.grey[200],
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          leading: IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back)),
          title: Text(
            widget.category,
            style: const TextStyle(fontSize: 18),
          ),
        ),
        body: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('posts')
              .where('Category', isEqualTo: widget.category)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.black,
                  ),
                ),
              );
            }
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
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
                      Text(
                        'หมวดหมู่${widget.category}',
                        style: const TextStyle(fontSize: 16),
                      )
                    ],
                  ),
                ),
              );
            }

            final posts = snapshot.data!.docs
                .where((doc) => doc['UserId'] != auth.currentUser!.uid)
                .toList();

            if (posts.isEmpty) {
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
                      Text(
                        'หมวดหมู่${widget.category}',
                        style: const TextStyle(fontSize: 16),
                      )
                    ],
                  ),
                ),
              );
            }

            return Padding(
              padding: EdgeInsets.zero,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 0.5,
                  crossAxisSpacing: 0.5,
                  childAspectRatio: 0.6,
                ),
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  final image = List<String>.from(post['Images']);
                  final userId = post['UserId'];
                  final Timestamp timestamp = post['createdAt'] as Timestamp;
                  final DateTime createdAt = timestamp.toDate();
                  final String formattedDate =
                      DateFormat('dd/MM/yyyy HH:mm').format(createdAt);

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                VisitDetailPost(postId: post.id),
                          ));
                    },
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(0),
                      ),
                      child: Column(
                        children: [
                          StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('informationUser')
                                .doc(userId)
                                .snapshots(),
                            builder: (context, snapshot2) {
                              if (snapshot2.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }
                              if (!snapshot2.hasData ||
                                  !snapshot2.data!.exists) {
                                return const Center(
                                    child: Text('User not found'));
                              }
                              final userData = snapshot2.data!;
                              return Container(
                                color: Colors.white,
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(10, 0, 0, 0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          CircleAvatar(
                                            radius: 16,
                                            backgroundImage:
                                                CachedNetworkImageProvider(
                                              userData['profileImageUrl'],
                                            ),
                                            backgroundColor: Colors.white,
                                          ),
                                          SizedBox(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                50,
                                          ),
                                          Text(
                                            userData['Name'],
                                            style:
                                                const TextStyle(fontSize: 15),
                                          ),
                                        ],
                                      ),
                                      PopupMenuButton<String>(
                                        color: Colors.white,
                                        itemBuilder: (BuildContext context) =>
                                            <PopupMenuEntry<String>>[
                                          const PopupMenuItem<String>(
                                            value: 'profile',
                                            child: ListTile(
                                              leading:
                                                  Icon(Icons.person_pin_sharp),
                                              title: Text('เยี่ยมชมโปรไฟล์'),
                                            ),
                                          ),
                                          PopupMenuItem<String>(
                                            value: 'report',
                                            child: ListTile(
                                              leading: Icon(Icons.report,
                                                  color: Colors.red[400]),
                                              title: Text(
                                                'รายงานปัญหา',
                                                style: TextStyle(
                                                    color: Colors.red[400]),
                                              ),
                                            ),
                                          ),
                                        ],
                                        offset: const Offset(0, 50),
                                        onSelected: (String value) {
                                          if (value == 'report') {
                                            null;
                                          } else if (value == 'profile') {
                                            null;
                                          }
                                        },
                                      )
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(0),
                                topRight: Radius.circular(0),
                              ),
                              child: CachedNetworkImage(
                                imageUrl: image.isNotEmpty ? image[0] : '',
                                fit: BoxFit.cover,
                                width: double.infinity,
                                placeholder: (context, url) => const Center(
                                  child: SizedBox(
                                    height: 40,
                                    width: 40,
                                    child: CircularProgressIndicator(
                                      color: Colors.black,
                                      strokeWidth: 3,
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.error),
                              ),
                            ),
                          ),
                          Container(
                            color: Colors.white,
                            padding: const EdgeInsets.all(8.0),
                            alignment: Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  post['Name'] ?? 'No Name',
                                  style: const TextStyle(fontSize: 15),
                                ),
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height / 160,
                                ),
                                Text(post['Detail'] ?? 'No Detail'),
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height / 160,
                                ),
                                Text(
                                  formattedDate,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height / 160,
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(3),
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(post['PostCategory'] ??
                                          'No PostCategory'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
