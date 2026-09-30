import 'dart:math';

import 'package:couple_calendar/data/couple_service.dart';
import 'package:couple_calendar/models/user_profile.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore db;
  late DateTime now;
  late CoupleService service;

  setUp(() {
    db = FakeFirebaseFirestore();
    now = DateTime(2026, 9, 30, 12);
    service = CoupleService(db: db, clock: () => now, random: Random(1));
  });

  // 가짜 Firestore의 snapshots()는 이전 값을 캐시할 때가 있어 문서를 직접 읽는다.
  Future<UserProfile> readUser(String uid) async =>
      UserProfile.fromDoc(await db.doc('users/$uid').get());
  Future<Couple> readCouple(String id) async =>
      Couple.fromDoc(await db.doc('couples/$id').get());

  Future<UserProfile> user(String uid, String name) async {
    await service.saveProfile(
      uid: uid,
      name: name,
      birthday: DateTime(1996, 11, 5),
    );
    return (await readUser(uid));
  }

  test('프로필을 저장하고 날짜는 yyyy-MM-dd로 남긴다', () async {
    final me = await user('a', ' 민준 ');
    expect(me.name, '민준');
    expect(me.birthday, DateTime(1996, 11, 5));
    expect((await db.doc('users/a').get()).data()!['birthday'], '1996-11-05');
  });

  test('초대 코드를 만들고 상대가 입력하면 연결된다', () async {
    final a = await user('a', '민준');
    final b = await user('b', '서연');

    final code = await service.createInvite(a);
    expect(code, hasLength(CoupleService.codeLength));

    final aAfter = (await readUser('a'));
    final pending = (await readCouple(aAfter.coupleId!));
    expect(pending.members, ['a']);
    expect(pending.inviteCode, code);

    await service.joinWithCode(b, code.toLowerCase());

    final couple = (await readCouple(aAfter.coupleId!));
    expect(couple.members, ['a', 'b']);
    expect(couple.isConnected, isTrue);
    expect(couple.inviteCode, isNull);
    expect((await readUser('b')).coupleId, couple.id);
    expect((await db.doc('invites/$code').get()).exists, isFalse);
  });

  test('코드를 다시 만들면 같은 커플에 새 코드가 발급되고 예전 코드는 지워진다', () async {
    final a = await user('a', '민준');
    final first = await service.createInvite(a);
    final aAfter = (await readUser('a'));
    final pending = (await readCouple(aAfter.coupleId!));

    final second = await service.createInvite(aAfter, pendingCouple: pending);

    expect(second, isNot(first));
    expect((await readCouple(pending.id)).inviteCode, second);
    expect((await db.doc('invites/$first').get()).exists, isFalse);
  });

  group('잘못된 코드는 안내 메시지와 함께 거절한다', () {
    test('없는 코드', () async {
      final b = await user('b', '서연');
      expect(
        () => service.joinWithCode(b, 'ZZZZZZ'),
        throwsA(isA<InviteException>()),
      );
    });

    test('내가 만든 코드', () async {
      final a = await user('a', '민준');
      final code = await service.createInvite(a);
      final aAfter = (await readUser('a'));
      await expectLater(
        service.joinWithCode(aAfter, code),
        throwsA(
          isA<InviteException>().having(
            (e) => e.message,
            'message',
            contains('내가 만든'),
          ),
        ),
      );
    });

    test('만료된 코드', () async {
      final a = await user('a', '민준');
      final b = await user('b', '서연');
      final code = await service.createInvite(a);
      now = now.add(const Duration(hours: 25));
      await expectLater(
        service.joinWithCode(b, code),
        throwsA(
          isA<InviteException>().having(
            (e) => e.message,
            'message',
            contains('만료'),
          ),
        ),
      );
    });

    test('이미 연결된 코드', () async {
      final a = await user('a', '민준');
      final b = await user('b', '서연');
      final c = await user('c', '다른 사람');
      final code = await service.createInvite(a);
      await service.joinWithCode(b, code);
      await expectLater(
        service.joinWithCode(c, code),
        throwsA(isA<InviteException>()),
      );
    });
  });

  test('사귄 날짜를 저장하고 연결을 해제할 수 있다', () async {
    final a = await user('a', '민준');
    final b = await user('b', '서연');
    final code = await service.createInvite(a);
    await service.joinWithCode(b, code);
    final bAfter = (await readUser('b'));

    await service.setStartDate(bAfter.coupleId!, DateTime(2024, 8, 1));
    expect(
      (await readCouple(bAfter.coupleId!)).startDate,
      DateTime(2024, 8, 1),
    );

    await service.disconnect(bAfter);
    expect((await readUser('b')).coupleId, isNull);
    expect((await readCouple(bAfter.coupleId!)).members, ['a']);
  });

  test('캘린더 이름을 바꾸고, 비우면 기본 이름으로 돌아간다', () async {
    final a = await user('a', '민준');
    await service.createInvite(a);
    final coupleId = (await readUser('a')).coupleId!;

    await service.setCalendarName(coupleId, '  민준♡서연 캘린더 ');
    expect((await readCouple(coupleId)).calendarName, '민준♡서연 캘린더');

    await service.setCalendarName(coupleId, '   ');
    expect((await readCouple(coupleId)).calendarName, isNull);
  });
}
