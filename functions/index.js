/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const logger = require("firebase-functions/logger");
const admin = require('firebase-admin');

admin.initializeApp();

/**
 * Trigger: When a new Episode is created.
 * Action: Send a notification to 'all' topic AND save to global notifications.
 */
exports.onEpisodeCreate = onDocumentCreated("episodes/{episodeId}", async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
        console.log("No data associated with the event");
        return;
    }
    const data = snapshot.data();

    const title = `New Episode: ${data.animeTitle || 'Anime'} ${data.number}`;
    const body = `Episode ${data.number} is now available! Watch it now.`;
    const animeId = data.animeId;

    const message = {
        notification: {
            title: title,
            body: body,
        },
        data: {
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
            type: 'new_episode',
            animeId: animeId || '',
        },
        topic: 'all',
    };

    try {
        // 1. Send Push Notification
        const response = await admin.messaging().send(message);
        logger.log('Successfully sent message:', response);

        // 2. Save to Global Notifications Collection
        await admin.firestore().collection('notifications').add({
            title: title,
            body: body,
            type: 'new_episode',
            relatedId: animeId || '',
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            target: 'all'
        });

    } catch (error) {
        logger.error('Error sending message:', error);
    }
});

/**
 * Trigger: When a new Comment is created.
 * Action: If it's a reply, notify the parent comment's author AND save to user's notifications.
 */
exports.onCommentCreate = onDocumentCreated("comments/{commentId}", async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;
    const data = snapshot.data();

    // Check if it is a reply
    if (!data.replyToCommentId) {
        return;
    }

    const parentCommentId = data.replyToCommentId;
    const replierName = data.userName || 'Someone';

    try {
        // 1. Fetch the parent comment to find the author ID
        const parentDoc = await admin.firestore().collection('comments').doc(parentCommentId).get();
        if (!parentDoc.exists) return;

        const parentData = parentDoc.data();
        const targetUserId = parentData.userId;

        // Don't notify if replying to oneself
        if (targetUserId === data.userId) return;

        // 2. Fetch the target user's profile to get FCM Token
        const userDoc = await admin.firestore().collection('users').doc(targetUserId).get();
        if (!userDoc.exists) return;

        const userData = userDoc.data();
        const fcmToken = userData.fcmToken;

        const title = 'New Reply';
        const bodyContent = `${replierName} replied to your comment.`;

        // 3. Save to User's Personal Notification Collection
        await admin.firestore()
            .collection('users')
            .doc(targetUserId)
            .collection('notifications')
            .add({
                title: title,
                body: bodyContent,
                type: 'comment_reply',
                relatedId: data.animeId || '',
                secondaryId: event.params.commentId,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                isRead: false
            });

        if (!fcmToken) {
            logger.log(`No FCM token for user ${targetUserId}`);
            return;
        }

        // 4. Send Push Notification
        const message = {
            notification: {
                title: title,
                body: bodyContent,
            },
            data: {
                click_action: 'FLUTTER_NOTIFICATION_CLICK',
                type: 'comment_reply',
                animeId: data.animeId || '',
                commentId: event.params.commentId,
            },
            token: fcmToken,
        };

        const response = await admin.messaging().send(message);
        logger.log('Successfully sent reply notification:', response);

    } catch (error) {
        logger.error('Error sending reply notification:', error);
    }
});
