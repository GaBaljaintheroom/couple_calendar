import 'package:couple_calendar/data/anniversary_repository.dart';
import 'package:couple_calendar/data/event_repository.dart';
import 'package:couple_calendar/models/anniversary.dart';
import 'package:couple_calendar/models/event.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore db;

  setUp(() => db = FakeFirebaseFirestore());

  group('EventRepository (Firestore)', () {
    late EventRepository mine;
    late EventRepository partners;

    setUp(() {
      // 같은 커플을 두 사람이 각자의 폰에서 보고 있다.
      mine = EventRepository.firestore(
        db: db,
        coupleId: 'c1',
        myUid: 'a',
        partnerUid: 'b',
      );
      partners = EventRepository.firestore(
        db: db,
        coupleId: 'c1',
        myUid: 'b',
        partnerUid: 'a',
      );
    });

    tearDown(() {
      mine.dispose();
      partners.dispose();
    });

    final day = DateTime(2026, 10, 3);

    test('내가 등록한 일정이 상대에게는 "상대" 일정으로 보인다', () async {
      await mine.add(
        Event(
          id: 'e1',
          title: '필라테스',
          date: day,
          owner: EventOwner.me,
          category: EventCategory.daily,
          startTime: const TimeOfDay(hour: 8, minute: 30),
          endTime: const TimeOfDay(hour: 9, minute: 0),
          location: '성수',
          memo: '운동복 챙기기',
          checklist: const ['물병'],
        ),
      );
      await pumpEventQueue();

      final myView = mine.eventsOn(day).single;
      final partnerView = partners.eventsOn(day).single;
      expect(myView.owner, EventOwner.me);
      expect(partnerView.owner, EventOwner.partner);

      expect(partnerView.title, '필라테스');
      expect(partnerView.category, EventCategory.daily);
      expect(partnerView.startTime, const TimeOfDay(hour: 8, minute: 30));
      expect(partnerView.endTime, const TimeOfDay(hour: 9, minute: 0));
      expect(partnerView.location, '성수');
      expect(partnerView.memo, '운동복 챙기기');
      expect(partnerView.checklist, ['물병']);
    });

    test('"우리 함께" 일정은 두 사람 모두에게 함께 일정이다', () async {
      await partners.add(
        Event(id: 'e2', title: '데이트', date: day, owner: EventOwner.together),
      );
      await pumpEventQueue();

      expect(mine.eventsOn(day).single.owner, EventOwner.together);
      expect(partners.eventsOn(day).single.owner, EventOwner.together);
    });

    test('상대가 지우면 내 화면에서도 사라지고, 변경을 알린다', () async {
      await mine.add(
        Event(id: 'e3', title: '영화', date: day, owner: EventOwner.together),
      );
      await pumpEventQueue();
      var notified = 0;
      mine.addListener(() => notified++);

      await partners.remove('e3');
      await pumpEventQueue();

      expect(mine.eventsOn(day), isEmpty);
      expect(notified, greaterThan(0));
    });

    test('다른 커플의 일정은 섞이지 않는다', () async {
      final other = EventRepository.firestore(
        db: db,
        coupleId: 'c2',
        myUid: 'x',
        partnerUid: 'y',
      );
      addTearDown(other.dispose);
      await other.add(
        Event(id: 'e4', title: '남의 일정', date: day, owner: EventOwner.me),
      );
      await pumpEventQueue();

      expect(mine.eventsOn(day), isEmpty);
    });
  });

  group('AnniversaryRepository (Firestore)', () {
    late AnniversaryRepository mine;
    late AnniversaryRepository partners;

    setUp(() {
      mine = AnniversaryRepository.firestore(db: db, coupleId: 'c1');
      partners = AnniversaryRepository.firestore(db: db, coupleId: 'c1');
    });

    tearDown(() {
      mine.dispose();
      partners.dispose();
    });

    test('직접 등록한 기념일과 메모가 상대에게도 보인다', () async {
      await mine.add(
        CustomAnniversary(
          id: 'first-trip',
          title: '첫 여행',
          date: DateTime(2025, 5, 1),
        ),
      );
      await mine.setMemo('custom-first-trip-2027', '앨범 만들기');
      await partners.setMemo('days-800', ' 케이크 예약 ');
      await pumpEventQueue();

      final custom = partners.customs.single;
      expect(custom.title, '첫 여행');
      expect(custom.date, DateTime(2025, 5, 1));
      expect(custom.repeatsYearly, isTrue);
      expect(partners.memoFor('custom-first-trip-2027'), '앨범 만들기');
      expect(mine.memoFor('days-800'), '케이크 예약');
    });

    test('메모를 비우면 지워진다', () async {
      await mine.setMemo('days-800', '케이크');
      await pumpEventQueue();
      await mine.setMemo('days-800', '  ');
      await pumpEventQueue();

      expect(partners.memoFor('days-800'), isNull);
    });

    test('기념일을 지우면 그 기념일의 메모도 함께 지워진다', () async {
      await mine.add(
        CustomAnniversary(id: 'x', title: '기념일', date: DateTime(2025, 1, 1)),
      );
      await mine.setMemo('custom-x-2026', '메모');
      await mine.setMemo('days-800', '다른 메모');
      await pumpEventQueue();

      await partners.remove('x');
      await pumpEventQueue();

      expect(mine.customs, isEmpty);
      expect(mine.memoFor('custom-x-2026'), isNull);
      expect(mine.memoFor('days-800'), '다른 메모');
    });
  });
}
