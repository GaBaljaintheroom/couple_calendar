import 'package:flutter/material.dart';

/// 일정의 주인. 캘린더 점 색과 필터 칩에 쓰인다.
enum EventOwner { together, me, partner }

enum EventCategory {
  date('데이트', '☕️'),
  anniversary('기념일', '🎂'),
  travel('여행', '🚗'),
  food('맛집/카페', '🍝'),
  culture('영화/문화', '🎬'),
  daily('일상/개인', '📌');

  const EventCategory(this.label, this.emoji);

  final String label;
  final String emoji;
}

class Event {
  const Event({
    required this.id,
    required this.title,
    required this.date,
    required this.owner,
    this.endDate,
    this.category = EventCategory.date,
    this.startTime,
    this.endTime,
    this.location,
    this.memo,
    this.checklist = const [],
    this.createdByMe = true,
  });

  final String id;
  final String title;

  /// 시작 날짜.
  final DateTime date;

  /// 종료 날짜. null이면 [date]와 같은 날 끝난다.
  final DateTime? endDate;
  final EventOwner owner;
  final EventCategory category;

  /// 둘 다 null이면 종일 일정.
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final String? location;
  final String? memo;

  /// 함께 챙길 것.
  final List<String> checklist;

  /// 내가 등록한 일정인지. 새로 만드는 일정은 항상 내 것이다.
  final bool createdByMe;

  /// 수정·삭제할 수 있는지. "우리 함께" 일정이나 내가 등록한 일정만 된다.
  /// 서버(firestore.rules)도 같은 규칙으로 막는다.
  bool get editable => owner == EventOwner.together || createdByMe;

  /// 마지막 날짜. 하루짜리 일정이면 [date]와 같다.
  DateTime get lastDate => endDate ?? date;

  /// 시작일과 종료일이 다른 일정.
  bool get isMultiDay => !DateUtils.isSameDay(date, lastDate);

  /// [day]가 시작일부터 종료일 사이(양 끝 포함)에 있는지.
  bool occursOn(DateTime day) {
    final d = DateUtils.dateOnly(day);
    return !d.isBefore(DateUtils.dateOnly(date)) &&
        !d.isAfter(DateUtils.dateOnly(lastDate));
  }
}

/// 24시간제 "HH:mm".
String formatTime(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
