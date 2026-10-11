// 데이로그 푸시 알림.
// - onEventCreated: 일정이 등록되면 상대에게 "새 일정" 알림
// - morningReminder: 매일 아침 8시(한국 시간), 그날 시작하는 일정을 두 사람에게 알림
// 받는 주소(FCM 토큰)는 앱이 users/{uid}.fcmTokens에 올린다 (lib/data/push_service.dart).

const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { setGlobalOptions, logger } = require('firebase-functions/v2');
const { newEventMessage, todayMessage, todayInSeoul } = require('./messages');

initializeApp();
// Firestore와 같은 서울 리전. 두 사람이 쓰는 앱이라 인스턴스는 하나면 충분하다.
setGlobalOptions({ region: 'asia-northeast3', maxInstances: 1 });

const db = getFirestore();

exports.onEventCreated = onDocumentCreated(
  'couples/{coupleId}/events/{eventId}',
  async (snap) => {
    const event = snap.data?.data();
    if (!event || !event.createdBy) return;
    const couple = (await db.doc(`couples/${snap.params.coupleId}`).get()).data();
    const partners = (couple?.members || []).filter((uid) => uid !== event.createdBy);
    if (partners.length === 0) return;

    const creator = (await db.doc(`users/${event.createdBy}`).get()).data();
    await sendTo(partners, newEventMessage(event, creator?.name || '상대'));
  },
);

exports.morningReminder = onSchedule(
  { schedule: '0 8 * * *', timeZone: 'Asia/Seoul' },
  async () => {
    const today = todayInSeoul();
    const snapshot = await db.collectionGroup('events').where('date', '==', today).get();

    // 커플별로 묶어 한 번씩 보낸다.
    const byCouple = new Map();
    for (const doc of snapshot.docs) {
      const coupleId = doc.ref.parent.parent.id;
      if (!byCouple.has(coupleId)) byCouple.set(coupleId, []);
      byCouple.get(coupleId).push(doc.data());
    }
    for (const [coupleId, events] of byCouple) {
      const couple = (await db.doc(`couples/${coupleId}`).get()).data();
      await sendTo(couple?.members || [], todayMessage(events));
    }
    logger.info(`오늘(${today}) 일정 알림: 커플 ${byCouple.size}쌍`);
  },
);

/** [uids]의 모든 폰으로 보낸다. 더 이상 쓰지 않는 토큰은 지운다. */
async function sendTo(uids, { title, body }) {
  for (const uid of uids) {
    const userRef = db.doc(`users/${uid}`);
    const tokens = (await userRef.get()).data()?.fcmTokens || [];
    if (tokens.length === 0) continue;

    const result = await getMessaging().sendEachForMulticast({
      tokens,
      notification: { title, body },
      android: { notification: { channelId: 'events' } },
      apns: { payload: { aps: { sound: 'default' } } },
    });
    const stale = tokens.filter((_, i) => {
      const code = result.responses[i].error?.code;
      return code === 'messaging/registration-token-not-registered'
        || code === 'messaging/invalid-registration-token';
    });
    if (stale.length > 0) {
      await userRef.update({ fcmTokens: FieldValue.arrayRemove(...stale) });
    }
  }
}
