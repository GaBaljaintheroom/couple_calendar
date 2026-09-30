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
    this.category = EventCategory.date,
    this.startTime,
    this.endTime,
    this.location,
    this.memo,
    this.checklist = const [],
  });

  final String id;
  final String title;
  final DateTime date;
  final EventOwner owner;
  final EventCategory category;

  /// 둘 다 null이면 종일 일정.
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final String? location;
  final String? memo;

  /// 함께 챙길 것.
  final List<String> checklist;
}

/// 24시간제 "HH:mm".
String formatTime(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
