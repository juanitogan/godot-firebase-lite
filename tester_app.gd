extends Node2D

const firebase_config : Dictionary = {
	"apiKey": "",  # set somewhere only if using auth
	"authDomain": "godotfirebaselite.firebaseapp.com",
	"databaseURL": "https://godotfirebaselite-default-rtdb.firebaseio.com",
	"projectId": "godotfirebaselite",
	"storageBucket": "godotfirebaselite.appspot.com",
	"messagingSenderId": "979617527349",
	"appId": "1:979617527349:web:adc9c96ac1a79e0feca37c",
}
#var fb : Firebase
var db : FirebaseDatabase
var auth : FirebaseAuth


func _ready():
	# Load the API key from a place outside Git.
	#firebase_config.apiKey = ProjectSettings.get_setting("firebase/api_keys/default") # FAIL: gets cached in project.godot
	var config = ConfigFile.new()
	var err = config.load("res://firebase.cfg")
	if err == OK:
		firebase_config.apiKey = config.get_value("api_keys", "default_app")
		if firebase_config.apiKey == null:
			print_debug("API key went bonk!")
	else:
		print_debug("Config file went bonk!")
	
	# Initialize Firebase
	#var fb : Firebase = Firebase.new(firebase_config)
	#add_child(fb)
	#var db : FirebaseDatabase = fb.database()
#	fb = Firebase.new()
#	add_child(fb)
	firebase.initialize_app(firebase_config)  # inits the default app
	db = firebase.database() as FirebaseDatabase  # should cast even when using a pre-typed var like this
	auth = firebase.auth() as FirebaseAuth  # should cast even when using a pre-typed var like this

	auth.connect("on_auth_state_changed", self, "_auth_state_changed")
	auth.connect("on_id_token_changed", self, "_id_token_changed")


func _auth_state_changed(user : FirebaseUser):
	print("^^^ on_auth_state_changed signal received") 
	if user:
		print("        User signed in. Email: " + user.email)
	else:
		print("        No user.")


func _id_token_changed(user : FirebaseUser):
	print("~~~ on_id_token_changed signal received") 
	if user:
		print("        User signed in. Email: " + user.email)
	else:
		print("        No user.")


################################################################################
################################################################################
################################################################################


func _on_Truncate_pressed():
#	var ref : FirebaseReference = db.get_reference_lite("", true)
#	var result = yield(ref.remove(), "completed")
#	if result is FirebaseError:
#		print(result.code)
#	else:
#		print("removed all")
# The above stopped working once I added r/w rules for auth testing.

	var ref : FirebaseReference = db.get_reference_lite("array-test")
	yield(ref.remove(), "completed")
	ref = db.get_reference_lite("dict-test")
	yield(ref.remove(), "completed")
	ref = db.get_reference_lite("increment-test")
	yield(ref.remove(), "completed")
	ref = db.get_reference_lite("list-test")
	yield(ref.remove(), "completed")
	ref = db.get_reference_lite("test-no-auth")
	yield(ref.remove(), "completed")
	ref = db.get_reference_lite("timestamp-test")
	yield(ref.remove(), "completed")
	print("removed all pulic data... we hope")

	var result = yield(auth.sign_in_with_email_and_password("pele@football.rules", "pelerules"), "completed")
	if result is FirebaseError:
		print(result.code)
	else:
		print(">>> signed in")
		ref = db.get_reference_lite("locked")
		yield(ref.remove(), "completed")
		ref = db.get_reference_lite("secret")
		yield(ref.remove(), "completed")
		print("removed all auth data... we hope")
	auth.sign_out()


################################################################################
################################################################################
################################################################################


func _on_NoAuth_pressed():
	var ref : FirebaseReference = db.get_reference_lite("test-no-auth", true)
	var result = yield(ref.put("yo"), "completed")
	if result is FirebaseError:
		print("error")
		print(result.code)
	else:
		print("Youza! Yo, it works.")


const TESTEMAIL = "test@example.commode"
const TESTEMAIL2 = "test_________ing@example.commode"
const TESTPWD = "notverysecret"
const TESTPWD2 = "almostsecret"


