import 'package:couple_calendar/data/push_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('푸시 토큰을 프로필에 겹치지 않게 추가하고, 다른 정보는 그대로 둔다', () async {
    final db = FakeFirebaseFirestore();
    await db.doc('users/a').set({'name': '민준'});
    final push = PushService(db: db);

    await push.saveToken('a', 'phone-1');
    await push.saveToken('a', 'phone-2');
    await push.saveToken('a', 'phone-1');

    final data = (await db.doc('users/a').get()).data()!;
    expect(data['name'], '민준');
    expect(data['fcmTokens'], ['phone-1', 'phone-2']);
  });
}
