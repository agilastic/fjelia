# Phone ↔ computer sync: what is missing

State 2026-11-26, branch `sync-m1`. Built: the change log (fjelia_data),
pairing by QR code and the HTTPS transport (fjelia_sync), finding a moved
computer by Bonjour, and on the phone Settings › System › Computers (scan,
Sync now, Unpair), with a sync whenever the app comes to the foreground.

## Not yet tried for real

- [ ] Pair and sync an iPhone and an Android phone with the Mac over a real
      Wi-Fi (only tested over loopback and in the simulator build).
- [ ] The iOS local-network prompt and the camera prompt on a device.
- [ ] A large first sync (years of activities with routes and samples):
      time, memory, what happens when the app goes to the background midway.

## Phone

- [x] Sync after a workout import, not only when the app comes back: the
      computers sync once the watch, health and history syncs are done
      (`NearbySyncNotifier.syncAfterOtherSyncs`), also on resume, and after
      a file or Strava import.
- [x] Remember the last successful sync per computer (`sync_peers.
      last_synced_ms`, on both sides); the page shows "Last synced …".
- [x] Show progress as "n of m" (`SyncClient.sync(onProgress:)`).
- [x] Retry with back-off when the computer is not reachable: syncs the
      phone starts itself try again after 5 s, 30 s and 2 min.
- [ ] Android: sync from a foreground service, so the phone does not need to
      be open (iOS cannot listen in the background).
- [x] "Delete all data" first unpairs every computer it can reach
      (`unpairAll`); one out of reach keeps the pairing until unpaired there.
- [ ] A restore from backup on the same phone resends everything (by design);
      confirm it does not leave stale rows on the computer.

## Computer (fjelia-desktop)

- [x] A list of paired phones with Unpair: File › Paired Devices…, with
      when each last synced.
- [ ] Keep the identity in the keychain once the app is signed with a team;
      Windows and Linux credential stores (today a file in the app folder).
- [x] Ask for ECG waveforms on demand: Health › ECG Recordings opens a
      recording; "Get Waveform from Phone" asks for it (`sync_wanted`,
      `GET /v1/wanted`) and the phone sends it on its next sync. The sheet
      shows ten-second strips, heart rate, HRV and signal quality.
- [ ] Photos and videos: the list syncs, the files do not yet (on demand).
- [x] One copy at a time: the database is locked while a copy has it; a
      second copy says "Fjelia Is Already Open" and quits (it cannot bring
      the first to the front from the sandbox).

## Protocol

- [x] A newer computer accepts an older phone; only a phone newer than the
      computer is refused ("Update Fjelia on both devices").
- [x] Two-way sync (M2): edits on the computer reach the phone; the newer
      change of a record both may edit wins (per record, not yet per field).
- [ ] Newest change per field instead of per record.
- [x] Sessions the computer adds to the active plan go to the watch after
      the sync (`SyncedPlanFollowUp` runs `deliverPlan`). Sessions outside
      an active plan (plan `athlete`) go only when sent by hand, as on the
      phone.
- [x] A moved, edited or skipped session reaches the phone by sync: the
      watch entry moves, is sent again or comes off (`SyncedPlanFollowUp`).
- [x] A session deleted on the computer comes off the watch: the sync
      queues its platform ids in provider_cleanups before deleting the row,
      and the follow-up after a computer sync runs the cleanup.
- [ ] Certificate renewal (the certificate is valid for ten years).
- [ ] Coach relay through fjelia-service, end-to-end encrypted.
