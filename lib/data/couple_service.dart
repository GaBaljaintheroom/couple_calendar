import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_profile.dart';
import 'push_service.dart';

/// 초대 코드 연결 실패. [message]는 그대로 사용자에게 보여준다.
class InviteException implements Exception {
  InviteException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 프로필, 커플 연결, 사귄 날짜를 Firestore에 저장한다.
///
/// 구조
/// - users/{uid}: name, birthday, photoUrl, email, coupleId
/// - couples/{id}: members, startDate, inviteCode, inviteExpiresAt
/// - invites/{code}: coupleId, createdBy, expiresAt
class CoupleService {
  CoupleService({
    FirebaseFirestore? db,
    DateTime Function()? clock,
    Random? random,
  }) : _db = db ?? FirebaseFirestore.instance,
       _now = clock ?? DateTime.now,
       _random = random ?? Random.secure();

  final FirebaseFirestore _db;

  /// 커플 데이터(일정·기념일) 저장소도 같은 DB를 쓴다.
  FirebaseFirestore get firestore => _db;

  /// 이 폰의 푸시 알림 주소를 내 프로필에 올린다.
  late final push = PushService(db: _db);
  final DateTime Function() _now;
  final Random _random;

  static const inviteValidity = Duration(hours: 24);

  /// 헷갈리는 글자(0/O, 1/I/L)를 뺀 코드 문자.
  static const _codeAlphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  static const codeLength = 6;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _couples =>
      _db.collection('couples');
  CollectionReference<Map<String, dynamic>> get _invites =>
      _db.collection('invites');

  /// 문서가 없으면 null.
  Stream<UserProfile?> watchUser(String uid) => _users
      .doc(uid)
      .snapshots()
      .map((doc) => doc.exists ? UserProfile.fromDoc(doc) : null);

  Stream<Couple?> watchCouple(String coupleId) => _couples
      .doc(coupleId)
      .snapshots()
      .map((doc) => doc.exists ? Couple.fromDoc(doc) : null);

