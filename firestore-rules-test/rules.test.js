// firestore.rules 테스트. 민준(a)과 서연(b)이 커플 c1이다.
const test = require('node:test');
const { readFileSync } = require('node:fs');
const path = require('node:path');
const {
  initializeTestEnvironment, assertSucceeds, assertFails,
} = require('@firebase/rules-unit-testing');
const { doc, getDoc, setDoc, updateDoc, deleteDoc } = require('firebase/firestore');

let env;

test.before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-daylog',
    firestore: { rules: readFileSync(path.join(__dirname, '../firestore.rules'), 'utf8') },
  });
});
test.after(() => env.cleanup());

test.beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'couples/c1'), { members: ['a', 'b'] });
    const event = (owner, createdBy) => ({ title: '일정', date: '2026-10-30', owner, createdBy });
    await setDoc(doc(db, 'couples/c1/events/mine'), event('a', 'a'));
    await setDoc(doc(db, 'couples/c1/events/partners'), event('b', 'b'));
    await setDoc(doc(db, 'couples/c1/events/together-by-b'), event('together', 'b'));
    await setDoc(doc(db, 'couples/c1/anniversaries/x'), { title: '기념일' });
  });
});

const as = (uid) => env.authenticatedContext(uid).firestore();
const minjun = () => as('a');

test('둘 다 모든 일정을 볼 수 있다', async () => {
  await assertSucceeds(getDoc(doc(minjun(), 'couples/c1/events/partners')));
});

test('내가 등록한 일정은 고치고 지울 수 있다', async () => {
  await assertSucceeds(updateDoc(doc(minjun(), 'couples/c1/events/mine'), { title: '수정' }));
  await assertSucceeds(deleteDoc(doc(minjun(), 'couples/c1/events/mine')));
});

test('상대가 등록한 "우리 함께" 일정도 고치고 지울 수 있다', async () => {
  await assertSucceeds(updateDoc(doc(minjun(), 'couples/c1/events/together-by-b'), { title: '수정' }));
  await assertSucceeds(deleteDoc(doc(minjun(), 'couples/c1/events/together-by-b')));
});

test('상대가 등록한 상대 일정은 고치거나 지울 수 없다', async () => {
  await assertFails(updateDoc(doc(minjun(), 'couples/c1/events/partners'), { title: '수정' }));
  await assertFails(deleteDoc(doc(minjun(), 'couples/c1/events/partners')));
});

test('등록자를 바꿔 치기할 수 없다', async () => {
  // 함께 일정을 고치면서 등록자를 나로 바꾸면 안 된다.
  await assertFails(updateDoc(doc(minjun(), 'couples/c1/events/together-by-b'), { createdBy: 'a' }));
  // 새 일정의 등록자는 반드시 나.
  await assertFails(setDoc(doc(minjun(), 'couples/c1/events/new'), { title: '새', owner: 'b', createdBy: 'b' }));
  await assertSucceeds(setDoc(doc(minjun(), 'couples/c1/events/new'), { title: '새', owner: 'b', createdBy: 'a' }));
});

test('커플이 아닌 사람은 일정도 기념일도 볼 수 없다', async () => {
  await assertFails(getDoc(doc(as('z'), 'couples/c1/events/mine')));
  await assertFails(getDoc(doc(as('z'), 'couples/c1/anniversaries/x')));
});

test('기념일은 지금처럼 둘 다 자유롭게 쓸 수 있다', async () => {
  await assertSucceeds(updateDoc(doc(minjun(), 'couples/c1/anniversaries/x'), { title: '수정' }));
  await assertSucceeds(setDoc(doc(as('b'), 'couples/c1/anniversaryMemos/m'), { memo: '선물' }));
  await assertSucceeds(deleteDoc(doc(minjun(), 'couples/c1/anniversaries/x')));
});
