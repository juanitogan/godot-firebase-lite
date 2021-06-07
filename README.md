# ![Godot Firebase Lite Logo](icon.png) Godot Firebase Lite

> Yet another Godot package for Firebase.  The dumb one that simply works.

This project targets [Firebase Realtime Database](https://firebase.google.com/products/realtime-database) only.

I have no current plans for Cloud Firestore or Cloud Storage.  Firebase Authentication is included with limited functionality (limited in addition to being lite: email/password and anon auths only; no email link, phone, or OAuth yet).

Requires Godot 3.3.0 (rc6+) and later for the listeners to work in HTML5 exports.
Otherwise, Godot 3.?.x should suffice.

### Origin and direction

Skip this section if you are bored already.

[GodotFirebase](https://github.com/GodotNuts/GodotFirebase) didn't have the features I was looking for -- and mandatory features I didn't want.  When I tried to request allowing no auth, like Firebase itself allows, I was met with far too much unsolicited advice including this comment:

_"It's clear you don't really understand how any of this works, so yeah, we'll lecture you because we, the folks who know a lot better than you..."_

Never mind that `firebase-auth.js` is an optional package in the JavaScript SDK.  No one can fix naive braggarts and almighty gatekeeper attitudes, so I made no further defense and built what I needed instead.

Because I'm apparently too dumb to contribute to that other project, I now have this separate package as opposed to a PR.  It's not a fork either because I rewrote the entire shebang while expanding the features.  Seriously, nothing was worth saving (maybe they were right that I don't understand how any of this works... yup... I certainly didn't understand how code like theirs could lead to a useful tool).  So, welcome to the less-better way!  If you're moving from that other project, you can find an overview of my less-better changes in the [CHANGELOG](CHANGELOG.md#010---2021-04-05).

No authoritarianism here.  If you just want to get some rapid prototyping done before adding auth... great!  If you understand how to manage public repos of disposable data... that's your business, not mine.  I won't try to stop you or lecture you.  I also won't try to dictate how you should manage your incoming data or anything else of the sort.  Your data-engineering patterns are your business.  How you choose to keep logins alive is also your business (no unwanted timers here).  For those who want to mod my code, I hope you find it concise and clear.  I don't write valley-girl code and other silliness such as single-line/single-use functions.

Godot Firebase Lite's programming pattern diverges significantly from GodotFirebase and instead closely follows the model set by Google's Firebase JavaScript SDK with hints from other language SDKs.

If anyone wants to help me make this even more less better... cool.

If you want to steal this for yet another tool... awesome.

If you want to steal this for reverting into GodotFirebase... well, supporting the haughty-net is your right I suppose.

### Side note

In actuality, I build games and only the minimal tools necessary for those games ([Sendit Soccer](https://juanitogan.itch.io/sendit-soccer) in this case).  Thus, I'm not likely to add features to this for the sake of being feature complete.  Others will probably need to do that.  Look for the TODOs in the code for hints on where to plug in some of the missing features.

Also, this is my first Godot project, so pardon the mess (especially in the tester_app, in which I don't care how messy it gets).

---

## Installation

1. Clone this repo or download the zip of it.
2. Copy the `firebase_app_lite` folders into the `res://` folder of your game.  This is not an editor plugin so it does not need to be in the `addons` folder if you have one (and shouldn't be there if you want the class icons to display).
3. Also copy one or more of the following folders into the `res://` folder of your game, depending on the features you need (critical: place at the same level as `firebase_app_lite`):
    - `firebase_auth_lite`
    - `firebase_database_lite`
4. Create a `firebase` global namespace ([AutoLoad Singleton](https://docs.godotengine.org/en/stable/getting_started/step_by_step/singletons_autoload.html#autoload)) by going into Project Settings > AutoLoad tab, and add a new entry with the following settings:
    - Path: `res://firebase_app_lite/firebase.gd` (or wherever you put it)
    - Name: `firebase` (note this is all lower case -- if you try proper case it will generate a conflict error with the `Firebase` class [Godot's style guide is mixed up about class instances])
    - Singleton: [x] Enable

Or, maybe check Godot's AssetLib, copy the packages in from there, and then enable the singleton.

##  Usage

### Initialization

Copy the config from your Firebase Project Settings > Web App, and adapt it from JavaScript to GDScript (quote the key names):

```gdscript
# Set the configuration options for your app.
# TODO: Replace with your project's config object.
var firebase_config = {
    "apiKey": "",  # set somewhere only if using auth
    "authDomain": "your-awesome-app.firebaseapp.com",
    "databaseURL": "https://your-awesome-app-db.region-maybe.firebaseio.com",
    "projectId": "your-awesome-app",
    "storageBucket": "your-awesome-app.appspot.com",
    "messagingSenderId": "111111111111",
    "appId": "1:111111111111:web:aaaaaaaaaaaaaaaaaaaaaa"
}
# Initialize Firebase
firebase.initialize_app(firebase_config)

# Get a reference to the database service.
var db : FirebaseDatabase = firebase.database()
```

### Read and write data

To manipulate data you must first get a [reference](docs/database.md#firebasereference-class) to a path in the database that you want to manipulate:

```gdscript
var ref : FirebaseReference = db.get_reference_lite("some/path/to/data")
```

If not using [Firebase array fakies](https://firebase.googleblog.com/2014/04/best-practices-arrays-in-firebase.html) (and you shouldn't) always use `get_reference_lite()` instead of `get_reference()`.  Array fakies are a headache to code for.  The light version of this method still supports them as whole objects in case that fits your use case for them.  Otherwise, the heavier version makes a good effort in supporting array fakies in all sorts of crazy ways... but testing it fully has exhausted me a bit too much for a feature I don't need.  Maybe someone with a bigger brain will tackle it harder (or rewrite it the lazier-but-slower way).

After you get a ref to a node, you can start issuing [CRUD methods](docs/database.md#ref-methods) against it.

Godot Firebase Lite promotes the pattern of using `yield()` for all of the CRUD methods (which saves a lot of signal wiring).  This is a similar pattern to using `.then()` in JavaScript even though the resulting code looks quite different.  For example:

JavaScript:
```javascript
ref.update({"name": "Pelé"}).then(() => {
    // do something
}).catch((error) => {
    // do something else
})
```
<!-- // or, by callback //
ref.update({"name": "Pelé"}, (error) => {
    if (error) {
        // do something else
    } else {
        // do something
    }
}) -->

GDScript:
```gdscript
var result = yield(ref.update({"name": "Pelé"}), "completed")
if result is FirebaseError:
    # do something else
else:
    # do something
```

Signaling still plays a big role in this tool but it is primarily used for triggering the same [SSE](https://www.w3.org/TR/eventsource/) listener events that other Firebase SDKs trigger.

### Listening to data changes

You can listen for [data-change events](docs/database.md#signals) by turning on a ref's listener:

```gdscript
ref.connect("child_added", self, "_do_something")
ref.connect("child_changed", self, "_do_something_else")
ref.connect("child_removed", self, "_do_something_elser")
ref.enable_listener()
```

You can skip the yield to `enable_listener()` if all you need from it is the signaling (which can be connect beforehand if you like).  Note: enabling a listener will trigger a `"child_added"` signal for each existing child, followed by a single `"value_changed"` signal.  If you don't want these initial `"child_added"` signals, connect that signal after `enable_listener()` has finished (by yielding to it or by waiting for the first `"value_changed"` signal).

### Auth

If you need to enable the auth service, make a call to `firebase.auth()`.  From there, call the [auth methods](docs/auth.md#methods) you need.  For example:

```gdscript
# Get a reference to the database service.
var auth : FirebaseAuth = firebase.auth()

# Sign a user in.
var result = yield(auth.sign_in_with_email_and_password(email, password), "completed")
if result is FirebaseError:
    print(result.code)
else:
    var user = result as FirebaseUser
    print(user.email)
```

Currently, only email/password and anonymous authentications are supported -- and only by the Firebase's built-in email/password handler.

### Type casting

Due to various limitations and/or nuances with GDScript, precise typing of the return objects from many methods in this SDK is not possible.  Thus, if you want better autocompletion with some variables, you will need to cast them as their specific type yourself.  For example:

```gdscript
db = firebase.database() as FirebaseDatabase
```

or

```gdscript
var db : FirebaseDatabase = firebase.database()
```

Note that pre-typing is not sufficient.  For example, this **does not** result in a properly-cast `db` variable:

```gdscript
var db : FirebaseDatabase
db = firebase.database()
```

When and what to cast to is indicated in the reference docs by a type (or types) in parenthesis next to the actual type.  For example: `Node` (`FirebaseDatabase`) indicates the actual type is `Node` but you _should_ cast it as `FirebaseDatabase` if you plan on working with it much.

Obviously, simple types like `OK` and even `FirebaseError` don't need casting considering their simplicity and their short lifetime.

---

## Reference manual

- [FirebaseAppLite Reference](docs/app.md)
- [FirebaseAuthLite Reference](docs/auth.md)
- [FirebaseDatabaseLite Reference](docs/database.md)

### More help

This readme assumes you already know how to use Realtime Database and Authentication from using one of the other language SDKs.

For details not covered here -- and there are many things I simply don't have time to re-document here -- these docs for the JavaScript SDK should help (these are where I first learned how to use Realtime Database before writing this package):

- https://firebase.google.com/docs/database/web/start  (a bit outdated)
- https://firebase.google.com/docs/database/admin/start  (a bit outdated)
- https://firebase.google.com/docs/reference/js
- https://firebase.google.com/docs/reference/js/firebase.database.Reference
- https://firebase.google.com/docs/auth/web/start

You can also try to derive how to use this from `tester_app.gd` in the GitHub repo, but don't expect the code there to be a great example of the programming patterns you should be using.  Most of it is quick-and-dirty programming just to test functionality.

### Differences from the JavaScript SDK

As the name suggests, Godot Firebase Lite is not nearly as feature-complete as, say, the JS SDK.  Not even close.  The bits that _are_ here, however, seem to cover the most-likely use-cases well.  Building a full version looks like it might require 40x the code... and I only need a tool that is merely good enough.

Primarily, anything related to priority data, ordering, filtering, and transactions (ETags), is not here.  Some of that you can do in GDScript if you need it.  Some of that may be added in the future.

For detailed differences from the JS SDK, see the items at the bottom of each class reference.