  Future<void> saveProfile({
    required String uid,
    required String name,
    required DateTime? birthday,
    String? photoUrl,
    String? email,
  }) {
    return _users.doc(uid).set({
      'name': name.trim(),
      'birthday': birthday == null ? null : formatDate(birthday),
      'photoUrl': ?photoUrl,
      'email': ?email,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// 내 초대 코드를 만든다. 프로필 문서([saveProfile])가 먼저 있어야 한다. 상대를 기다리는 중인 커플이 있으면 그 커플에 새 코드를 발급한다.
  Future<String> createInvite(UserProfile me, {Couple? pendingCouple}) async {
    final reuse =
        pendingCouple != null &&
        !pendingCouple.isConnected &&
        pendingCouple.members.contains(me.uid);
    final coupleRef = reuse ? _couples.doc(pendingCouple.id) : _couples.doc();
    final expiresAt = Timestamp.fromDate(_now().add(inviteValidity));

    for (var attempt = 0; attempt < 5; attempt++) {
      final code = _generateCode();
      final created = await _db.runTransaction((tx) async {
        final inviteRef = _invites.doc(code);
        if ((await tx.get(inviteRef)).exists) return false; // 드물게 겹치면 다시 뽑는다.

        if (reuse) {
          tx.update(coupleRef, {
            'inviteCode': code,
            'inviteExpiresAt': expiresAt,
          });
        } else {
          tx.set(coupleRef, {
            'members': [me.uid],
            'createdBy': me.uid,
            'createdAt': FieldValue.serverTimestamp(),
            'inviteCode': code,
            'inviteExpiresAt': expiresAt,
          });
        }
        tx.update(_users.doc(me.uid), {'coupleId': coupleRef.id});
        tx.set(inviteRef, {
          'coupleId': coupleRef.id,
          'createdBy': me.uid,
          'expiresAt': expiresAt,
        });
        return true;
      });
      if (created) {
        final oldCode = reuse ? pendingCouple.inviteCode : null;
        if (oldCode != null) {
          // 예전 코드는 더 이상 쓰이지 않는다. 지우지 못해도 만료되므로 무시한다.
          await _invites.doc(oldCode).delete().catchError((_) {});
        }
        return code;
      }
    }
    throw InviteException('초대 코드를 만들지 못했어요. 다시 시도해 주세요.');
  }

  /// 상대의 초대 코드로 커플에 합류한다.
  Future<void> joinWithCode(UserProfile me, String rawCode) async {
    final code = rawCode.trim().toUpperCase();
    if (code.length != codeLength) {
      throw InviteException('코드 $codeLength자리를 모두 입력해 주세요.');
    }

    final inviteDoc = await _invites.doc(code).get();
    if (!inviteDoc.exists) {
      throw InviteException('코드를 찾을 수 없어요. 다시 확인해 주세요.');
    }
    final coupleId = inviteDoc.data()!['coupleId'] as String;

    await _db.runTransaction((tx) async {
      final coupleRef = _couples.doc(coupleId);
      final coupleDoc = await tx.get(coupleRef);
      if (!coupleDoc.exists) {
        throw InviteException('코드를 찾을 수 없어요. 다시 확인해 주세요.');
      }
      final couple = Couple.fromDoc(coupleDoc);
      if (couple.members.contains(me.uid)) {
        throw InviteException('내가 만든 코드예요. 상대방에게 공유해 주세요.');
      }
      if (couple.isConnected || couple.inviteCode != code) {
        throw InviteException('이미 사용된 코드예요.');
      }
      final expiresAt = couple.inviteExpiresAt;
      if (expiresAt == null || !expiresAt.isAfter(_now())) {
        throw InviteException('만료된 코드예요. 상대방에게 새 코드를 받아 주세요.');
      }

      tx.update(coupleRef, {
        'members': [...couple.members, me.uid],
        'inviteCode': FieldValue.delete(),
        'inviteExpiresAt': FieldValue.delete(),
      });
      tx.update(_users.doc(me.uid), {'coupleId': coupleId});
      tx.delete(_invites.doc(code));
    });
  }

  Future<void> setStartDate(String coupleId, DateTime date) =>
      _couples.doc(coupleId).update({'startDate': formatDate(date)});

  static const calendarNameMaxLength = 15;

  /// 비워서 저장하면 기본 이름으로 돌아간다.
  Future<void> setCalendarName(String coupleId, String name) {
    final trimmed = name.trim();
    return _couples.doc(coupleId).update({
      'calendarName': trimmed.isEmpty ? FieldValue.delete() : trimmed,
    });
  }

  /// 캘린더에 표시할 나의 색. null이면 기본 색으로 돌아간다.
  Future<void> setMyColor(String uid, int? argb) =>
      _users.doc(uid).update({'color': argb ?? FieldValue.delete()});

  /// "우리 함께" 일정 색. 두 사람 모두 바꿀 수 있고, null이면 기본 색으로 돌아간다.
  Future<void> setTogetherColor(String coupleId, int? argb) => _couples
      .doc(coupleId)
      .update({'togetherColor': argb ?? FieldValue.delete()});

  /// 커플에서 나간다. 상대에게는 연결 대기 상태로 보이고, 함께 쓴 기록은 커플 문서에 남는다.
  Future<void> disconnect(UserProfile me) async {
    final coupleId = me.coupleId;
    if (coupleId == null) return;
    final batch = _db.batch()
      ..update(_couples.doc(coupleId), {
        'members': FieldValue.arrayRemove([me.uid]),
      })
      ..update(_users.doc(me.uid), {'coupleId': FieldValue.delete()});
    await batch.commit();
  }

  String _generateCode() => List.generate(
    codeLength,
    (_) => _codeAlphabet[_random.nextInt(_codeAlphabet.length)],
  ).join();
}
