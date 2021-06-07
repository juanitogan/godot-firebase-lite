################################################################################
# Class for processing SSE listener events.
#
# So far, these objects have a 1:1 relationship to FirebaseReference objects.
# Thus, this class could be built into the Ref class if desired.
# In fact, this class is tightly coupled to objects that have the same signals as a Ref class.
#
# While this "lite" version is technically a tiny bit faster than the heavier version,
# it is not fast enough to warrant its existance on that alone.
# No, this mostly exists because it is easier to understand and troubleshoot.
# If nothing else, identifying whether a bug is array-related or not is useful.
# Yes, it's a pain to maintain two sets of similar code... but, alas....
#
# I may dump this version after all--or leave it as unlisted (and unsupported).
# Or not.  Arrays are a monster to support.  Twice the code... so far.
################################################################################
# Should maybe come back and just compare oldest-child nodes before and after
# since I'm somewhat doing that already (but only on a put to root).
# Seems that would be far simpler.
# Especially, in the heavier version with the arrays... which is pretty insane
# trying write all use cases for it up front.
# Was I trying to avoid the cost of such a loop?...  Maybe.
# It would be fast enough with few oldest-children, but the cost grows exponentially.
################################################################################
extends Reference
class_name FirebaseEventProcessorLite, "icon.png"

const SEP : String = "/"

var _ref: Object
var _snap : FirebaseDataSnapshot
var _debug: bool

var _children_added : Array		# stores oldest-child keys
var _children_changed : Array	# stores oldest-child keys
#var _children_removed : Array	# stores oldest-child keys, just a gatekeeper to the *_snaps array
var _children_tbd : Array		# stores oldest-child keys, just a gatekeeper to the *_snaps array
var _children_removed_snaps : Array	# stores snapshots of the data to be removed
var _children_tbd_snaps : Array		# stores snapshots of the data to be removed (potentially)


func _init(ref: Object):
	_ref = ref
	_snap = FirebaseDataSnapshot.new(_ref.key, null)
	_debug = ref.debug


# Returns a deep copy of the listener's snapshot.
func get_snapshot() -> FirebaseDataSnapshot:
	return FirebaseDataSnapshot.new(_snap.key, _snap.value())


# Handle the SSE put event.
func put(event_data : Dictionary) -> void:
	if _debug: print("\n<<< Put: %s === %s" % [event_data.path, event_data.data])
	_process_event(event_data.path, event_data.data)


# Handle the SSE patch event.
func patch(event_data : Dictionary) -> void:
	if _debug: print("\n<<< Patch: %s ### %s" % [event_data.path, event_data.data])
	_process_event(event_data.path, event_data.data, true)


