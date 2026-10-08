extends SceneTree

const Animal = preload("res://scripts/animal_model.gd")
var checks := 0
var failures := 0

func _initialize() -> void:call_deferred("run")

func check(value: bool,message: String) -> void:
	checks+=1
	if value:print("PASS: "+message)
	else:push_error("FAIL: "+message);failures+=1

func collect_meshes(node: Node,result: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:result.append(node)
	for child in node.get_children():collect_meshes(child,result)

func joint_mesh(joint: Node3D) -> Mesh:
	for child in joint.get_children():
		if child is MeshInstance3D:return child.mesh
	return null

func vertex_bounds(model: WolfAnimalModel) -> AABB:
	var instances: Array[MeshInstance3D]=[];collect_meshes(model,instances)
	var first := true
	var bounds := AABB()
	for instance in instances:
		var transform: Transform3D=model.global_transform.affine_inverse()*instance.global_transform
		var vertices: PackedVector3Array=instance.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		for vertex in vertices:
			var p := transform*vertex
			if first:bounds=AABB(p,Vector3.ZERO);first=false
			else:bounds=bounds.expand(p)
	return bounds

func run() -> void:
	var anatomical_bounds := {}
	for species in ["wolf","fox","deer","rabbit"]:
		var model := Animal.new();root.add_child(model);model.build(species)
		model.animate(0,0,"lauschen",0)
		var instances: Array[MeshInstance3D]=[];collect_meshes(model,instances)
		check(instances.size()==21,"detail remains in twenty-one shared joint meshes "+species)
		var triangles := 0
		var finite := true
		var varied_colors := {}
		for instance in instances:
			triangles+=instance.mesh.surface_get_array_index_len(0)/3
			var arrays := instance.mesh.surface_get_arrays(0)
			for point in arrays[Mesh.ARRAY_VERTEX]:finite=finite and point.is_finite()
			for normal in arrays[Mesh.ARRAY_NORMAL]:finite=finite and normal.is_finite() and absf(normal.length()-1)<.002
			for color in arrays[Mesh.ARRAY_COLOR]:varied_colors[color.to_html()]=true
		check(triangles<9000,"bounded triangle cost for facial, ear and fur detail "+species)
		check(finite and varied_colors.size()>35,"finite smooth taper normals and original painted fur "+species)
		var bounds := vertex_bounds(model)
		anatomical_bounds[species]=bounds.size*model.scale.x
		check(bounds.position.y>-.005 and bounds.size.x<1.1 and bounds.size.z>1 and bounds.size.z<3.2,"standing silhouette has four grounded limbs and coherent proportions "+species)
		var duplicate := Animal.new();root.add_child(duplicate);duplicate.build(species)
		check(joint_mesh(model.head)==joint_mesh(duplicate.head),"detail meshes are reused by a second individual "+species)
		duplicate.free()
		var standing_nose := model.nose_position().y
		var nose_heights := {}
		var max_contact_error := 0.0
		var largest_nose_jump := 0.0
		var lowest_skin := 0.0
		var time := 0.0
		var old_nose := model.nose_position()
		for mood in ["grasen","trinken","lauschen","ruhen","heulen"]:
			for frame in range(180):
				time+=1.0/60.0
				model.animate(0,0,mood,time)
				largest_nose_jump=maxf(largest_nose_jump,old_nose.distance_to(model.nose_position()))
				old_nose=model.nose_position()
				for i in range(4):max_contact_error=maxf(max_contact_error,absf(model.foot_position(i).y-model.paw_sizes[i].y))
				nose_heights[mood]=model.nose_position().y
			if mood=="ruhen":lowest_skin=vertex_bounds(model).position.y
		check(max_contact_error<.003,"pads keep soil contact through feeding / drinking / listening / rest / howl "+species)
		check(nose_heights.grasen<.26 and nose_heights.grasen<standing_nose*.4,"actual muzzle reaches low flora instead of merely tipping the head "+species)
		check(nose_heights.trinken<nose_heights.grasen+.05 and nose_heights.trinken>-.01,"drinking muzzle approaches water without passing below the soil "+species)
		check(nose_heights.lauschen>nose_heights.grasen+.25 and nose_heights.heulen>standing_nose+.10,"listening and raised calling muzzle restore clear distinct silhouettes "+species)
		check(lowest_skin>-.06,"resting belly and ears do not disappear beneath the ground "+species)
		check(largest_nose_jump<.25,"full mood changes keep the muzzle moving continuously "+species)
		print(JSON.stringify({"species":species,"triangles":triangles,"standing_bounds":str(bounds),"nose_heights":nose_heights,"contact_error_m":max_contact_error,"rest_skin_min_y":lowest_skin,"largest_nose_step_m":largest_nose_jump}))
		model.free()
	check(anatomical_bounds.deer.y>anatomical_bounds.wolf.y*1.35 and anatomical_bounds.wolf.y>anatomical_bounds.fox.y and anatomical_bounds.fox.y>anatomical_bounds.rabbit.y,"species retain distinct measured overall heights")
	print("Animal detail checks: ",checks,"; failures: ",failures)
	quit(failures)
