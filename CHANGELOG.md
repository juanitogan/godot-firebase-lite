# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

#### Todo
- More FB-array-fakie testing. (Hard to care about this.)
- OAuth and other missing auths.  (I'm not likely to do this myself since I don't need it and it looks to be a mountain of work.)

#### Done


<!-- Don't forget to change version in firebase.gd, README.md, and footer here. -->

## [0.1.0] - 2021-04-05

This is a total rewrite of the Firebase Realtime Database and Auth code found at [GodotFirebase commit #151](https://github.com/GodotNuts/GodotFirebase/commit/0dcabd4f410058c656d3f000ad733990edf42e3c).  All other non-RTDB code has been removed as I don't need it and, given this redux, it will not work with the new (old) paradigm presented here.

Changes are too many to list in detail (I did say this was a rewrite and not just a refactor) but, below, is a high-level overview of what to expect if moving from that other project.

Also, if coming from that other project, don't forget to delete it's lines from your `override.cfg` file (or remove the whole file if nothing else in it).  Then, go into Project Settings and null out all the Firebase envars from General, trash Firebase from AutoLoad, and kill anything else it might have loaded.  You might need to restart to work out any lingering or cyclic dependencies.

### FirebaseAppLite API:

### Added
- Added a FirebaseApp class and related changes to the Firebase class for managing multiple apps in addition to the default app.  This included adding the `initialize_app()` method to Firebase.
- Added a FirebaseError class.  This was necessary to overcome limitations in the GDScript language.  This is not unlike how `JSON.parse()` returns a JSONParseResult object, and is a bit less abstract than that.

### Changed
- I see no reason for any of this to be an editor plugin, so it is now just an API -- a collection of "Script Classes" -- that you can drop anywhere in your code tree (and probably not under `res://addons` which is where plugins work best and non-plugin classes still work but without their fancy icon).  Godot's docs recommends script classes when you don't need an editor interface.  Many small changes related to this.
- Similarly, I see no reason to put a Firebase config in ProjectSettings via override.cfg.  Cute... but why limit yourself to one Firebase app or database (I need more) and why bury it under such complication?  Now, just throw your config into a dict and pass it into `fb.initialize_app(config)` to init the default app, or `fb.initialize_app(config, "SomeAppName")` to init another app.
- Both FirebaseAuthLite and FirebaseDatabaseLite are now optional APIs under the required FirebaseAppLite API.  Their folders can be removed and the app should still build (not that you would want to remove both, but one or the other if you don't need it).

### Removed
- Removed the authoritarian requirement for authentication.  Firebase doesn't impose this on you, so why should I?  How you choose to protect your data, or not, is up to you.
- Removed all code related to Firestore and Storage.  I don't have time to rewrite them to match the new paradigm here.
- Removed the test and doc tools.  I don't have time for them either [yes, famous last words]; although, I do have a fairly rigorous tester app that I may adapt back into unit testing at some point.

### FirebaseDatabaseLite API:

### Added
- Added `enable_listener()` and `disable_listener()` methods for discrete control of the listener on a db ref.  If you don't need the listener, no need to enable it.
- New listener signals modeled after the JS SDK:
  - `data_changed(snapshot)`
  - `child_added(snapshot)`
  - `child_changed(snapshot)`
  - `child_removed(snapshot)`
- Deep-path updates are now supported in listener events to keep the local snapshot in sync.
- [Firebase array fakies](https://firebase.googleblog.com/2014/04/best-practices-arrays-in-firebase.html) are now well supported in listener events to keep the local snapshot in sync (one can hope).
- Added `get_reference_lite()` if not using array fakies in your db (and you shouldn't).  May nix this idea as the code is not much smaller.
- Added `fetch()` (get), `put()` (set), and `remove()` methods to finish out the CRUD methods.  (`get()` and `set()` are reserved by the Object class.)
- Added the `ServerValue` helper class and its `TIMESTAMP` constant and `increment()` method.
- Added the `app` property to FirebaseDatabase.
- Added the `key` and `path` properties to FirebaseReference.

### Changed
- Local storage is now called a snapshot like many other SDKs.  Various things renamed to match.
- Object setup now done primarily through `_init()` instead of a weird array of methods.
- `get_data()` renamed to `fetch_local()`.
- `push()` and `update()` were rewritten to yield until the HTTP request is complete.  This allows yielding to them, when needed, instead of the more complicated signaling paradigm.  They also now return an object or error code.  `update()` no longer accepts a path parameter -- such things should be included in the dictionary keys if needed.

### Fixed
- Wrote a new `HTTPSSEClient` class that is more concise and with a more robust event parser that can also handle multiple events.  Also, this is no longer an editor plugin either.

### Removed
- Removed put and patch listener signals: `new_data_update` and `patch_data_update`.  Put and patch are internal events, processed by the snapshot, and are used to generate more useful listener signals.
- Removed `push()` signals: `push_successful` and `push_failed`.  It doesn't try to queue pushes anymore either.  If you need to queue pushes, you are either doing it wrong, or should manage it yourself.  See new usage of `push()` and other CRUD methods.
- Filtering has been removed until it can be done right... if ever.  May not ever be part of this "lite" version.

### FirebaseAuthLite API:

### Added
- Added an IdTokenResult fake class (dictionary) under FirebaseUser with properties useful to keeping the session alive.
- Added `verify_before_update_email()` for sending a verification email to a new address (instead of the current address like `send_email_verification()` does).

### Changed
- Um... uh... I don't know where to start.  It basically worked like this: throw everything out and start from scratch.  Nothing was worth saving.
- The main auth class is still called FirebaseAuth but it doesn't resemble the other one much.  It extents Node rather than HTTPRequest (extending HTTPRequest was a cute idea, I guess, but it also makes things more complicated than they need to be).  I suspect all the signals, properties, and methods are different... and don't care to dig to prove otherwise.  Signaling is much different/simplified, and based on the JS SDK.  Many of the methods that the other project put here were put in the FirebaseUser class instead (again, modeled after the JS SDK).
- The FirebaseUserData class was dumped for a much-more-functional FirebaseUser class.
- Everything uses the same yield paradigm that FirebaseDatabaseLite was rewritten to use (see above).

### Removed
- Removed the weird cut-n-paste Google OAuth until OAuth, in general, can be done right from the end-user point of view (and with provider objects and all that).
- Removed the intrinsic ID token keep-alive code and timer.  If this is how the dev wants to keep sessions alive, they should do this themselves rather than have it shoved down their throat.
- Removed `get_user_data()` and automated it with every sign in and reload.  So, yes, I shove this one down the dev's throat (but I stole this idea from the JS SDK -- it's kinda critical to the architecture... or will be).



[Unreleased]: https://github.com/juanitogan/godotfirebaselite/compare/0.1.0...HEAD
<!-- [0.1.1]: https://github.com/juanitogan/godotfirebaselite/compare/0.1.0...0.1.1 -->
[0.1.0]: https://github.com/juanitogan/godotfirebaselite/releases/tag/0.1.0
