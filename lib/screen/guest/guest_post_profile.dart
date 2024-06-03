import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:exchange/screen/guest/guest_detail_exchange.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class GuestPostProfile extends StatefulWidget {
  final String userId;
  const GuestPostProfile({super.key, required this.userId});

  @override
  State<GuestPostProfile> createState() => _GuestPostProfileState();
}

class _GuestPostProfileState extends State<GuestPostProfile> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('UserId', isEqualTo: widget.userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
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
            ),
          );
        }

        final posts = snapshot.data!.docs;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.zero,
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
                  final postData = post.data() as Map<String, dynamic>;
                  final images = List<String>.from(postData['Images']);
                  final createdAt = postData.containsKey('createdAt')
                      ? (postData['createdAt'] as Timestamp).toDate()
                      : DateTime.now();

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GuestDetailExchange(
                              postId: post.id,
                            ),
                          ));
                    },
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(0),
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
                                      MediaQuery.of(context).size.height / 160,
                                ),
                                Text(postData['Detail'] ?? 'No Detail'),
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height / 160,
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
                                      child: Text(
                                        postData['PostCategory'] ??
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
