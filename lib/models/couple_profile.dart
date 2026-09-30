import 'event.dart';

/// 커플 정보. 지금은 고정값이고, 이후 연결(초대) 기능이 생기면 서버에서 받아온다.
/// 캘린더 이름을 정하지 않았을 때 쓰는 기본값.
const defaultCalendarName = '캘린더';

class CoupleProfile {
  const CoupleProfile({
    required this.myName,
    required this.partnerName,
    required this.startDate,
    this.myBirthday,
    this.partnerBirthday,
    this.calendarName = defaultCalendarName,
  });

  final String myName;
  final String partnerName;

  /// 사귀기 시작한 날. 이 날이 D+1이다.
  final DateTime startDate;

  /// 생일. 연도는 쓰지 않고 월·일만 본다.
  final DateTime? myBirthday;
  final DateTime? partnerBirthday;

  /// 상단바에 보이는 이름. 커플이 우리공간에서 바꿀 수 있다.
  final String calendarName;

  String nameOf(EventOwner owner) => switch (owner) {
    EventOwner.together => '우리 함께',
    EventOwner.me => myName,
    EventOwner.partner => partnerName,
  };

  /// 사귄 지 며칠째인지 (시작일 = 1).
  int dayCountOn(DateTime day) =>
      _dateOnly(day).difference(_dateOnly(startDate)).inDays + 1;

  /// [today] 이후 가장 가까운 100일 단위 기념일의 일수.
  int nextHundredDayMilestone(DateTime today) =>
      (dayCountOn(today) ~/ 100 + 1) * 100;

  /// N일째가 되는 날짜.
  DateTime dateOfDay(int dayCount) =>
      _dateOnly(startDate).add(Duration(days: dayCount - 1));

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
