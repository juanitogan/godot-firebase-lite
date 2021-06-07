################################################################################
# Server-Sent Events (EventSource)
#
# https://firebase.google.com/docs/reference/rest/database/#section-streaming
################################################################################
extends Node
class_name HTTPSSEClient, "icon.png"

signal sse_event(event)

enum State {DISCONNECTED, CONNECTING, REQUESTING, LISTENING}
var state : int = State.DISCONNECTED

const INT_LF := 0x0A
const INT_COLON := ord(":")
var EVENT : PoolByteArray = "event".to_ascii()
var DATA : PoolByteArray = "data".to_ascii()

var http := HTTPClient.new()
var _path : String
var _buffer : PoolByteArray = []


################################################################################
func connect_to_source(
	host : String,
	path : String,
	port : int = -1,
	use_ssl : bool = false,
	verify_host : bool = true
) -> int:
	_path = path
	var err = http.connect_to_host(host, port, use_ssl, verify_host)
	if err == OK:
		state = State.CONNECTING
	return err


################################################################################
func close() -> void:
	http.close()
	state = State.DISCONNECTED


################################################################################
func _process(delta):
	#TODO: should I slow this polling down to 100ms or so?
	match state:

		# Put most likely state first.
		State.LISTENING:
			#http.poll()
			#if http.get_status() == HTTPClient.STATUS_BODY:  # always true with SSE?
			var chunk = http.read_response_body_chunk()
			if chunk.size() > 0:
				_buffer += chunk
				if _buffer:
					#print("ss_event: ", _buffer.get_string_from_utf8())
					var events : Array = _parse_event_messages()
					for e in events:
						if e.error == OK and e.event != "keep-alive":
							#Signal (instead of call parent func) to allow general-purpose use.
							emit_signal("sse_event", e)

		State.DISCONNECTED:
			pass

		State.CONNECTING:
			http.poll()
			if http.get_status() == HTTPClient.STATUS_CONNECTED:
				#print(_path)
				var err = http.request(HTTPClient.METHOD_GET, _path, ["Accept: text/event-stream"])
				if err == OK:
					state = State.REQUESTING

		State.REQUESTING:
			# Kinda superflous: could jump straight to listening... NOPE, needs a beat it seems.
			# This is also a bit useful for debugging.
			# First body-parse happens a frame late like this... but don't care right now.
			http.poll()
			#if http.get_status() != HTTPClient.STATUS_REQUESTING:
			if http.get_status() == HTTPClient.STATUS_BODY:
				print_debug(http.get_response_headers())
				state = State.LISTENING


################################################################################
# Look for and returns 0..n events.
#
# Yes, I do see multiple events in a single chunk on occasion.  Especially,
# when first starting up a listener on an empty path during its first write.
#
#TOmaybeDO: possibly breaks when space in key string
#TODONEmaybe: should at least add recovery from such errors by looking for "event: keep-alive" and resetting
func _parse_event_messages() -> Array:
	# First, find the complete lines.
	var lines : Array = []
	var colon_idx : int = 0
	var colon_found : bool = false
	var last : int = 0
	for i in _buffer.size():
		var b = _buffer[i]
		if !colon_found and b == INT_COLON:
			colon_idx = i
			colon_found = true
		elif b == INT_LF:
			# Only keep lines with colons in them.
			if colon_found:
				lines.append([
					_buffer.subarray(last, colon_idx - 1), # label
					_buffer.subarray(colon_idx + 2, i - 1), # value
					i + 1  # store the pos for later trimming
				])
				colon_found = false
			else:
				# If this is a blank or junk line,
				# adjust the last pos entry to trim this line as well.
				if lines:
					lines[-1][2] = i + 1
			last = i + 1

	# Next, find the line-pairs for events.
	var events : Array = []
	last = 0
	var i : int = 0
	while i < lines.size() - 1:  # can skip the last line (also saves checking for i+1 below)
		if lines[i][0] == EVENT and lines[i + 1][0] == DATA:
			var event : String = lines[i][1].get_string_from_utf8()
			var data = null
			var error = OK
			# Handle event types and data types.
			# "keep-alive" is always null, so don't parse it. (unless we want to make sure it is there???)
			if event != "keep-alive":
				data = lines[i + 1][1].get_string_from_utf8()
				if event == "put" or event == "patch":
					# JSON data.
					assert(data.length() > 0)
					var jpr = JSON.parse(data)
					assert(jpr.error == OK)
					error = jpr.error
					data = jpr.result  # could be null even if OK maybe?
				# "cancel" and "auth_revoked" can return info string.
			events.append({"event": event, "data": data, "error": error})
			last = lines[i + 1][2]  # store the pos for later trimming
			i += 2
		else:
			# Skip lines that don't jive.
			i += 1

	# Scrub what we just used from the buffer.
	if last >= _buffer.size():
		_buffer = []
	elif last > 0:
		_buffer = _buffer.subarray(last, -1)
	# Fin.
	return events


################################################################################
func _exit_tree():
	if http:
		http.close()
