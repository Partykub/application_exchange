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
              final String type = notification['type'];

              final String userId = type == 'like'
                  ? notification['likerId']
                  : type == 'offer'
                      ? notification['currentUserId']
                      : type == 'match'
                          ? notification['matchedUserId']
                          : type == 'successfulExchange'
                              ? notification['exchangeWith']
                              : type == 'unsuccessful'
                                  ? notification['currentUserId']
                                  : type == 'firstConfirmExchange'
                                      ? notification['userFirstConfirm']
                                      : type == 'successfulExchange'
                                          ? notification['exchangeWith']
                                          : '';

              if (userId.isEmpty) {
                return const ListTile(
                  title: Text('Error loading user information'),
                );
              }

              final String postName = notification['postName'] ?? '';
              final String chatId = notification['chatId'] ?? '';
              final bool isRead = notification['read'] ?? false;

              return FutureBuilder<Map<String, dynamic>>(
                future: getUserInfo(userId),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return Container();
                  }
                  if (!userSnapshot.hasData) {
                    return const ListTile(
                      title: Text('Error loading user information'),
                    );
                  }
                  final userInfo = userSnapshot.data!;
                  final String userName = userInfo['name'] ?? 'Unknown';
                  final String profileImageUrl =
                      userInfo['profileImageUrl'] ?? '';

                  final TextStyle textStyle = isRead
                      ? const TextStyle(fontWeight: FontWeight.normal)
                      : const TextStyle(fontWeight: FontWeight.w600);

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(0, 1, 0, 1),
                    child: Container(
                        color: Colors.white,
                        child: Stack(
                          children: [
                            isRead
                                ? Container()
                                : Positioned(
                                    right: 10,
                                    top: 35,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(10)),
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 10,
                                        minHeight: 10,
                                      ),
                                    ),
                                  ),
                            ListTile(
                              leading: CircleAvatar(
                                backgroundImage: profileImageUrl.isNotEmpty
                                    ? NetworkImage(profileImageUrl)
                                    : const AssetImage(
                                            'assets/default_avatar.png')
                                        as ImageProvider,
                              ),
                              title: Text(
                                type == 'match'
                                    ? 'แมทช์สำเร็จ!'
                                    : type == 'unsuccessful'
                                        ? 'การแลกเปลี่ยนสิ่งของไม่สำเร็จ!'
                                        : type == 'offer'
                                            ? 'มีการเสนอซื้อสิ่งของของคุณ'
                                            : type == 'firstConfirmExchange'
                                                ? '$userName ยืนยันการแลกเปลี่ยน'
                                                : type == 'successfulExchange'
                                                    ? 'แลกเปลี่ยนสำเร็จ'
                                                    : '$userName กดถูกใจโพสต์ของคุณ!',
                                style: textStyle,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    type == 'match'
                                        ? 'คุณมีการแมทช์ใหม่กับผู้ใช้ $userName'
                                        : type == 'unsuccessful'
                                            ? '${notification['message']} กับ $userName'
                                            : type == 'offer'
                                                ? 'เสนอซื้อสิ่งของของคุณในราคา ${notification['bidAmount']} บาท โดย $userName'
                                                : type == 'firstConfirmExchange'
                                                    ? '$userName ยืนยันการแลกเปลี่ยนสำเร็จกับคุณ ระบบจะยืนยืนอัตโนมัติให้คุณภายใน 24 ชั่วโมง หากคุณไม่ได้ยืนยันการแลกเปลี่ยน'
                                                    : type ==
                                                            'successfulExchange'
                                                        ? 'คุณทำการแลกเปลี่ยนสิ่งของกับ $userName สำเร็จ'
                                                        : '$userName กดถูกใจโพสต์ $postName ของคุณ',
                                    style: textStyle,
                                  ),
                                  Text(
                                    DateFormat('dd/MM/yyyy HH:mm').format(
                                      (notification['createdAt'] as Timestamp)
                                          .toDate(),
                                    ),
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                              onTap: () async {
                                await FirebaseFirestore.instance
                                    .collection('Notifications')
                                    .doc(notifications[index].id)
                                    .update({'read': true});

                                if (type == 'match') {
                                  // ignore: use_build_context_synchronously
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatScreen(
                                        chatId: chatId,
                                        name: userName,
                                      ),
                                    ),
                                  );
                                } else if (type == 'offer') {
                                  // ignore: use_build_context_synchronously
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatScreen(
                                        chatId: chatId,
                                        name: userName,
                                      ),
                                    ),
                                  );
                                } else if (type == 'unsuccessful' ||
                                    type == 'like') {
                                  // ignore: use_build_context_synchronously
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => VisitProfile(
                                        informationUserUID: userId,
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        )),
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
