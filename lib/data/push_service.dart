import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// 푸시 알림 주소(FCM 토큰)를 `users/{uid}.fcmTokens`에 올린다.
///
/// 실제 발송은 서버(functions/index.js)가 한다.
/// - 상대가 일정을 등록하면 → "새 일정" 알림
/// - 일정 당일 아침 8시 → 두 사람 모두에게 "오늘 일정" 알림
class PushService {
  PushService({required this._db, this._messaging});

  final FirebaseFirestore _db;
  final FirebaseMessaging? _messaging;

  // 푸시를 쓰지 않는 테스트에서 Firebase 초기화 없이 만들 수 있도록 처음 쓸 때 가져온다.
  FirebaseMessaging get _fm => _messaging ?? FirebaseMessaging.instance;

  StreamSubscription<String>? _refresh;
  String? _uid;
  String? _token;

  /// 로그인한 사용자의 토큰을 등록한다. 권한을 거절하면 아무것도 하지 않는다.
  Future<void> register(String uid) async {
    if (_uid == uid) return;
    _uid = uid;
    try {
      final settings = await _fm.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      // 앱을 보고 있을 때도 iOS에서 배너를 띄운다.
      await _fm.setForegroundNotificationPresentationOptions(
        alert: true,
        sound: true,
      );
      final token = await _fm.getToken();
      if (token != null) await saveToken(uid, token);
      _refresh ??= _fm.onTokenRefresh.listen((t) {
        final current = _uid;
        if (current != null) saveToken(current, t);
      });
    } catch (e) {
      // 시뮬레이터처럼 푸시를 못 받는 환경에서도 앱은 그대로 동작해야 한다.
      debugPrint('푸시 알림을 등록하지 못했어요: $e');
    }
  }

  @visibleForTesting
  Future<void> saveToken(String uid, String token) async {
    _token = token;
    await _db.doc('users/$uid').set({
      'fcmTokens': FieldValue.arrayUnion([token]),
    }, SetOptions(merge: true));
  }

  /// 로그아웃 전에 부른다. 이 폰으로는 더 이상 알림이 가지 않는다.
  Future<void> unregister() async {
    final uid = _uid;
    final token = _token;
    _uid = null;
    _token = null;
    if (uid == null || token == null) return;
    try {
      await _db.doc('users/$uid').update({
        'fcmTokens': FieldValue.arrayRemove([token]),
      });
    } catch (e) {
      debugPrint('푸시 알림 주소를 지우지 못했어요: $e');
    }
  }
}
