SnowGo demo with enhanced counter-offer and scheduled tracking. See README in chat for setup.

## Cloud Functions (JS)
- functions/index.js implements scheduleTracking and startTracking.
- Install dependencies in functions/ with `npm install` then `firebase deploy --only functions`.
- Enable Cloud Tasks API and create a queue (see functions/README.md).
