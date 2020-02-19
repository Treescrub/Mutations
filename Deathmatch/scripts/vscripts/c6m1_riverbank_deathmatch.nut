IncludeScript("response_testbed")

Map_PlayerSpawns <- [
	PlayerSpawn(Vector(4703, 3695, 32), QAngle(0, -135, 0)),
	PlayerSpawn(Vector(2879, 2592, 74), QAngle(0, 65, 0)),
	PlayerSpawn(Vector(1109, 4108, 96), QAngle(0, -100, 0)),
	PlayerSpawn(Vector(1725, 2687, 96), QAngle(0, 115, 0)),
	PlayerSpawn(Vector(3619, 3682, -31), QAngle(0, -135, 0)),
]

Map_ItemSpawns <- [
	DeathmatchItemSpawn("gnome", Vector(3350.64, 2402.37, 147.531), QAngle(0, -193, 0)),
	DeathmatchItemSpawn("rifle_sg552", Vector(939.073, 4001.66, 151.988), QAngle(0, -86, 91)),
	DeathmatchItemSpawn("pistol_magnum", Vector(939.121, 4019.46, 151.667), QAngle(1, 67, -92)),
	DeathmatchItemSpawn("molotov", Vector(1476.94, 3638.07, 30.0313), QAngle(0, -91, 92)),
	DeathmatchItemSpawn("pain_pills", Vector(2460.49, 3274.61, 0.031253), QAngle(0, -94, 0)),
	DeathmatchItemSpawn("sniper_awp", Vector(3105.63, 2258.37, 210.031), QAngle(-67, 86, -83)),
	DeathmatchItemSpawn("grenade_launcher", Vector(3466.74, 2527.94, 100.945), QAngle(0, 79, -90)),
	DeathmatchItemSpawn("rifle_ak47", Vector(2531.63, 2938.77, 112.527), QAngle(-1, -80, -96)),
	DeathmatchItemSpawn("smg_silenced", Vector(3592.06, 2917.7, 82.8355), QAngle(4, 0, 85)),
	DeathmatchItemSpawn("adrenaline", Vector(3587.54, 2933.19, 81.9337), QAngle(-2, 3, -3)),
	DeathmatchItemSpawn("rifle", Vector(3234.86, 3569.99, 1.03125), QAngle(0, 14, -92)),
	DeathmatchItemSpawn("shotgun_chrome", Vector(4457.17, 3655.71, 71.6613), QAngle(-4, -19, -99)),
	DeathmatchItemSpawn("pipe_bomb", Vector(4465.18, 3647.17, 72.6627), QAngle(0, 0, 83)),
	DeathmatchItemSpawn("shotgun_spas", Vector(1556.81, 3020.72, 133.67), QAngle(-4, 0, -85)),
	DeathmatchItemSpawn("hunting_rifle", Vector(1974.01, 3166.4, 8.53125), QAngle(0, 0, 83)),
	DeathmatchItemSpawn("first_aid_kit", Vector(2771.76, 3731.91, 67.9632), QAngle(89, -18, 0)),
	DeathmatchItemSpawn("pistol", Vector(3238.08, 3082.29, 51.3415), QAngle(0, 0, -91)),
	DeathmatchItemSpawn("rifle_m60", Vector(2632.77, 3331.36, 115.487), QAngle(-1, 20, 69)),
]

Map_InitialPlayerSpawns <- [PlayerSpawn(Vector(880, 3788, 100), QAngle(0, 49.5, 0))]

EntFire("store1_door3", "Close")
EntFire("store1_door3", "Lock")
EntFire("store1_door3", "SetHealth", "100000")

EntFire("store2_door3", "Lock")
EntFire("store2_door3", "SetHealth", "100000")

EntFire("locker-*", "Kill")

function OnGameplayStart(){
	if(!g_ModeScript.ExecuteMapFileCode()){
		SpawnEntityFromTable("prop_dynamic_override", {model = "models/props_debris/wood_board05a.mdl", origin = Vector(3264.38, 2624.84, 118.938), angles = "-1.000000 -90.000000 -94.000000", solid = 6, spawnflags = 8})
		SpawnEntityFromTable("prop_dynamic_override", {model = "models/props_debris/wood_board05a.mdl", origin = Vector(3265.69, 2625.78, 91.5), angles = "-2.000000 -90.000000 -88.000000", solid = 6, spawnflags = 8})
		
		SpawnEntityFromTable("prop_dynamic_override", {model = "models/props_debris/wood_board05a.mdl", origin = Vector(3532.75, 2625.28, 128.875), angles = "0.000000 -90.000000 -92.000000", solid = 6, spawnflags = 8})
		SpawnEntityFromTable("prop_dynamic_override", {model = "models/props_debris/wood_board05a.mdl", origin = Vector(3510.44, 2625, 91.875), angles = "0.000000 -90.000000 -89.000000", solid = 6, spawnflags = 8})
		
		DoEntFire("!self", "Lock", "", 0, null, Entities.FindByClassnameNearest("prop_door_rotating", Vector(3417, 2219, 200), 64))
		Entities.FindByClassnameNearest("prop_door_rotating", Vector(3417, 2219, 200), 64).SetHealth(100000)
		Entities.FindByClassnameNearest("func_breakable", Vector(3648, 1834, 112), 64).SetHealth(100000)
	}
}