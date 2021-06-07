################################################################################
# A Firebase app holds the initialization information for a collection of services.
#
# Do not call this constructor directly. Instead, use `firebase.initialize_app()`
# to create an app.
#
# https://firebase.google.com/docs/reference/js/firebase.app.App
################################################################################
extends Node
class_name FirebaseApp, "icon.png"

const SEP = "/"

#TODO: consider has_auth prop (etc) for checking before ref REST calls - but probably not needed

#var app_name : String setget ,get_name  # The (read-only) name for this app. (Do we still care since deprecating Firebase.apps[]?)
#func get_name() -> String: return name

var _options : Dictionary  # solves the prob of having an init param of the same name as a var without a setter
var options : Dictionary setget ,_get_options  # The (read-only) configuration options for this app.
func _get_options() -> Dictionary: return _options.duplicate(true)  # don't like; a dupe is too busy

#var _auth : FirebaseAuth
#var _db : FirebaseDatabase
var _auth : Node
var _db : Node

var _package_path : String  # because load() doens't allow relative paths (../)


func _init(options : Dictionary, name : String):
	_options = options.duplicate(true)
	self.name = name  # sets Node.name, to be precise
	# Strip any tailing separator the user might have copied from the Firebase console.
	_options.databaseURL = _options.databaseURL.rstrip(SEP)

	# Find the parent path of the package folder because load() doens't allow relative paths.
	# This allows the user to place us any depth in their res:// tree.
	_package_path = get_script().resource_path.rsplit("/", true, 2)[0] + "/"


#TODO:
# Renders this app unusable and frees the resources of all associated services.
#func delete():
#	pass


# Loads and gets the `FirebaseAuth` service for the current app.
func auth() -> Node:
	if !_auth:
		var FirebaseAuth = load(_package_path + "firebase_auth_lite/auth.gd")
		if FirebaseAuth:
			_auth = FirebaseAuth.new(self)
			add_child(_auth)
		else:
			push_error("'auth.gd' from FirebaseAuthLite package not found.")
	return _auth


# Loads and gets the `FirebaseDatabase` service for the current app.
func database() -> Node:
	if !_db:
		var FirebaseDatabase = load(_package_path + "firebase_database_lite/database.gd")
		if FirebaseDatabase:
			_db = FirebaseDatabase.new(self)
			add_child(_db)
		else:
			push_error("'database.gd' from FirebaseDatabaseLite package not found.")
	return _db
