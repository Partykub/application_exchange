import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:exchange/screen/exchange/chat/chat_screen.dart';
import 'package:exchange/screen/exchange/visit_profile.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class NotificationPage extends StatelessWidget {
  final currentUser = FirebaseAuth.instance.currentUser;

  NotificationPage({super.key});

  Future<Map<String, dynamic>> getUserInfo(String userId) async {
    final userDoc = await FirebaseFirestore.instance
        .collection('informationUser')
        .doc(userId)
        .get();
    if (userDoc.exists) {
      return {
        'name': userDoc.data()?['Name'] ?? 'Unknown',
        'profileImageUrl': userDoc.data()?['profileImageUrl'] ?? ''
      };
    }
    return {'name': 'Unknown', 'profileImageUrl': ''};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('การแจ้งเตือน'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Notifications')
            .where('userId', isEqualTo: currentUser!.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.black,
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('ไม่มีการแจ้งเตือน'));
          }
          final notifications = snapshot.data!.docs;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification =
                  notifications[index].data() as Map<String, dynamic>;
              final String targetUserId = notification['likerId'] ??
                  notification['matchedUserId'] ??
                  '';
              final String postName = notification['postName'] ?? '';
              final String chatId = notification['chatId'] ?? '';
              final bool isMatch = notification['type'] == 'match';

              return FutureBuilder<Map<String, dynamic>>(
                future: getUserInfo(targetUserId),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const ListTile(
                      title: Text('Loading...'),
                    );
                  }
                  final userInfo = userSnapshot.data!;
                  final String userName = userInfo['name'] ?? 'Unknown';
                  final String profileImageUrl =
                      userInfo['profileImageUrl'] ?? '';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: profileImageUrl.isNotEmpty
                          ? NetworkImage(profileImageUrl)
                          : AssetImage('assets/default_avatar.png')
                              as ImageProvider,
                    ),
                    title: Text(
                      isMatch
                          ? 'แมทช์สำเร็จ!'
                          : '$userName กดถูกใจโพสต์ของคุณ!',
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isMatch
                              ? 'คุณมีการแมทช์ใหม่กับผู้ใช้ $userName'
                              : '$userName ได้กดถูกใจโพสต์ $postName ของคุณ',
                        ),
                        Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(
                            (notification['createdAt'] as Timestamp).toDate(),
                          ),
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                    onTap: () async {
                      await FirebaseFirestore.instance
                          .collection('Notifications')
                          .doc(notifications[index].id)
                          .update({'read': true});

                      if (isMatch) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              chatId: chatId,
                              name: userName,
                            ),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VisitProfile(
                              informationUserUID: targetUserId,
                            ),
                          ),
                        );
                      }
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