# curl 'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' -H 'Content-Type: application/json' --data-binary '{"email":"testup@example.com","password":"[PASSWORD]","returnSecureToken":true}'
# curl 'https://identitytoolkit.googleapis.com/v1/accounts:delete?key=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' -H 'Content-Type: application/json' --data-binary '{"idToken":"[FIREBASE_ID_TOKEN]"}'
func _on_AuthCreate_pressed():
	print("############################################################ CREATE W/ EMAIL/PWD")
	var result = yield(auth.create_user_with_email_and_password(TESTEMAIL, TESTPWD), "completed")
	if result is FirebaseError:
		print(result.code)
		print("OOPS! Delete user via Firebase Authentication console to recover: " + TESTEMAIL)
	else:
		print(">>> created new test user")
		print(result)
	auth.sign_out()


# curl 'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' -H 'Content-Type: application/json' --data-binary '{"email":"pele@football.rules","password":"pelerules","returnSecureToken":true}'
# curl 'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' -H 'Content-Type: application/json' --data-binary '{"email":"dummy@example.com","password":"[PASSWORD]","returnSecureToken":true}'
func _on_AuthEmailPwd_pressed():
	print("############################################################ SIGN IN EMAIL/PWD")
	# Important to cast as FirebaseAuth if wanting autocomplete.
	#var auth : FirebaseAuth = fb.auth()
	#var auth = fb.auth() as FirebaseAuth

	var fail
	fail = yield(auth.sign_in_with_email_and_password("nope", "pelerules"), "completed")
	print(fail)
	fail = yield(auth.sign_in_with_email_and_password("pele@football.rules", "nope"), "completed")
	print(fail)
	fail = yield(auth.sign_in_with_email_and_password("nope@football.rules", "pelerules"), "completed")
	print(fail)

	var result = yield(auth.sign_in_with_email_and_password("pele@football.rules", "pelerules"), "completed")
	if result is FirebaseError:
		print(result.code)
	else:
		print(">>> signed in")
		print(result)
	auth.sign_out()


# curl 'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' -H 'Content-Type: application/json' --data-binary '{"returnSecureToken":true}'
func _on_AuthAnon_pressed():
	print("############################################################ SIGN IN ANON")
	var result = yield(auth.sign_in_anonymously(), "completed")
	if result is FirebaseError:
		print(result.code)
		print("OOPS! Delete anon user via Firebase Authentication console.")
	else:
		print(result)
		var user = result as FirebaseUser
		result = yield(user.delete(), "completed")
		if result is FirebaseError:
			print(result.code)
			print("OOPS! Delete anon user via Firebase Authentication console.")
		else:
			print(">>> deleted new anon user")


func _on_AuthReload_pressed():
	print("############################################################ RELOAD")
	var result = yield(auth.sign_in_with_email_and_password(TESTEMAIL, TESTPWD), "completed")
	if result is FirebaseError:
		print(result.code)
	else:
		var user = result as FirebaseUser
		result = yield(user.get_id_token(), "completed")
		if result is FirebaseError:
			print(result.code)
		else:
			print(result)
		result = yield(user.get_id_token_result(true), "completed")
		if result is FirebaseError:
			print(result.code)
		else:
			print(result.token)

		# Test not yielding when it _should_ not be needed (but still is... for now... and ever?).
		result = user.get_id_token_result()  # returns a GDScriptFunctionState
		print(result)
		# Now finish it (you can also while/resume it, but that's silly).
		if result is GDScriptFunctionState:
			result = yield(result, "completed")
		print(result.auth_time_secs)
	auth.sign_out()


func _on_AuthUpdateProfile_pressed():
	print("############################################################ UPDATE PROFILE")
	var result = yield(auth.sign_in_with_email_and_password(TESTEMAIL, TESTPWD), "completed")
	if result is FirebaseError:
		print(result.code)
	else:
		var user = result as FirebaseUser
		print(user)
		result = yield(user.update_profile({"display_name": "Super Dave", "photo_url": "http://placekitten.com/100/100"}), "completed")
		print(user)
		result = yield(user.update_profile({"display_name": null, "photo_url": null}), "completed")
		print(user)
		result = yield(user.update_profile({display_name="Super Dog"}), "completed")
		print(user)
		result = yield(user.update_profile({photo_url="http://placekitten.com/101/101"}), "completed")
		print(user)
		#result = yield(user.update_profile({error="this"}), "completed")
	auth.sign_out()


