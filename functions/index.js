const functions = require("firebase-functions");
const admin = require("firebase-admin");
const twilio = require("twilio");


admin.initializeApp();

// const accountSid = functions.config().twilio.account_sid;
// const authToken = functions.config().twilio.auth_token;

// const client = new twilio.Twilio(accountSid, authToken);

// const sendSMS = async (to, message) => {
//   // Ensure the phone number is in E.164 format
//   const formattedPhoneNumber = formatPhoneNumber(to);

//   try {
//     await client.messages.create({
//       body: message,
//       from: "+12512505139",
//       to: formattedPhoneNumber,
//     });
//     console.log(`ส่ง SMS สำเร็จถึง ${formattedPhoneNumber}`);
//   } catch (error) {
//     console.error("เกิดข้อผิดพลาดในการส่ง SMS:", error);
//   }
// };

// Function to format phone numbers to E.164 format
// const formatPhoneNumber = (phoneNumber) => {
//   // Example for Thailand, update according to your needs
//   if (phoneNumber.startsWith("0")) {
//     return "+66" + phoneNumber.slice(1);
//   }
//   return phoneNumber; // Assumes phone number is already in E.164 format if it doesn't start with 0
// };

exports.sendNewMessageNotification = functions.firestore
    .document("Chats/{chatId}/messages/{messageId}")
    .onCreate(async (snap, context) => {
      const message = snap.data();
      const chatId = context.params.chatId;

      console.log(`สร้างข้อความใหม่: ${JSON.stringify(message)}`);

      const chatDoc = await admin.firestore().collection("Chats").doc(chatId).get();
      const chatData = chatDoc.data();
      const senderId = message.senderId;

      console.log(`ข้อมูลแชท: ${JSON.stringify(chatData)}`);

      const recipientId = chatData.userIds.find((uid) => uid !== senderId);

      if (recipientId) {
        const recipientDoc = await admin.firestore().collection("informationUser").doc(recipientId).get();
        const recipientData = recipientDoc.data();
        const recipientPhone = recipientData.PhoneNumber;

        console.log(`ข้อมูลผู้รับ: ${JSON.stringify(recipientData)}`);

        const senderDoc = await admin.firestore().collection("informationUser").doc(senderId).get();
        const senderData = senderDoc.data();
        const senderName = senderData.Name;

        console.log(`ข้อมูลผู้ส่ง: ${JSON.stringify(senderData)}`);

        const text = `คุณมีข้อความใหม่จาก ${senderName}: ${message.text}`;

        await sendSMS(recipientPhone, text);
      } else {
        console.log("ไม่พบผู้รับสำหรับข้อความนี้");
      }
    });

