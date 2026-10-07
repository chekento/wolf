class_name WolfAtmosphere
extends Control

var game: Node

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE

func _process(_dt: float) -> void:
	if game!=null and game.state.weather_enabled:queue_redraw()

func _draw() -> void:
	if game==null or not game.state.weather_enabled:return
	var weather: String=game.state.weather()
	var time: float=game.clock
	var amount := 0.25 if game.state.reduced_motion else 1.0
	if weather=="Regen":
		for i in range(64):
			var p := Vector2(fposmod(i*97.7-time*16*amount,size.x+30)-15,fposmod(i*47.3+time*270*amount,size.y))
			draw_line(p,p+Vector2(-4,15),Color(0.81,0.9,0.95,0.25),1)
		draw_rect(Rect2(Vector2.ZERO,size),Color(0.15,0.22,0.34,0.04))
	elif weather=="Schnee":
		for i in range(46):
			var p := Vector2(fposmod(i*137.2+sin(time*0.7+i)*14*amount,size.x),fposmod(i*61.1+time*24*amount,size.y))
			draw_circle(p,1.2+float(i%2),Color(0.95,0.98,1,0.68))
	elif weather=="Nebel":
		for i in range(4):
			var y := fposmod(i*225+time*4*amount,size.y)
			draw_line(Vector2(-60,y),Vector2(size.x+60,y-45),Color(0.78,0.87,0.77,0.024),100)
