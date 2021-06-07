################################################################################
# The Firebase Database service interface.
#
# Do not call this constructor directly. Instead, use `firebase.database()`.
#
# https://firebase.google.com/docs/reference/js/firebase.database.Database
################################################################################
extends Node
class_name FirebaseDatabase, "icon.png"

################################################################################
# ServerValue fake class.
#
# https://firebase.google.com/docs/reference/js/firebase.database
#var server_value : FirebaseServerValue = FirebaseServerValue.new()
const ServerValue = preload("server_value.gd")
################################################################################

#var app : FirebaseApp
var app : Node  # FirebaseApp (too circular to type this)


#func _init(config : Dictionary):
func _init(app : Node):
	self.app = app #as FirebaseApp


# Returns a reference to the specified node in the database.
func get_reference(path : String = "", debug : bool = false) -> FirebaseReference:
    var ref : FirebaseReference = FirebaseReference.new(self, path, debug)
    add_child(ref)
    return ref

func get_reference_lite(path : String = "", debug : bool = false) -> FirebaseReference:
    var ref : FirebaseReference = FirebaseReference.new(self, path, debug, true)
    add_child(ref)
    return ref
