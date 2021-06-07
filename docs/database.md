# FirebaseDatabaseLite Reference

Developer-facing classes included in the `firebase_database_lite` folder.


---

## FirebaseDatabase class

The Firebase Database service interface.

Do not call this constructor directly. Instead, use `firebase.database()`.

See [Installation & Setup in JavaScript](https://firebase.google.com/docs/database/web/start/) for a full guide on how to use the Firebase Database service.

### Modules

[`ServerValue`](#servervalue-module)

### Properties

| Property | Type (cast as) | Description |
|----------|----------------|-------------|
| `app`    | `Node` (`FirebaseApp`) | The app associated with the `FirebaseDatabase` service instance. |

### Methods

| Method | Returns | Typical usage |
|--------|---------|---------------|
| `get_reference(<path>)`      | `FirebaseReference` | Returns a ref to the specified node in the database.  **WARNING: Not fully tested.** |
| `get_reference_lite(<path>)` | `FirebaseReference` | Returns a ref to the specified node in the database.  Limited support for array fakies. |

If not using [Firebase array fakies](https://firebase.googleblog.com/2014/04/best-practices-arrays-in-firebase.html) (and you shouldn't) always use `get_reference_lite()` instead of `get_reference()`.  Array fakies are a headache to code for.  The light version of this method still supports them as whole objects in case that fits your use case for them.  Otherwise, the heavier version makes a good effort in supporting array fakies in all sorts of crazy ways... but testing it fully has exhausted me a bit too much for a feature I don't need.

### Source JavaScript docs

- https://firebase.google.com/docs/reference/js/firebase.database
- https://firebase.google.com/docs/reference/js/firebase.database.Database

Differences from the JavaScript SDK:

- `ref()` renamed to `get_reference()`.  (Similar to Java's `getReference()` and Unity's `GetReference()`.)
- This _lite_ version does not implement all features.


---

## FirebaseReference class

A `FirebaseReference` (ref) represents a specific location in your Realtime Database and can be used for reading or writing data to that Database location.

You can reference the root or child location in your Database by calling `firebase.database().get_reference()` or `firebase.database().get_reference("child/path")` (or `get_reference_lite(<path>)`).

### Signals

| Signal | Passes | Typical usage |
|--------|--------|---------------|
| `"value_changed"` | `FirebaseDataSnapshot` | Read and listen for changes to the entire contents of a path.  The snapshot passed to the callback contains the entire contents with the updated data. |
| `"child_added"`   | `FirebaseDataSnapshot` | Retrieve lists of items or listen for additions to a list of items.  This event is triggered once for each existing child and then again every time a new child is added to the specified path.  The callback is passed a snapshot containing the new child's data. |
| `"child_changed"` | `FirebaseDataSnapshot` | Listen for changes to the items in a list. This event is triggered any time a child node is modified.  This includes any modifications to descendants of the child node.  The snapshot passed to the callback contains the updated data for the child. |
| `"child_removed"` | `FirebaseDataSnapshot` | Listen for items being removed from a list.  This event is triggered when an immediate child is removed.  The snapshot passed to the callback contains the data for the removed child. |

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `key`    | any (`String` or `null`) | The last part of the ref's path. |
| `path`   | `String`                 | The (read-only) path this ref points to. |

### <a name="ref-methods"></a> Methods

🔻 = asynchronous.  These should be called from inside a `yield()` in a linear procedure.

| Method | Returns (cast as) | Typical usage |
|--------|-------------------|---------------|
| 🔻`fetch()`      | any (`FirebaseDataSnapshot` or `FirebaseError`) | Fetch a snapshot of all the data at the ref's path. |
| `fetch_local()`  | any (`FirebaseDataSnapshot` or `FAILED`)        | Return a deep copy of the current local copy of the listener's snapshot. |
| 🔻`push(<data>)` | any (`FirebaseReference` or `FirebaseError`)    | **Add to a list** of data (ref should point to a parent node of a list).  Returns a new ref to a generated unique-key. |
| 🔻`put(data)`    | any (any or `FirebaseError`)                    | Write or replace data at the ref's path.  Returns the data written. |
| 🔻`remove()`     | any (`OK` or `FirebaseError`)                   | Remove all data at the ref's path. |
| 🔻`update(data)` | any (any or `FirebaseError`)                    | Update some of the keys at the ref's path without replacing all of the data.  Accepts relative paths in the top-level key names.  Returns the data written. |

| Method | Returns | Typical usage |
|--------|---------|---------------|
| `disable_listener()`  | void | Turn off all listener signals. |
| 🔻`enable_listener()` | void | Set up a realtime listener at the ref's path. (yielded) |

### Listening to data changes

You can listen for data-change events by turning on a ref's listener:

```gdscript
ref.connect("child_added", self, "_do_something")
ref.connect("child_changed", self, "_do_something_else")
ref.connect("child_removed", self, "_do_something_elser")
ref.enable_listener()
```

You can skip the yield to `enable_listener()` if all you need from it is the signaling (which can be connect beforehand if you like).  Note: enabling a listener will trigger a `"child_added"` signal for each existing child, followed by a single `"value_changed"` signal.  If you don't want these initial `"child_added"` signals, connect that signal after `enable_listener()` has finished (by yielding to it or by waiting for the first `"value_changed"` signal).

### Source JavaScript docs

- https://firebase.google.com/docs/reference/js/firebase.database.Reference

Differences from the JavaScript SDK:

- `on()` replaced with two methods: `enable_listener()` and GDScript's `connect()` to connect listener signals to methods.  The signals do not pass a sibling key as a second argument because ordering is not supported in this _lite_ version.  There are no signals equivalent to the optional cancel callback yet (if ever).
- `off()` replaced with two methods: `disable_listener()` and GDScript's `disconnect()` to disconnect listener signals from methods.
- `get()` renamed to `fetch()`, as `get` is reserved by the Object base class.
- `set()` renamed to `put()`, as `set` is reserved by the Object base class.
- `once()` tabled due to confusion around it.  Partly replaced by `fetch_local()`.  May be added in some fashion eventually.
- `"value"` signal renamed to `"value_changed"`.  (Similar to Java's `onDataChange()` and Unity's `ValueChanged`.)
- `path` read-only property added.
- This _lite_ version does not implement all features.


---

## FirebaseDataSnapshot class

A `FirebaseDataSnapshot` contains data from a Database location.

Any time you read data from the Database, you receive the data as a
`FirebaseDataSnapshot`, such as with `fetch()`.
A `FirebaseDataSnapshot` is passed to the event callbacks you attach with
`connect()`.
You can extract the contents of the snapshot by calling the `value()` method.

### Modules

`ServerValue`

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `key`    | any (`String` or `null`) | The last part of the ref's path. |

### Methods

| Method | Returns | Typical usage |
|--------|---------|---------------|
| `value()` | any | Returns a deep copy of the snapshot.  Depending on the data in the snapshot, the `value()` method may return a scalar type (string, number, or boolean), an array, or a dictionary.  It may also return null, indicating that the snapshot is empty (contains no data). |

### Source JavaScript docs

- https://firebase.google.com/docs/reference/js/firebase.database.DataSnapshot

Differences from the JavaScript SDK:

- `val()` renamed to `value()`.  (Similar to Java's `getValue()` and Unity's `Value`.)
- This _lite_ version does not implement all features.


---

## ServerValue module

The `FirebaseDatabase` class contains the `ServerValue` property pointing to a static script resource.  Usage looks like this:

```gdscript
yield(ref.put({"created_at": db.ServerValue.TIMESTAMP}), "completed")
yield(ref.update({"one_up": db.ServerValue.increment(1)}), "completed")
```

### Constants

| Constant | Type | Description |
|----------|------|-------------|
| `TIMESTAMP` | `Dictionary` | A placeholder value for auto-populating the current timestamp (time since the Unix epoch, in milliseconds) as determined by the Firebase servers. |

### Functions

| Method | Returns | Typical usage |
|--------|---------|---------------|
| `increment(delta)` | `Dictionary` | Returns a placeholder value that can be used to atomically increment the current database value by the provided delta. |

### Source JavaScript docs

- https://firebase.google.com/docs/reference/js/firebase.database.ServerValue


---

## Working with data offline

More robust Firebase SDKs write changes locally before sending to the remote database.  Thus, if connection is lost, they will pool changes and make a best effort to send all pooled changes when they can.  This package, however, has not yet gone to such efforts because it is a lot of work for a feature I don't need.

Instead, a local snapshot of data is only kept if you have enabled the listener on a DB reference point, and is updated only after changes are made to the remote and broadcast back to the listeners.  Thus, the local copy is a best-effort representation of the remote copy.  If you lose connection to the remote, you still have access to the local copy, but it won't update until connection is re-established.  All this helps this lite package stay lite -- and also happens to be the round-trip paradigm I prefer.