exports.notifications = functions.firestore
    .document("Notifications/{notificationsId}")
    .onCreate(async (snap, context) => {
      const notificationsData = snap.data();

      console.log(`เริ่มสร้างการแจ้งเตือน: ${JSON.stringify(notificationsData)}`);

      const typeData = notificationsData.type;

      const recipientId = notificationsData.userId;
      const recipientDoc = await admin.firestore().collection("informationUser").doc(recipientId).get();
      const recipientData = recipientDoc.data();
      const recipientPhone = recipientData.PhoneNumber; // เปลี่ยนเป็นเบอร์โทรศัพท์ของผู้รับ

      console.log(`เบอร์โทรศัพท์ของผู้รับ: ${recipientPhone}`);

      let text = "";

      switch (typeData) {
        case "like": {
          const likerId = notificationsData.likerId;
          const likerDoc = await admin.firestore().collection("informationUser").doc(likerId).get();
          const likerData = likerDoc.data();
          const likerName = likerData.Name;

          text = `${likerName} ได้กดถูกใจโพสต์ของคุณ`;
          break;
        }
        case "offer": {
          const offerorId = notificationsData.currentUserId;
          const offerorDoc = await admin.firestore().collection("informationUser").doc(offerorId).get();
          const offerorData = offerorDoc.data();
          const offerorName = offerorData.Name;

          text = `${offerorName} เสนอซื้อสิ่งของของคุณในราคา ${notificationsData.bidAmount}`;
          break;
        }
        case "match": {
          const matchedUserId = notificationsData.matchedUserId;
          const matchedUserDoc = await admin.firestore().collection("informationUser").doc(matchedUserId).get();
          const matchedUserData = matchedUserDoc.data();
          const matchedUserName = matchedUserData.Name;

          text = `คุณมีการแมทช์ใหม่กับผู้ใช้ ${matchedUserName}`;
          break;
        }
        case "successfulExchange": {
          const exchangeWithId = notificationsData.exchangeWith;
          const exchangeWithDoc = await admin.firestore().collection("informationUser").doc(exchangeWithId).get();
          const exchangeWithData = exchangeWithDoc.data();
          const exchangeWithName = exchangeWithData.Name;

          text = `คุณทำการแลกเปลี่ยนสิ่งของกับ ${exchangeWithName} สำเร็จ`;
          break;
        }
        case "unsuccessful": {
          const currentUserId = notificationsData.currentUserId;
          const currentUserDoc = await admin.firestore().collection("informationUser").doc(currentUserId).get();
          const currentUserData = currentUserDoc.data();
          const currentUserName = currentUserData.Name;

          text = `การแลกเปลี่ยนสิ่งของกับ ${currentUserName} ไม่สำเร็จ`;
          break;
        }
        case "firstConfirmExchange": {
          const userFirstConfirmId = notificationsData.userFirstConfirm;
          const userFirstConfirmDoc = await admin.firestore().collection("informationUser").doc(userFirstConfirmId).get();
          const userFirstConfirmData = userFirstConfirmDoc.data();
          const userFirstConfirmName = userFirstConfirmData.Name;

          text = `${userFirstConfirmName} ยืนยันการแลกเปลี่ยนสำเร็จกับคุณแล้ว`;
          break;
        }
        default:
          console.log(`ไม่ได้รองรับประเภทการแจ้งเตือน: ${typeData}`);
          return;
      }

      await sendSMS(recipientPhone, text);
    });

