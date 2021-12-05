################################################################################
# A `FirebaseReference` (ref) represents a specific location in your Realtime
# Database and can be used for reading or writing data to that Database location.
#
# You can reference the root or child location in your Database by calling
# `firebase.database().get_reference()` or `firebase.database().get_reference("child/path")`
# (or `get_reference_lite(<path>)`).
#
# https://firebase.google.com/docs/reference/js/firebase.database.Reference
################################################################################
#TODO: Do we really need helper methods such as child() in this Lite version?
#      Seems like an easy lead to waste.
#      A fetch(path) with deep/path support seems like it would be more useful
#      than ref.child(x).child(y).fetch()
#
#TODO: Need to investigate best practices on sharing/instantiating/pooling HTTP clients.
#   ^^^ A HTTPClient should be reused between multiple requests or to connect to different hosts
#       instead of creating one client per request. Supports SSL and SSL server certificate
#       verification. HTTP status codes in the 2xx range indicate success, 3xx redirection
#       (i.e. "try again, but over here"), 4xx something was wrong with the request,
#       and 5xx something went wrong on the server's side.
#       https://docs.godotengine.org/en/stable/classes/class_httpclient.html#description
# But what about HTTPRequest?  Same?
#
#TOneverDO: If snapshot exists, update locally before send.
#      Don't revert on error--leave it to the user to refresh on error.
#      UPDATE: not a Lite version feature.
#
#TOnotDO: build these sorting and filtering methods
#      (sort can affect filters even though return is unsorted):
#      https://firebase.google.com/docs/database/web/lists-of-data#sorting_and_filtering_data
################################################################################
extends Node
class_name FirebaseReference, "icon.png"

signal value_changed(snapshot)  # JS: value, Java: onDataChange, Unity: ValueChanged
signal child_added(snapshot)
signal child_changed(snapshot)
signal child_removed(snapshot)
#TOnotDO:
#signal child_moved(snapshot)  # no hurry on this one - requires ordering first

const SEP = "/"
const PATH_SUFFIX = ".json"
const QUERY = "?"
const QUERY_DELIM = "&"
const EQUALS = "="
const ESC_DQUOTE = "\""

const ACCESS_TOKEN = "access_token"
const AUTH = "auth"

#const ORDER_BY = "orderBy"
#const LIMIT_TO_FIRST = "limitToFirst"
#const LIMIT_TO_LAST = "limitToLast"
#const START_AT = "startAt"
#const END_AT = "endAt"
#const EQUAL_TO = "equalTo"
#const KEY_FILTER = "$key"

var key  # Do not set type: will be null if root. Last part of the ref's path.  #TODO: make readonly?

var _path : String  # solves the prob of having an init param of the same name as a var without a setter
var path : String setget ,_get_ref_path  # The (read-only) path this ref points to.
func _get_ref_path() -> String: return _path  # because get_path() is reserved by Node

var debug: bool

#var _database : FirebaseDatabase
var _database : Node  # FirebaseDatabase (too circular to type this)
var _db_url : String
var _auth : Object
var _lite : bool

var _http : HTTPRequest = HTTPRequest.new()
var _listener : HTTPSSEClient
var _processor : FirebaseEventProcessorLite


func _init(
	database : Node,
	path : String,
	debug : bool = false,
	lite : bool = false
):
	_database = database
	_db_url = database.app._options.databaseURL
	_auth = database.app._auth  # don't use auth() as it will try to start it up (and error if not there)
	_path = path.strip_edges(true, true).lstrip(SEP)
	key = null if _path == "" else _path.rsplit(SEP, false, 1)[-1]
	self.debug = debug
	_lite = lite
	add_child(_http)


