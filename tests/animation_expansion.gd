extends SceneTree

# Consecutive frames catch support-pad sliding and airborne stops that
# anatomical snapshots alone cannot detect.
const Animal = preload("res://scripts/animal_model.gd")
const DT := 1.0/120.0
var failures := 0
var checks := 0

func _initialize() -> void:call_deferred("run")

func check(value: bool,message: String) -> void:
	checks+=1
	if value:print("PASS: "+message)
	else:push_error("FAIL: "+message);failures+=1

func new_animal(species: String) -> WolfAnimalModel:
	var model := Animal.new();root.add_child(model);model.build(species)
	return model

func world_pad(model: WolfAnimalModel,index: int) -> Vector3:
	return model.transform*model.foot_position(index)

func run() -> void:
	for species in ["wolf","fox","deer","rabbit"]:
		var model := new_animal(species)
		model.set_foot_heights([-.018,.014,-.008,.022])
		model.animate(0,0,"lauschen",0)
		var previous: Array[Vector3]=[]
		for i in range(4):previous.append(world_pad(model,i))
		var previous_planted: Array[bool]=model.foot_planted.duplicate()
		var previous_speed := 0.0
		var previous_height: float=model.torso.position.y
		var distance := 0.0
		var max_support_drift := 0.0
		var max_contact_error := 0.0
		var max_pose_jump := 0.0
		var max_excess_motion := 0.0
		var support_frames := 0
		var all_finite := true
		for frame in range(1,541):
			var time := frame*DT
			var speed := 0.0
			var mood := "lauschen"
			if time>=.4 and time<1.2:speed=lerpf(15,78,(time-.4)/.8);mood="wandern"
			elif time>=1.2 and time<2.0:speed=lerpf(78,82,(time-1.2)/.8);mood="laufen"
			elif time>=2.0 and time<2.6:speed=lerpf(82,120,(time-2.0)/.6);mood="fliehen"
			elif time>=2.6 and time<3.0:speed=lerpf(120,0,(time-2.6)/.4);mood="laufen"
			elif time>=3.5:mood="ruhen"
			distance+=speed*DT
			model.position.z=-distance*.032
			model.animate(distance/22.0,speed,mood,time)
			max_pose_jump=maxf(max_pose_jump,absf(model.torso.position.y-previous_height))
			previous_height=model.torso.position.y
			for i in range(4):
				var pad := world_pad(model,i)
				all_finite=all_finite and pad.is_finite() and is_finite(model.knees[i].rotation.x)
				var jump: float=pad.distance_to(previous[i])
				max_excess_motion=maxf(max_excess_motion,jump-(.035+speed*.032*DT*5))
				if model.foot_planted[i]:
					max_contact_error=maxf(max_contact_error,absf(model.foot_position(i).y-model.foot_ground[i]-model.paw_sizes[i].y))
					if previous_planted[i] and speed>3 and previous_speed>3:
						max_support_drift=maxf(max_support_drift,pad.distance_to(previous[i]))
						support_frames+=1
				previous[i]=pad
			previous_planted=model.foot_planted.duplicate()
			previous_speed=speed
		print(JSON.stringify({"species":species,"support_frames":support_frames,"support_drift_m":max_support_drift,"contact_error_m":max_contact_error,"body_jump_m":max_pose_jump,"excess_foot_jump_m":max_excess_motion}))
		check(all_finite,"finite continuous acceleration / trot / flee / rest "+species)
		check(support_frames>300 and max_support_drift<.004,"support pads stay still through speed and gait changes "+species)
		check(max_contact_error<.003,"planted paws remain on uneven soil during real-frame transitions "+species)
		check(max_pose_jump<.03,"body changes height without a one-frame drop "+species)
		check(max_excess_motion<.005,"no sudden foot teleport at gait or mood changes "+species)
		check(model.foot_planted.all(func(value:bool)->bool:return value),"all four pads settle after deceleration "+species)
		model.free()

		# Stop at an airborne moment, rather than waiting for convenient stance.
		model=new_animal(species)
		var period: float=model.stride_length()*model.scale.x/(22.0*.032)
		var stop_gait := period*(.40 if species=="rabbit" else .80)
		model.animate(stop_gait,80,"laufen",0)
		var flying := model.foot_planted.count(false)
		var first_air_pad := -1
		for i in range(4):
			if not model.foot_planted[i]:first_air_pad=i;break
		var air_position := model.foot_position(first_air_pad)
		model.animate(stop_gait,0,"lauschen",DT*.1)
		check(flying>0 and model.foot_position(first_air_pad).distance_to(air_position)<.035,"stop preserves an airborne foot instead of resetting it "+species)
		for frame in range(2,73):model.animate(stop_gait,0,"lauschen",frame*DT)
		var settled := true
		for i in range(4):settled=settled and model.foot_planted[i] and absf(model.foot_position(i).y-model.paw_sizes[i].y)<.003
		check(settled,"airborne stop finishes with all feet on the soil "+species)
		model.free()

		model=new_animal(species)
		model.animate(0,0,"lauschen",0,false,1.0,-.6)
		var old_head: float=model.head.rotation.y
		model.animate(0,0,"begrüßen",DT,false,1.0,.6)
		check(absf(model.head.rotation.y-old_head)<.12,"attention reversal eases the neck rather than snapping "+species)
		for frame in range(2,121):model.animate(0,0,"begrüßen",frame*DT,false,1.0,.6)
		check(model.head.rotation.y>.55 and model.ears[0].rotation.y>model.ears[1].rotation.y+.04,"head follows attention and ears orient independently "+species)
		var quiet := new_animal(species)
		model.animate(0,0,"begrüßen",0);quiet.animate(0,0,"begrüßen",0,true)
		var lively_range := 0.0;var quiet_range := 0.0
		for frame in range(1,241):
			model.animate(0,0,"begrüßen",frame*DT);quiet.animate(0,0,"begrüßen",frame*DT,true)
			lively_range=maxf(lively_range,absf(model.tail.rotation.y));quiet_range=maxf(quiet_range,absf(quiet.tail.rotation.y))
		check(lively_range>.12 and quiet_range<lively_range*.28,"calm greeting has visible wag with reduced-motion preference "+species)
		model.free();quiet.free()

		model=new_animal(species)
		var frozen_distance := 0.0
		for frame in range(121):
			var velocity := 35.0 if frame<70 else 95.0
			frozen_distance+=velocity/60.0
			model.animate(frozen_distance/22.0,velocity,"laufen",frame/60.0)
		var frozen_feet: Array[Vector3]=[]
		for i in range(4):frozen_feet.append(model.foot_position(i))
		model.animate(frozen_distance/22.0,95,"laufen",2.0)
		var unchanged := true
		for i in range(4):unchanged=unchanged and model.foot_position(i).distance_to(frozen_feet[i])<.00001
		check(unchanged,"repeated camera sync at the same clock preserves current feet "+species)
		model.free()

	for species in ["deer","fox","rabbit"]:
		var pose := WolfMapView.animal_pose(species,Vector2.LEFT,0,0,"lauschen")
		var previous_muzzle := Vector2(-39,-10)
		var maximum_step := 0.0
		for frame in range(60):
			var goal := WolfMapView.animal_pose(species,Vector2.LEFT,0,0,"grasen",false,0,frame/60.0)
			pose=WolfMapView.blend_animal_pose(pose,goal,1.0/60.0)
			var muzzle: Vector2=Vector2(-39,-10).rotated(pose.head_angle)+Vector2(0,pose.head_drop)
			maximum_step=maxf(maximum_step,muzzle.distance_to(previous_muzzle));previous_muzzle=muzzle
		check(maximum_step<3 and previous_muzzle.y>3,"illustrated muzzle eases downward into feeding "+species)
		var head_min := 1.0;var head_max := -1.0
		for frame in range(120):
			var feeding := WolfMapView.animal_pose(species,Vector2.LEFT,0,0,"grasen",false,0,frame/60.0)
			head_min=minf(head_min,feeding.head_angle);head_max=maxf(head_max,feeding.head_angle)
		check(head_max-head_min>.035 and head_max<-.32,"2D feeding retains groundward pose with small natural head motion "+species)
	var lively_pose := WolfMapView.animal_pose("wolf",Vector2.LEFT,0,0,"begrüßen",false,0,.9)
	var quiet_pose := WolfMapView.animal_pose("wolf",Vector2.LEFT,0,0,"begrüßen",true,0,.9)
	check(absf(lively_pose.breath_scale.y-1)>.004 and absf(quiet_pose.breath_scale.y-1)<.0016,"illustrated wolf breathes softly with reduced-motion preference")
	var old_pose := WolfMapView.animal_pose("wolf",Vector2.LEFT,0,0,"lauschen")
	var moving_pose := WolfMapView.animal_pose("wolf",Vector2.LEFT,.3,80,"laufen")
	check(WolfMapView.blend_animal_pose(old_pose,moving_pose,.001).frame==moving_pose.frame,"2D pose easing preserves exact distance-driven atlas frame")
	print("Animation checks: ",checks,"; failures: ",failures)
	quit(failures)
