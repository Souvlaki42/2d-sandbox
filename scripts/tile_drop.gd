@icon("res://assets/icons/color/icon_destroyable_2.png")
extends RigidBody2D

class_name TileDrop

@export var sprite: Sprite2D


func _on_pickup_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		queue_free()
		# todo: add player inventory
