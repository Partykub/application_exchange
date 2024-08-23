import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:exchange/screen/profile/post_detail.dart';
import 'package:flutter/material.dart';

class PostProfile extends StatefulWidget {
  final String userId;

  const PostProfile({Key? key, required this.userId}) : super(key: key);

  @override
  State<PostProfile> createState() => _PostProfileState();
}

class _PostProfileState extends State<PostProfile> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('UserId', isEqualTo: widget.userId)
          .where('status', isEqualTo: 'available')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container();
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Expanded(
            child: Container(
              color: Colors.grey[200],
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.camera_alt_outlined,
                      size: 40,
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height / 130,
                    ),
                    const Text(
                      "ยังไม่มีโพสต์",
                      style: TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final posts = snapshot.data!.docs;

        return Expanded(
          child: Padding(
            padding: EdgeInsets
                .zero, // กำหนด padding เป็น EdgeInsets.zero เพื่อลบช่องว่างรอบขอบ
            child: Container(
              color: Colors.grey[100],
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 0.7,
                  crossAxisSpacing: 0.7,
                  childAspectRatio: 0.7,
                ),
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  final images = List<String>.from(post['Images']);

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                PostDetailPage(postId: post.id),
                          ));
                    },
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            0), // ทำให้ Card เป็นสี่เหลี่ยม
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(0),
                                  topRight: Radius.circular(0),
                                ),
                                child: CachedNetworkImage(
                                  imageUrl: images.isNotEmpty ? images[0] : '',
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
                                )),
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
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(
                                          3), // กำหนดการเว้นระยะห่างด้านในของกรอบ
                                      margin: const EdgeInsets.symmetric(
                                          vertical:
                                              3), // กำหนดการเว้นระยะห่างด้านนอกของกรอบ
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.grey[300], // กำหนดสีของกรอบ
                                        borderRadius: BorderRadius.circular(
                                            4), // กำหนดรูปร่างของกรอบเป็นนูน
                                      ),
                                      child: Text(
                                        post['PostCategory'] ??
                                            'No PostCategory',
                                      ),
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
            ),
          ),
        );
      },
    );
  }
}
