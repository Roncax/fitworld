import * as admin from "firebase-admin";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { onDocumentCreated } from "firebase-functions/v2/firestore";

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

// ---------------------------------------------------------------------------
// Nightly decay job — runs every day at 02:00 UTC
// ---------------------------------------------------------------------------
export const nightlyDecay = onSchedule("0 2 * * *", async () => {
  const usersSnap = await db.collection("users").listDocuments();

  for (const userDoc of usersSnap) {
    await processUserDecay(userDoc.id);
  }
});

async function processUserDecay(userId: string): Promise<void> {
  const charsSnap = await db
    .collection("users")
    .doc(userId)
    .collection("characters")
    .get();

  if (charsSnap.empty) return;

  const now = Date.now();
  const batch = db.batch();
  const dyingCharacters: string[] = [];
  const deadCharacters: string[] = [];

  for (const doc of charsSnap.docs) {
    const data = doc.data();
    const lastActivity: admin.firestore.Timestamp = data.lastActivityAt;
    const daysSince = Math.floor(
      (now - lastActivity.toMillis()) / (1000 * 60 * 60 * 24)
    );

    if (daysSince <= 0) continue;

    const decayAmount = daysSince * 3;
    const newHp = Math.max(0, (data.hp as number) - decayAmount);
    const maxHp: number = data.maxHp;

    if (newHp <= 0) {
      // Character dies
      batch.delete(doc.ref);
      deadCharacters.push(data.class as string);
    } else {
      batch.update(doc.ref, { hp: newHp });
      // Warn if below 25%
      if (newHp / maxHp < 0.25) {
        dyingCharacters.push(data.class as string);
      }
    }
  }

  await batch.commit();

  // Send push notifications
  await sendDecayNotifications(userId, dyingCharacters, deadCharacters);

  // Update world health
  await updateWorldHealth(userId);
}

async function sendDecayNotifications(
  userId: string,
  dying: string[],
  dead: string[]
): Promise<void> {
  if (dying.length === 0 && dead.length === 0) return;

  // Get FCM token from user meta
  const metaDoc = await db
    .collection("users")
    .doc(userId)
    .collection("meta")
    .doc("world")
    .get();

  const fcmToken = metaDoc.data()?.fcmToken as string | undefined;
  if (!fcmToken) return;

  if (dead.length > 0) {
    const names = dead.map(classToName).join(", ");
    await messaging.send({
      token: fcmToken,
      notification: {
        title: "Personaggi morti!",
        body: `${names} ${dead.length === 1 ? "e' scomparso" : "sono scomparsi"} dal tuo mondo. Torna ad allenarti!`,
      },
      android: {
        notification: { channelId: "fitworld_decay" },
      },
    });
  } else if (dying.length > 0) {
    const names = dying.map(classToName).join(", ");
    await messaging.send({
      token: fcmToken,
      notification: {
        title: "Personaggi in pericolo!",
        body: `${names} ${dying.length === 1 ? "sta" : "stanno"} perdendo forza. Allenati per salvarli!`,
      },
      android: {
        notification: { channelId: "fitworld_decay" },
      },
    });
  }
}

async function updateWorldHealth(userId: string): Promise<void> {
  const charsSnap = await db
    .collection("users")
    .doc(userId)
    .collection("characters")
    .get();

  let health = 10;
  if (!charsSnap.empty) {
    const avgRatio =
      charsSnap.docs.reduce((sum, doc) => {
        const d = doc.data();
        return sum + (d.hp as number) / (d.maxHp as number);
      }, 0) / charsSnap.size;
    health = Math.round(avgRatio * 100);
  }

  await db
    .collection("users")
    .doc(userId)
    .collection("meta")
    .doc("world")
    .set({ health, lastDecayRun: admin.firestore.FieldValue.serverTimestamp() },
      { merge: true });
}

// ---------------------------------------------------------------------------
// On new character created — welcome notification
// ---------------------------------------------------------------------------
export const onCharacterCreated = onDocumentCreated(
  "users/{userId}/characters/{charId}",
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    const userId = event.params.userId;
    const metaDoc = await db
      .collection("users")
      .doc(userId)
      .collection("meta")
      .doc("world")
      .get();

    const fcmToken = metaDoc.data()?.fcmToken as string | undefined;
    if (!fcmToken) return;

    await messaging.send({
      token: fcmToken,
      notification: {
        title: "Nuovo personaggio nato!",
        body: `Un ${classToName(data.class as string)} e' apparso nel tuo mondo dal tuo allenamento.`,
      },
      android: {
        notification: { channelId: "fitworld_events" },
      },
    });
  }
);

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
function classToName(cls: string): string {
  const names: Record<string, string> = {
    warrior: "Guerriero",
    ranger: "Ranger",
    knight: "Cavaliere",
    mage: "Mago",
    assassin: "Assassino",
    druid: "Druido",
  };
  return names[cls] ?? cls;
}
