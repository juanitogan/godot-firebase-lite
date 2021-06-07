################################################################################
# A Firebase error.
#
# Originally used for just auth errors (as is true in JS) but will likely be
# expanded for other errors in Godot.
#
# Conveniently, in JS, all auth errors take the form of:
#   `"auth/<code>"`
# Thus, use a similar pattern for other packages, such as:
#   `"database/<code>"`
#
# NOTE: Decided to remove the message property.  The use case for it seems weak--
# especially for a lite version.  It feels like 10k of bulk for no good reason.
# Most devs will likely write their own messages--and in various languages.
#
# https://firebase.google.com/docs/reference/js/firebase.FirebaseError (this found after creating this)
# https://firebase.google.com/docs/reference/js/firebase.auth.Error
# https://firebase.google.com/docs/reference/js/firebase.auth.AuthError
################################################################################
extends Reference
class_name FirebaseError, "icon.png"

# Error codes are strings using the following format: `"service/string-code"`.
# Some examples include `"app/no-app"` and `"auth/user-not-found"`.
var code : String

#var message : String


#func _init(code : String, message : String):
#	self.code = code
#	self.message = message

func _init(code : String):
	self.code = code


func _to_string() -> String:
	return "code: %s\n" % code
