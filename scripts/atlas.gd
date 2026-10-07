class_name WolfAtlas
extends RefCounted

static var texture: Texture2D
static var slices: Array[AtlasTexture]=[]

static func sprite(index: int) -> Texture2D:
	if texture==null:
		if not ResourceLoader.exists("res://assets/woodland-atlas.png"):return null
		texture=load("res://assets/woodland-atlas.png")
		var cell := Vector2(texture.get_width()/4.0,texture.get_height()/4.0)
		var rows := [0.0,0.30,0.515,0.757,1.0]
		for i in range(16):
			var a := AtlasTexture.new()
			a.atlas=texture
			var row := int(i/4)
			a.region=Rect2(Vector2((i%4)*cell.x,rows[row]*texture.get_height()),Vector2(cell.x,(rows[row+1]-rows[row])*texture.get_height()))
			if i==8:a.region=Rect2(Vector2(80,rows[row]*texture.get_height()),Vector2(175,(rows[row+1]-rows[row])*texture.get_height()))
			slices.append(a)
	return slices[index]

static var walk_texture: Texture2D
static var walk_frames: Array[AtlasTexture]=[]

static func walking(facing: Vector2,frame: int) -> Texture2D:
	if walk_texture==null:
		walk_texture=load("res://assets/wolf-walk-atlas.png")
		var cell := Vector2(walk_texture.get_width(),walk_texture.get_height())/4.0
		var rows := [0.0,304.0/1254.0,579.0/1254.0,885.0/1254.0,1.0]
		for i in range(16):
			var slice := AtlasTexture.new()
			slice.atlas=walk_texture
			var row := int(i/4)
			var columns: Array=[0.0,332.0/1254.0,646.0/1254.0,962.0/1254.0,1.0] if row==0 else [0.0,0.25,0.5,0.75,1.0]
			slice.region=Rect2(Vector2(columns[i%4]*walk_texture.get_width(),rows[row]*walk_texture.get_height()),Vector2((columns[i%4+1]-columns[i%4])*walk_texture.get_width(),(rows[row+1]-rows[row])*walk_texture.get_height()))
			walk_frames.append(slice)
	var row := 0 if absf(facing.x)>absf(facing.y) and facing.x<0 else 1 if absf(facing.x)>absf(facing.y) else 2 if facing.y<0 else 3
	return walk_frames[row*4+posmod(frame,4)]

static var wildlife_texture: Texture2D
static var wildlife_frames: Array[AtlasTexture]=[]

static func wildlife(row: int,frame: int) -> Texture2D:
	if wildlife_texture==null:
		wildlife_texture=load("res://assets/wildlife-action-atlas.png")
		var rows := [0.0,350.0/1254.0,645.0/1254.0,912.0/1254.0,1.0]
		var columns := [0.0,322.0/1254.0,641.0/1254.0,956.0/1254.0,1.0]
		for i in range(16):
			var sprite := AtlasTexture.new()
			sprite.atlas=wildlife_texture
			var r := int(i/4)
			var c := i%4
			sprite.region=Rect2(Vector2(columns[c]*wildlife_texture.get_width(),rows[r]*wildlife_texture.get_height()),Vector2((columns[c+1]-columns[c])*wildlife_texture.get_width(),(rows[r+1]-rows[r])*wildlife_texture.get_height()))
			wildlife_frames.append(sprite)
	return wildlife_frames[clampi(row,0,3)*4+posmod(frame,4)]
