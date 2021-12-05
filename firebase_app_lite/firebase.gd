################################################################################
# The core of the Godot Firebase Lite API.
# The parent node to all Firebase apps and services.
#
# Construct this as an "AutoLoad Singleton" and not as a regular class.
# (Although, you can construct it as a new class instead if you really would rather manage it that way.)
#
# https://firebase.google.com/docs/reference/js/firebase
################################################################################
extends Node
class_name Firebase, "icon.png"

const SDK_VERSION = "0.1.1"  # The current SDK version.

#var apps : Array = []  # FirebaseApp; deprecated: use Node.get_children()/get_node() instead

const _DEFAULT = "[DEFAULT]"

var _default_app : FirebaseApp


func _init():
	#TODO: maybe search for existant packages here ??
	pass


# Creates and initializes a Firebase app instance.
func initialize_app(options : Dictionary, name : String = _DEFAULT) -> FirebaseApp:
	#TODO: validate name
	var app = FirebaseApp.new(options, name)
	#apps.push_back(app)  # redundant, no?
	add_child(app, true)
	if name == _DEFAULT:
		_default_app = app
	return app


################################################################################
# Modules
################################################################################


# Retrieves a Firebase app instance.
# https://firebase.google.com/docs/reference/js/firebase.app
func app(name : String = _DEFAULT) -> FirebaseApp:
	#TODO: validate name
	return get_node(name) as FirebaseApp


# Gets the `FirebaseAuth` service for the default app or a given app.
# https://firebase.google.com/docs/reference/js/firebase.auth
func auth(app : FirebaseApp = _default_app) -> Node:
	return app.auth()


# Gets the `FirebaseDatabase` service for the default app or a given app.
# https://firebase.google.com/docs/reference/js/firebase.database
func database(app : FirebaseApp = _default_app) -> Node:
	return app.database()
