extends SceneTree
var failures := 0
func _initialize() -> void:call_deferred("run")
func check(value: bool,message: String) -> void:
	if value:print("PASS: "+message)
	else:push_error("FAIL: "+message);failures+=1
func run() -> void:
	for species in ["wolf","fox","deer","rabbit"]:
		var model := WolfAnimalModel.new()
		root.add_child(model);model.build(species)
		var max_stance_error := 0.0
		var max_tilt := 0.0
		var finite := true
		var lifted := false
		for mood in ["laufen","fliehen"]:
			for step in range(96):
				var gait: float=float(step)/96*model.stride_length()*model.scale.x/(22.0*.032)
				model.animate(gait,80 if mood=="laufen" else 150,mood,0)
				for i in range(4):
					var foot := model.foot_position(i)
					finite=finite and foot.is_finite() and is_finite(model.knees[i].rotation.x)
					if model.foot_planted[i]:max_stance_error=maxf(max_stance_error,absf(foot.y-model.paw_sizes[i].y))
					else:lifted=lifted or foot.y>model.paw_sizes[i].y+.035
					max_tilt=maxf(max_tilt,absf(model.torso.rotation.x+model.legs[i].rotation.x+model.knees[i].rotation.x+model.paws[i].rotation.x))
		check(finite,"finite two-joint solutions over complete walk and escape cycles "+species)
		check(max_stance_error<.003,"planted pads stay on soil through entire gait "+species+" max="+str(max_stance_error))
		check(max_tilt<.0001 and lifted,"ankles cancel shin angle while swing feet lift "+species)
		var planted_index := 2 if species=="rabbit" else 0
		var distance_step := model.stride_length()*model.scale.x/(22.0*.032)
		model.animate(distance_step*.08,80,"laufen",0)
		var first_z := model.foot_position(planted_index).z*model.scale.x
		model.animate(distance_step*.16,80,"laufen",0)
		var second_z := model.foot_position(planted_index).z*model.scale.x-distance_step*.08*22*.032
		check(absf(second_z-first_z)<.006,"stance progression matches actual forward distance "+species)
		model.animate(distance_step*.08,32,"wandern",0)
		first_z=model.foot_position(planted_index).z*model.scale.x
		model.animate(distance_step*.16,32,"wandern",0)
		second_z=model.foot_position(planted_index).z*model.scale.x-distance_step*.08*22*.032
		check(absf(second_z-first_z)<.006,"slow walk also keeps its stance pad planted "+species)
		model.set_foot_heights([-.025,.02,.01,-.015])
		model.animate(0,0,"lauschen",0)
		var uneven_error := 0.0
		for i in range(4):uneven_error=maxf(uneven_error,absf(model.foot_position(i).y-model.paw_sizes[i].y-model.foot_ground[i]))
		check(uneven_error<.003,"four terrain samples support uneven standing ground "+species)
		model.set_foot_heights([0.0,0.0,0.0,0.0])
		model.animate(0,0,"lauschen",0,false,1.0,.55)
		check(model.head.rotation.y>.45 and model.ears[0].rotation.y>.12,"head and ears orient toward attention target "+species)
		model.animate(0,0,"begrüßen",.5)
		var greeting_tail := absf(model.tail.rotation.y)
		model.animate(0,0,"begrüßen",0,true)
		check(greeting_tail>.03 and absf(model.tail.rotation.y)<greeting_tail,"friendly greeting and reduced incidental motion "+species)
		if species=="rabbit":
			model.animate(distance_step*.40,80,"laufen",0)
			check(not model.foot_planted.any(func(p:bool):return p),"rabbit has coordinated airborne phase")
		model.free()
	var grazing := WolfMapView.animal_pose("deer",Vector2.LEFT,0,0,"grasen")
	var resting := WolfMapView.animal_pose("fox",Vector2.RIGHT,0,0,"ruhen")
	var standing := WolfMapView.animal_pose("fox",Vector2.RIGHT,0,0,"lauschen")
	check(grazing.head_drop>6 and grazing.head_angle>.2,"2D grazing lowers and turns illustrated head")
	check(resting.scale.y<standing.scale.y*.8,"2D resting body is visibly lower")
	check(WolfMapView.animal_pose("rabbit",Vector2.LEFT,.16,80,"laufen",true).lift==0,"reduced-motion 2D keeps body steady")
	print("Locomotion failures: ",failures)
	quit(failures)
