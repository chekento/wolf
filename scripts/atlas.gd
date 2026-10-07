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
