import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';

class AdminHistoryPost extends StatefulWidget {
  final String userId;
  const AdminHistoryPost({super.key, required this.userId});

  @override
  State<AdminHistoryPost> createState() => _AdminHistoryPostState();
}

class _AdminHistoryPostState extends State<AdminHistoryPost> {
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .where('recipientReview', isEqualTo: widget.userId)
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
                    Icons.info_outline,
                    size: 40,
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height / 250,
                  ),
                  const Text(
                    "ยังไม่มีการแลกเปลี่ยน",
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
          ));
        }

        final reviews = snapshot.data!.docs;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.zero,
            child: ListView.builder(
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                final review = reviews[index];
                final reviewData = review.data() as Map<String, dynamic>;

                final otherPostId = reviewData.containsKey('otherPostId')
                    ? reviewData['otherPostId']
                    : null;
                final reviewer = reviewData.containsKey('reviewer')
                    ? reviewData['reviewer']
                    : null;

                // แปลง timestamp จาก String หรือ Timestamp เป็น DateTime
                DateTime timestamp;
                if (reviewData['timestamp'] is Timestamp) {
                  timestamp = (reviewData['timestamp'] as Timestamp).toDate();
                } else if (reviewData['timestamp'] is String) {
                  timestamp = DateFormat("MMMM d, yyyy 'at' h:mm:ss a zzz")
                      .parse(reviewData['timestamp']);
                } else {
                  timestamp = DateTime.now();
                }

                final imageUrl = reviewData.containsKey('imageUrl')
                    ? reviewData['imageUrl']
                    : null;
                final text =
                    reviewData.containsKey('text') ? reviewData['text'] : null;
                final rating =
                    reviewData.containsKey('rating') ? reviewData['rating'] : 0;

                return Padding(
                  padding: const EdgeInsets.fromLTRB(0, 3, 5, 0),
                  child: Container(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(15, 8, 8, 15),
                      child: StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('informationUser')
                            .doc(reviewer)
                            .snapshots(),
                        builder: (context, snapshotReviewer) {
                          if (snapshotReviewer.connectionState ==
                              ConnectionState.waiting) {
                            return Container();
                          }
                          if (!snapshotReviewer.hasData) {
                            return Container(
                              color: Colors.grey[200],
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.info_outline,
                                      size: 40,
                                    ),
                                    SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height /
                                              250,
                                    ),
                                    const Text(
                                      "หาชื่อผู้รีวิวไม่เจอ",
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          final reviewerData = snapshotReviewer.data!;
                          final reviewerName = reviewerData['Name'];
                          final reviewerImage = reviewerData['profileImageUrl'];

                          return StreamBuilder(
                            stream: FirebaseFirestore.instance
                                .collection('posts')
                                .doc(otherPostId)
                                .snapshots(),
                            builder: (context, snapshotPostImage) {
                              if (snapshotPostImage.connectionState ==
                                  ConnectionState.waiting) {
                                return Container();
                              }
                              if (!snapshotPostImage.hasData) {
                                return Container(
                                  color: Colors.grey[200],
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.info_outline,
                                          size: 40,
                                        ),
                                        SizedBox(
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height /
                                              250,
                                        ),
                                        const Text(
                                          "หารูปที่ถูกรีวิวไม่เจอ",
                                          style: TextStyle(fontSize: 18),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                              final postImageData = snapshotPostImage.data;
                              final postImageUrl =
                                  postImageData!['Images'] as List<dynamic>?;
                              final postName = postImageData['Name'];

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // ซ้าย
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 18,
                                            backgroundImage:
                                                CachedNetworkImageProvider(
                                                    reviewerImage),
                                            backgroundColor: Colors.white,
                                          ),
                                          SizedBox(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                50,
                                          ),
                                          Text(
                                            reviewerName,
                                            style:
                                                const TextStyle(fontSize: 15),
                                          ),
                                        ],
                                      ),
                                      SizedBox(
                                        height:
                                            MediaQuery.of(context).size.height /
                                                200,
                                      ),
                                      RatingBar.builder(
                                        initialRating: rating.toDouble(),
                                        minRating: 1,
                                        direction: Axis.horizontal,
                                        allowHalfRating: true,
                                        itemCount: 5,
                                        itemSize: 17,
                                        itemPadding: const EdgeInsets.symmetric(
                                            horizontal: 0.0),
                                        itemBuilder: (context, _) => const Icon(
                                          Icons.star,
                                          color: Colors.amber,
                                        ),
                                        onRatingUpdate: (rating) {
                                          print('New Rating: $rating');
                                        },
                                      ),
                                      SizedBox(
                                        child: Column(
                                          children: [
                                            SizedBox(
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .height /
                                                  180,
                                            ),
                                            text != null
                                                ? Text(text)
                                                : SizedBox(
                                                    height:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .height /
                                                            180,
                                                  ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        child: Column(
                                          children: [
                                            SizedBox(
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .height /
                                                  180,
                                            ),
                                            imageUrl != null
                                                ? CachedNetworkImage(
                                                    fit: BoxFit.cover,
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width /
                                                            6,
                                                    height:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width /
                                                            6,
                                                    imageUrl: imageUrl)
                                                : const SizedBox(),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        DateFormat('dd/MM/yyyy HH:mm')
                                            .format(timestamp),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),

                                  // ขวา
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.1),
                                          spreadRadius: 2,
                                          blurRadius: 5,
                                          offset: const Offset(0, 0),
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        CachedNetworkImage(
                                            fit: BoxFit.cover,
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                4.5,
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                4.5,
                                            imageUrl: postImageUrl![0]),
                                        const SizedBox(height: 8.0),
                                        Text(
                                          postName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
