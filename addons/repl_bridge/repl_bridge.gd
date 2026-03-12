extends Node

const VERSION := "3.0.0"
const HTTP_PORT := 6009
var _log_buffer: Array[String] = []
var _err_buffer: Array[String] = []
var _watches: Dictionary = {}
var _watch_id: int = 0
var _tcp: TCPServer = TCPServer.new()
var _peers: Array = []

func _ready() -> void:
	print("[ReplBridge] v", VERSION, " initialized")
	if _tcp.listen(HTTP_PORT) == OK:
		print("[ReplBridge] HTTP server on port ", HTTP_PORT)
	else:
		push_warning("[ReplBridge] HTTP port %d busy" % HTTP_PORT)
	if EngineDebugger.is_active():
		EngineDebugger.register_message_capture("repl", _on_repl_message)
		print("[ReplBridge] TCP debugger capture registered")

func _on_repl_message(message: String, data: Array) -> bool:
	var id: String = str(data[0]) if data.size() > 0 else ""
	match message:
		"eval":
			EngineDebugger.send_message("repl:result", [id, _eval(data[1] if data.size() > 1 else "")])
			return true
		"tree":
			EngineDebugger.send_message("repl:result", [id, {"tree": _dump_node(get_tree().root)}])
			return true
		"node":
			EngineDebugger.send_message("repl:result", [id, _get_node_props(data[1] if data.size() > 1 else "/")])
			return true
		"perf":
			EngineDebugger.send_message("repl:result", [id, _get_perf()])
			return true
		"set":
			EngineDebugger.send_message("repl:result", [id, _set_prop(str(data[1]), str(data[2]), data[3] if data.size() > 3 else null)])
			return true
		"call":
			var args: Array = data[3] if data.size() > 3 else []
			EngineDebugger.send_message("repl:result", [id, _call_node(str(data[1]), str(data[2]), args)])
			return true
		"watch":
			_watch_id += 1
			_watches[str(_watch_id)] = str(data[1]) if data.size() > 1 else ""
			EngineDebugger.send_message("repl:result", [id, {"id": _watch_id}])
			return true
		"globals":
			EngineDebugger.send_message("repl:result", [id, _get_globals()])
			return true
		"groups":
			EngineDebugger.send_message("repl:result", [id, _get_groups()])
			return true
		"logs":
			EngineDebugger.send_message("repl:result", [id, {"logs": _log_buffer.duplicate()}])
			return true
		"pause":
			get_tree().paused = not get_tree().paused
			EngineDebugger.send_message("repl:result", [id, {"paused": get_tree().paused}])
			return true
		"reload":
			EngineDebugger.send_message("repl:result", [id, {"ok": true}])
			get_tree().reload_current_scene()
			return true
	return false

func _process(_delta: float) -> void:
	if _tcp.is_connection_available():
		var conn := _tcp.take_connection()
		if conn: _peers.append(conn)
	for i in range(_peers.size() - 1, -1, -1):
		var p: StreamPeerTCP = _peers[i]
		if p.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			_peers.remove_at(i); continue
		var avail := p.get_available_bytes()
		if avail > 0:
			_handle_http(p, p.get_utf8_string(avail))
			_peers.remove_at(i)

func _handle_http(peer: StreamPeerTCP, raw: String) -> void:
	var lines := raw.split("\r\n")
	if lines.size() == 0: return
	var parts := lines[0].split(" ")
	if parts.size() < 2: return
	var method := parts[0]; var url_path := parts[1]; var body := ""; var in_body := false
	for line in lines:
		if in_body: body += line
		elif line == "": in_body = true
	var result := _route(method, url_path, body)
	var json_str := JSON.stringify(result)
	var response := "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nAccess-Control-Allow-Origin: *\r\nContent-Length: %d\r\nConnection: close\r\n\r\n%s" % [json_str.length(), json_str]
	peer.put_data(response.to_utf8_buffer())

func _route(method: String, url_path: String, body: String) -> Dictionary:
	var data: Dictionary = {}
	if body.length() > 0:
		var parsed := JSON.parse_string(body)
		if parsed is Dictionary: data = parsed
	if url_path == "/tree": return {"tree": _dump_node(get_tree().root)}
	if url_path == "/globals": return _get_globals()
	if url_path == "/perf": return _get_perf()
	if url_path == "/input": return {"paused": get_tree().paused, "joypads": Input.get_connected_joypads()}
	if url_path == "/groups": return _get_groups()
	if url_path == "/resources": return {"resources": []}
	if url_path == "/physics": return _get_physics()
	if url_path == "/logs": return {"logs": _log_buffer.duplicate()}
	if url_path == "/errors": return {"errors": _err_buffer.duplicate()}
	if url_path == "/watches": return _eval_watches()
	if url_path == "/eval" and method == "POST": return _eval(data.get("expr", ""))
	if url_path == "/set" and method == "POST": return _set_prop(data.get("path", ""), data.get("prop", ""), data.get("value", null))
	if url_path == "/call" and method == "POST": return _call_node(data.get("path", ""), data.get("method", ""), data.get("args", []))
	if url_path == "/signal" and method == "POST":
		var node := get_node_or_null(data.get("path", ""))
		if not node: return {"error": "not found"}
		node.emit_signal(data.get("signal", ""), data.get("args", [])); return {"ok": true}
	if url_path == "/pause" and method == "POST":
		get_tree().paused = not get_tree().paused; return {"paused": get_tree().paused}
	if url_path == "/reload" and method == "POST":
		get_tree().reload_current_scene(); return {"ok": true}
	if url_path == "/screenshot":
		var img := get_viewport().get_texture().get_image()
		if not img: return {"error": "no viewport image"}
		var b64 := Marshalls.raw_to_base64(img.save_png_to_buffer())
		return {"format": "png", "base64": b64, "width": img.get_width(), "height": img.get_height()}
	if url_path == "/watch" and method == "POST":
		_watch_id += 1; _watches[str(_watch_id)] = data.get("expr", ""); return {"id": _watch_id, "expr": data.get("expr", "")}
	if url_path.begins_with("/watch/") and method == "DELETE":
		_watches.erase(url_path.substr(7)); return {"ok": true}
	if url_path.begins_with("/node/"): return _get_node_props("/" + url_path.substr(6))
	return {"error": "not found", "path": url_path}

