extends Chunk

enum Faces{
	TOP,
	BOTTOM,
	LEFT,
	RIGHT,
	FRONT,
	BACK,
	SOLID
}

const vertices = [
	Vector3(0, 0, 0), #0	   2 +--------+ 3  a+------+b 
	Vector3(1, 0, 0), #1	    /|       /|     |      |
	Vector3(0, 1, 0), #2	   / |      / |     |      |
	Vector3(1, 1, 0), #3	6 +--------+ 7|    c+------+d
	Vector3(0, 0, 1), #4	  |0 +-----|--+ 1  
	Vector3(1, 0, 1), #5	  | /      | /     b-a-c
	Vector3(0, 1, 1), #6	  |/       |/      b-c-d
	Vector3(1, 1, 1)  #7	4 +--------+ 5
]

const TOP = [2, 3, 6, 7]
const BOTTOM = [4, 5, 0, 1]
const LEFT = [2, 6, 0, 4]
const RIGHT = [7, 3, 5, 1]
const BACK = [6, 7, 4, 5]
const FRONT = [3, 2, 1, 0]

const TEXTURE_ATLAS_SIZE := Vector2(8,2)

enum {
	AIR,
	DIRT,
	GRASS,
	STONE,
	LOG1,
	LEAVES1,
	WOOD1,
	LOG2,
	LEAVES2,
	WOOD2,
	GLASS,
	STUMP # Not real block type, signals that we need a tree here.
}


var find_type:Dictionary = {
	0:AIR,
	1:"res://Items/Dirt.tres",
	2:"res://Items/Grass.tres",
	3:"res://Items/Stone.tres",
	4:"res://Items/Log1.tres",
	5:"res://Items/Leaf1.tres",
	6:"res://Items/Wood1.tres",
	7:"res://Items/Log2.tres",
	8:"res://Items/Leaf2.tres",
	9:"res://Items/Wood2.tres",
	10:"res://Items/Glass.tres",
	11:STUMP # No
}
const offsets = {
	AIR:{
	},
	DIRT:{
		Faces.TOP:Vector2(2, 0), Faces.BOTTOM:Vector2(2, 0), Faces.LEFT:Vector2(2, 0),
		Faces.RIGHT:Vector2(2,0), Faces.FRONT:Vector2(2, 0), Faces.BACK:Vector2(2, 0),
	},
	GRASS:{
		Faces.TOP:Vector2(0, 0), Faces.BOTTOM:Vector2(2, 0), Faces.LEFT:Vector2(1, 0),
		Faces.RIGHT:Vector2(1, 0), Faces.FRONT:Vector2(1, 0), Faces.BACK:Vector2(1, 0),
	},
	STONE:{
		Faces.TOP:Vector2(3, 0), Faces.BOTTOM:Vector2(3, 0), Faces.LEFT:Vector2(3, 0),
		Faces.RIGHT:Vector2(3, 0), Faces.FRONT:Vector2(3, 0), Faces.BACK:Vector2(3, 0),
	},
	LOG1:{
		Faces.TOP:Vector2(5, 0), Faces.BOTTOM:Vector2(5, 0), Faces.LEFT:Vector2(4, 0),
		Faces.RIGHT:Vector2(4, 0), Faces.FRONT:Vector2(4, 0), Faces.BACK:Vector2(4, 0),
	},
	LEAVES1:{
		Faces.TOP:Vector2(6, 0), Faces.BOTTOM:Vector2(6, 0), Faces.LEFT:Vector2(6, 0),
		Faces.RIGHT:Vector2(6, 0), Faces.FRONT:Vector2(6, 0), Faces.BACK:Vector2(6, 0),
	},
	WOOD1:{
		Faces.TOP:Vector2(7, 0), Faces.BOTTOM:Vector2(7, 0), Faces.LEFT:Vector2(7, 0),
		Faces.RIGHT:Vector2(7,0), Faces.FRONT:Vector2(7, 0), Faces.BACK:Vector2(7, 0),
	},
	LOG2:{
		Faces.TOP:Vector2(5, 1), Faces.BOTTOM:Vector2(5, 1), Faces.LEFT:Vector2(4, 1),
		Faces.RIGHT:Vector2(4, 1), Faces.FRONT:Vector2(4, 1), Faces.BACK:Vector2(4, 1),
	},
	LEAVES2:{
		Faces.TOP:Vector2(6, 1), Faces.BOTTOM:Vector2(6, 1), Faces.LEFT:Vector2(6, 1),
		Faces.RIGHT:Vector2(6, 1), Faces.FRONT:Vector2(6, 1), Faces.BACK:Vector2(6, 1),
	},
	WOOD2:{
		Faces.TOP:Vector2(7, 1), Faces.BOTTOM:Vector2(7, 1), Faces.LEFT:Vector2(7, 1),
		Faces.RIGHT:Vector2(7,1), Faces.FRONT:Vector2(7, 1), Faces.BACK:Vector2(7, 1),
	},
	GLASS:{
		Faces.TOP:Vector2(2, 1), Faces.BOTTOM:Vector2(2, 1), Faces.LEFT:Vector2(2, 1),
		Faces.RIGHT:Vector2(2,1), Faces.FRONT:Vector2(2, 1), Faces.BACK:Vector2(2, 1),
	},
	STUMP:{
	}
}

