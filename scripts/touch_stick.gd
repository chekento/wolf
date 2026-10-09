class_name WolfTouchStick
extends Control

var vector := Vector2.ZERO
var pointer := -1
var mouse_down := false

func _ready() -> void:
	custom_minimum_size=Vector2(140,140)
	mouse_filter=Control.MOUSE_FILTER_STOP

func _gui_input(event: InputEvent) -> void:
	if event.device==InputEvent.DEVICE_ID_EMULATION and (event is InputEventMouseButton or event is InputEventMouseMotion):return
	if event is InputEventScreenTouch:
		if event.pressed and pointer==-1:
			pointer=event.index
			_update_vector(event.position)
		elif not event.pressed and pointer==event.index:
			reset()
		accept_event()
	elif event is InputEventScreenDrag and event.index==pointer:
		_update_vector(event.position)
		accept_event()
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		mouse_down=event.pressed
		if mouse_down:_update_vector(event.position)
		else:reset()
		accept_event()
	elif event is InputEventMouseMotion and mouse_down:
		_update_vector(event.position)
		accept_event()

func _update_vector(p: Vector2) -> void:
	# The joystick becomes narrower on a phone; its usable travel must scale
	# with the actual touch region rather than a fixed 48-pixel desktop radius.
	var travel := maxf(28.0,minf(size.x,size.y)*0.32)
	vector=((p-size*0.5)/travel).limit_length(1)
	if vector.length()<0.12:vector=Vector2.ZERO
	queue_redraw()

func reset() -> void:
	vector=Vector2.ZERO
	pointer=-1
	mouse_down=false
	queue_redraw()

func _draw() -> void:
	var p := size*0.5
	var radius := minf(63.0,minf(size.x,size.y)*0.43)
	var travel := maxf(28.0,minf(size.x,size.y)*0.32)
	var knob := maxf(15.0,radius*0.38)
	draw_circle(p,radius,Color(0.05,0.15,0.15,0.68))
	draw_arc(p,radius-1,0,TAU,60,Color(0.86,0.89,0.76,0.6),2)
	for d in [Vector2.UP,Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT]:
		draw_circle(p+d*(radius*.74),maxf(2.0,radius*.045),Color("#bfcbbb"))
	draw_circle(p+vector*travel,knob,Color("#d6d7bc"))
	draw_circle(p+vector*travel-Vector2(3,4),knob*.62,Color("#ede9cc"))
