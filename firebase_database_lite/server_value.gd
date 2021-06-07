################################################################################
# Just a simple helper library based on the same one found in the JS SDK.
# What?  No singletons?  No real singletons?
# Oh, okay, a static script resource is good enough.
#
# https://firebase.google.com/docs/reference/js/firebase.database.ServerValue
# https://github.com/firebase/firebase-js-sdk/blob/9f5578e3610d582e1644373e5325dd5cd952a9ae/packages/database/src/api/Database.ts#L214
################################################################################
#extends Reference
#class_name FirebaseServerValue, "icon.png"

# A placeholder value for auto-populating the current timestamp
# (time since the Unix epoch, in milliseconds) as determined by the
# Firebase servers.
const TIMESTAMP := {'.sv': 'timestamp'}

# Returns a placeholder value that can be used to atomically increment the
# current database value by the provided delta.
static func increment(delta: float) -> Dictionary:
	return {'.sv': {'increment': delta}}
