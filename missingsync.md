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

- [ ] Sync after a workout import, not only when the app comes back
      (`sync_provider` does not call `nearbySyncProvider.syncAll()`).
- [ ] Remember the last successful sync per computer; it is only in memory,
      so after a restart the page shows nothing.
- [ ] Show progress as "n of m" for the first sync; the total is not known.
- [ ] Retry with back-off when the computer is not reachable; today a resume
      tries once (up to 4 s connect plus 5 s Bonjour).
- [ ] Android: sync from a foreground service, so the phone does not need to
      be open (iOS cannot listen in the background).
- [ ] "Delete all data" deletes the device identity from secure storage, so
      the computer keeps an orphaned pairing; tell the computer, or say so
      in the wipe dialog.
- [ ] A restore from backup on the same phone resends everything (by design);
      confirm it does not leave stale rows on the computer.

## Computer (fjelia-desktop)

- [ ] A list of paired phones with Unpair (only Pair Phone… exists).
- [ ] Keep the identity in the keychain once the app is signed with a team;
      Windows and Linux credential stores (today a file in the app folder).
- [ ] Ask for ECG waveforms on demand (the log supports it; nothing asks).
- [ ] Photos and videos: the list syncs, the files do not yet (on demand).
- [ ] A second copy of the app on the same computer shares the identity and
      the database, announces the same device id on another port, and a
      phone may reach either. Allow one copy only (bring the running one to
      the front).

## Protocol

- [ ] Different schema versions refuse to sync ("Update Fjelia on both
      devices"); allow a newer computer to accept an older phone.
- [ ] Two-way sync (M2): edits on the computer, newest change per field,
      edit rights per record, then the computer as a hub for several phones.
- [ ] Certificate renewal (the certificate is valid for ten years).
- [ ] Coach relay through fjelia-service, end-to-end encrypted.
