@tool
extends SkeletonModifier3D

class_name MomentumModifier

#var previous_bone_transforms: Array[Transform3D] = []
var prevprevious_bone_rot : Array[Quaternion] = []
var previous_bone_rot : Array[Quaternion] = []
#var simulated_rotations: Array[Quaternion]
#var angular_velocities: Array[Vector3]

func _ready() -> void:
	var skeleton = get_skeleton()
	previous_bone_rot.resize(skeleton.get_bone_count())
	for i in skeleton.get_bone_count():
		#previous_bone_transforms[i] = skeleton.get_bone_global_pose(i)
		var rot : Quaternion = skeleton.get_bone_pose_rotation(i)
		previous_bone_rot[i] = rot
	prevprevious_bone_rot.append_array(previous_bone_rot)

func StorePose() -> void:
	var skeleton = get_skeleton()
	#previous_bone_transforms.resize(skeleton.get_bone_count())
	previous_bone_rot.resize(skeleton.get_bone_count())
	prevprevious_bone_rot.resize(skeleton.get_bone_count())
	#simulated_rotations.resize(skeleton.get_bone_count())
	#angular_velocities.resize(skeleton.get_bone_count())

	for i in skeleton.get_bone_count():
		prevprevious_bone_rot[i] = previous_bone_rot[i]
		#previous_bone_transforms[i] = skeleton.get_bone_global_pose(i)
		var rot : Quaternion = skeleton.get_bone_pose_rotation(i)
		previous_bone_rot[i] = rot
		
		#simulated_rotations[i] = rot
		#angular_velocities[i] = Vector3.ZERO
	
func apply_bone_momentum(current_pose: Transform3D, previous_pose: Transform3D, strength: float) -> Transform3D:
	var result := current_pose

	# Linear momentum
	var linear_velocity := current_pose.origin - previous_pose.origin
	result.origin += linear_velocity * strength

	# Angular momentum
	var current_q := current_pose.basis.get_rotation_quaternion()
	var previous_q := previous_pose.basis.get_rotation_quaternion()

	var angular_velocity := previous_q.inverse() * current_q

	var momentum_q := Quaternion.IDENTITY.slerp(
		angular_velocity,
		strength
	)

	result.basis = Basis(current_q * momentum_q)

	return result

func apply_bone_rotation_momentum(current_q: Quaternion,previous_q: Quaternion,strength: float) -> Quaternion:
	var delta_q := previous_q.inverse() * current_q
	var predicted_q := current_q * delta_q
	
	return current_q.slerp(predicted_q, strength)

func apply_bone_spring(
	target_q: Quaternion,
	simulated_q: Quaternion,
	angular_velocity: Vector3,
	dt: float,
	stiffness: float,
	damping: float
) -> Dictionary:

	var error_q := simulated_q.inverse() * target_q

	var angle := error_q.get_angle()

	if angle > PI:
		angle -= TAU

	var axis := error_q.get_axis()

	# Spring force
	angular_velocity += axis * angle * stiffness * dt

	# Damping
	angular_velocity *= damping

	var speed := angular_velocity.length()

	if speed > 0.00001:
		simulated_q = simulated_q * Quaternion(
			angular_velocity.normalized(),
			speed * dt
		)

	return {
		"rotation": simulated_q,
		"velocity": angular_velocity
	}

func ApplyMementum():
	var skeleton = get_skeleton()
	#for bone_idx in previous_bone_transforms.size():
		#var current := skeleton.get_bone_global_pose(bone_idx)
		#var previous := previous_bone_transforms[bone_idx]
		#var momentum_pose := apply_bone_momentum(current, previous, 0.25)
		#skeleton.set_bone_global_pose(bone_idx, momentum_pose)
	for bone_idx in previous_bone_rot.size():
		var currentRot = previous_bone_rot[bone_idx]
		var previousRot = prevprevious_bone_rot[bone_idx]
		var newRot = apply_bone_rotation_momentum(currentRot, previousRot, 0.5)
		skeleton.set_bone_pose_rotation(bone_idx, newRot)
		
		#var result = apply_bone_spring(newRot, simulated_rotations[bone_idx], angular_velocities[bone_idx], delta, 10.0, 0.2)

		#simulated_rotations[bone_idx] = result.rotation
		#angular_velocities[bone_idx] = result.velocity
		
		#skeleton.set_bone_pose_rotation(bone_idx, result.rotation)
		#bone_q = result.rotation

func _process_modification_with_delta(_delta: float) -> void:
	StorePose()
	ApplyMementum()
	
	