################################################################################
# Handles the grunt work and error reporting of each REST API request.
#
func _db_request(parse_response : bool, method, body : String = "") -> Object:
	# Find the path suffix.
	var suffix : String
	if _auth and _auth.current_user:
		suffix = yield(_get_auth_path_suffix(), "completed")
	else:
		suffix = _get_path_suffix()
	#print(suffix)
	#
	# Wait for open client.
	#TODO: look into pooling, etc
	while _http.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		yield(_http, "request_completed")
	# Do it.
	var error = _http.request(
		_db_url + SEP + _path + suffix, [], true, method, body
	)
	if error == OK:
		var response = yield(_http, "request_completed")
		#print(response)
		if response[0] == HTTPRequest.RESULT_SUCCESS:
			# Note that sending ?print=silent will return a 204. No plans to use this setting
			# (although we could on PUT and PATCH since we don't parse their response anyhow).
			if response[1] == HTTPClient.RESPONSE_OK:
				if parse_response:
					var jpr = JSON.parse(response[3].get_string_from_utf8())
					if jpr.error == OK:
						return jpr.result
					else:
						push_error("Database JSON parse error: " + jpr.error_line + ": " + jpr.error_string)
						return FirebaseError.new("http/response-parse-error")
				else:
					return OK
			else:
				var rbody = response[3].get_string_from_utf8()
				var jpr = JSON.parse(rbody)
				if jpr.error == OK and jpr.result.has("error"):
					#TODO: maybe expand this to "database/better-codes-here"
					# or maybe: return FirebaseError.new("database/" + jpr.result.error.to_lower().replace(" ", "-"))
					# actually: return FirebaseError.new("database/" + jpr.result.error.substr(0, jpr.result.error.find(";")).to_lower().replace(" ", "-"))  # up to first ";"
					rbody = jpr.result.error
				push_error("Database response error code: " + String(response[1]) + " " + rbody)
				return FirebaseError.new("http/response-error")
		else:
			push_error("Database request result error codes: " + String(response[0]) + " " + String(response[1]))
			return FirebaseError.new("http/request-result-error")
	else:
		push_error("Database request error code: " + String(error))
		return FirebaseError.new("http/request-error")


################################################################################
# Return a deep copy of the current local copy of the listener's snapshot.
#
# Returns `FirebaseDataSnapshot` or an error `int`.
#
#MJJ: Unsure of the use cases at the moment.
func fetch_local():
	if !_processor:
		return FAILED
	return _processor.get_snapshot()


################################################################################
# Fetch a snapshot of all the data at the ref's path.
#TOmaybeDO: If offline, falls back to local storage if it exists.
#TODO: if online error, check and return local storage before error... maybe
#
# Returns `FirebaseDataSnapshot` or `FirebaseError`.
#
# The response.data field contains the snapshot of all the data at the ref's path.
#
#MJJ: can't use get() -- appears to be reserved by Node
func fetch():
	var result = yield(_db_request(true, HTTPClient.METHOD_GET), "completed")
	if result is FirebaseError:
		return result
	else:
		return FirebaseDataSnapshot.new(key, result)


################################################################################
# Write or replace data at the ref's path.
#
# Returns any or `FirebaseError`.
#
# The response.data field contains the data specified in the PUT request.
# MJJ Note: The response can be different if, for example, you sent a server value.
#
# Write or replace data to a defined path, like `messages/users/user1/<data>`
#
#MJJ: can't use set() -- appears to be reserved by Node
func put(data):
	var body = to_json(data)
	return yield(_db_request(true, HTTPClient.METHOD_PUT, body), "completed")


################################################################################
# **Add to a list** of data (ref should point to a parent node of a list).
# Accepts relative paths in the top-level key names.
#
# `push()` and `push(data)` are allowed.
# `push()` returns a ref to a new empty key (sending `null` returns the key but doesn't create it yet).
#
# Returns `FirebaseReference` or `FirebaseError`.
#
# The response.data field contains the child name of the new data specified in the POST request.
# `{ "name": "-INOQPH-aV_psbk3ZXEX" }`
#
# Every time we send a POST request, the Firebase client generates a unique key,
# like `messages/users/<unique-id>/<data>`
#
func push(data = null):
	var body = to_json(data)
	var result = yield(_db_request(true, HTTPClient.METHOD_POST, body), "completed")
	if result is FirebaseError:
		return result
	else:
		if _lite:
			return get_parent().get_reference_lite(_path + SEP + result.name, debug)
		else:
			return get_parent().get_reference(_path + SEP + result.name, debug)


################################################################################
# Update some of the keys at the ref's path without replacing all of the data.
#
# Returns any or `FirebaseError`.
#
# The response.data field contains the data specified in the PATCH request.
# MJJ Note: The response can be different if, for example, you sent a server value.
#
#MJJ: consider rename to patch() ... nope... JS is update()
func update(data):
	var body = to_json(data)
	return yield(_db_request(true, HTTPClient.METHOD_PATCH, body), "completed")


################################################################################
# Remove all data at the ref's path.
#
# Returns OK or `FirebaseError`.
#
# You can also delete by specifying null as the value for another write operation
# such as put() or update().
# You can use this technique with update() to delete multiple children in a single API call.
#
# The response contains JSON `null`.
#
func remove():
	return yield(_db_request(false, HTTPClient.METHOD_DELETE), "completed")


