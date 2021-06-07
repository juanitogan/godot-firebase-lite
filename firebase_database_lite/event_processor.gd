################################################################################
# The heavier version of the listener processor.
# This one handles more use cases with Firebase arrays.
################################################################################
extends FirebaseEventProcessorLite
class_name FirebaseEventProcessor, "icon.png"


func _init(ref: Object).(ref):
	pass


################################################################################
# Process the put or patch event and update the snapshot accordingly.
#
#TODO:	Arrays? What arrays?  There are no **arrays** in Firebase!!  Oh, array fakies:
#		https://firebase.googleblog.com/2014/04/best-practices-arrays-in-firebase.html
#		DONE-ISH
#
func _process_event(path: String, payload, patch: bool = false) -> void:
	var keys : Array = [_snap.ROOT] + Array(path.split(SEP, false))
	var final_key = keys.pop_back()
	var keys_size = keys.size()
	var payload_type = typeof(payload)
	
	########################################
	# Preprocess for child events.
	_children_added = []
	_children_changed = []
	#_children_removed = []
	_children_tbd = []
	_children_removed_snaps = []
	_children_tbd_snaps = []
	if _snap._data[_snap.ROOT] == null:
		_snap._data = {_snap.ROOT: {}}  # prep for adding something
	var node = _snap._data[_snap.ROOT]
	var root_node_type = typeof(node)
	# Root-level event or deeper?
	if keys_size == 0:

		# This is a root event, which can include multiple child events.
		if patch:

			# I'm currently guessing a patch event cannot include array items.
			#   Nope, it can, if you try stupidly hard to do so... with an int-keyed dict update.
			for k in payload.keys():
				# Handle deep-path patches/updates.
				var deep_keys : Array = Array(k.split(SEP, false, 1))
				var deep_root_key = deep_keys[0]
				var exists : bool
				if root_node_type == TYPE_ARRAY:
					deep_root_key = int(deep_root_key)
					exists = deep_root_key < node.size() and node[deep_root_key] != null
				else:
					exists = node.has(deep_root_key)
				if exists:
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

			if payload_type == TYPE_ARRAY:
				match root_node_type:
					TYPE_ARRAY:
						var old_size : int = node.size()
						var new_size : int = payload.size()
						for i in min(old_size, new_size):
							if node[i] != payload[i]:
								# Pessimistic, for now.
								#TODO: currently don't care that dicts and arrays never equate without hash
								if _debug: print("    Array item changed: ", i)
								_children_changed.push_back(i)
						if new_size > old_size:
							for i in range(old_size, new_size):
								if _debug: print("    Array item added: ", i)
								_children_added.push_back(i)
						elif new_size < old_size:
							for i in range(new_size, old_size):
								if _debug: print("    Array item removed: ", i)
								_children_removed_snaps.push_back(FirebaseDataSnapshot.new(i, node[i]))
					TYPE_DICTIONARY:
						# Check for equivalent array entries in the dict.
						for i in payload.size():
							var k = String(i)
							if node.has(k):
								if node[k] != payload[i]:
									# Pessimistic, for now.
									#TODO: currently don't care that dicts and arrays never equate without hash
									if _debug: print("    Child changed to array item: ", i)
									_children_changed.push_back(i)
							else:
								if _debug: print("    Array item added: ", i)
								_children_added.push_back(i)
						# Check for dict entries indexed larger than the array, or not a number.
						var new_size : int = payload.size()
						for k in node.keys():
							var idx : int = int(k)
							if idx >= new_size or String(idx) != k:
								if _debug: print("    Child removed: ", k)
								_children_removed_snaps.push_back(FirebaseDataSnapshot.new(k, node[k]))
					_: # includes TYPE_NIL
						# Do not fire child_removed for scalars that might have been here.
						for i in payload.size():
							if _debug: print("    Array item added: ", i)
							_children_added.push_back(i)

			elif root_node_type == TYPE_ARRAY: # payload is dict, null, scalar
				var old_size : int = node.size()
				var idx : int = -1
				if payload:
					for k in payload.keys():
						idx = int(k)
						# Is k really the string of an integer?
						if idx < old_size and String(idx) == k:
							match typeof(payload[k]):
								TYPE_NIL:
									if _debug: print("    Array item removed: ", idx)
									_children_removed_snaps.push_back(FirebaseDataSnapshot.new(idx, node[idx]))
								TYPE_DICTIONARY, TYPE_ARRAY:
									# Pessimistic, for now.
									#TODO: could still be a remove if final payload node is null and no other content (if such updates exist)
									#TODO: consider hashing or other comparisons before determining change
									if _debug: print("    Array item changed to child: ", k)
									_children_changed.push_back(k)
								_:
									if node[idx] != payload[k]:
										if _debug: print("    Array item changed to child: ", k)
										_children_changed.push_back(k)
						else:
							match typeof(payload[k]):
								TYPE_NIL:
									pass
								_:
									if _debug: print("    Child added: ", k)
									_children_added.push_back(k)
				for i in range(idx + 1, old_size):
					if _debug: print("    Array item removed: ", i)
					_children_removed_snaps.push_back(FirebaseDataSnapshot.new(i, node[i]))
					# This handles a null send to \ as well.

			else: # dict, null, scalar
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
		var exists : bool
		if root_node_type == TYPE_ARRAY:
			k = int(k)
			exists = k < node.size() and node[k] != null
		else:
			exists = node.has(k)
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
		# Check if this is a node into a local array from Firebase's auto-array feature.
		if root_node_type == TYPE_ARRAY:
			var idx : int = int(k)
			# Verify that the possible integer is the integer we think it is
			# by converting it to an int and back to a string
			# to see if it comes out the same.
			if String(idx) == k:
				# Yes, it is a valid int.
				# Keep a copy of the node route for later retreat (when needed).
				nodes.push_back([idx, node])
				# Does it fit?
				if node.size() <= idx:
					# Array is too small for a presumed new entry, so resize it.
					#TODO: could maybe first make sure we aren't growing by more than 1 or 2... or not
					node.resize(idx + 1)
				node = node[idx]
				continue
			#TODO: is this really the right fallback?
		# Keep a copy of the node route for later retreat (when needed).
		nodes.push_back([k, node])
		# If the path node doesn't exist for some reason, create it.
		if !node.has(k):
			node[k] = {}
		# All good, reset the pointer a level deeper.
		node = node[k]

	# If the parent is an array, convert the final key to an int (if possible).
	var penult_node_type = typeof(node)
	if penult_node_type == TYPE_ARRAY:
		var idx : int = int(final_key)
		# Verify the possible integer.
		if String(idx) == final_key:
			# Yes, it is a valid int.
			# Does it fit?
			if node.size() <= idx:
				# Array is too small for a presumed new entry, so resize it.
				node.resize(idx + 1)
			final_key = idx
		else:
			#TODO: is this really the right fallback?
			pass

	########################################
	# Do it.
	match payload_type:
		TYPE_NIL:
			# Check for delete root.
			if keys_size == 0:
				_snap._data = {_snap.ROOT: null}
			else:
				if penult_node_type == TYPE_ARRAY:
					if final_key == node.size() - 1:
						node.pop_back()
						# Crawl backwards through the array removing trailing nulls (due to fakie gaps).
						while node.size() > 0 and node[-1] == null:
							node.pop_back()
					else:
						node[final_key] = null
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
						# Check if this is a node into a local array from Firebase's auto-array feature.
						if typeof(deep_node) == TYPE_ARRAY:
							var idx : int = int(dk)
							# Verify that the possible integer is the integer we think it is
							# by converting it to an int and back to a string
							# to see if it comes out the same.
							if String(idx) == dk:
								# Yes, it is a valid int.
								# Keep a copy of the node route for later retreat (when needed).
								deep_nodes.push_back([idx, deep_node])
								# Does it fit?
								if deep_node.size() <= idx:
									# Array is too small for a presumed new entry, so resize it.
									#TODO: could maybe first make sure we aren't growing by more than 1 or 2... or not
									deep_node.resize(idx + 1)
								deep_node = deep_node[idx]
								continue
							#TODO: is this really the right fallback?
						# Are we in a new/null or scalar array entry?
						if typeof(deep_node) != TYPE_DICTIONARY and deep_nodes.size() > 0:
							# Yes, so back up and make it a dict.
							deep_nodes[-1][1][deep_nodes[-1][0]] = {}
							deep_node = deep_nodes[-1][1][deep_nodes[-1][0]]
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
					# If the parent is an array, convert the final key to an int (if possible).
					if typeof(deep_node) == TYPE_ARRAY:
						var idx : int = int(deep_final_key)
						# Verify the possible integer.
						if String(idx) == deep_final_key:
							# Yes, it is a valid int.
							# Does it fit?
							if deep_node.size() <= idx:
								# Array is too small for a presumed new entry, so resize it.
								deep_node.resize(idx + 1)
							deep_final_key = idx
						else:
							#TODO: is this really the right fallback?
							pass
					match typeof(payload[k]):
						TYPE_NIL:
							if typeof(deep_node) == TYPE_ARRAY:
								if deep_final_key == deep_node.size() - 1:
									deep_node.pop_back()
									# Crawl backwards through the array removing trailing nulls (due to fakie gaps).
									while deep_node.size() > 0 and deep_node[-1] == null:
										deep_node.pop_back()
								else:
									deep_node[deep_final_key] = null
							else:
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
									if penult_node_type == TYPE_ARRAY:
										if final_key == node.size() - 1:
											node.pop_back()
											# Crawl backwards through the array removing trailing nulls (due to fakie gaps).
											while node.size() > 0 and node[-1] == null:
												node.pop_back()
										else:
											node[final_key] = null
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
				# Are we in a new/null or scalar array entry?
				if (typeof(node) != TYPE_DICTIONARY or typeof(node) != TYPE_ARRAY) and nodes.size() > 0:
					# Yes, so back up and make it a dict.
					nodes[-1][1][nodes[-1][0]] = {}
					node = nodes[-1][1][nodes[-1][0]]
				node[final_key] = payload.duplicate(true)
		_:
			node[final_key] = payload

	########################################
	_finish_it()