func _dump_node(node: Node) -> Dictionary:
	var children := []
	for c in node.get_children(): children.append(_dump_node(c))
	return {"name": node.name, "class": node.get_class(), "path": str(node.get_path()), "groups": node.get_groups(), "children": children}

func _get_node_props(np: String) -> Dictionary:
	var node := get_node_or_null(np)
	if not node: return {"error": "not found: " + np}
	var props := {}
	for p in node.get_property_list():
		if p.usage & PROPERTY_USAGE_EDITOR: props[p.name] = str(node.get(p.name))
	return {"path": np, "class": node.get_class(), "groups": node.get_groups(), "properties": props}

func _eval(expr_str: String) -> Dictionary:
	var expr := Expression.new()
	if expr.parse(expr_str) != OK: return {"error": expr.get_error_text()}
	var result = expr.execute([], self)
	if expr.has_execute_failed(): return {"error": expr.get_error_text()}
	return {"result": str(result)}

func _get_globals() -> Dictionary:
	var out := []
	for child in get_tree().root.get_children(): out.append({"name": child.name, "class": child.get_class(), "path": str(child.get_path())})
	return {"globals": out}

func _get_perf() -> Dictionary:
	return {"fps": Performance.get_monitor(Performance.TIME_FPS), "process_ms": Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, "physics_ms": Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0, "memory_static": Performance.get_monitor(Performance.MEMORY_STATIC), "memory_dynamic": Performance.get_monitor(Performance.MEMORY_MESSAGE_BUFFER_MAX), "objects": Performance.get_monitor(Performance.OBJECT_COUNT), "nodes": Performance.get_monitor(Performance.OBJECT_NODE_COUNT), "resources": Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT), "draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), "video_mem": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED), "physics3d_objects": Performance.get_monitor(Performance.PHYSICS_3D_ACTIVE_OBJECTS), "physics2d_objects": Performance.get_monitor(Performance.PHYSICS_2D_ACTIVE_OBJECTS)}

func _get_groups() -> Dictionary:
	var groups: Dictionary = {}
	_collect_groups(get_tree().root, groups); return {"groups": groups}

func _collect_groups(node: Node, groups: Dictionary) -> void:
	for g in node.get_groups():
		if not groups.has(g): groups[g] = []
		groups[g].append(str(node.get_path()))
	for c in node.get_children(): _collect_groups(c, groups)

func _get_physics() -> Dictionary:
	return {"active_objects_3d": PhysicsServer3D.get_process_info(PhysicsServer3D.INFO_ACTIVE_OBJECTS), "collision_pairs_3d": PhysicsServer3D.get_process_info(PhysicsServer3D.INFO_COLLISION_PAIRS), "island_count_3d": PhysicsServer3D.get_process_info(PhysicsServer3D.INFO_ISLAND_COUNT), "active_objects_2d": PhysicsServer2D.get_process_info(PhysicsServer2D.INFO_ACTIVE_OBJECTS), "collision_pairs_2d": PhysicsServer2D.get_process_info(PhysicsServer2D.INFO_COLLISION_PAIRS)}

func _set_prop(np: String, prop: String, value: Variant) -> Dictionary:
	var node := get_node_or_null(np)
	if not node: return {"error": "not found: " + np}
	node.set(prop, value); return {"ok": true}

func _call_node(np: String, method_name: String, args: Array) -> Dictionary:
	var node := get_node_or_null(np)
	if not node: return {"error": "not found: " + np}
	return {"result": str(node.callv(method_name, args))}

func _eval_watches() -> Dictionary:
	var out := {}
	for wid in _watches: out[wid] = _eval(_watches[wid])
	return {"watches": out}

func log_info(msg: String) -> void:
	_log_buffer.append("[INFO] " + msg)
	if _log_buffer.size() > 500: _log_buffer.pop_front()
	print(msg)

func log_error(msg: String) -> void:
	_err_buffer.append("[ERROR] " + msg)
	if _err_buffer.size() > 500: _err_buffer.pop_front()
	push_error(msg)