func _on_AuthUpdateEmail_pressed():
	print("############################################################ UPDATE EMAIL")
	var result = yield(auth.sign_in_with_email_and_password(TESTEMAIL, TESTPWD), "completed")
	if result is FirebaseError:
		print(result.code)
	else:
		var user = result as FirebaseUser
		print(user)
		result = yield(user.update_email("bademail"), "completed")
		if result is FirebaseError:
			print(result.code)
		print(user)
		result = yield(user.update_email(TESTEMAIL2), "completed")
		if result is FirebaseError:
			print(result.code)
		print(user)
		# The following won't work without a reauth:
		result = yield(user.update_email(TESTEMAIL), "completed")
		if result is FirebaseError:
			print(result.code)
		print(user)
	auth.sign_out()


func _on_AuthUpdatePwd_pressed():
	print("############################################################ UPDATE PWD")
	var result = yield(auth.sign_in_with_email_and_password(TESTEMAIL, TESTPWD), "completed")
	if result is FirebaseError:
		print(result.code)
	else:
		var user = result as FirebaseUser
		print(user)
		result = yield(user.update_password(TESTPWD2), "completed")
		auth.sign_out()
		user = auth.current_user  ################
		print(">>> signed out")
		print(user)
		result = yield(auth.sign_in_with_email_and_password(TESTEMAIL, TESTPWD2), "completed")
		if result is FirebaseError:
			print(result.code)
		else:
			user = result as FirebaseUser
			result = yield(user.update_password(TESTPWD), "completed")
			print(user)
	auth.sign_out()


func _on_DeleteTestUsers_pressed():
	print("############################################################ DELETE")
	for email in [TESTEMAIL, TESTEMAIL2]:
		var result = yield(auth.sign_in_with_email_and_password(email, TESTPWD), "completed")
		if result is FirebaseError:
			print(result.code)
			result = yield(auth.sign_in_with_email_and_password(email, TESTPWD2), "completed")
			if result is FirebaseError:
				print(result.code)
				continue
		var user = result as FirebaseUser
		result = yield(user.delete(), "completed")
		if result is FirebaseError:
			print(result.code)
			print("OOPS! Delete user via Firebase Authentication console to recover: " + email)
		else:
			print(">>> deleted test user: " + email)


################################################################################
################################################################################
################################################################################


const WRONGEMAIL = "oops@example.oopsie"
var current_user : FirebaseUser


func _on_RealCreate_pressed():
	print("############################################################ CREATE REAL")
	var real = $RealEmail.text
	var pwd = $RealEmailPwd.text
	var result = yield(auth.create_user_with_email_and_password(real, pwd), "completed")
	if result is FirebaseError:
		print(result.code)
		print("OOPS! Delete user via Firebase Authentication console to recover: " + real)
	else:
		print(">>> created real-email user")
		current_user = result as FirebaseUser
		print(current_user.email)
		print("Verified? " + current_user.email_verified as String)


func _on_RealVerify_pressed():
	print("############################################################ VERIFY")
	var result = yield(current_user.send_email_verification(), "completed")
	if result is FirebaseError:
		print(result.code)
	else:
		print(">>> email verification sent")


func _on_RealCheckUser_pressed():
	print("############################################################ CHECK USER")
	var result = yield(current_user.reload(), "completed")
	if result is FirebaseError:
		print(result.code)
	else:
		print(current_user.email)
		print("Verified? " + current_user.email_verified as String)


func _on_RealUpdateEmail_pressed():
	print("############################################################ UPDATE EMAIL")
	var result = yield(current_user.update_email(WRONGEMAIL), "completed")
	if result is FirebaseError:
		print(result.code)
	else:
		print(">>> changed email to WRONG email")
		print(current_user.email)
		print("Verified? " + current_user.email_verified as String)


