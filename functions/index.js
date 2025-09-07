
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { CloudTasksClient } = require('@google-cloud/tasks');

admin.initializeApp();
const db = admin.firestore();

exports.scheduleTracking = functions.firestore
  .document("jobs/{jobId}")
  .onUpdate(async (change, context) => {
    const jobId = context.params.jobId;
    const before = change.before.data() || {};
    const after = change.after.data() || {};

    // React only when status changes (or provider assigned)
    if (before.status === after.status && before.providerId === after.providerId) return null;
    if (!after.providerId) return null;

    // If status already en_route or tracking, start immediately
    const scheduledStart = after.scheduledStart ? new Date(after.scheduledStart) : null;
    const providerId = after.providerId;

    if (!scheduledStart) {
      // No scheduled start: start tracking now
      await db.collection('locations').doc(providerId).set({
        activeJob: jobId,
        startedAt: admin.firestore.FieldValue.serverTimestamp(),
        status: "tracking"
      }, { merge: true });
      return null;
    }

    const triggerTime = new Date(scheduledStart.getTime() - 10 * 60 * 1000); // 10 min before
    const now = new Date();

    if (triggerTime <= now) {
      // start now
      await db.collection('locations').doc(providerId).set({
        activeJob: jobId,
        startedAt: admin.firestore.FieldValue.serverTimestamp(),
        status: "tracking"
      }, { merge: true });
      return null;
    }

    // Schedule Cloud Task
    const client = new CloudTasksClient();
    const project = process.env.GCP_PROJECT || process.env.GCLOUD_PROJECT;
    const location = process.env.TASKS_LOCATION || 'us-central1';
    const queue = process.env.TASKS_QUEUE || 'tracking-queue';
    const parent = client.queuePath(project, location, queue);

    const url = `https://${location}-${project}.cloudfunctions.net/startTracking`;

    const payload = { providerId, jobId };
    const task = {
      httpRequest: {
        httpMethod: 'POST',
        url,
        headers: { 'Content-Type': 'application/json' },
        body: Buffer.from(JSON.stringify(payload)).toString('base64'),
      },
      scheduleTime: {
        seconds: Math.floor(triggerTime.getTime() / 1000),
      },
    };

    try {
      const [response] = await client.createTask({ parent, task });
      console.log('Created task:', response.name);
    } catch (err) {
      console.error('Error creating task', err);
    }
    return null;
  });

exports.startTracking = functions.https.onRequest(async (req, res) => {
  try {
    const { providerId, jobId } = req.body || {};
    if (!providerId || !jobId) {
      res.status(400).send('Missing providerId or jobId');
      return;
    }
    await db.collection('locations').doc(providerId).set({
      activeJob: jobId,
      startedAt: admin.firestore.FieldValue.serverTimestamp(),
      status: "tracking"
    }, { merge: true });
    res.status(200).send('Tracking started');
  } catch (e) {
    console.error(e);
    res.status(500).send('Internal error');
  }
});
