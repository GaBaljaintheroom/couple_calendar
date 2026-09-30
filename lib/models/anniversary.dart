import 'couple_profile.dart';
import 'event.dart';

enum AnniversaryKind { hundredDays, yearly, birthday, custom }

/// 사용자가 직접 등록한 기념일.
class CustomAnniversary {
  const CustomAnniversary({
    required this.id,
    required this.title,
    required this.date,
    this.repeatsYearly = true,
  });

  final String id;
  final String title;
  final DateTime date;
  final bool repeatsYearly;
}

/// 피드에 표시되는 기념일 한 건 (다음에 돌아오는 날짜 기준).
class Anniversary {
  const Anniversary({
    required this.id,
    required this.title,
    required this.date,
    required this.kind,
    this.birthdayOf,
    this.customId,
    this.repeatsYearly = false,
  });

  /// 같은 기념일의 같은 회차면 항상 같은 값. 메모를 붙이는 키로 쓴다.
  final String id;
  final String title;
  final DateTime date;
  final AnniversaryKind kind;

  /// 생일일 때 누구의 생일인지.
  final EventOwner? birthdayOf;

  /// 직접 등록한 기념일이면 원본 id.
  final String? customId;
  final bool repeatsYearly;

  int dDayFrom(DateTime today) =>
      _dateOnly(date).difference(_dateOnly(today)).inDays;
}

/// [today]부터 [window]일 안에 돌아오는 기념일을 날짜순으로 계산한다.
List<Anniversary> upcomingAnniversaries({
  required CoupleProfile profile,
  required DateTime today,
  List<CustomAnniversary> customs = const [],
  int window = 365,
}) {
  final start = _dateOnly(today);
  final end = start.add(Duration(days: window));
  bool inWindow(DateTime d) => !d.isBefore(start) && !d.isAfter(end);

  final result = <Anniversary>[];

  // 100일 단위
  for (var n = (profile.dayCountOn(start) + 99) ~/ 100 * 100; ; n += 100) {
    if (n <= 0) continue;
    final date = profile.dateOfDay(n);
    if (date.isAfter(end)) break;
    if (inWindow(date)) {
      result.add(
        Anniversary(
          id: 'days-$n',
          title: '$n일 기념일',
          date: date,
          kind: AnniversaryKind.hundredDays,
        ),
      );
    }
  }

  // N주년
  final first = _dateOnly(profile.startDate);
  for (var year = start.year; year <= end.year; year++) {
    final n = year - first.year;
    if (n <= 0) continue;
    final date = DateTime(year, first.month, first.day);
    if (inWindow(date)) {
      result.add(
        Anniversary(
          id: 'years-$n',
          title: '$n주년 기념일',
          date: date,
          kind: AnniversaryKind.yearly,
          repeatsYearly: true,
        ),
      );
    }
  }

  // 생일
  for (final (owner, birthday) in [
    (EventOwner.me, profile.myBirthday),
    (EventOwner.partner, profile.partnerBirthday),
  ]) {
    if (birthday == null) continue;
    final date = _nextOccurrence(birthday, start);
    if (inWindow(date)) {
      result.add(
        Anniversary(
          id: 'birthday-${owner.name}-${date.year}',
          title: '${profile.nameOf(owner)} 생일',
          date: date,
          kind: AnniversaryKind.birthday,
          birthdayOf: owner,
          repeatsYearly: true,
        ),
      );
    }
  }

  // 직접 등록
  for (final custom in customs) {
    final date = custom.repeatsYearly
        ? _nextOccurrence(custom.date, start)
        : _dateOnly(custom.date);
    if (inWindow(date)) {
      result.add(
        Anniversary(
          id: 'custom-${custom.id}-${date.year}',
          title: custom.title,
          date: date,
          kind: AnniversaryKind.custom,
          customId: custom.id,
          repeatsYearly: custom.repeatsYearly,
        ),
      );
    }
  }

  result.sort((a, b) => a.date.compareTo(b.date));
  return result;
}

/// [from] 당일 또는 그 이후로 처음 돌아오는 같은 월·일.
DateTime _nextOccurrence(DateTime date, DateTime from) {
  final thisYear = DateTime(from.year, date.month, date.day);
  return thisYear.isBefore(from)
      ? DateTime(from.year + 1, date.month, date.day)
      : thisYear;
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
