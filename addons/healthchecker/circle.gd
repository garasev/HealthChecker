class_name CircleLabel
extends VBoxContainer

enum Status {DEFAULT, OK, BAD}
var status_icons := {
	Status.DEFAULT: "🟡",
	Status.OK: "🟢", 
	Status.BAD: "🔴"
}

var settings := {}

var label: Label
var request: HTTPRequest = null
var tooltip: CanvasLayer = null
var tooltip_panel: Panel = null
var tooltip_label: RichTextLabel = null

func _init():
	_setup_ui()
	_setup_signals()

func _setup_ui():
	# Основной лейбл статуса
	label = Label.new()
	label.name = "StatusLabel"
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(label)
	
	# Настройки тултипа
	mouse_filter = MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(24, 24)

func set_status(status: Status) -> void:
	label.text = status_icons.get(status, status_icons[Status.DEFAULT])

func ok():
	set_status(Status.OK)

func bad():
	set_status(Status.BAD)

func _update_tooltip_content():
	if tooltip_label:
		tooltip_label.text = "[b]%s[/b]\n[b]%s[/b]\n%s" % [
			settings.get("title", "Unknown"),
			settings.get("url", "No URL"),
			settings.get("desc", "No description")
		]

func get_setting(param: String):
	return settings.get(param, null)

func init(service_settings: Dictionary) -> void:
	settings = service_settings
	label.text = status_icons[Status.DEFAULT]
	_update_tooltip_content()


func _create_tooltip():
	tooltip = CanvasLayer.new()
	tooltip.layer = 100
	
	tooltip_panel = Panel.new()
	tooltip_panel.visible = false
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.9)
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_color = Color(0.5, 0.5, 0.5)
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	tooltip_panel.add_theme_stylebox_override("panel", style)
	
	tooltip_label = RichTextLabel.new()
	tooltip_label.bbcode_enabled = true
	tooltip_label.fit_content = true
	tooltip_label.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	tooltip_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	
	tooltip_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tooltip_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tooltip_label.anchor_right = 1.0
	tooltip_label.anchor_bottom = 1.0

	tooltip_panel.add_child(tooltip_label)
	tooltip.add_child(tooltip_panel)
	get_tree().root.add_child(tooltip)
	
	await get_tree().process_frame
	tooltip_panel.size = tooltip_label.size + Vector2(16, 16)

func _update_tooltip_position():
	if tooltip:
		var mouse_pos = get_global_mouse_position()
		tooltip_panel.global_position = mouse_pos + Vector2(15, 15)
		_clamp_to_screen()

func _clamp_to_screen():
	var viewport_rect = get_viewport().get_visible_rect()
	var tooltip_rect = Rect2(tooltip_panel.global_position, tooltip_panel.size)
	
	if tooltip_rect.end.x > viewport_rect.end.x:
		tooltip_panel.global_position.x = viewport_rect.end.x - tooltip_rect.size.x
	   
	if tooltip_rect.end.y > viewport_rect.end.y:
		tooltip_panel.global_position.y = viewport_rect.end.y - tooltip_rect.size.y

func _process(delta):
	if tooltip and tooltip_panel.visible:
		_update_tooltip_position()

func _setup_signals():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered():
	_create_tooltip()
	_update_tooltip_position()
	_update_tooltip_content()
	tooltip_panel.visible = true

func _on_mouse_exited():
	if tooltip:
		tooltip.queue_free()
		tooltip = null
