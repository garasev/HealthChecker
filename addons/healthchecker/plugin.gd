@tool
extends EditorPlugin

var config = {}
var toolbar
var services = []
var timer = Timer.new()

func _enter_tree():
	_load_config()
	print("Config file loaded successfully")
	_create_custom_panel()
	print("Health Check Plugin v", config["plugin"]["version"], " is ready")
	timer.timeout.connect(_update_services)
	add_child(timer)
	timer.start()

func _exit_tree():
	remove_control_from_container(EditorPlugin.CONTAINER_TOOLBAR, toolbar)
	toolbar.free()
	for service in services:
		if is_instance_valid(service.request):
			service.request.queue_free()
	services.clear()

func _load_config():
	var config_file = ConfigFile.new()
	var err = config_file.load("res://addons/healthchecker/plugin.cfg")
	if err == OK:
		for section in config_file.get_sections():
			config[section] = {}
			for key in config_file.get_section_keys(section):
				config[section][key] = config_file.get_value(section, key)
	timer.wait_time = config["settings"]["check_interval"]

func _create_custom_panel():
	toolbar = HBoxContainer.new()
	toolbar.custom_minimum_size.x = 80
	
	var left_button = Button.new()
	left_button.text = "◀️"
	left_button.visible = false
	toolbar.add_child(left_button)
	
	var right_button = Button.new()
	right_button.text = "▶"
	right_button.visible = false
	toolbar.add_child(right_button)
	
	for section in config:
		if section.begins_with("service"):
			var s = config[section]
			var label = CircleLabel.new()
			label.init(s)
			toolbar.add_child(label)
			services.append(label)
	
	add_control_to_container(EditorPlugin.CONTAINER_TOOLBAR, toolbar)

func _update_services():
	for service in services:
		if service.request != null && service.request.is_processing():
			service.request.cancel_request()
		
		service.request = HTTPRequest.new()
		add_child(service.request)
		service.request.request_completed.connect(_handle_response.bind(service))
		var error = service.request.request(service.get_setting("url"))
		if error != OK:
			service.bad()

func _handle_response(result, code, headers, body, service):
	if code == 200:
		service.ok()
	else:
		service.bad()
	if is_instance_valid(service.request):
		service.request.queue_free()
