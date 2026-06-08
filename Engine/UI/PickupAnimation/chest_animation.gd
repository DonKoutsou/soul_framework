extends SubViewportContainer

class_name ChestAnimation

@export var animation_player: AnimationPlayer
@export var item: MeshInstance3D

signal Finished

func _ready() -> void:
	animation_player.play("Open")

func Init(It : Item) -> void:
	item.mesh = It.Model
	item.material_override = It.ModelMat
	var aabb = item.mesh.get_aabb()
	var Offset = -(aabb.size.y / 2.0) - aabb.position.y
	item.position.y  = Offset

func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	Finished.emit()
	queue_free()
