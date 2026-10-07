class_name WolfForestMesh
extends RefCounted

static var cache: Dictionary = {}

static func get_mesh(kind: String) -> Mesh:
	if cache.has(kind):return cache[kind]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segments := 12
	var rows := 9 if kind=="pine" else 7
	for j in range(rows):
		for i in range(segments):
			for coord in [Vector2i(j,i),Vector2i(j+1,i),Vector2i(j+1,i+1),Vector2i(j,i),Vector2i(j+1,i+1),Vector2i(j,i+1)]:
				var a := float(coord.y)/segments*TAU
				var t := float(coord.x)/rows
				var r := 1.0
				var y := t-0.5
				if kind=="pine":
					r=pow(1-t,0.65)*(0.87+0.13*sin(a*5+t*12))
					y+=sin(a*5+t*15)*0.025*(1-t)
				elif kind=="leaf":
					r=sin(t*PI)*(0.91+sin(a*4+t*14)*0.09)
					y=cos(t*PI)*0.5
				elif kind=="trunk":r=0.5*(1-t*0.3)*(0.94+sin(a*5+t*9)*0.06)
				else:r=sin(t*PI)*(0.87+sin(a*3+t*8)*0.13);y=cos(t*PI)*0.5
				st.add_vertex(Vector3(cos(a)*r,y,sin(a)*r))
	st.generate_normals()
	var mesh := st.commit()
	cache[kind]=mesh
	return mesh
