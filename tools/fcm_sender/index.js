const admin = require('firebase-admin');
const prompt = require('prompt-sync')();
const fs = require('fs');

// Check for service account key
const serviceAccountPath = './service-account.json';
if (!fs.existsSync(serviceAccountPath)) {
    console.error("❌ Error: 'service-account.json' not found!");
    console.log("👉 Please download your Service Account Key from Firebase Console -> Project Settings -> Service accounts");
    console.log("   and save it as 'service-account.json' in this directory.");
    process.exit(1);
}

const serviceAccount = require(serviceAccountPath);

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

console.log("📢 AnimeHat Notification Sender");
console.log("-------------------------------");

const title = prompt('📝 Title: ');
const body = prompt('💬 Body: ');
const topic = prompt('🎯 Topic (default: "all"): ') || 'all';
// Specific type logic: e.g. "anime_update" for custom handling in app if needed
const type = prompt('🔧 Type (optional, e.g. "update"): ');

if (!title || !body) {
    console.error("❌ Title and Body are required.");
    process.exit(1);
}

const message = {
    notification: {
        title: title,
        body: body
    },
    data: {
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
        type: type || 'general',
        // Add extra data keys here if your app logic needs them (e.g. anime_id)
    },
    topic: topic
};

console.log(`\n🚀 Sending to topic: '${topic}'...`);

admin.messaging().send(message)
    .then((response) => {
        console.log('✅ Successfully sent message:', response);
        process.exit(0);
    })
    .catch((error) => {
        console.log('❌ Error sending message:', error);
        process.exit(1);
    });
