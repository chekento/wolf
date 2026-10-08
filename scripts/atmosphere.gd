class_name WolfAtmosphere
extends Control

var game: Node
var redraw_timer := 0.0
var last_clock := -1.0
var last_weather := ""

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE

func _process(dt: float) -> void:
	if game==null:return
	redraw_timer+=dt
	var weather: String=game.state.weather() if game.state.weather_enabled else "disabled"
	# Redraw once when effects are disabled so previous rain/snow disappears.
	# Paused menus and unchanging skies need no repeating canvas work.
	if weather!=last_weather or (weather!="disabled" and game.clock!=last_clock and redraw_timer>=1.0/30.0):
		last_weather=weather
		last_clock=game.clock
		redraw_timer=0.0
		queue_redraw()

func mist_band(y: float,width: float,alpha: float,time: float,layer: int) -> void:
	var polygon := PackedVector2Array()
	for i in range(13):
		var x := -60+float(i)/12.0*(size.x+120)
		polygon.append(Vector2(x,y+sin(float(i)*.55+time*.08+layer)*13))
	for i in range(12,-1,-1):
		var x := -60+float(i)/12.0*(size.x+120)
		polygon.append(Vector2(x,y+width+sin(float(i)*.55+time*.08+layer)*13))
	draw_colored_polygon(polygon,Color(.77,.86,.78,alpha))

func _draw() -> void:
	if game==null or not game.state.weather_enabled or size.x<=0 or size.y<=0:return
	var weather: String=game.state.weather()
	var time: float=game.clock
	var amount := 0.18 if game.state.reduced_motion else 1.0
	var daylight: float=game.state.sunlight()
	if weather=="Regen":
		for i in range(72):
			var depth := .65+float(i%3)*.25
			var p := Vector2(fposmod(i*97.7-time*18*amount*depth,size.x+40)-20,fposmod(i*47.3+time*245*amount*depth,size.y+30)-15)
			draw_line(p,p+Vector2(-3.5,13)*depth,Color(.78,.87,.92,.13+float(i%3)*.045),.8 if i%3!=2 else 1.2,true)
		draw_rect(Rect2(Vector2.ZERO,size),Color(.16,.23,.30,.035))
	elif weather=="Schnee":
		for i in range(58):
			var depth := .7+float(i%3)*.3
			var drift := sin(time*.65+i)*12*amount+time*5*amount
			var p := Vector2(fposmod(i*137.2+drift,size.x+20)-10,fposmod(i*61.1+time*22*amount*depth,size.y+20)-10)
			var colour := Color(.93,.97,.98,.39+float(i%3)*.12)
			draw_circle(p,(.95+float(i%3)*.6)*depth,colour)
			if i%9==0:
				for arm in range(3):
					var direction := Vector2(cos(arm*PI/3),sin(arm*PI/3))*3*depth
					draw_line(p-direction,p+direction,Color(colour,.45),.7,true)
	elif weather=="Nebel":
		for layer in range(5):
			var y := fposmod(layer*211.0+time*3*amount,size.y+240)-120
			mist_band(y,110+float(layer%2)*30,.020+float(layer%2)*.007,time*amount,layer)
		draw_rect(Rect2(Vector2.ZERO,size),Color(.63,.73,.67,.015))
	elif weather=="klar":
		var biome: String=WolfWorldData.REGIONS[game.state.region].biome
		if daylight<.30 and biome in ["forest","oak","marsh","lake"] and game.state.season_name()!="Winter":
			for i in range(7):
				var p := Vector2(fposmod(i*83.3+sin(time*.23+i)*18*amount,size.x),fposmod(i*97.2+cos(time*.31+i)*20*amount,size.y))
				var glow := .17+maxf(0.0,sin(time*.8+i*1.3))*.20
				draw_circle(p,3,Color(.83,.84,.44,glow*.17))
				draw_circle(p,1,Color(.95,.93,.64,glow))
