
# Firebase Cloud Functions for SnowGo

This folder contains two functions:
- `scheduleTracking`: triggered on `jobs/{jobId}` updates. Schedules or starts tracking.
- `startTracking`: HTTP endpoint intended to be called by Cloud Tasks to flip provider to tracking status.

Setup:
1. Enable Cloud Tasks API in Google Cloud Console.
2. Create a queue, for example:
   gcloud tasks queues create tracking-queue --location=us-central1
3. Deploy functions:
   firebase deploy --only functions

Ensure environment variables TASKS_LOCATION and TASKS_QUEUE are set if you use a different location/queue.
