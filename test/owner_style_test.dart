import 'package:couple_calendar/models/couple_profile.dart';
import 'package:couple_calendar/models/event.dart';
import 'package:couple_calendar/widgets/owner_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final base = CoupleProfile(
    myName: '민준',
    partnerName: '서연',
    startDate: DateTime(2025, 1, 1),
  );

  test('색을 고르지 않으면 디자인 시스템 기본 색을 쓴다', () {
    for (final owner in EventOwner.values) {
      expect(base.styleOf(owner).dot, OwnerStyle.defaultOf(owner).dot);
    }
  });

  test('고른 색은 점에 그대로, 이름표는 연한 배경과 진한 글자로 쓴다', () {
    const teal = Color(0xFF2A9D8F);
    final profile = CoupleProfile(
      myName: '민준',
      partnerName: '서연',
      startDate: DateTime(2025, 1, 1),
      myColor: teal,
    );
    final style = profile.styleOf(EventOwner.me);

    expect(style.dot, teal);
    expect(
      style.chipBackground.computeLuminance(),
      greaterThan(teal.computeLuminance()),
    );
    expect(
      style.chipForeground.computeLuminance(),
      lessThan(teal.computeLuminance()),
    );
    // 이름표 글자와 배경의 대비가 충분해야 읽힌다 (WCAG AA 4.5:1).
    for (final color in ownerColorChoices) {
      final s = OwnerStyle.from(color);
      final l1 = s.chipBackground.computeLuminance();
      final l2 = s.chipForeground.computeLuminance();
      expect((l1 + 0.05) / (l2 + 0.05), greaterThanOrEqualTo(4.5));
    }
    // 다른 주인 색은 그대로.
    expect(
      profile.styleOf(EventOwner.partner).dot,
      OwnerStyle.defaultOf(EventOwner.partner).dot,
    );
  });
}
