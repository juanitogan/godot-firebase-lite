################################################################################
# A `FirebaseDataSnapshot` contains data from a Database location.
#
# Any time you read data from the Database, you receive the data as a
# `FirebaseDataSnapshot`, such as with `fetch()`.
# A `FirebaseDataSnapshot` is passed to the event callbacks you attach with
# `connect()` ~~or `once()`~~.
# You can extract the contents of the snapshot by calling the `value()` method.
#
# https://firebase.google.com/docs/reference/js/firebase.database.DataSnapshot
################################################################################
# It appears that in order to update a dict by reference that the left side of
# the assignment must reference a child [key], as in parent_node[child_key].
################################################################################
#TODO: all this deep copying... is there not a better way?
################################################################################
extends Reference
class_name FirebaseDataSnapshot, "icon.png"

const SEP : String = "/"
const ROOT : String = "root"

var key									# can be null - The last part of the ref's path.
var _data : Dictionary = {ROOT: null}	# A root node helps updating by reference.
#var ref: Object  # no use case yet, later maybe


func _init(key, data):
	self.key = key
	# A snapshot, by its very nature, should be a deep copy, so always make sure of that.
	match typeof(data):
		TYPE_DICTIONARY, TYPE_ARRAY:
			_data[ROOT] = data.duplicate(true)
		_:
			_data[ROOT] = data


# Returns a deep copy of the snapshot.
#
# Depending on the data in the snapshot, the `value()` method may return a
# scalar type (string, number, or boolean), an array, or a dictionary.
# It may also return null, indicating that the snapshot is empty (contains no data).
func value():
	match typeof(_data[ROOT]):
		TYPE_DICTIONARY, TYPE_ARRAY:
			return _data[ROOT].duplicate(true)
		_:
			return _data[ROOT]
