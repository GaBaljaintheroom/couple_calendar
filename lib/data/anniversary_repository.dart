import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/anniversary.dart';
import '../models/user_profile.dart';

/// 직접 등록한 기념일과 기념일별 메모.
///
/// - [AnniversaryRepository.firestore]: `couples/{coupleId}/anniversaries`와
///   `couples/{coupleId}/anniversaryMemos/{회차 id}`를 실시간 구독한다.
/// - [AnniversaryRepository.memory]: 메모리에만 저장한다 (테스트·미리보기용).
class AnniversaryRepository extends ChangeNotifier {
  AnniversaryRepository.memory({
    List<CustomAnniversary> customs = const [],
    Map<String, String> memos = const {},
  }) : _customsRef = null,
       _memosRef = null {
    _customs.addAll(customs);
    _memos.addAll(memos);
  }

  AnniversaryRepository.firestore({
    required FirebaseFirestore db,
    required String coupleId,
  }) : _customsRef = db
           .collection('couples')
           .doc(coupleId)
           .collection('anniversaries'),
       _memosRef = db
           .collection('couples')
           .doc(coupleId)
           .collection('anniversaryMemos') {
    _subscriptions.add(
      _customsRef!.snapshots().listen((snapshot) {
        _customs
          ..clear()
          ..addAll(snapshot.docs.map(_customFromDoc).nonNulls);
        notifyListeners();
      }, onError: _logError),
    );
    _subscriptions.add(
      _memosRef!.snapshots().listen((snapshot) {
        _memos
          ..clear()
          ..addEntries(
            snapshot.docs.map((d) {
              final text = d.data()['text'] as String?;
              return text == null ? null : MapEntry(d.id, text);
            }).nonNulls,
          );
        notifyListeners();
      }, onError: _logError),
    );
  }

  final CollectionReference<Map<String, dynamic>>? _customsRef;
  final CollectionReference<Map<String, dynamic>>? _memosRef;
  final List<StreamSubscription<Object?>> _subscriptions = [];
  final List<CustomAnniversary> _customs = [];
  final Map<String, String> _memos = {};

  List<CustomAnniversary> get customs => List.unmodifiable(_customs);

  String? memoFor(String anniversaryId) => _memos[anniversaryId];

  /// 비워서 저장하면 메모를 지운다.
  Future<void> setMemo(String anniversaryId, String memo) async {
    final trimmed = memo.trim();
    final ref = _memosRef;
    if (ref == null) {
      if (trimmed.isEmpty) {
        _memos.remove(anniversaryId);
      } else {
        _memos[anniversaryId] = trimmed;
      }
      notifyListeners();
      return;
    }
    if (trimmed.isEmpty) {
      await ref.doc(anniversaryId).delete();
    } else {
      await ref.doc(anniversaryId).set({
        'text': trimmed,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> add(CustomAnniversary anniversary) async {
    final ref = _customsRef;
    if (ref == null) {
      _customs.add(anniversary);
      notifyListeners();
      return;
    }
    await ref.doc(anniversary.id).set({
      'title': anniversary.title,
      'date': formatDate(anniversary.date),
      'repeatsYearly': anniversary.repeatsYearly,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// 기념일과 그 기념일에 달린 메모를 모두 지운다.
  Future<void> remove(String customId) async {
    bool ownMemo(String key) => key.startsWith('custom-$customId-');
    final customsRef = _customsRef;
    final memosRef = _memosRef;
    if (customsRef == null || memosRef == null) {
      _customs.removeWhere((c) => c.id == customId);
      _memos.removeWhere((key, _) => ownMemo(key));
      notifyListeners();
      return;
    }
    final batch = customsRef.firestore.batch()
      ..delete(customsRef.doc(customId));
    for (final key in _memos.keys.where(ownMemo)) {
      batch.delete(memosRef.doc(key));
    }
    await batch.commit();
  }

  @override
  void dispose() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    super.dispose();
  }

  static CustomAnniversary? _customFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final title = data['title'] as String?;
    final date = parseDate(data['date'] as String?);
    if (title == null || date == null) return null;
    return CustomAnniversary(
      id: doc.id,
      title: title,
      date: date,
      repeatsYearly: data['repeatsYearly'] as bool? ?? true,
    );
  }

  static void _logError(Object e) => debugPrint('기념일을 불러오지 못했어요: $e');
}