func _on_RealVerifyBeforeUpdate_pressed():
	print("############################################################ VERIFY BEFORE UPDATE")
	var real = $RealEmail.text
	var result = yield(current_user.verify_before_update_email(real), "completed")
	if result is FirebaseError:
		print(result.code)
	else:
		print(">>> email verification sent to new/real email")


func _on_RealSignIn_pressed():
	print("############################################################ SIGN IN EMAIL/PWD")
	var real = $RealEmail.text
	var pwd = $RealEmailPwd.text
	var result = yield(auth.sign_in_with_email_and_password(real, pwd), "completed")
	if result is FirebaseError:
		print(result.code)
	else:
		print(">>> signed in")
		current_user = result as FirebaseUser
		print(current_user.email)
		print("Verified? " + current_user.email_verified as String)


func _on_RealResetPwd_pressed():
	print("############################################################ RESET PWD")
	var real = $RealEmail.text
	var result = yield(auth.send_password_reset_email(real), "completed")
	if result is FirebaseError:
		print(result.code)
	else:
		print(">>> password-reset email sent")


func _on_RealDelete_pressed():
	print("############################################################ DELETE REAL")
	var real = $RealEmail.text
	var pwd = $RealEmailPwd.text
	for email in [real, WRONGEMAIL]:
		var result = yield(auth.sign_in_with_email_and_password(email, pwd), "completed")
		if result is FirebaseError:
			print(result.code)
			result = yield(auth.sign_in_with_email_and_password(email, pwd), "completed")
			if result is FirebaseError:
				print(result.code)
				continue
		var user = result as FirebaseUser
		result = yield(user.delete(), "completed")
		if result is FirebaseError:
			print(result.code)
			print("OOPS! Delete user via Firebase Authentication console to recover: " + email)
		else:
			print(">>> deleted real-email user: " + email)


################################################################################
################################################################################
################################################################################


# Locked area allows all to read but only auth'd to write.

func _on_NoAuthWriteToLocked_pressed():
	auth.sign_out()
	var ref : FirebaseReference = db.get_reference_lite("locked")
	var result = yield(ref.put("yo"), "completed")
	if result is FirebaseError:
		print(result.code)
		print("PASS: No-auth write failed to locked area.")
	else:
		print("FAIL: No-auth write was allowed to locked area.")


func _on_AuthWriteToLocked_pressed():
	var result = yield(auth.sign_in_with_email_and_password("pele@football.rules", "pelerules"), "completed")
	if result is FirebaseError:
		print(result.code)
	else:
		print(">>> signed in")
		var ref : FirebaseReference = db.get_reference_lite("locked")
		result = yield(ref.put({"bro": "amigo"}), "completed")
		if result is FirebaseError:
			print(result.code)
			print("FAIL: Auth write failed to locked area.")
		else:
			print("PASS: Auth write was allowed to locked area.")
	auth.sign_out()


func _on_NoAuthReadFromLocked_pressed():
	auth.sign_out()
	var ref : FirebaseReference = db.get_reference_lite("locked")
	var result = yield(ref.fetch(), "completed")
	if result is FirebaseError:
		print(result.code)
		print("FAIL: No-auth read failed from locked area.")
	else:
		print(result.value())
		print("PASS: No-auth read was allowed from locked area.")


# Secret area allows only auth'd to read and write.
#TODO: test secret area... but don't really see why anymore--auth is tested enough.


################################################################################
################################################################################
################################################################################


# If path does not yet exist, listener first sends:  event: put, data: {"path":"/","data":null}
# This tests handling this odd response.
# Expected result: Snap: {root:Null}
func _on_PathNotExist_pressed():
	var ref : FirebaseReference = db.get_reference_lite("path-not-exist", true)
	yield(ref.enable_listener(), "completed")
	print("listening")
	ref.disable_listener()


# Basic dictionary testing including deep paths.
func _on_Dict_pressed():
	var ref : FirebaseReference = db.get_reference_lite("dict-test", true)
	yield(ref.enable_listener(), "completed")
	print("listening")
	yield(ref.put({"a/a/a": 1}), "completed")  ### errored by FB
	yield(ref.put({"a": 1}), "completed")
	yield(ref.update({"b": 1}), "completed")
	yield(ref.update({"b": 2}), "completed")
	yield(ref.update({"c": 1, "d": 1}), "completed")
	yield(ref.update({"e/f/g": 1}), "completed")
	yield(ref.update({"e/f": {"g/h": 1}}), "completed")  ### errored by FB
	#
	ref.disable_listener()


