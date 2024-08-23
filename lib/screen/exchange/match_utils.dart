import 'package:cloud_firestore/cloud_firestore.dart';

class MatchUtils {
  static Future<void> checkMatch(DocumentSnapshot postSnapshot,
      String currentUserId, Transaction transaction) async {
    final postUserId = postSnapshot['UserId'];
    final currentUserPosts = await FirebaseFirestore.instance
        .collection('posts')
        .where('UserId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'available')
        .get();

    bool isMatched = false;

    for (var currentUserPost in currentUserPosts.docs) {
      if (isMatched) {
        break; // หากมีการแมทช์แล้ว หยุดการวนลูป
      }

      List<String> currentUserLikes;
      if (currentUserPost.data().containsKey('likes')) {
        currentUserLikes = List<String>.from(currentUserPost['likes']);
      } else {
        currentUserLikes = [];
      }

      if (currentUserLikes.contains(postUserId)) {
        isMatched = true;
        // สร้างห้องแชทและการแจ้งเตือน
        final chatRef = FirebaseFirestore.instance.collection('Chats').doc();
        final chatId = chatRef.id;

        transaction.set(chatRef, {
          'userIds': [currentUserId, postUserId],
          'postIds': [postSnapshot.id, currentUserPost.id],
          'createdAt': FieldValue.serverTimestamp(),
          'isExchanged': false,
          'status': 'match',
          'matchType': 'match'
        });

        // อัปเดตสถานะโพสต์เป็น matched
        transaction.update(postSnapshot.reference,
            {'status': 'matched', 'matchedUserId': currentUserId});
        transaction.update(currentUserPost.reference,
            {'status': 'matched', 'matchedUserId': postUserId});

        final notificationRef =
            FirebaseFirestore.instance.collection('Notifications').doc();
        transaction.set(notificationRef, {
          'userId': postUserId,
          'matchedUserId': currentUserId,
          'title': 'แมทช์สำเร็จ!',
          'message': 'คุณมีการแมทช์ใหม่กับผู้ใช้ $currentUserId',
          'type': 'match',
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
          'chatId': chatId,
        });

        final currentUserNotificationRef =
            FirebaseFirestore.instance.collection('Notifications').doc();
        transaction.set(currentUserNotificationRef, {
          'userId': currentUserId,
          'matchedUserId': postUserId,
          'title': 'แมทช์สำเร็จ!',
          'message': 'คุณมีการแมทช์ใหม่กับผู้ใช้ $postUserId',
          'type': 'match',
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
          'chatId': chatId,
        });
      }
    }

    if (!isMatched) {
      final likeNotificationRef =
          FirebaseFirestore.instance.collection('Notifications').doc();
      transaction.set(likeNotificationRef, {
        'userId': postUserId,
        'likerId': currentUserId,
        'postName': postSnapshot['Name'] ?? '',
        'title': 'มีการกดถูกใจโพสต์ของคุณ!',
        'message': 'ได้กดถูกใจโพสต์ของคุณ',
        'type': 'like',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
