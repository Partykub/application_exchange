import 'dart:async'; // เพิ่มการนำเข้า Completer
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

      if (isExchanged == null) {
        await _firestore.collection('Chats').doc(chatId).update({
          'isExchanged': {
            currentUser!.uid: true,
            oppositeUserId: false,
          },
          'exchangeCompleted': false,
          'firstConfirmedAt': FieldValue.serverTimestamp(),
        });

        final currentUserRef = await _firestore
            .collection("informationUser")
            .doc(currentUser!.uid)
            .get();
        final nameCurrentData = currentUserRef.data();
        final nameCurrentUser = nameCurrentData!['Name'];

        final notificationData = {
          'userId': oppositeUserId,
          'userFirstConfirm': currentUser!.uid,
          'title': '$nameCurrentUser ยืนยันการแลกเปลี่ยน',
          'message':
              '$nameCurrentUser ยืนยันการแลกเปลี่ยนสำเร็จกับคุณ ระบบจะยืนยืนอัตโนมัติให้คุณภายใน 24 ชั่วโมง หากคุณไม่ได้ยืนยันการแลกเปลี่ยน',
          'read': false,
          'type': 'firstConfirmExchange',
          'createdAt': FieldValue.serverTimestamp(),
          'chatId': chatId,
        };
        await _firestore.collection('Notifications').add(notificationData);
      } else if (isExchanged[oppositeUserId] == true) {
        await _firestore.collection('Chats').doc(chatId).update({
          'isExchanged.${currentUser!.uid}': true,
          'exchangeCompleted': true,
          'status': 'successfully'
        });
        await updateStatus(postIds, userIds);
        await _saveExchangeHistory(postIds, userIds, chatId);
        await notification(chatId, postIds, userIds);
      } else {
        print('แลกเปลี่ยนเสร็จสิ้นแล้ว');
      }
    }
  }

  Future<void> notification(
      String chatId, List<dynamic> postIds, List<dynamic> userIds) async {
    final user1Ref =
        await _firestore.collection("informationUser").doc(userIds[0]).get();
    final user1Data = user1Ref.data();

    final user2Ref =
        await _firestore.collection("informationUser").doc(userIds[1]).get();
    final user2Data = user2Ref.data();

    final nameUser1 = user1Data!['Name'];
    final nameUser2 = user2Data!['Name'];

    final notificationData1 = {
      'userId': '${userIds[0]}',
      'title': 'แลกเปลี่ยนสำเร็จ',
      'message': 'คุณทำการแลกเปลี่ยนสิ่งของกับ $nameUser2 สำเร็จ',
      'read': false,
      'type': 'successfulExchange',
      'createdAt': FieldValue.serverTimestamp(),
      'chatId': chatId,
      'exchangeWith': '${userIds[1]}'
    };

    final notificationData2 = {
      'userId': '${userIds[1]}',
      'title': 'แลกเปลี่ยนสำเร็จ',
      'message': 'คุณทำการแลกเปลี่ยนสิ่งของกับ $nameUser1 สำเร็จ',
      'read': false,
      'type': 'successfulExchange',
      'createdAt': FieldValue.serverTimestamp(),
      'chatId': chatId,
      'exchangeWith': '${userIds[0]}'
    };

    await _firestore.collection('Notifications').add(notificationData1);
    await _firestore.collection('Notifications').add(notificationData2);
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
