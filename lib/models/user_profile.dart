import 'package:cloud_firestore/cloud_firestore.dart';

/// `users/{uid}` 문서.
class UserProfile {
  const UserProfile({
    required this.uid,
    this.name = '',
    this.birthday,
    this.photoUrl,
    this.email,
    this.coupleId,
  });

  final String uid;
  final String name;
  final DateTime? birthday;
  final String? photoUrl;
  final String? email;
  final String? coupleId;

  bool get isComplete => name.trim().isNotEmpty;

  factory UserProfile.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return UserProfile(
      uid: doc.id,
      name: data['name'] as String? ?? '',
      birthday: parseDate(data['birthday'] as String?),
      photoUrl: data['photoUrl'] as String?,
      email: data['email'] as String?,
      coupleId: data['coupleId'] as String?,
    );
  }
}

/// `couples/{id}` 문서.
class Couple {
  const Couple({
    required this.id,
    required this.members,
    this.startDate,
    this.calendarName,
    this.inviteCode,
    this.inviteExpiresAt,
  });

  final String id;
  final List<String> members;
  final DateTime? startDate;

  /// 정하지 않았으면 null (기본 이름을 쓴다).
  final String? calendarName;

  /// 상대가 아직 합류하지 않았을 때만 있다.
  final String? inviteCode;
  final DateTime? inviteExpiresAt;

  bool get isConnected => members.length == 2;

  String? partnerOf(String uid) => members.where((m) => m != uid).firstOrNull;

  factory Couple.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return Couple(
      id: doc.id,
      members: List<String>.from(data['members'] as List? ?? const []),
      startDate: parseDate(data['startDate'] as String?),
      calendarName: data['calendarName'] as String?,
      inviteCode: data['inviteCode'] as String?,
      inviteExpiresAt: (data['inviteExpiresAt'] as Timestamp?)?.toDate(),
    );
  }
}

/// 날짜만 필요한 값(생일, 사귄 날)은 시간대 영향을 받지 않도록 "yyyy-MM-dd" 문자열로 저장한다.
String formatDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

DateTime? parseDate(String? s) {
  if (s == null) return null;
  final parts = s.split('-').map(int.tryParse).toList();
  if (parts.length != 3 || parts.contains(null)) return null;
  return DateTime(parts[0]!, parts[1]!, parts[2]!);
}
