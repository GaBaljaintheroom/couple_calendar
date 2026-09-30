import 'package:couple_calendar/data/daily_messages.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('글귀가 40개 이상이고 중복이 없다', () {
    expect(dailyMessages.length, greaterThanOrEqualTo(40));
    expect(dailyMessages.toSet(), hasLength(dailyMessages.length));
  });

  test('하루마다 다른 글귀가 나오고, 한 바퀴 돌면 처음으로 돌아온다', () {
    final n = dailyMessages.length;
    expect(dailyMessageFor(100), isNot(dailyMessageFor(101)));
    expect(
      dailyMessageFor(100).replaceAll('100', ''),
      dailyMessageFor(100 + n).replaceAll('${100 + n}', ''),
    );
  });

  test('{days}는 사귄 일수로 바뀐다', () {
    for (var day = 1; day <= dailyMessages.length; day++) {
      final message = dailyMessageFor(day);
      expect(message, isNot(contains('{days}')));
    }
    final withDays = dailyMessages.indexWhere((m) => m.contains('{days}'));
    expect(dailyMessageFor(withDays), contains('$withDays일'));
  });
}
