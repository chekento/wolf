class_name WolfGuardianLore
extends RefCounted

# One named, hand-authored NPC for every connected macro-sector.
# Locations use the stable legacy 16x16 map, never newly assigned IDs.
const GUARDIANS := [
	{"name":"Auri · die Polarfüchsin","kind":"fox","coord":Vector2i(2,2),"token":"Bernstein im Eis","reward":"tonic","story":"Auri hütet die frostigen Küsten. Sie sucht den einzigen Bernstein, den das Eis ans Ufer getragen hat."},
	{"name":"Nivar · der Schneehirsch","kind":"deer","coord":Vector2i(7,2),"token":"Kristallfeder","reward":"food","story":"Nivar kennt den Schnee wie seine Hufspur. Eine einzelne Kristallfeder ging im weißen Wald verloren."},
	{"name":"Tora · die Bergwölfin","kind":"wolf","coord":Vector2i(13,2),"token":"Sonnenquarz","reward":"tonic","story":"Tora bewacht die hohen Grate. Finde den Sonnenquarz an einem sicheren Felswechsel."},
	{"name":"Mirra · der Küstenfuchs","kind":"fox","coord":Vector2i(2,8),"token":"Perlmuttmuschel","reward":"food","story":"Mirra hat eine ungewöhnlich schimmernde Muschel am Strand verloren."},
	{"name":"Eno · der Silberwolf","kind":"wolf","coord":Vector2i(7,8),"token":"Alte Rudelfeder","reward":"tonic","story":"Eno erinnert sich an eine Feder, die der Wind einst aus der Familienlichtung trug."},
	{"name":"Sera · die Waldhirschkuh","kind":"deer","coord":Vector2i(12,9),"token":"Smaragdblatt","reward":"food","story":"Hinter dem Menschendorf bewahrt Sera das Wissen über ein einziges Smaragdblatt."},
	{"name":"Moori · der Moorfuchs","kind":"fox","coord":Vector2i(2,13),"token":"Mondschilf","reward":"tonic","story":"Moori sucht eine seltene Schilfblüte, die nur in diesem Moor wächst."},
	{"name":"Piko · der Auenhase","kind":"rabbit","coord":Vector2i(7,13),"token":"Flussopal","reward":"food","story":"Piko hat den einzigen Flussopal in den Auen versteckt. Nun hat er die Spur verloren."},
	{"name":"Sora · der Höhenwolf","kind":"wolf","coord":Vector2i(13,13),"token":"Goldgras","reward":"tonic","story":"Sora braucht einen Halm Goldgras, den die Berge nur in dieser Jahreszeit tragen."}
]

static func data(zone: int) -> Dictionary:
	return GUARDIANS[zone] if zone>=0 and zone<GUARDIANS.size() else {}

static func home_region(zone: int) -> int:
	return WolfWorldData.index_at(data(zone).get("coord",Vector2i(-1,-1)))

static func relic_region(zone: int) -> int:
	var here: Vector2i=data(zone).get("coord",Vector2i(-1,-1))
	# The unique item is never directly beside the quest giver.
	var target: Vector2i=here+Vector2i(1,0) if here.x<15 and WolfRegionGates.zone_at(here+Vector2i(1,0))==zone else here+Vector2i(-1,0)
	return WolfWorldData.index_at(target)

static func relic_pos(zone: int) -> Vector2:
	var region := relic_region(zone)
	return WolfWorldData.nature_sites(region)[4].p if region>=0 else WolfWorldData.CENTER

static func home_pos(zone: int) -> Vector2:
	return Vector2(890,1080) if zone==4 else Vector2(1650,960)

static func find_zone(region: int) -> int:
	return WolfRegionGates.zone(region)
