# FirebaseAuthLite Reference

Developer-facing classes included in the `firebase_auth_lite` folder.


---

## FirebaseAuth class

The Firebase Auth service interface.

Do not call this constructor directly. Instead, use `firebase.auth()`.

See [Firebase Authentication](https://firebase.google.com/docs/auth/) for a full guide on how to use the Firebase Auth service.

### Signals

| Signal | Passes | Typical usage |
|--------|--------|---------------|
| `"on_auth_state_changed"` | `FirebaseUser` | Triggered on sign-in or sign-out. |
| `"on_id_token_changed"`   | `FirebaseUser` | Triggered on changes to the signed-in user's ID token, which includes sign-in, sign-out, and token refresh events. |

### Properties

| Property | Type (cast as) | Description |
|----------|----------------|-------------|
| `app`          | `Node` (`FirebaseApp`) | The app associated with the `FirebaseAuth` service instance. |
| `current_user` | `FirebaseUser`         | The currently signed-in user (or null). |

### Methods

🔻 = asynchronous.  These should be called from inside a `yield()` in a linear procedure.

| Method | Returns (cast as) | Typical usage |
|--------|-------------------|---------------|
| 🔻`create_user_with_email_and_password(email, password)` | `Object` (`FirebaseUser` or `FirebaseError`) | Creates a new user account associated with the specified email address and password. |
| 🔻`send_password_reset_email(email)`                     | `Object` (`OK` or `FirebaseError`)           | Sends a password reset email to the given email address.  The default password reset process is completed by firebaseapp.com's own service. |
| 🔻`sign_in_with_email_and_password(email, password)`     | `Object` (`FirebaseUser` or `FirebaseError`) | Signs in using an email and password. |
| 🔻`sign_in_anonymously()`                                | `Object` (`FirebaseUser` or `FirebaseError`) | Signs in as an anonymous user.  If there is already an anonymous user signed in, that user will be returned; otherwise, a new anonymous user identity will be created and returned. |
| `sign_out()`                                             | void                                         | Signs out the current user. |

### Source JavaScript docs

- https://firebase.google.com/docs/reference/js/firebase.auth
- https://firebase.google.com/docs/reference/js/firebase.auth.Auth

Differences from the JavaScript SDK:

- `onAuthStateChanged()` and `onIdTokenChanged()` replaced by signals, `"on_auth_state_changed"` and `"on_id_token_changed"`.  The JS methods also include optional callbacks for auth errors but signals have not yet been provided to match (as the use cases are not clear to me over other error handling).
- This _lite_ version does not have an equivalent object to `UserCredential` yet.  Thus, the methods that return a `UserCredential` in JS return a `FirebaseUser` object here (equivalent to `UserCredential.user`).
- Cases changed from camelCase to snake_case, where appropriate.  For example, `currentUser` renamed to `current_user`.
- This _lite_ version does not implement all features.

Note: There is no estimate as to when OAuth, phone, or email-link auth might arrive.


---

## FirebaseUser class

A Firebase user account.

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `display_name`   | `String`     |  |
| `email`          | `String`     |  |
| `email_verified` | `bool`       |  |
| `is_anonymous`   | `bool`       |  |
| `metadata`       | UserMetadata `Dictionary` | [UserMetadata](#usermetadata-fake-class) |
| `phone_number`   | `String`     |  |
| `photo_url`      | `String`     |  |
| `provider_data`  | `Array`      |  |
| `provider_id`    | `String`     |  |
| `refresh_token`  | `String`     |  |
| `uid`            | `String`     |  |

### Methods

🔻 = asynchronous.  These should be called from inside a `yield()` in a linear procedure.

| Method | Returns (cast as) | Typical usage |
|--------|-------------------|---------------|
| 🔻`delete()`                              | `Object` (`OK` or `FirebaseError`) | Deletes and signs out the user. |
| 🔻`get_id_token(<force_refresh>)`         | `Object` (JWT `String` or `FirebaseError`) | Returns a JSON Web Token (JWT) used to identify the user to a Firebase service.  Returns the current token if it has not expired. Otherwise, this will refresh the token and return a new one. |
| 🔻`get_id_token_result(<force_refresh>)`  | `Object` (IdTokenResult `Dictionary` or `FirebaseError`) | Returns an [IdTokenResult](#idtokenresult-fake-class) dictionary (fake class). |
| 🔻`reload()`                              | `Object` (`OK` or `FirebaseError`) | Refreshes the current user, if signed in. |
| 🔻`send_email_verification()`             | `Object` (`OK` or `FirebaseError`) | Sends a verification email to a user.  The default verfication process is completed by firebaseapp.com's own service. |
| 🔻`verify_before_update_email(new_email)` | `Object` (`OK` or `FirebaseError`) | Sends a verification email to a new email address. The user's email will be updated to the new one after being verified.  The default verfication process is completed by firebaseapp.com's own service. |
| 🔻`update_email(new_email)`               | `Object` (`OK` or `FirebaseError`) | Updates the user's email address.  An email will be sent to the original email address (if it was set) that allows to revoke the email address change, in order to protect them from account hijacking.  Important: this is a security sensitive operation that requires the user to have recently signed in. |
| 🔻`update_password(new_password)`         | `Object` (`OK` or `FirebaseError`) | Updates the user's password.  Important: this is a security sensitive operation that requires the user to have recently signed in. |
| 🔻`update_profile(profile)`               | `Object` (`OK` or `FirebaseError`) | Updates a user's profile data. |

**profile:** { **display_name:** _String_ | _null_; **photo_url:** _String_ | _null_ }
- The profile's display_name and photo_url to update.
  - **display_name:** _String_ | _null_ (optional). Set to `null` to delete current value.
  - **photo_url:** _String_ | _null_ (optional). Set to `null` to delete current value.
- Example: `{"display_name": "Super Dave", "photo_url": "http://placekitten.com/100/100"}`

### Source JavaScript docs

- https://firebase.google.com/docs/reference/js/firebase.User

Differences from the JavaScript SDK:

- Cases changed from camelCase to snake_case, where appropriate.  For example, `displayName` renamed to `display_name`.
- This _lite_ version does not implement all features.


---

## IdTokenResult fake class

Interface representing ID token result obtained from `FirebaseUser.get_id_token_result()`.  It contains the ID token JWT string and other helper properties for getting different data associated with the token.

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `auth_time_secs`           | `int`    | The authentication time in OS epoch seconds. This is the time the user authenticated (signed in) and not the time the token was refreshed. |
| `expiration_interval_secs` | `int`    | Seconds this token lasts before it expires. Should always be 3600 in Firebase. |
| `expiration_time_secs`     | `int`    | The ID token expiration time in OS epoch seconds. |
| `issued_at_time_secs`      | `int`    | The ID token issued-at time in OS epoch seconds. |
| `token`                    | `String` | The Firebase Auth ID token JWT string. |

### Source JavaScript docs

- https://firebase.google.com/docs/reference/js/firebase.auth.IDTokenResult

Differences from the JavaScript SDK:

- `authTime`, `issuedAtTime`, and `expirationTime` (which contain UTC strings) replaced by integer properties of similar name that are compatible with GDScript's `OS.get_system_time_secs()` etc.
- `expiration_interval_secs` added just because the Firebase API always sends it (as `expires_in`).  It is always 3600 but stored here in case it ever changes -- or you want a property to pull it from.


---

## UserMetadata fake class

Interface representing a user's metadata.

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `creation_time_secs`     | `int` | The user-account-creation time in OS epoch seconds. |
| `last_sign_in_time_secs` | `int` | The user's last sign-in time in OS epoch seconds. |

### Source JavaScript docs

- https://firebase.google.com/docs/reference/js/firebase.auth.UserMetadata

Differences from the JavaScript SDK:

- `creationTime` and `lastSignInTime` (which contain UTC strings) replaced by integer properties of similar name that are compatible with GDScript's `OS.get_system_time_secs()` etc.