################################################################################
# Process the put or patch event and update the snapshot accordingly.
#
# It appears that in order to update a dict by reference that the left side of
# the assignment must reference a child [key], as in parent_node[child_key].  <<<<<<<<
#
#TODO:	When a point only contains only a single scalar value--and not a list
#		of some sort (like a dict or array) does changing it produce a child_changed
#		event?  I'm guessing no for now... and that's what value_changed is for.
#
func _process_event(path: String, payload, patch: bool = false) -> void:
	var keys : Array = [_snap.ROOT] + Array(path.split(SEP, false))
	var final_key = keys.pop_back()
	var keys_size = keys.size()
	var payload_type = typeof(payload)
	
	########################################
	# Preprocess for child events.
	#
	# Tried to do this in the path traversal but it was too complex there.
	#
	_children_added = []
	_children_changed = []
	#_children_removed = []
	_children_tbd = []
	_children_removed_snaps = []
	_children_tbd_snaps = []
	if _snap._data[_snap.ROOT] == null:
		_snap._data = {_snap.ROOT: {}}  # prep for adding something
	var node = _snap._data[_snap.ROOT]
	# Root-level event or deeper?
	if keys_size == 0:

		# This is a root event, which can include multiple child events.
		if patch:

			for k in payload.keys():
				# Handle deep-path patches/updates.
				var deep_keys : Array = Array(k.split(SEP, false, 1))
				var deep_root_key : String = deep_keys[0]
				if node.has(deep_root_key):
					#TODOne: what about {a/b:1,a:null} - should maybe process and trigger one at a time - FB ignored this one
					match typeof(payload[k]):
						TYPE_NIL:
							if deep_keys.size() == 1:
								if _debug: print("    Child removed: ", k)
								# Dupes like {a:null,a:null} are not possible from GDScript, but maybe other tools?
								# Nope.  Comes back as simply {a:null} when sent to REST.
								_children_removed_snaps.push_back(FirebaseDataSnapshot.new(deep_root_key, node[deep_root_key]))
							else:
								# Will be determined after null payload processing later.
								if _debug: print("    Child potential remove: ", k)
								# Dupes can happen like {a/b:null,a/c:null}.
								if !_children_tbd.has(deep_root_key):
									_children_tbd.push_back(deep_root_key)
									_children_tbd_snaps.push_back(FirebaseDataSnapshot.new(deep_root_key, node[deep_root_key]))
						_:
							#TODO: could still be a remove if final payload node is null and no other content (if such updates exist)
							if _debug: print("    Child changed: ", k)
							# Dupes can happen like {a/b:1,a/c:1}.
							if !_children_changed.has(deep_root_key):
								_children_changed.push_back(deep_root_key)
				else:
					match typeof(payload[k]):
						TYPE_NIL:
							pass
						_:
							if _debug: print("    Child added: ", k)
							# Dupes can happen like {a/b:1,a/c:1}.
							if !_children_added.has(deep_root_key):
								_children_added.push_back(deep_root_key)

		else: # put

			if payload:
				for k in payload.keys():
					if node and node.has(k):
						match typeof(payload[k]):
							TYPE_NIL:
								if _debug: print("    Child removed: ", k)
								_children_removed_snaps.push_back(FirebaseDataSnapshot.new(k, node[k]))
							TYPE_DICTIONARY, TYPE_ARRAY:
								# Pessimistic, for now.
								#TODO: could still be a remove if final payload node is null and no other content (if such updates exist)
								#TODO: consider hashing or other comparisons before determining change
								if _debug: print("    Child changed: ", k)
								_children_changed.push_back(k)
							_:
								if node[k] != payload[k]:
									if _debug: print("    Child changed: ", k)
									_children_changed.push_back(k)
					else:
						match typeof(payload[k]):
							TYPE_NIL:
								pass
							_:
								if _debug: print("    Child added: ", k)
								_children_added.push_back(k)
				for k in node.keys():
					if !payload.has(k):
						if _debug: print("    Child removed: ", k)
						_children_removed_snaps.push_back(FirebaseDataSnapshot.new(k, node[k]))
			else:
				# This handles a null sent to /.
				for k in node.keys():
					if _debug: print("    Child removed: ", k)
					_children_removed_snaps.push_back(FirebaseDataSnapshot.new(k, node[k]))

	else:

		# Non-root events can still add/change/remove a single child.
		var k = final_key if keys_size == 1 else keys[1]  # keys_size cannot be 0 here
		var exists : bool = node.has(k)
		if node and exists:
			match payload_type:
				TYPE_NIL:
					if keys_size == 1:
						if _debug: print("    Child removed: ", k)
						_children_removed_snaps.push_back(FirebaseDataSnapshot.new(k, node[k]))
					else:  #  > 1
						# Will be determined after null payload processing later.
						if _debug: print("    Child potential remove: ", k)
						_children_tbd_snaps.push_back(FirebaseDataSnapshot.new(k, node[k]))
				TYPE_DICTIONARY:
					if payload.values()[0] == null:
						if _debug: print("    Child potential remove: ", k)
						_children_tbd_snaps.push_back(FirebaseDataSnapshot.new(k, node[k]))
					else:
						if _debug: print("    Child changed: ", k)
						_children_changed.push_back(k)
				_:
					if _debug: print("    Child changed: ", k)
					_children_changed.push_back(k)
		else:
			if _debug: print("    Child added: ", k)
			_children_added.push_back(k)

	########################################
	# Traverse the snapshot.
	var nodes : Array = []
	node = _snap._data
	for k in keys:
		# Keep a copy of the node route for later retreat (when needed).
		nodes.push_back([k, node])
		# If the path node doesn't exist for some reason, create it.
		if !node.has(k):
			node[k] = {}
		# All good, reset the pointer a level deeper.
		node = node[k]

	########################################
	# Do it.
	match payload_type:
		TYPE_NIL:
			# Check for delete root.
			if keys_size == 0:
				_snap._data = {_snap.ROOT: null}
			else:
				node.erase(final_key)
				# Crawl back up the parents, deleting them as well if they are empty.
				var i = -1
				var nsize = -nodes.size()
				while i > nsize and node.empty():
					node = nodes[i][1]
					node.erase(nodes[i][0])
					i -= 1
				# Check for delete root.
				if _snap._data[_snap.ROOT].empty():
					_snap._data = {_snap.ROOT: null}
		TYPE_DICTIONARY:
			if patch:
				# Patch doesn't replace as this level, but replaces/adds one level deeper.
				#for k in payload.keys():
				#	match typeof(payload[k]):
				#		TYPE_NIL:
				#			node.erase(final_key)
				#		TYPE_DICTIONARY:
				#			node[final_key][k] = payload[k].duplicate(true)
				#		_:
				#			node[final_key][k] = payload[k]
				for k in payload.keys():
					# Handle deep-path patches like {a/b/c:1}.
					# Fortunately, you can't use deep paths below root like {a:{b/c:1}}.
					# https://firebase.googleblog.com/2015/09/introducing-multi-location-updates-and_86.html
					# (Maybe relegate this to the heavy version only.)
					var deep_keys : Array = Array(k.split(SEP, false))
					var deep_final_key = deep_keys.pop_back()
					var deep_nodes : Array = []
					if !node.has(final_key):
						node[final_key] = {}
					var deep_node = node[final_key]
					for dk in deep_keys:
						# Keep a copy of the node route for later retreat (when needed).
						deep_nodes.push_back([dk, deep_node])
						# If the path node doesn't exist for some reason, create it.
						if !deep_node.has(dk):
							deep_node[dk] = {}
						# If the node type can't handle a child, wipe it out and reset it so it can.
						elif typeof(deep_node[dk]) != TYPE_DICTIONARY:
							deep_node[dk] = {}
						# All good, reset the pointer a level deeper.
						deep_node = deep_node[dk]
					match typeof(payload[k]):
						TYPE_NIL:
							deep_node.erase(deep_final_key)
							# Crawl back up the parents, deleting them as well if they are empty.
							var di = -1
							var dnsize = -deep_nodes.size()
							while di >= dnsize and deep_node.empty():
								deep_node = deep_nodes[di][1]
								deep_node.erase(deep_nodes[di][0])
								di -= 1
							# Check the non-deep side of the tree for further deletes.
							if node[final_key].empty():
								# Check for delete root.
								if keys_size == 0:
									_snap._data = {_snap.ROOT: null}
								else:
									node.erase(final_key)
									# Crawl back up the parents, deleting them as well if they are empty.
									var i = -1
									var nsize = -nodes.size()
									while i > nsize and node.empty():
										node = nodes[i][1]
										node.erase(nodes[i][0])
										i -= 1
									# Check for delete root.
									if _snap._data[_snap.ROOT].empty():
										_snap._data = {_snap.ROOT: null}
						TYPE_DICTIONARY:
							deep_node[deep_final_key] = payload[k].duplicate(true)
						_:
							# Handle data type changes like {"a":1} to {"a":{"b":1}}.
							if typeof(deep_node) != TYPE_DICTIONARY:
								deep_node = deep_nodes[-1][1]
								deep_node[deep_nodes[-1][0]] = {}
								deep_node = deep_node[deep_nodes[-1][0]]
							deep_node[deep_final_key] = payload[k]
			else:	
				node[final_key] = payload.duplicate(true)
		_:
			node[final_key] = payload

	########################################
	_finish_it()


