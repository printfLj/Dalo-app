import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { after, before, beforeEach, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  Timestamp,
  collection,
  doc,
  getDoc,
  getDocs,
  runTransaction,
  serverTimestamp,
  setDoc,
  updateDoc,
} from 'firebase/firestore';

const projectId = 'demo-dalo-security';
let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId,
    firestore: {
      rules: await readFile(new URL('../firestore.rules', import.meta.url), 'utf8'),
      host: '127.0.0.1',
      port: 8088,
    },
  });
});

after(async () => env?.cleanup());
beforeEach(async () => env.clearFirestore());

const auth = (uid, email = `${uid}@udd.edu.ph`, verified = true) =>
  env.authenticatedContext(uid, {
    email,
    email_verified: verified,
  }).firestore();

async function seed() {
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    const batch = db.batch();
    batch.set(doc(db, 'users/owner'), {
      email: 'owner@udd.edu.ph', displayName: 'Event Owner', role: 'student',
      createdAt: Timestamp.now(),
    });
    batch.set(doc(db, 'users/student'), {
      email: 'student@udd.edu.ph', displayName: 'Test Student', role: 'student',
      createdAt: Timestamp.now(),
    });
    batch.set(doc(db, 'users/facilitator'), {
      email: 'facilitator@udd.edu.ph', displayName: 'Event Helper', role: 'facilitator',
      createdAt: Timestamp.now(),
    });
    batch.set(doc(db, 'users/another'), {
      email: 'another@udd.edu.ph', displayName: 'Another Student', role: 'student',
      createdAt: Timestamp.now(),
    });
    batch.set(doc(db, 'users/unverified'), {
      email: 'new@udd.edu.ph', displayName: 'New Student', role: 'student',
      createdAt: Timestamp.now(),
    });
    batch.set(doc(db, 'events/open'), eventData({ capacity: 1 }));
    await batch.commit();
  });
}

function eventData(overrides = {}) {
  return {
    title: 'Campus Forum',
    date: Timestamp.fromDate(new Date('2026-12-01T08:00:00Z')),
    time: '8:00 AM',
    location: 'Campus Hall',
    capacity: 2,
    registeredCount: 0,
    organizerUid: 'owner',
    organizerName: 'Event Owner',
    createdAt: Timestamp.now(),
    ...overrides,
  };
}

function registrationData(uid, overrides = {}) {
  return {
    eventId: 'open',
    studentUid: uid,
    studentName: 'Test Student',
    studentEmail: `${uid}@udd.edu.ph`,
    qrToken: 'A'.repeat(43),
    status: 'registered',
    registeredAt: Timestamp.now(),
    checkedInAt: null,
    ...overrides,
  };
}

test('only verified institution accounts can browse events', async () => {
  await seed();
  await assertSucceeds(getDocs(collection(auth('student'), 'events')));
  await assertFails(getDocs(collection(auth('outsider', 'person@example.com'), 'events')));
  await assertFails(getDocs(collection(auth('unverified', 'new@udd.edu.ph', false), 'events')));
  await assertFails(getDocs(collection(env.unauthenticatedContext().firestore(), 'events')));
});

test('profiles are private and users cannot grant themselves a role', async () => {
  await seed();
  const studentDb = auth('student');
  await assertSucceeds(getDoc(doc(studentDb, 'users/student')));
  await assertFails(getDoc(doc(studentDb, 'users/owner')));
  await assertFails(updateDoc(doc(studentDb, 'users/student'), { role: 'facilitator' }));
  await assertSucceeds(setDoc(doc(auth('new-student'), 'users/new-student'), {
    email: 'new-student@udd.edu.ph', displayName: 'New Student', role: 'student',
    createdAt: serverTimestamp(),
  }));
  await assertFails(setDoc(doc(auth('self-appointed'), 'users/self-appointed'), {
    email: 'self-appointed@udd.edu.ph', displayName: 'Self Appointed',
    role: 'facilitator', createdAt: Timestamp.now(),
  }));
});

test('verified users can create valid events only under their own identity', async () => {
  await seed();
  const db = auth('owner');
  await assertSucceeds(setDoc(doc(db, 'events/new-event'), eventData({
    organizerUid: 'owner', organizerName: 'Event Owner', createdAt: serverTimestamp(),
  })));
  await assertFails(setDoc(doc(db, 'events/spoofed'), eventData({
    organizerUid: 'student', organizerName: 'Someone Else',
  })));
  await assertFails(setDoc(doc(db, 'events/too-large'), eventData({ capacity: 501 })));
});

test('registration atomically respects capacity and unique registration IDs', async () => {
  await seed();
  const db = auth('student');
  const eventRef = doc(db, 'events/open');
  const registrationRef = doc(db, 'registrations/open_student');
  await assertSucceeds(runTransaction(db, async (transaction) => {
    const event = await transaction.get(eventRef);
    transaction.set(registrationRef, registrationData('student', {
      registeredAt: serverTimestamp(),
    }));
    transaction.update(eventRef, { registeredCount: event.data().registeredCount + 1 });
  }));
  const anotherDb = auth('another');
  await assertFails(runTransaction(anotherDb, async (transaction) => {
    const anotherEventRef = doc(anotherDb, 'events/open');
    const event = await transaction.get(anotherEventRef);
    transaction.set(doc(anotherDb, 'registrations/open_another'), registrationData('another', {
      studentName: 'Another Student', registeredAt: serverTimestamp(),
    }));
    transaction.update(anotherEventRef, { registeredCount: event.data().registeredCount + 1 });
  }));
  await assertFails(setDoc(doc(db, 'registrations/open_student'), registrationData('student')));
  await assertFails(setDoc(doc(auth('owner'), 'registrations/open_owner'), registrationData('owner', {
    studentName: 'Event Owner', studentEmail: 'owner@udd.edu.ph',
  })));
  await assertFails(setDoc(doc(auth('facilitator'), 'registrations/open_facilitator'), registrationData('facilitator', {
    studentName: 'Event Helper', studentEmail: 'facilitator@udd.edu.ph',
  })));
});

test('registration records are visible only to their student and event managers', async () => {
  await seed();
  await env.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), 'registrations/open_student'), registrationData('student'));
  });
  await assertSucceeds(getDoc(doc(auth('student'), 'registrations/open_student')));
  await assertSucceeds(getDoc(doc(auth('owner'), 'registrations/open_student')));
  await assertFails(getDoc(doc(auth('another'), 'registrations/open_student')));
  await assertFails(getDoc(doc(auth('unverified', 'new@udd.edu.ph', false), 'registrations/open_student')));
});

test('only an event owner may check in, and a registration cannot be checked in twice', async () => {
  await seed();
  await env.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), 'registrations/open_student'), registrationData('student'));
  });
  await assertFails(updateDoc(doc(auth('student'), 'registrations/open_student'), {
    status: 'checkedIn', checkedInAt: serverTimestamp(),
  }));
  await assertSucceeds(updateDoc(doc(auth('owner'), 'registrations/open_student'), {
    status: 'checkedIn', checkedInAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(doc(auth('owner'), 'registrations/open_student'), {
    status: 'checkedIn', checkedInAt: serverTimestamp(),
  }));
});
