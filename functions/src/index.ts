import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import { v4 as uuidv4 } from "uuid";
import * as nodemailer from "nodemailer";
import * as QRCode from "qrcode";

admin.initializeApp();
const db = admin.firestore();

function escapeHtml(value: string): string {
  return value.replace(/[&<>\"']/g, (character) => {
    const entities: Record<string, string> = {
      "&": "&amp;",
      "<": "&lt;",
      ">": "&gt;",
      '\"': "&quot;",
      "'": "&#39;",
    };
    return entities[character];
  });
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/** Send a registration confirmation email. Returns false if not configured. */
async function sendConfirmationEmail(params: {
  toEmail: string;
  toName: string;
  eventTitle: string;
  eventDate: string;
  eventTime: string;
  eventLocation: string;
  qrToken: string;
}): Promise<boolean> {
  // Read mail config from Firebase environment variables.
  // Set with: firebase functions:config:set mail.host="..." mail.port="587"
  //   mail.user="your@email.com" mail.pass="yourpassword" mail.from="Daló <noreply@yourdomain.com>"
  const cfg = functions.config().mail as
    | { host?: string; port?: string; user?: string; pass?: string; from?: string }
    | undefined;

  if (!cfg?.host || !cfg?.user || !cfg?.pass) {
    functions.logger.warn(
      "Email not configured — skipping confirmation email. " +
        "Set mail.host, mail.port, mail.user, mail.pass, mail.from via firebase functions:config:set."
    );
    return false;
  }

  const transporter = nodemailer.createTransport({
    host: cfg.host,
    port: parseInt(cfg.port ?? "587", 10),
    secure: parseInt(cfg.port ?? "587", 10) === 465,
    auth: { user: cfg.user, pass: cfg.pass },
  });

  const qrPng = await QRCode.toBuffer(params.qrToken, {
    type: "png",
    width: 280,
    margin: 2,
  });

  const html = `
    <div style="font-family: sans-serif; max-width: 480px; margin: 0 auto;">
      <h2 style="font-weight: 700;">You're registered! 🎉</h2>
      <p>Hi ${escapeHtml(params.toName)},</p>
      <p>Your registration for <strong>${escapeHtml(params.eventTitle)}</strong> is confirmed.</p>
      <table style="border-collapse: collapse; margin: 16px 0;">
        <tr><td style="padding: 4px 12px 4px 0;color:#666">Date</td><td>${escapeHtml(params.eventDate)}</td></tr>
        <tr><td style="padding: 4px 12px 4px 0;color:#666">Time</td><td>${escapeHtml(params.eventTime)}</td></tr>
        <tr><td style="padding: 4px 12px 4px 0;color:#666">Location</td><td>${escapeHtml(params.eventLocation)}</td></tr>
      </table>
      <p>Show this QR code at the event entrance:</p>
      <p><img src="cid:dalo-ticket-qr" alt="Daló event ticket QR code" width="280" height="280" /></p>
      <p style="color:#888;font-size:12px;">This token is unique to your registration. Keep it safe.</p>
      <p>See you there!<br/>— Daló</p>
    </div>
  `;

  await transporter.sendMail({
    from: cfg.from ?? cfg.user,
    to: params.toEmail,
    subject: `Your ticket: ${params.eventTitle}`,
    html,
    attachments: [
      {
        filename: "dalo-ticket-qr.png",
        content: qrPng,
        contentType: "image/png",
        cid: "dalo-ticket-qr",
      },
    ],
  });

  return true;
}

// ---------------------------------------------------------------------------
// registerForEvent
// Atomically checks capacity, creates registration, increments counter.
// ---------------------------------------------------------------------------
export const registerForEvent = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "You must be signed in to register."
      );
    }

    const { eventId } = data as { eventId: string };

    if (!eventId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Missing event ID."
      );
    }

    if (context.auth.token.email_verified !== true) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Verify your student email before registering."
      );
    }

    const studentUid = context.auth.uid;
    const userSnap = await db.collection("users").doc(studentUid).get();
    const user = userSnap.data();
    if (!userSnap.exists || user?.role !== "student") {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Only student accounts can register for events."
      );
    }

    const studentName = String(user.displayName ?? "").trim();
    const studentEmail = String(context.auth.token.email ?? "").trim();
    if (!studentName || !studentEmail) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Your account profile is incomplete."
      );
    }

    const allowedStudentDomains = String(
      functions.config().student?.email_domains ??
        functions.config().student?.email_domain ??
        ""
    )
      .split(",")
      .map((domain: string) => domain.trim().replace(/^@/, "").toLowerCase())
      .filter(Boolean);
    if (allowedStudentDomains.length === 0) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "The allowed student email domain has not been configured."
      );
    }
    const studentDomain = studentEmail.trim().toLowerCase().split("@").pop();
    if (!studentDomain || !allowedStudentDomains.includes(studentDomain)) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Use an email address from your institution."
      );
    }

    const eventRef = db.collection("events").doc(eventId);
    const regRef = db
      .collection("registrations")
      .doc(`${eventId}_${studentUid}`);

    const qrToken = uuidv4(); // opaque, no personal data
    const registrationId = regRef.id;

    await db.runTransaction(async (tx) => {
      const regDoc = await tx.get(regRef);
      if (regDoc.exists) {
        throw new functions.https.HttpsError(
          "already-exists",
          "You are already registered for this event."
        );
      }

      const eventDoc = await tx.get(eventRef);
      if (!eventDoc.exists) {
        throw new functions.https.HttpsError(
          "not-found",
          "Event not found."
        );
      }

      const eventData = eventDoc.data()!;
      const capacity: number = eventData.capacity ?? 0;
      const registeredCount: number = eventData.registeredCount ?? 0;

      if (registeredCount >= capacity) {
        throw new functions.https.HttpsError(
          "resource-exhausted",
          "This event is full. Registration is closed."
        );
      }

      tx.set(regRef, {
        eventId,
        studentUid,
        studentName,
        studentEmail,
        qrToken,
        status: "registered",
        registeredAt: admin.firestore.FieldValue.serverTimestamp(),
        checkedInAt: null,
      });

      tx.update(eventRef, {
        registeredCount: admin.firestore.FieldValue.increment(1),
      });
    });

    // Send confirmation email (non-blocking; don't fail registration if email fails)
    const eventSnap = await eventRef.get();
    const ed = eventSnap.data()!;
    const dateObj: admin.firestore.Timestamp = ed.date;
    const d = dateObj.toDate();
    const dateStr = `${d.getDate()} ${[
      "Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"
    ][d.getMonth()]} ${d.getFullYear()}`;

    await sendConfirmationEmail({
      toEmail: studentEmail,
      toName: studentName,
      eventTitle: ed.title,
      eventDate: dateStr,
      eventTime: ed.time,
      eventLocation: ed.location,
      qrToken,
    }).catch((err) =>
      functions.logger.error("Email send failed:", err)
    );

    return { registrationId };
  }
);

