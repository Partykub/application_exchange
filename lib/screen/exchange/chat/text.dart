import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExchangeUtils {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final currentUser = FirebaseAuth.instance.currentUser;

  Future<void> confirmExchange(String chatId, BuildContext context) async {
    final chatDoc = await _firestore.collection('Chats').doc(chatId).get();
    final data = chatDoc.data();
    final postIds = data?['postIds'] as List<dynamic>?;
    final userIds = data?['userIds'] as List<dynamic>?;

    if (postIds != null && userIds != null && userIds.length == 2) {
      final oppositeUserId = userIds.firstWhere((id) => id != currentUser!.uid);

      dynamic isExchangedDynamic = data?['isExchanged'];
      Map<String, dynamic>? isExchanged;

      if (isExchangedDynamic is bool) {
        isExchanged = null;
      } else if (isExchangedDynamic is Map<String, dynamic>) {
        isExchanged = isExchangedDynamic;
      }

      // คนที่กดยืนยันการแลกเปลี่ยนคนแรก
      if (isExchanged == null) {
        await _firestore.collection('Chats').doc(chatId).update({
          'isExchanged': {
            currentUser!.uid: true,
            oppositeUserId: false,
          },
          'firstConfirmedAt': FieldValue.serverTimestamp(),
        });

        Future.delayed(const Duration(minutes: 2), () async {
          await _firestore.collection('Chats').doc(chatId).update({
            'isExchanged.${currentUser!.uid}': true,
            'exchangeCompleted': true,
          });
          await _checkAndResetExchange(chatId, postIds, userIds);
        });
      } else if (isExchanged[oppositeUserId] == true) {
        await _firestore.collection('Chats').doc(chatId).update({
          'isExchanged.${currentUser!.uid}': true,
          'exchangeCompleted': true,
        });
        await updateStatus(postIds, userIds);

        await _saveExchangeHistory(postIds, userIds, chatId);
      } else {
        print('แลกเปลี่ยนเสร็ตสิ้นแล้ว');
      }
    }
  }

  Future<void> _checkAndResetExchange(
      String chatId, List<dynamic> postIds, List<dynamic> userIds) async {
    final chatDoc = await _firestore.collection('Chats').doc(chatId).get();
    final isExchanged = chatDoc.data()?['isExchanged'] as Map<String, dynamic>?;
    final firstConfirmedAt =
        (chatDoc.data()?['firstConfirmedAt'] as Timestamp).toDate();

    if (isExchanged != null &&
        isExchanged.values.any((value) => value == true) &&
        isExchanged.values.any((value) => value == false)) {
      final now = DateTime.now();
      if (now.difference(firstConfirmedAt).inMinutes >= 2) {
        await updateStatus(postIds, userIds);
        await _saveExchangeHistory(postIds, userIds, chatId);
      }
    }
  }

  Future<void> updateStatus(
      List<dynamic> postIds, List<dynamic> userIds) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    final batch = _firestore.batch();

    for (var postId in postIds) {
      final postRef = _firestore.collection('posts').doc(postId);
      batch.update(postRef, {
        'status': 'successfully',
      });
    }

    for (var userId in userIds) {
      DocumentReference userDocRef =
          firestore.collection('informationUser').doc(userId);
      await firestore.runTransaction((transaction) async {
        DocumentSnapshot userDocSnapshot = await transaction.get(userDocRef);

        if (!userDocSnapshot.exists ||
            userDocSnapshot.data() is! Map<String, dynamic> ||
            !(userDocSnapshot.data() as Map<String, dynamic>)
                .containsKey('exchangeSuccess')) {
          // ใช้ `merge` เพื่อไม่ให้ field อื่นๆ หายไป
          transaction.set(
              userDocRef, {'exchangeSuccess': 1}, SetOptions(merge: true));
        } else {
          int currentNumberOfPosts = (userDocSnapshot.data()
              as Map<String, dynamic>)['exchangeSuccess'] as int;
          transaction.update(
              userDocRef, {'exchangeSuccess': currentNumberOfPosts + 1});
        }
      });
    }
    await batch.commit();
  }

  Future<void> _saveExchangeHistory(
      List<dynamic> postIds, List<dynamic> userIds, String chatId) async {
    final batch = _firestore.batch();
    for (var userId in userIds) {
      final userRef = _firestore.collection('informationUser').doc(userId);
      List<dynamic> exchangeEntry = [
        {
          'chatId': chatId,
          'postIds': postIds,
        }
      ];
      batch.update(userRef, {
        'successfulExchanges': FieldValue.arrayUnion(exchangeEntry),
      });
    }
    await batch.commit();
  }
}