exports.delayedUpdate = functions.firestore
    .document("Chats/{chatId}")
    .onUpdate(async (change, context) => {
      const newValue = change.after.data();
      const previousValue = change.before.data();

      const previousIsExchanged = previousValue.isExchanged;
      const newIsExchanged = newValue.isExchanged;

      if (typeof previousIsExchanged === "boolean" && typeof newIsExchanged !== "boolean" && newIsExchanged !== null) {
        console.log(`เริ่ม setTimeout สำหรับ ${context.params.chatId}`);

        setTimeout(async () => {
          console.log(`setTimeout ทำงานเสร็จแล้ว สำหรับเอกสาร ${context.params.chatId}`);
          const chatDocRef = admin.firestore().collection("Chats").doc(context.params.chatId);
          const chatDoc = await chatDocRef.get();
          const chatData = chatDoc.data();
          const exchangeCompleted = chatData.exchangeCompleted;

          console.log(`สถานะแลกเปลี่ยนสำเร็จ: ${exchangeCompleted}`);

          if (!exchangeCompleted) {
            console.log(`เริ่ม update data`);
            const batch = admin.firestore().batch();
            const isExchanged = newValue.isExchanged;
            const userIds = newValue.userIds;
            const postIds = newValue.postIds;
            const matchType = newValue.matchType;

            const currentUserId = Object.keys(isExchanged).find((id) => isExchanged[id] === true);
            const oppositeUserId = userIds.find((id) => id !== currentUserId);

            // Update chat document
            batch.update(change.after.ref, {
              "isExchanged": {
                ...isExchanged,
                [oppositeUserId]: true,
              },
              "exchangeCompleted": true,
              "status": "successfully",
            });

            // Update post documents
            postIds.forEach((postId) => {
              const postRef = admin.firestore().collection("posts").doc(postId);
              batch.update(postRef, {"status": "successfully"});
            });

            // Fetch user documents and update them
            const userDocs = await Promise.all(userIds.map((userId) => admin.firestore().collection("informationUser").doc(userId).get()));

            userDocs.forEach((userDoc, index) => {
              if (userDoc.exists) {
                const currentExchangeSuccess = userDoc.data().exchangeSuccess || 0;
                batch.update(userDoc.ref, {
                  exchangeSuccess: currentExchangeSuccess + 1,
                  successfulExchanges: admin.firestore.FieldValue.arrayUnion({chatId: context.params.chatId, postIds}),
                });
              } else {
                console.log(`ไม่พบเอกสารสำหรับ userId ${userIds[index]}`);
              }
            });

            try {
              await batch.commit();
              console.log(`เอกสาร ${context.params.chatId} อัปเดตสำเร็จหลังจาก setTimeout`);

              // Create notifications and reviews
              const [user1Doc, user2Doc] = userDocs;
              const user1Name = user1Doc.exists ? user1Doc.data().Name : "User 1";
              const user2Name = user2Doc.exists ? user2Doc.data().Name : "User 2";

              const notifications = [
                {
                  userId: userIds[0],
                  title: "แลกเปลี่ยนสำเร็จ",
                  message: `คุณทำการแลกเปลี่ยนสิ่งของกับ ${user2Name} สำเร็จ`,
                  read: false,
                  type: "successfulExchange",
                  createdAt: admin.firestore.FieldValue.serverTimestamp(),
                  chatId: context.params.chatId,
                  exchangeWith: userIds[1],
                },
                {
                  userId: userIds[1],
                  title: "แลกเปลี่ยนสำเร็จ",
                  message: `คุณทำการแลกเปลี่ยนสิ่งของกับ ${user1Name} สำเร็จ`,
                  read: false,
                  type: "successfulExchange",
                  createdAt: admin.firestore.FieldValue.serverTimestamp(),
                  chatId: context.params.chatId,
                  exchangeWith: userIds[0],
                },
              ];

              await Promise.all(notifications.map((notification) => admin.firestore().collection("Notifications").add(notification)));
              console.log("Notifications added successfully.");

              const reviews = [];

              if (matchType === "offer") {
                reviews.push({
                  rating: 5,
                  otherPostId: postIds[0],
                  recipientReview: currentUserId,
                  reviewer: oppositeUserId,
                  createdAt: admin.firestore.FieldValue.serverTimestamp(),
                });
              } else {
                const [post1Doc, post2Doc] = await Promise.all([
                  admin.firestore().collection("posts").doc(postIds[0]).get(),
                  admin.firestore().collection("posts").doc(postIds[1]).get(),
                ]);

                const post1UserId = post1Doc.data().UserId;
                const post2UserId = post2Doc.data().UserId;

                const reviewData = {
                  rating: 5,
                  recipientReview: currentUserId,
                  reviewer: oppositeUserId,
                  timestamp: admin.firestore.FieldValue.serverTimestamp(),
                };

                if (currentUserId === post1UserId) {
                  reviewData.otherPostId = postIds[0];
                } else if (currentUserId === post2UserId) {
                  reviewData.otherPostId = postIds[1];
                } else {
                  console.log(`ไม่พบโพสต์ที่ตรงกับผู้ใช้ปัจจุบัน ${currentUserId}`);
                }

                reviews.push(reviewData);
              }

              await Promise.all(reviews.map((review) => admin.firestore().collection("reviews").add(review)));
              console.log("Reviews added successfully.");
            } catch (error) {
              console.log(`เกิดข้อผิดพลาดในการอัปเดตการแลกเปลี่ยน: ${error}`);
            }
          } else {
            console.log(`The exchange was completed successfully or Filed "exchangeCompleted" is True`);
          }
        }, 2 * 60 * 1000); // 2 minutes delay
      } else {
        console.log(`No change in fields isExchanged or exchangeCompleted in document ${context.params.chatId}!!.`);
      }
    });

exports.deleteUser = functions.https.onCall((data, context) => {
  const uid = data.uid;

  // ลบผู้ใช้จาก Firebase Authentication
  return admin.auth().deleteUser(uid)
      .then(() => {
        return {success: true};
      })
      .catch((error) => {
        return {success: false, error: error.message};
      });
});