# Deep-path delete testing.
func _on_Dict2_pressed():
	var ref : FirebaseReference = db.get_reference_lite("dict-test", true)
	yield(ref.enable_listener(), "completed")
	print("listening")
	yield(ref.update({"i": 1}), "completed")
	yield(ref.update({"i": null}), "completed")
	yield(ref.update({"i/j": 1}), "completed")
	yield(ref.update({"i/j": null}), "completed")
	yield(ref.update({"i": 1}), "completed")
	yield(ref.update({"i/j": 1}), "completed")
	yield(ref.update({"i": null}), "completed")
	yield(ref.update({"i/j": 1, "i/k": 1}), "completed")
	yield(ref.update({"i/j": null}), "completed")
	yield(ref.update({"i": 1}), "completed")
	yield(ref.update({"i/j/k": 1}), "completed")
	yield(ref.update({"i/j": 1, "i/k": 1}), "completed")
	yield(ref.update({"i/j": 2, "i": null}), "completed")  ### errored by FB
	yield(ref.update({"i/j": null, "i": null}), "completed")  ### errored by FB
	yield(ref.update({"i": null, "i/k": null}), "completed")  ### errored by FB
	#yield(ref.update({"i": null, "i": null}), "completed")  ### GDScript error
	# curl -X PATCH -d '{"i": null, "i": null}' 'https://godotfirebaselite-default-rtdb.firebaseio.com/dict-test.json'
	yield(ref.update({"i": null, "i/": null}), "completed")  ### errored by FB
	yield(ref.update({"i/j": null, "i/k": null}), "completed")
	yield(ref.update({"i/j": 1, "i/k": 1}), "completed")
	#
	ref.disable_listener()


# Deep-listener/deep-path testing.
func _on_Dict3_pressed():
	var ref : FirebaseReference = db.get_reference_lite("dict-test", true)
	yield(ref.enable_listener(), "completed")
	print("listening")
	var ref_i : FirebaseReference = db.get_reference_lite("dict-test/i", true)
	yield(ref_i.put({"j": 2, "k": 2}), "completed")
	yield(ref_i.update({"j/k": 11, "k": 11}), "completed")
	yield(ref_i.put({"j": 22}), "completed")
	yield(ref_i.update({"j/k/l": 22}), "completed")
	yield(ref_i.update({"j/k/l": null}), "completed")
	var ref_n : FirebaseReference = db.get_reference_lite("dict-test/i/l/n", true)
	yield(ref_n.update({"o/p/q": 1, "o/r": 1}), "completed")
	yield(ref_n.put({"p": 1}), "completed")
	yield(ref_n.put(null), "completed")
	yield(ref_n.put({"p": 1}), "completed")
	yield(ref_n.put("foo"), "completed")
	yield(ref_n.remove(), "completed")
	#
	ref.disable_listener()


# List testing.
# https://firebase.google.com/docs/database/web/lists-of-data
func _on_List_pressed():
	var ref : FirebaseReference = db.get_reference_lite("list-test/somelist", true)
	yield(ref.enable_listener(), "completed")
	print("listening")
	yield(ref.push("aaa"), "completed")
	var ref_bbb : FirebaseReference = yield(ref.push("bbb"), "completed")
	yield(ref_bbb.put({"a": 1}), "completed")
	yield(ref_bbb.update({"a/b/c": 1}), "completed")
	var ref_empty : FirebaseReference = yield(ref.push(), "completed")
	yield(ref_empty.put({"ccc": {"a": 123}}), "completed")
	yield(ref_bbb.update({"a/b/c": null}), "completed")
	#
	ref.disable_listener()


func _on_Timestamp_pressed():
	var ref : FirebaseReference = db.get_reference_lite("timestamp-test", true)
	yield(ref.enable_listener(), "completed")
	print("listening")
	yield(ref.put({"a": db.ServerValue.TIMESTAMP}), "completed")
	ref.disable_listener()