var st = SurfaceTool.new()
var mesh: ArrayMesh = null
var mesh_instance: MeshInstance3D = null

var material = preload("res://assets/materials/texturemat_mesh.tres")


func place_block(local_pos: Vector3, type, regen = true):
	blocks.set_block(local_pos, type)
	if regen:
		update()
		finalize()


func break_block(local_pos: Vector3, regen = true):
	#print(blocks.get_block(local_pos))
	var type = blocks.get_block(local_pos)
	#print("type ", find_type[type])
	if type != 0:
		if type != 11:
			Globals.spawn_item_inventory.emit(load(find_type[type]))
		
	place_block(local_pos, WorldGen.AIR, regen)

func update():
	# Update the block data.
	blocks.update()
	
	# Unload chunk.
	if mesh_instance != null:
		mesh_instance.queue_free()
		mesh_instance = null
	
	# Generate new chunk.
	mesh = ArrayMesh.new()
	mesh_instance = MeshInstance3D.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for x in Globals.chunk_size.x:
		for z in Globals.chunk_size.z:
			@warning_ignore("narrowing_conversion")
			create_column(x, z, blocks.types[x][z], blocks.flags[x][z])
	
	st.generate_normals(false)
	st.set_material(material)
	st.commit(mesh)
	mesh_instance.set_mesh(mesh)
	
	mesh_instance.call_deferred("create_trimesh_collision")


func finalize():
	add_child(mesh_instance)
	blocks.depool()


func create_column(x: int, z: int, types: PackedByteArray, faces: PackedByteArray):
	var height = blocks.get_height(x, z)
	for y in height:
		create_block(Vector3(x, y, z), types[y], faces[y])


func create_block(pos: Vector3, type: int, flags: int):
	var block_offsets = offsets[type]
	if type == WorldGen.AIR:
		return
	if (flags & ChunkData.ALL_SIDES == ChunkData.ALL_SIDES):
		return
	
	if !flags & ChunkData.TOP:
		create_face(TOP, pos, block_offsets[Faces.TOP])
	if !flags & ChunkData.BOTTOM:
		create_face(BOTTOM, pos, block_offsets[Faces.BOTTOM])
	if !flags & ChunkData.FRONT:
		create_face(FRONT, pos, block_offsets[Faces.FRONT])
	if !flags & ChunkData.BACK:
		create_face(BACK, pos, block_offsets[Faces.BACK])
	if !flags & ChunkData.LEFT:
		create_face(LEFT, pos, block_offsets[Faces.LEFT])
	if !flags & ChunkData.RIGHT:
		create_face(RIGHT, pos, block_offsets[Faces.RIGHT])


func create_face(face, pos: Vector3, texture_atlas_offset):
	# a+------+b 
	#  |      | b-c-a
	#  |      | b-d-c
	# c+------+d
	var a = vertices[face[0]] + pos
	var b = vertices[face[1]] + pos
	var c = vertices[face[2]] + pos
	var d = vertices[face[3]] + pos
	
	var uv_offset = texture_atlas_offset / TEXTURE_ATLAS_SIZE
	var height = 1.0 / TEXTURE_ATLAS_SIZE.y
	var width = 1.0 / TEXTURE_ATLAS_SIZE.x
	
	var uv_a = uv_offset + Vector2(0, 0)
	var uv_b = uv_offset + Vector2(width, 0)
	var uv_c = uv_offset + Vector2(0, height)
	var uv_d = uv_offset + Vector2(width, height)
	
	st.add_triangle_fan([b, c, a], [uv_b, uv_c, uv_a])
	st.add_triangle_fan([b, d, c], [uv_b, uv_d, uv_c])
