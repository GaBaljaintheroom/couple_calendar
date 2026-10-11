const test = require('node:test');
const assert = require('node:assert/strict');
const { formatDay, newEventMessage, todayMessage, todayInSeoul } = require('../messages');

test('날짜를 "M월 d일 (요일)"로 쓴다', () => {
  assert.equal(formatDay('2026-10-30'), '10월 30일 (금)');
  assert.equal(formatDay('2026-01-04'), '1월 4일 (일)');
});

test('새 일정 알림: 시간 있는 일정, 종일, 여러 날', () => {
  assert.deepEqual(
    newEventMessage({ title: '저녁 데이트', date: '2026-10-30', startTime: '19:00', endTime: '21:00' }, '서진'),
    { title: '서진님이 새 일정을 등록했어요', body: '저녁 데이트 · 10월 30일 (금) 19:00 - 21:00' },
  );
  assert.equal(
    newEventMessage({ title: '휴가', date: '2026-10-30', startTime: null }, '준수').body,
    '휴가 · 10월 30일 (금) 하루 종일',
  );
  assert.equal(
    newEventMessage({ title: '워크숍', date: '2026-10-30', endDate: '2026-10-31', startTime: '12:00' }, '서진').body,
    '워크숍 · 10월 30일 (금) ~ 10월 31일 (토)',
  );
});

test('오늘 일정 알림: 종일 일정이 먼저, 시간순', () => {
  assert.deepEqual(todayMessage([{ title: '영화', startTime: '14:00' }]), {
    title: '오늘 일정이 있어요 💕',
    body: '14:00 영화',
  });
  assert.deepEqual(
    todayMessage([
      { title: '저녁', startTime: '19:00' },
      { title: '휴가', startTime: null },
      { title: '점심', startTime: '12:00' },
    ]),
    { title: '오늘 일정 3개 💕', body: '휴가 (하루 종일)\n12:00 점심\n19:00 저녁' },
  );
});

test('한국 시간 기준 오늘: UTC로 전날 23시 = 서울 다음날 8시', () => {
  assert.equal(todayInSeoul(new Date('2026-10-29T23:00:00Z')), '2026-10-30');
  assert.equal(todayInSeoul(new Date('2026-10-30T14:59:00Z')), '2026-10-30');
});
