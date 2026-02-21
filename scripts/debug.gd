extends Control

class_name Debug

var properties: Array[StringName] = []

@export var container: VBoxContainer


func _ready() -> void:
	visible = false


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_stats"):
		visible = not visible
		get_viewport().set_input_as_handled()


func add_debug_property(id: StringName, value: Variant) -> void:
	if properties.has(id):
		var target: Label = container.find_child(id, true, false)
		target.text = id + ": " + str(value)
	else:
		var property: Label = Label.new()
		container.add_child(property)
		property.name = id
		property.text = id + ": " + str(value)
		properties.append(id)