// ---------------------------------------------------------------------------
// checkInByQrToken
// Atomically validates and marks a registration as checked-in by QR token.
// ---------------------------------------------------------------------------
export const checkInByQrToken = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "You must be signed in."
      );
    }

    // Verify caller has facilitator role
    const callerDoc = await db
      .collection("users")
      .doc(context.auth.uid)
      .get();
    const callerRole = callerDoc.data()?.role as string | undefined;
    if (callerRole !== "facilitator" && callerRole !== "organizer") {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Only facilitators and organizers can check in attendees."
      );
    }

    const { qrToken, expectedEventId } = data as {
      qrToken: string;
      expectedEventId: string;
    };

    if (!qrToken || !expectedEventId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Missing qrToken or expectedEventId."
      );
    }

    const regsRef = db.collection("registrations");
    const snap = await regsRef
      .where("qrToken", "==", qrToken)
      .limit(1)
      .get();

    if (snap.empty) {
      return {
        success: false,
        message: "QR code not recognised. Is this the right event?",
      };
    }

    const regRef = snap.docs[0].ref;
    return db.runTransaction(async (tx) => {
      const currentSnap = await tx.get(regRef);
      if (!currentSnap.exists) {
        return { success: false, message: "Registration not found." };
      }

      const reg = currentSnap.data()!;
      if (reg.eventId !== expectedEventId) {
        return {
          success: false,
          message: "This QR code is for a different event.",
        };
      }
      if (reg.status === "checkedIn") {
        return {
          success: false,
          message: "Already checked in.",
          studentName: reg.studentName,
        };
      }

      tx.update(regRef, {
        status: "checkedIn",
        checkedInAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      return {
        success: true,
        message: "Checked in successfully!",
        studentName: reg.studentName,
      };
    });
  }
);

// ---------------------------------------------------------------------------
// checkInByRegistrationId
// Manual check-in by registration document ID (facilitator).
// ---------------------------------------------------------------------------
export const checkInByRegistrationId = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "You must be signed in."
      );
    }

    const callerDoc = await db
      .collection("users")
      .doc(context.auth.uid)
      .get();
    const callerRole = callerDoc.data()?.role as string | undefined;
    if (callerRole !== "facilitator" && callerRole !== "organizer") {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Only facilitators and organizers can check in attendees."
      );
    }

    const { registrationId, expectedEventId } = data as {
      registrationId: string;
      expectedEventId: string;
    };

    if (!registrationId || !expectedEventId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Missing registrationId or expectedEventId."
      );
    }

    const regRef = db.collection("registrations").doc(registrationId);
    return db.runTransaction(async (tx) => {
      const regSnap = await tx.get(regRef);
      if (!regSnap.exists) {
        return { success: false, message: "Registration not found." };
      }

      const reg = regSnap.data()!;
      if (reg.eventId !== expectedEventId) {
        return {
          success: false,
          message: "Registration is for a different event.",
        };
      }
      if (reg.status === "checkedIn") {
        return {
          success: false,
          message: "Already checked in.",
          studentName: reg.studentName,
        };
      }

      tx.update(regRef, {
        status: "checkedIn",
        checkedInAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      return {
        success: true,
        message: "Checked in successfully!",
        studentName: reg.studentName,
      };
    });
  }
);
