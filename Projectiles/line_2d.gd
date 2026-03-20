extends MeshInstance2D
class_name Trail

@export var max_trail_points := 15
@export var trail_width := 8.0

var _parent: Node2D
var _positions: Array[Vector2] = []
var _mesh := ImmediateMesh.new()


func _ready() -> void:
	_parent = get_parent()
	top_level = true
	mesh = _mesh


func _process(_delta: float) -> void:
	if !is_instance_valid(_parent) or !visible:
		_mesh.clear_surfaces()
		return

	_positions.push_front(_parent.global_position)
	if _positions.size() > max_trail_points:
		_positions.pop_back()

	if _positions.size() < 2:
		return

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

		var dir := (p2 - p1).normalized()
		var perp := Vector2(-dir.y, dir.x)

		var a := p1 + perp * width1
		var b := p1 - perp * width1
		var c := p2 + perp * width2
		var d := p2 - perp * width2

		_mesh.surface_set_uv(Vector2(t1, 0.0)); _mesh.surface_add_vertex(Vector3(a.x, a.y, 0))
		_mesh.surface_set_uv(Vector2(t1, 1.0)); _mesh.surface_add_vertex(Vector3(b.x, b.y, 0))
		_mesh.surface_set_uv(Vector2(t2, 0.0)); _mesh.surface_add_vertex(Vector3(c.x, c.y, 0))

		_mesh.surface_set_uv(Vector2(t1, 1.0)); _mesh.surface_add_vertex(Vector3(b.x, b.y, 0))
		_mesh.surface_set_uv(Vector2(t2, 1.0)); _mesh.surface_add_vertex(Vector3(d.x, d.y, 0))
		_mesh.surface_set_uv(Vector2(t2, 0.0)); _mesh.surface_add_vertex(Vector3(c.x, c.y, 0))

	_mesh.surface_end()


func clear_trail() -> void:
	_positions.clear()
	_mesh.clear_surfaces()
