import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:exchange/screen/exchange/visit_detail_post.dart';
import 'package:exchange/screen/exchange/visit_profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PostLike extends StatefulWidget {
  const PostLike({super.key});

  @override
  State<PostLike> createState() => _PostLikeState();
}

class _PostLikeState extends State<PostLike> {
  final auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Text('โพสต์ของผู้ที่กดถูกใจคุณ'),
        ),
        body: Container(
          color: Colors.grey[200],
          child: FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection('posts')
                .where('UserId', isEqualTo: auth.currentUser!.uid)
                .get(),
            builder:
                (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
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
                          "ยังไม่มีโพสต์ที่ถูกไลค์",
                          style: TextStyle(fontSize: 20),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final userPosts = snapshot.data!.docs;
              final likedPosts = userPosts.where((post) {
                final postData = post.data() as Map<String, dynamic>;
                final likes = List<String>.from(postData['likes'] ?? []);
                return likes.isNotEmpty && postData['status'] == 'available';
              }).toList();

              if (likedPosts.isEmpty) {
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
                          "ยังไม่มีโพสต์ที่ถูกไลค์",
                          style: TextStyle(fontSize: 20),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final likedUserIds = likedPosts
                  .expand((post) => List<String>.from(
                      (post.data() as Map<String, dynamic>)['likes'] ?? []))
                  .toSet()
                  .toList();

              return FutureBuilder<List<DocumentSnapshot>>(
                future: _getLikedUserPosts(likedUserIds),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text('ไม่พบโพสต์ของผู้ใช้ที่ไลค์โพสต์ของคุณ'),
                    );
                  }

                  final likedUserPosts = snapshot.data!;

                  return GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 0.5,
                      crossAxisSpacing: 0.5,
                      childAspectRatio: 0.6, // ปรับค่านี้ให้เหมาะสม
                    ),
                    itemCount: likedUserPosts.length,
                    itemBuilder: (context, index) {
                      final post = likedUserPosts[index];
                      final postData = post.data() as Map<String, dynamic>;
                      final images = List<String>.from(postData['Images']);
                      final userId = postData['UserId'];
                      final createdAt = postData.containsKey('createdAt')
                          ? (postData['createdAt'] as Timestamp).toDate()
                          : DateTime.now();

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
                                  return Container(
                                    color: Colors.white,
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          10, 0, 0, 0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              GestureDetector(
                                                onTap: () {
                                                  Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            VisitProfile(
                                                                informationUserUID:
                                                                    post[
                                                                        'UserId']),
                                                      ));
                                                },
                                                child: CircleAvatar(
                                                  radius: 16,
                                                  backgroundImage:
                                                      CachedNetworkImageProvider(
                                                    snapshot2.data![
                                                        'profileImageUrl'],
                                                  ),
                                                  backgroundColor: Colors.white,
                                                ),
                                              ),
                                              SizedBox(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width /
                                                    50,
                                              ),
                                              GestureDetector(
                                                onTap: () => Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          VisitProfile(
                                                              informationUserUID:
                                                                  post[
                                                                      'UserId']),
                                                    )),
                                                child: Text(
                                                  snapshot2.data!['Name'],
                                                  style: const TextStyle(
                                                      fontSize: 15),
                                                ),
                                              )
                                            ],
                                          ),
                                          PopupMenuButton<String>(
                                            color: Colors.white,
                                            itemBuilder:
                                                (BuildContext context) =>
                                                    <PopupMenuEntry<String>>[
                                              const PopupMenuItem<String>(
                                                value: 'profile',
                                                child: ListTile(
                                                  leading: Icon(
                                                      Icons.person_pin_sharp),
                                                  title:
                                                      Text('เยี่ยมชมโปรไฟล์'),
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
                                                Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          VisitProfile(
                                                              informationUserUID:
                                                                  post[
                                                                      'UserId']),
                                                    ));
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
                                    imageUrl:
                                        images.isNotEmpty ? images[0] : '',
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: MediaQuery.of(context).size.height /
                                        2.5, // ปรับความสูงของรูปภาพ
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
                                      postData['Name'] ?? 'No Name',
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                    SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height /
                                              160,
                                    ),
                                    Text(postData['Detail'] ?? 'No Detail'),
                                    SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height /
                                              160,
                                    ),
                                    Text(
                                      DateFormat('dd/MM/yyyy HH:mm')
                                          .format(createdAt),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height /
                                              160,
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
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                              postData['PostCategory'] ??
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
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Future<List<DocumentSnapshot>> _getLikedUserPosts(
      List<String> userIds) async {
    final likedUserPostsQuery = await FirebaseFirestore.instance
        .collection('posts')
        .where('UserId', whereIn: userIds)
        .where('status', isEqualTo: 'available')
        .get();
    return likedUserPostsQuery.docs;
  }
}