func _on_Increment_pressed():
	var ref : FirebaseReference = db.get_reference_lite("increment-test", true)
	yield(ref.enable_listener(), "completed")
	print("listening")
	yield(ref.put({"a": 1}), "completed")
	yield(ref.update({"a": db.ServerValue.increment(1)}), "completed") # works either way
	yield(ref.put({"a": db.ServerValue.increment(1.23)}), "completed") # works either way
	ref.disable_listener()


################################################################################


# Basic array tests.
# curl -X POST -d '{"user_id" : "jack", "text" : "Ahoy!"}' 'https://godotfirebaselite-default-rtdb.firebaseio.com/message_list.json'
func _on_Array_pressed():
	var ref : FirebaseReference = db.get_reference("array-test", true)
	yield(ref.enable_listener(), "completed")
	print("listening")
	yield(ref.put(["a", "b", {"c": 1}]), "completed")
	yield(ref.update([{"c": 2}]), "completed")  ### errored by FB
	yield(ref.update({"2": {"c": 2}}), "completed")
	yield(ref.update({"2": {"c": null}}), "completed")
	#
	ref.disable_listener()

	# Is it possible for an update/patch event on an array to generate a return patch event?
	# I hope not... it is.  Ugh.


# Slightly more complex array tests.
func _on_Array2_pressed():
	var ref : FirebaseReference = db.get_reference("array-test", true)
	yield(ref.enable_listener(), "completed")
	print("listening")
	yield(ref.put(["a", "b", {"c": 1}]), "completed")
	# Go sparse:
	yield(ref.update({"4": {"c": 1}}), "completed")
	# Fill sparse in:
	yield(ref.update({"3": {"c": 1}}), "completed")
	# Make it sparse again:
	yield(ref.update({"3": null}), "completed")
	# Push beyond FB's treatment of this as an array by making it too sparse:
	yield(ref.update({"10": {"c": 1}}), "completed")
	# Still comes back as a patch into an array.
	# But, if you fetch it again, it will come back as a dict...  Do I care???
	# Try a deeper edit:
	var ref_5 : FirebaseReference = db.get_reference("array-test/5", true)
	yield(ref_5.update({"a/b/c": {"c": 1}}), "completed")
	yield(ref_5.update({"a/b": [1, 2, 3]}), "completed")
	var ref_10 : FirebaseReference = db.get_reference("array-test/10", true)
	yield(ref_10.remove(), "completed")
	#
	ref.disable_listener()


# Try a root-level array.
# NOTE: This, unsurprisingly, broke after adding r/w rules for auth testing.
#       Otherwise, this was a working test on a completely open db.
func _on_Array3_pressed():
	print("\n!!! This test was disabled after adding r/w rules for auth testing.\n")
	return
	#
	var ref : FirebaseReference = db.get_reference("", true)
	yield(ref.remove(), "completed")
	yield(ref.enable_listener(), "completed")
	print("listening")
	yield(ref.put(["a", "b", {"c": 1}]), "completed")
	# Go sparse:
	yield(ref.update({"4": {"c": 1}}), "completed")
	# Fill sparse in:
	yield(ref.update({"3": {"c": 1}}), "completed")
	# Make it sparse again:
	yield(ref.update({"3": null}), "completed")
	# Kill it the hard way:
	yield(ref.update({"0": null, "1": null, "2": null, "4": null}), "completed")
	#
	ref.disable_listener()


# Go even deeper.
func _on_Array4_pressed():
	var ref : FirebaseReference = db.get_reference("array-test", true)
	yield(ref.enable_listener(), "completed")
	print("listening")
	yield(ref.put(["a", "b", {"c": 1}]), "completed")
	yield(ref.update({"4/a/b": [1, 2, 3]}), "completed")
	var ref_hello : FirebaseReference = db.get_reference("array-test/4/a/b/0/hello", true)
	yield(ref_hello.put({"c": "here"}), "completed")
	yield(ref_hello.update({"c/d": "there"}), "completed")

