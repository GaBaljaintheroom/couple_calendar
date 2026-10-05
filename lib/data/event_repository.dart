import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/event.dart';
import '../models/user_profile.dart';

/// 일정 저장소.
///
/// - [EventRepository.firestore]: `couples/{coupleId}/events`를 실시간 구독한다.
///   한쪽이 추가·삭제하면 두 사람 화면에 모두 반영된다.
/// - [EventRepository.memory]: 메모리에만 저장한다 (테스트·미리보기용).
class EventRepository extends ChangeNotifier {
  EventRepository.memory([List<Event> initial = const []])
    : _collection = null,
      _myUid = null,
      _partnerUid = null {
    _events.addAll(initial);
  }

  EventRepository.firestore({
    required FirebaseFirestore db,
    required String coupleId,
    required String this._myUid,
    required String this._partnerUid,
  }) : _collection = db
           .collection('couples')
           .doc(coupleId)
           .collection('events') {
    _subscription = _collection!.snapshots().listen((snapshot) {
      _events
        ..clear()
        ..addAll(snapshot.docs.map(_fromDoc).nonNulls);
      notifyListeners();
    }, onError: (Object e) => debugPrint('일정을 불러오지 못했어요: $e'));
  }

  /// 예시 일정이 들어 있는 메모리 저장소.
  factory EventRepository.demo() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return EventRepository.memory([
      Event(
        id: '1',
        title: '세차 및 차량점검',
        date: today,
        owner: EventOwner.me,
        category: EventCategory.daily,
        startTime: const TimeOfDay(hour: 10, minute: 30),
        endTime: const TimeOfDay(hour: 12, minute: 0),
        location: '오토케어 성수센터',
      ),
      Event(
        id: '2',
        title: '저녁 데이트',
        date: today,
        owner: EventOwner.together,
        category: EventCategory.food,
        memo: '창가 자리로 예약해 두었어요',
        checklist: const ['예약 확인 문자', '꽃 한 송이'],
        startTime: const TimeOfDay(hour: 19, minute: 0),
        endTime: const TimeOfDay(hour: 21, minute: 0),
        location: '성수동 파스타바',
      ),
      Event(
        id: '3',
        title: '영화 보기',
        date: today.add(const Duration(days: 3)),
        owner: EventOwner.together,
        category: EventCategory.culture,
        startTime: const TimeOfDay(hour: 14, minute: 0),
        endTime: const TimeOfDay(hour: 16, minute: 30),
      ),
      Event(
        id: '4',
        title: '필라테스',
        date: today.add(const Duration(days: 1)),
        owner: EventOwner.partner,
        category: EventCategory.daily,
        startTime: const TimeOfDay(hour: 8, minute: 0),
        endTime: const TimeOfDay(hour: 9, minute: 0),
      ),
    ]);
  }

  final CollectionReference<Map<String, dynamic>>? _collection;
  final String? _myUid;
  final String? _partnerUid;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  final List<Event> _events = [];

  /// [day]의 일정을 시간순으로 반환한다. 종일 일정이 먼저 온다.
  /// 여러 날에 걸친 일정은 시작일부터 종료일까지 매일 포함되고,
  /// 시작일이 아닌 날에는 전날부터 이어지므로 종일 일정처럼 맨 위에 온다.
  List<Event> eventsOn(DateTime day, {Set<EventOwner>? owners}) {
    int sortKey(Event e) =>
        DateUtils.isSameDay(e.date, day) ? _minutes(e.startTime) : -1;
    final result =
        _events
            .where((e) => e.occursOn(day))
            .where((e) => owners == null || owners.contains(e.owner))
            .toList()
          ..sort((a, b) => sortKey(a).compareTo(sortKey(b)));
    return result;
  }

  /// Firestore 모드에서는 로컬에 먼저 반영되고(화면에 바로 보임) 서버에는 연결되는 대로 올라간다.
  /// 오프라인이면 반환된 Future가 한참 뒤에 끝나므로 화면에서는 기다리지 않는다.
  Future<void> add(Event event) async {
    final collection = _collection;
    if (collection == null) {
      _events.add(event);
      notifyListeners();
      return;
    }
    await collection.doc(event.id).set({
      ..._toMap(event),
      'createdBy': _myUid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// 같은 id의 일정을 [event] 내용으로 바꾼다. 처음 등록한 사람과 시각은 유지된다.
  Future<void> update(Event event) async {
    final collection = _collection;
    if (collection == null) {
      final index = _events.indexWhere((e) => e.id == event.id);
      if (index < 0) return;
      _events[index] = event;
      notifyListeners();
      return;
    }
    await collection.doc(event.id).update({
      ..._toMap(event),
      'updatedBy': _myUid,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> remove(String id) async {
    final collection = _collection;
    if (collection == null) {
      _events.removeWhere((e) => e.id == id);
      notifyListeners();
      return;
    }
    await collection.doc(id).delete();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  // 일정의 주인은 내 기준(나/상대)이 아니라 'together' 또는 실제 uid로 저장한다.
  // 그래야 같은 일정이 두 사람 화면에서 각자 기준으로 올바르게 보인다.
  static const _together = 'together';

  Map<String, dynamic> _toMap(Event e) => {
    'title': e.title,
    'date': formatDate(e.date),
    'endDate': e.isMultiDay ? formatDate(e.lastDate) : null,
    'owner': switch (e.owner) {
      EventOwner.together => _together,
      EventOwner.me => _myUid,
      EventOwner.partner => _partnerUid,
    },
    'category': e.category.name,
    'startTime': e.startTime == null ? null : formatTime(e.startTime!),
    'endTime': e.endTime == null ? null : formatTime(e.endTime!),
    'location': e.location,
    'memo': e.memo,
    'checklist': e.checklist,
  };

  Event? _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final date = parseDate(data['date'] as String?);
    final title = data['title'] as String?;
    if (date == null || title == null) return null;
    final owner = data['owner'] as String?;
    final endDate = parseDate(data['endDate'] as String?);
    return Event(
      id: doc.id,
      title: title,
      date: date,
      endDate: endDate != null && endDate.isAfter(date) ? endDate : null,
      owner: owner == _together
          ? EventOwner.together
          : owner == _myUid
          ? EventOwner.me
          : EventOwner.partner,
      category:
          EventCategory.values.asNameMap()[data['category']] ??
          EventCategory.date,
      startTime: _parseTime(data['startTime'] as String?),
      endTime: _parseTime(data['endTime'] as String?),
      location: data['location'] as String?,
      memo: data['memo'] as String?,
      checklist: List<String>.from(data['checklist'] as List? ?? const []),
    );
  }

  static TimeOfDay? _parseTime(String? s) {
    final parts = s?.split(':').map(int.tryParse).toList();
    if (parts == null || parts.length != 2 || parts.contains(null)) return null;
    return TimeOfDay(hour: parts[0]!, minute: parts[1]!);
  }

  static int _minutes(TimeOfDay? t) => t == null ? -1 : t.hour * 60 + t.minute;
}