################################################################################
func _get_path_suffix(is_get : bool = false) -> String:
	var suffix = PATH_SUFFIX
#	if is_get and _filter:
#		suffix += QUERY + _get_filter()
	return suffix

# Need a separete func here due to yielding requiring an inner yield or a return obj.
# So, until I figure out how to fake one of those... we have this mess...
func _get_auth_path_suffix(is_get : bool = false) -> String:
	var suffix = PATH_SUFFIX
	var query_delim = QUERY
#	if is_get and _filter:
#		suffix += QUERY + _get_filter()
#		query_delim = QUERY_DELIM
#	if _auth and _auth.current_user:
#		#TODO: maybe handle existance of current_user differently
	var result = yield(_auth.current_user.get_id_token(), "completed")
	if result is FirebaseError:
		print_debug("Auth request failed: Firebase token expired or other error.")
	else:
		suffix += query_delim + AUTH + EQUALS + result
	return suffix


#TODO: fix this found mess
#      https://firebase.google.com/docs/database/web/lists-of-data#sorting_and_filtering_data
#      https://firebase.google.com/docs/database/rest/retrieve-data#section-complex-queries
#var _filter : Dictionary
#var _cached_filter : String
#func _get_filter():
#	if !_filter:
#		return ""
#	# At the moment, this means you can't dynamically change your filter; I think it's okay to specify that in the rules.
#	if !_cached_filter:
#		_cached_filter = ""
#		if _filter.has(ORDER_BY):
#			_cached_filter += ORDER_BY + EQUALS + ESC_DQUOTE + _filter[ORDER_BY] + ESC_DQUOTE
#			_filter.erase(ORDER_BY)
#		else:
#			_cached_filter += ORDER_BY + EQUALS + ESC_DQUOTE + KEY_FILTER + ESC_DQUOTE # Presumptuous, but to get it to work at all...
#		for key in _filter.keys():
#			_cached_filter += QUERY_DELIM + key + EQUALS + _filter[key]
#	return _cached_filter


################################################################################
# This sets up a realtime listener such as on("value") and once("value") in JS.
#TODO: add signal support to turn on specific signals ... nope
#func on(signal_name : String):
func enable_listener() -> void:
	if !_processor:
		if _lite:
			_processor = FirebaseEventProcessorLite.new(self)
		else:
			_processor = FirebaseEventProcessor.new(self)
	if !_listener:
		_listener = HTTPSSEClient.new()
		add_child(_listener)
		_listener.connect("sse_event", self, "_on_sse_event")
		# Find the path suffix.
		var suffix : String
		if _auth and _auth.current_user:
			suffix = yield(_get_auth_path_suffix(true), "completed")
		else:
			suffix = _get_path_suffix(true)
		_listener.connect_to_source(_db_url, SEP + _path + suffix)  # yes, needs SEP prefix
		#yield(_listener, "sse_event")
		yield(self, "value_changed")
	# If already listening, don't yield.
	

# Turn off all listener signals.
# https://firebase.google.com/docs/database/web/read-and-write#detach_listeners
func disable_listener() -> void:
	if _listener:
		_listener.close()
		_listener.queue_free()
		_listener = null


################################################################################
# Starts the listener if not started but does not register continuing signals.
# Returns local data only.
# Immediately returns snapshot if listener already started, otherwise wait for it.
#MJJ: nixing - very muddy
#     Ooooh! this explains it:
#     https://firebase.google.com/docs/reference/js/firebase.database.Reference#once
#TODO: fix this
# Listens for exactly one event of the specified event type, and then stops listening.
#
# This is equivalent to calling `on()`, and then calling `off()` inside the callback function.
# See `on()` for details on the event types.
#func once(signal_name : String = "value_changed") -> Dictionary:
#	yield(enable_listener(), "completed")
#	return fetch_local()


################################################################################
# Event looks like: {event:put, data:{data:Null, path:/}, error:0}
#
# https://firebase.google.com/docs/database/web/lists-of-data#listen_for_child_events
func _on_sse_event(event : Dictionary) -> void:
	#print("_on_sse_event: ", event)
	# https://firebase.google.com/docs/database/rest/retrieve-data#section-rest-streaming
	match event.event:
		# Update the local/offline copy and trigger events.
		"put":
			_processor.put(event.data)
		"patch":
			_processor.patch(event.data)
