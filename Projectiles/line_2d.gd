extends MeshInstance2D
class_name Trail

@export var max_trail_points := 35
@export var trail_width := 25.0
@export var min_point_distance := 6.0

var _parent: Node2D
var _positions: Array[Vector2] = []
var _mesh := ImmediateMesh.new()
var _last_added_position := Vector2.ZERO


func _ready() -> void:
	_parent = get_parent()
	top_level = true
	mesh = _mesh

	if is_instance_valid(_parent):
		_last_added_position = _parent.global_position
		_positions.append(_last_added_position)


func _physics_process(_delta: float) -> void:
	if !is_instance_valid(_parent) or !visible:
		if !_positions.is_empty():
			_positions.clear()
			_mesh.clear_surfaces()
		return

	var current_pos := _parent.global_position

	if _positions.is_empty():
		_positions.append(current_pos)
		_last_added_position = current_pos
		return

	if current_pos.distance_to(_last_added_position) < min_point_distance:
		return

	_last_added_position = current_pos
	_positions.push_front(current_pos)

	if _positions.size() > max_trail_points:
		_positions.pop_back()

	if _positions.size() >= 2:
		_rebuild_mesh()


func _rebuild_mesh() -> void:
	_mesh.clear_surfaces()
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	var count := _positions.size()

	for i in range(count - 1):
		var p1 := _positions[i]
		var p2 := _positions[i + 1]

		var t1 := float(i) / float(count - 1)
		var t2 := float(i + 1) / float(count - 1)

		var width1 := trail_width * (1.0 - t1)
		var width2 := trail_width * (1.0 - t2)

		var segment := p2 - p1
		if segment.length_squared() <= 0.0001:
			continue

		var dir := segment.normalized()
		var perp := Vector2(-dir.y, dir.x)

		var a := p1 + perp * width1
		var b := p1 - perp * width1
		var c := p2 + perp * width2
		var d := p2 - perp * width2

		_mesh.surface_set_uv(Vector2(t1, 0.0))
		_mesh.surface_add_vertex(Vector3(a.x, a.y, 0.0))

		_mesh.surface_set_uv(Vector2(t1, 1.0))
		_mesh.surface_add_vertex(Vector3(b.x, b.y, 0.0))

		_mesh.surface_set_uv(Vector2(t2, 0.0))
		_mesh.surface_add_vertex(Vector3(c.x, c.y, 0.0))

		_mesh.surface_set_uv(Vector2(t1, 1.0))
		_mesh.surface_add_vertex(Vector3(b.x, b.y, 0.0))

		_mesh.surface_set_uv(Vector2(t2, 1.0))
		_mesh.surface_add_vertex(Vector3(d.x, d.y, 0.0))

		_mesh.surface_set_uv(Vector2(t2, 0.0))
		_mesh.surface_add_vertex(Vector3(c.x, c.y, 0.0))

	_mesh.surface_end()


func clear_trail() -> void:
	_positions.clear()
	_mesh.clear_surfaces()

	if is_instance_valid(_parent):
		_last_added_position = _parent.global_position
