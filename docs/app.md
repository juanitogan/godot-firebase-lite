# FirebaseAppLite Reference

Developer-facing classes included in the `firebase_app_lite` folder.


---

## Firebase class (firebase namespace)

The core of the Godot Firebase Lite API.  The parent node to all Firebase apps and services.

Construct this as an "AutoLoad Singleton" and not as a regular class.  (Although, you can instantiate it as a new class instead if you really would rather manage it that way.)

Create a `firebase` global namespace ([AutoLoad Singleton](https://docs.godotengine.org/en/stable/getting_started/step_by_step/singletons_autoload.html#autoload)) by going into Project Settings > AutoLoad tab, and add a new entry with the following settings:
- Path: `res://firebase_app_lite/firebase.gd` (or wherever you put it)
- Name: `firebase` (note this is all lower case -- if you try proper case it will generate a conflict error with the `Firebase` class [Godot's style guide is mixed up about class instances])
- Singleton: [x] Enable

Then, for example, to initialize the _default app_ to work with a database service:

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

### Constants

| Constant | Type | Description |
|----------|------|-------------|
| `SDK_VERSION` | `String` | The current SDK version. |

### Methods

| Method | Returns (cast as) | Typical usage |
|--------|-------------------|---------------|
| `app(<name>)`     | `FirebaseApp`             | Retrieves a Firebase app instance. |
| `auth(<app>)`     | `Node` (`FirebaseAuth`)     | Gets the [`FirebaseAuth`](auth.md) service for the default app or a given app. |
| `database(<app>)` | `Node` (`FirebaseDatabase`) | Gets the [`FirebaseDatabase`](database.md) service for the default app or a given app. |
| `initialize_app(options, <name>)` | `FirebaseApp` | Creates and initializes a Firebase app instance. |

**Note:** If `<name>` or `<app>` is not specified with any of the above methods, the _default app_ is assumed.  These parameters allow for more apps to be managed that just the one _default app_.

See [Add Firebase to your app](https://firebase.google.com/docs/web/setup#add_firebase_to_your_app) and [Initialize multiple projects](https://firebase.google.com/docs/web/learn-more#multiple-projects) for detailed documentation.

### Source JavaScript docs

- https://firebase.google.com/docs/reference/js/firebase

Differences from the JavaScript SDK:

- **`apps` array property replaced by GDScript's child Node handling such as `get_children()` and `get_node(name)`.**
- Cases changed from camelCase to snake_case, where appropriate.  For example, `initializeApp()` renamed to `initialize_app()`.  (Well, the key names in the Firebase app config were not changed because... uh... to make copying from Firebase's console easier... I suppose.  Hrmm.  No standards here [or in Godot] with dictionary key names.)
- `app()`, `auth()`, and `database()` are module calls in JS but are methods here.  (What's the difference?  Nothing that matters in _lite_.)
- This _lite_ version does not implement all features.


---

## FirebaseApp class

A Firebase app holds the initialization information for a collection of services.

Do not call this constructor directly. Instead, use `firebase.initialize_app()` to create an app.

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `name`    | `String`     | The name for this app.  The default app's name is "\[DEFAULT\]". |
| `options` | `Dictionary` | The (read-only) configuration options for this app. |

### Methods

| Method | Returns (cast as) | Typical usage |
|--------|-------------------|---------------|
| `auth()`     | `Node` (`FirebaseAuth`)     | Loads and gets the [`FirebaseAuth`](auth.md) service for the current app. |
| `database()` | `Node` (`FirebaseDatabase`) | Loads and gets the [`FirebaseDatabase`](database.md) service for the current app. |
| ~~`delete()`~~   | void                      | **TODO.** Renders this app unusable and frees the resources of all associated services. |

### Source JavaScript docs

- https://firebase.google.com/docs/reference/js/firebase.app.App

Differences from the JavaScript SDK:

- `name` property is actually provided by the `Node` class rather than this class.  As such, it is not read only -- and perhaps does not need to be given the new architecture in the `Firebase` class.  You should not, however, rename the _default app_.
- This _lite_ version does not implement all features.


---

## FirebaseError class

A Firebase error.

Created to overcome nuances in GDScript.  There is, however, a similar class in Firebase (see the source docs below).

```gdscript
var result = yield(ref.update({"name": "Pelé"}), "completed")
if result is FirebaseError:
    print(result.code)
else:
    # do something
```

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `code` | `String` | Error codes are strings using the following format: `"service/string-code"`.  Some examples include `"app/no-app"` and `"auth/user-not-found"`. |

### Source JavaScript docs

- https://firebase.google.com/docs/reference/js/firebase.FirebaseError
- https://firebase.google.com/docs/reference/js/firebase.auth.Error
- https://firebase.google.com/docs/reference/js/firebase.auth.AuthError
