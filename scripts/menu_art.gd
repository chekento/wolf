class_name WolfMenuArt
extends Control

var game: Node
var kind := "landscape"
var caption := "WIND · PFOTEN · VERTRAUTE DÜFTE"

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	if kind!="landscape":
		_glyph()
		return
	var w := size.x
	var h := size.y
	var dark: bool=game!=null and game.state.time_name()=="Nacht"
	var biome: String=WolfWorldData.REGIONS[game.state.region].biome if game!=null else "forest"
	var skies := {"snow":"#b9cfda","alpine":"#b2c5cf","coast":"#aeced0","river":"#a3c9bc","marsh":"#adbcad","meadow":"#bad3ae","pine":"#9bbcaf","oak":"#c5c3a3","lake":"#b0cacf"}
	var sky := Color("#24464c") if dark else Color(skies.get(biome,"#9bc2b3"))
	var ridges: Array[Color]=[Color("#779889"),Color("#426f62"),Color("#244f43")]
	if biome in ["snow","alpine"]:ridges=[Color("#cbd7d2"),Color("#99b2ac"),Color("#617e78")]
	elif biome=="coast":ridges=[Color("#b8c9ae"),Color("#82afa7"),Color("#426f68")]
	elif biome=="marsh":ridges=[Color("#8b9e89"),Color("#667b60"),Color("#405747")]
	elif biome=="meadow":ridges=[Color("#adc18c"),Color("#819f66"),Color("#526f4b")]
	elif biome=="oak":ridges=[Color("#b4ac79"),Color("#8c965e"),Color("#596b43")]
	draw_style_box(game.panel_style(sky,18),Rect2(Vector2.ZERO,size))
	for band in range(16):
		var t := float(band)/15
		draw_rect(Rect2(3,18+t*(h-36),w-6,(h-36)/15+2),sky.lerp(Color("#ddce99") if not dark else Color("#42686a"),t))
	var sun := Vector2(w*0.72,h*0.25)
	draw_circle(sun,30,Color(1,0.94,0.73,0.13))
	draw_circle(sun,22,Color("#e6e5cc") if dark else Color("#f7e5ad"))
	if dark:draw_circle(sun+Vector2(10,-7),20,sky)
	for layer in range(3):
		var ridge := PackedVector2Array([Vector2(3,h-5)])
		for step in range(37):
			var x := 3+(w-6)*step/36.0
			var y := h*(0.41+layer*0.12)+sin(step*0.29+layer*2)*h*0.09+cos(step*0.54)*h*0.025
			ridge.append(Vector2(x,y))
		ridge.append(Vector2(w-3,h-5))
		draw_colored_polygon(ridge,ridges[layer])
	var stream := PackedVector2Array([Vector2(w*0.56,h*0.57),Vector2(w*0.5,h*0.72),Vector2(w*0.63,h*0.85),Vector2(w*0.48,h-4)])
	if biome in ["river","lake","marsh"]:draw_polyline(stream,Color("#85b7ab"),8 if biome=="river" else 5,true)
	if biome=="coast":
		for row in range(4):draw_line(Vector2(w*.47,h*(.58+row*.08)),Vector2(w-4,h*(.60+row*.08)),Color("#9fc9c2"),3,true)
	if biome in ["snow","alpine"]:
		for i in range(5):
			var peak := Vector2(w*(.43+i*.12),h*(.37+sin(i)*.04))
			draw_colored_polygon(PackedVector2Array([peak,peak+Vector2(-17,21),peak+Vector2(14,17)]),Color("#e2e8dd"))
	for i in range(12):
		var x := w*i/11
		var y := h*0.78+sin(i*1.7)*10
		var height := 26+fposmod(i*13,26)
		if biome in ["coast","meadow"] and i%3!=0:continue
		if biome in ["oak","forest"]:
			draw_line(Vector2(x,y),Vector2(x,y-height*.7),Color("#435442"),3)
			for crown in range(3):draw_circle(Vector2(x+(crown-1)*height*.17,y-height*.68-absf(crown-1)*height*.07),height*.24,Color("#4b6843") if biome=="oak" else Color("#244e41"))
		else:_tree(Vector2(x,y),height,Color("#415e57") if biome=="snow" else Color("#153d34"))
	for i in range(11):
		var point := Vector2(w*0.06+i*w*0.084,h*0.90+sin(i*1.3)*6)
		draw_line(point,point-Vector2(4,8),Color("#93af69"),1.5)
		draw_circle(point-Vector2(4,8),2,[Color("#dfca83"),Color("#aec095"),Color("#b992a1")][i%3])
	var wolf := WolfAtlas.sprite(15)
	draw_texture_rect(wolf,Rect2(w*0.05,h*0.30,w*0.42,h*0.55),false,Color("#faf3de"))
	draw_rect(Rect2(3,h-32,w-6,28),Color(0.06,0.17,0.13,0.86))
	draw_string(ThemeDB.fallback_font,Vector2(14,h-14),caption,HORIZONTAL_ALIGNMENT_LEFT,w-24,11,Color("#e1d6b6"))

func _tree(p: Vector2,height: float,color: Color) -> void:
	draw_line(p,p-Vector2(0,height*0.8),color.darkened(0.12),2)
	for tier in range(3):
		var y := p.y-height+tier*height*0.18
		var spread := height*(0.15+tier*0.09)
		draw_colored_polygon(PackedVector2Array([Vector2(p.x,y),Vector2(p.x-spread,y+height*0.42),Vector2(p.x+spread,y+height*0.42)]),color)

func _glyph() -> void:
	var c := size*0.5
	var r := minf(size.x,size.y)*0.42
	var ink := Color("#dfce92")
	match kind:
		"map":
			for i in range(3):
				var p := c+Vector2((i-1)*r*0.7,-r*0.75)
				draw_rect(Rect2(p,Vector2(r*0.65,r*1.5)),ink,false,1.5)
			draw_line(c+Vector2(-r*0.65,r*0.35),c+Vector2(r*0.6,-r*0.25),ink,2)
		"book","journal":
			draw_rect(Rect2(c-Vector2(r,r*0.72),Vector2(r*2,r*1.45)),ink,false,2)
			draw_line(c-Vector2(0,r*0.7),c+Vector2(0,r*0.7),ink,2)
			for i in range(3):draw_line(c+Vector2(-r*0.8,-r*0.35+i*r*0.3),c+Vector2(-r*0.25,-r*0.35+i*r*0.3),ink,1)
		"compass":
			draw_arc(c,r,0,TAU,32,ink,2,true)
			draw_colored_polygon(PackedVector2Array([c+Vector2(r*0.45,-r*0.7),c+Vector2(-r*0.35,r*0.55),c]),ink)
			draw_line(c+Vector2(r*0.45,-r*0.7),c+Vector2(-r*0.35,r*0.55),ink,1)
		"leaf":
			draw_colored_polygon(PackedVector2Array([c-Vector2(0,r),c+Vector2(r*0.8,-r*0.25),c+Vector2(r*0.65,r*0.6),c+Vector2(0,r),c+Vector2(-r*0.65,r*0.6),c-Vector2(r*0.8,r*0.25)]),ink.darkened(0.15))
			draw_line(c-Vector2(0,r*0.8),c+Vector2(0,r*0.85),Color("#faf0c9"),1.5)
		_:
			draw_circle(c+Vector2(0,r*0.38),r*0.48,ink)
			for i in range(4):draw_circle(c+Vector2((i-1.5)*r*0.45,-r*0.38-absf(i-1.5)*r*-0.13),r*0.22,ink)