func _finish_it() -> void:
	########################################
	# Postprocess child events.
	# Return key should be the watched node (null if root is watched).
	# Have not tested an array point in JS yet to see if the key is a string or int,
	# but going with string -- it is a key name after all, which can only be strings.
	var node = _snap._data[_snap.ROOT]

	for n in _children_added:
		_ref.emit_signal("child_added", FirebaseDataSnapshot.new(n, node[n]))
		if _debug: print("+++ child_added: ", n, ": ", node[n])

	for n in _children_changed:
		_ref.emit_signal("child_changed", FirebaseDataSnapshot.new(n, node[n]))
		if _debug: print("/// child_changed: ", n, ": ", node[n])
		# Might have to come back and treat these as _children_tbd
		# if a deep null can kill an oldest-child.

	for s in _children_removed_snaps:
		_ref.emit_signal("child_removed", s)
		if _debug: print("--- child_removed: ", s.key, ": ", s._data[s.ROOT])

	for s in _children_tbd_snaps:
		# Was child removed after all?
		# If it was the last item in the db, and removed, then root node will be null.
		if node != null and node.has(s.key):
			# Nope.
			_ref.emit_signal("child_changed", FirebaseDataSnapshot.new(s.key, node[s.key]))
			if _debug: print("/// child_changed: ", s.key, ": ", node[s.key])
		else:
			# Yup.
			_ref.emit_signal("child_removed", s)
			if _debug: print("--- child_removed: ", s.key, ": ", s._data[s.ROOT])

	# https://firebase.google.com/docs/database/admin/retrieve-data#section-event-guarantees
	#   Value events are always triggered last and are guaranteed to contain updates
	#   from any other events which occurred before that snapshot was taken.
	_ref.emit_signal("value_changed", get_snapshot())

	if _debug: print(">>> Snap: ", _snap._data)
