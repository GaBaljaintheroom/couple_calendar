// 알림 문구. Firebase 없이 테스트할 수 있도록 순수 함수로 둔다.
// 일정 문서 형식은 lib/data/event_repository.dart의 _toMap과 같다.

const WEEKDAYS = ['일', '월', '화', '수', '목', '금', '토'];

/** "2026-10-30" → "10월 30일 (금)" */
function formatDay(ymd) {
  const [y, m, d] = ymd.split('-').map(Number);
  const weekday = WEEKDAYS[new Date(Date.UTC(y, m - 1, d)).getUTCDay()];
  return `${m}월 ${d}일 (${weekday})`;
}

/** 시간 부분. 종일이면 "하루 종일". */
function formatTime(event) {
  if (!event.startTime) return '하루 종일';
  return event.endTime ? `${event.startTime} - ${event.endTime}` : event.startTime;
}

/** 상대가 일정을 등록했을 때. */
function newEventMessage(event, creatorName) {
  const when = event.endDate && event.endDate !== event.date
    ? `${formatDay(event.date)} ~ ${formatDay(event.endDate)}`
    : `${formatDay(event.date)} ${formatTime(event)}`;
  return {
    title: `${creatorName}님이 새 일정을 등록했어요`,
    body: `${event.title} · ${when}`,
  };
}

/** 당일 아침. 같은 날 일정이 여러 개면 한 번에 보낸다. */
function todayMessage(events) {
  const sorted = [...events].sort((a, b) =>
    (a.startTime || '').localeCompare(b.startTime || ''));
  const lines = sorted.map((e) =>
    e.startTime ? `${e.startTime} ${e.title}` : `${e.title} (하루 종일)`);
  return {
    title: sorted.length === 1 ? '오늘 일정이 있어요 💕' : `오늘 일정 ${sorted.length}개 💕`,
    body: lines.join('\n'),
  };
}

/** 한국 시간 기준 오늘 "yyyy-MM-dd". */
function todayInSeoul(now = new Date()) {
  const seoul = new Date(now.getTime() + 9 * 60 * 60 * 1000);
  return seoul.toISOString().slice(0, 10);
}

module.exports = { formatDay, newEventMessage, todayMessage, todayInSeoul };
