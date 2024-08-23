import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UnsuccessfulUtils {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> unsuccessfulExchange(String chatId, BuildContext context) async {
    try {
      final chatDoc = await _firestore.collection('Chats').doc(chatId).get();
      final data = chatDoc.data()!;
      final postIds = data['postIds'] as List<dynamic>;
      final postId1 = postIds[0];
      final postId2 = postIds[1];

      final postDoc1 = await _firestore.collection('posts').doc(postId1).get();
      final postData1 = postDoc1.data()!;
      final userId1 = postData1['UserId'];

      final postDoc2 = await _firestore.collection('posts').doc(postId2).get();
      final postData2 = postDoc2.data()!;
      final userId2 = postData2['UserId'];

      await _firestore
          .collection('Chats')
          .doc(chatId)
          .update({'status': 'unsuccessful'});
      await _updatePost(postId1);
      await _updatePost(postId2);
      await _sendNotification(chatId, userId1, userId2);

      print(postId1);
      print(postId2);
    } catch (e) {
      print(e);
    }
  }

  Future<void> _updatePost(String postId) async {
    final postDoc = await _firestore.collection('posts').doc(postId).get();
    final postData = postDoc.data()!;
    final matchedUserId = postData['matchedUserId'];

    await _firestore.collection('posts').doc(postId).update({
      'status': 'available',
      'likes': FieldValue.arrayRemove([matchedUserId]),
      'matchedUserId': FieldValue.delete(),
    });
  }

  Future<void> _sendNotification(
      String chatId, String userId1, String userId2) async {
    final notificationRef1 = _firestore.collection('Notifications').doc();
    final notificationRef2 = _firestore.collection('Notifications').doc();

    await notificationRef1.set({
      'userId': userId1,
      'title': 'แลกเปลี่ยนสิ่งของไม่สำเร็จ!',
      'message': 'การแลกเปลี่ยนสิ่งของ',
      'type': 'unsuccessful',
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
      'chatId': chatId,
      'currentUserId': userId2
    });

    await notificationRef2.set({
      'userId': userId2,
      'title': 'แลกเปลี่ยนสิ่งของไม่สำเร็จ!',
      'message': 'การแลกเปลี่ยนสิ่งของ',
      'type': 'unsuccessful',
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
      'chatId': chatId,
      'currentUserId': userId1
    });
  }
}
