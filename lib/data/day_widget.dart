import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../models/couple_profile.dart';
import '../models/user_profile.dart';

/// 홈 화면 "D+일수" 위젯에 보여줄 정보를 넘긴다.
///
/// 일수는 위젯이 사귄 날짜로 직접 계산한다. 그래서 앱을 열지 않아도 자정마다 하루씩 늘어난다.
/// - iOS: App Group(`appGroupId`)의 UserDefaults → `ios/DayWidget`
/// - Android: SharedPreferences → `DayWidgetProvider.kt`
abstract final class DayWidget {
  static const appGroupId = 'group.com.junsupark.coupleCalendar';
  static const _iOSKind = 'DayWidget';
  static const _androidProvider =
      'com.junsupark.couple_calendar.DayWidgetProvider';

  static Future<void> init() =>
      _guard(() => HomeWidget.setAppGroupId(appGroupId));

  static Future<void> update(CoupleProfile profile) => _save(
    startDate: formatDate(profile.startDate),
    myName: profile.myName,
    partnerName: profile.partnerName,
  );

  /// 로그아웃·연결 해제 시. 위젯은 "앱에서 커플을 연결해 주세요"를 보여준다.
  static Future<void> clear() =>
      _save(startDate: null, myName: null, partnerName: null);

  static Future<void> _save({
    required String? startDate,
    required String? myName,
    required String? partnerName,
  }) => _guard(() async {
    await HomeWidget.saveWidgetData<String>('startDate', startDate);
    await HomeWidget.saveWidgetData<String>('myName', myName);
    await HomeWidget.saveWidgetData<String>('partnerName', partnerName);
    await HomeWidget.updateWidget(
      iOSName: _iOSKind,
      qualifiedAndroidName: _androidProvider,
    );
  });

  /// 위젯이 없는 환경(테스트, 웹)이나 실패해도 앱 동작에는 영향을 주지 않는다.
  static Future<void> _guard(Future<void> Function() run) async {
    try {
      await run();
    } catch (e) {
      debugPrint('홈 화면 위젯을 갱신하지 못했어요: $e');
    }
  }
}
