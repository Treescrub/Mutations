IncludeScript("response_testbed")

PrecacheEntityFromTable({classname = "prop_dynamic", model = "models/props_street/police_barricade.mdl"})

Map_ResponseRules <- [{
	name = "ConceptIntroC2M1",
	criteria = [["concept", "introC2M1"]],
	responses = [{scenename = ""}],
	group_params = RGroupParams({permitrepeats = true, sequential = false, norepeat = false})
}]

Map_PlayerSpawns <- [
	PlayerSpawn(Vector(7389, 8287, -625), QAngle(0, -55, 0)), 
	PlayerSpawn(Vector(6317, 8364, -692), QAngle(0, -20, 0)), 
	PlayerSpawn(Vector(6214, 6824, -690), QAngle(0, 55, 0)),
	PlayerSpawn(Vector(10858, 8503, -600), QAngle(0, -125, 0)),
	PlayerSpawn(Vector(8365, 7064, -564), QAngle(0, 130, 0)),
	PlayerSpawn(Vector(8064, 8311, -603), QAngle(0, -120, 0)),
	PlayerSpawn(Vector(7011, 7735, -648), QAngle(0, -10, 0)),
	PlayerSpawn(Vector(7346, 6841, -627), QAngle(0, 130, 0)),
]

Map_ItemSpawns <- [
	DeathmatchItemSpawn("rifle", Vector(10405.9, 7685, -518.978), QAngle(-50, 15, -45)),
	DeathmatchItemSpawn("first_aid_kit", Vector(10677.7, 7895.49, -538.761), QAngle(-267, -24, 0)),
	DeathmatchItemSpawn("pain_pills", Vector(10680.6, 7859.02, -541.169), QAngle(2, 0, 0)),
	DeathmatchItemSpawn("gascan", Vector(6841.83, 7522.23, -670.051), QAngle(-2, 115, -4)),
	DeathmatchItemSpawn("autoshotgun", Vector(6854.33, 7484.1, -683.395), QAngle(3, -50, 86)),
	DeathmatchItemSpawn("shotgun_chrome", Vector(7831.16, 7307.66, -598.867), QAngle(4, 21, 70)),
	DeathmatchItemSpawn("propanetank", Vector(7768.33, 7305.55, -592.067), QAngle(0, 0, -23)),
	DeathmatchItemSpawn("pistol", Vector(7327.47, 7025.77, -587.708), QAngle(-3, 69, -88)),
	DeathmatchItemSpawn("pistol_magnum", Vector(7348.97, 7069.52, -586.68), QAngle(0, 119, -89)),
	DeathmatchItemSpawn("smg_mp5", Vector(7100.25, 8023.36, -610.987), QAngle(-5, 0, 92)),
	DeathmatchItemSpawn("adrenaline", Vector(6348.42, 8268.22, -652.568), QAngle(-4, 17, -1)),
	DeathmatchItemSpawn("first_aid_kit", Vector(6324.75, 8261.48, -652.514), QAngle(84, -3, 5)),
	DeathmatchItemSpawn("rifle_ak47", Vector(8555.79, 7997.29, -510.601), QAngle(-54, -4, -83)),
	DeathmatchItemSpawn("hunting_rifle", Vector(8281.47, 7072.41, -569.568), QAngle(-2, 61, -92)),
	DeathmatchItemSpawn("smg", Vector(6204.16, 7049.16, -651.674), QAngle(-7, 29, -94)),
	DeathmatchItemSpawn("pumpshotgun", Vector(6183.95, 7032.64, -656.158), QAngle(-13, -2, 88)),
	DeathmatchItemSpawn("pistol", Vector(8296.79, 7087.32, -568.698), QAngle(-5, 0, -91)),
	DeathmatchItemSpawn("smg_silenced", Vector(6886.66, 7017.7, -594.644), QAngle(-1, -38, -88)),
	DeathmatchItemSpawn("rifle_sg552", Vector(9913.4, 8016.3, -506.757), QAngle(-78, -202, -95)),
	DeathmatchItemSpawn("molotov", Vector(7530.67, 7844.34, -568.551), QAngle(1, 98, 0)),
	DeathmatchItemSpawn("pipe_bomb", Vector(8391.72, 7468.83, -590.069), QAngle(77, 29, 0)),
	//DeathmatchItemSpawn("melee_katana", Vector(10352, 7769, -515), QAngle(0, 0, 0)),
]

Map_InitialPlayerSpawns <- [PlayerSpawn(Vector(10728, 7836, -525), QAngle(0, 139.5, 0)), PlayerSpawn(Vector(10756, 7848, -527), QAngle(0, 160.5, 0)), PlayerSpawn(Vector(10756, 7892, -528), QAngle(0, 191.5, 0)), PlayerSpawn(Vector(10716, 7908, -526), QAngle(0, 159.5, 0))]

/*EntFire("weapon_adrenaline_spawn","Kill")
EntFire("weapon_ammo_spawn","Kill")
EntFire("weapon_autoshotgun_spawn","Kill")
EntFire("weapon_defibrillator_spawn","Kill")
EntFire("weapon_first_aid_kit_spawn","Kill")
EntFire("weapon_gascan_spawn","Kill")
EntFire("weapon_grenade_launcher_spawn","Kill")
EntFire("weapon_item_spawn","Kill")
EntFire("weapon_molotov_spawn","Kill")
EntFire("weapon_pain_pills_spawn","Kill")
EntFire("weapon_pipe_bomb_spawn","Kill")
EntFire("weapon_spawn","Kill")
EntFire("weapon_sniper_military_spawn","Kill")
EntFire("upgrade_laser_sight","Kill")
EntFire("weapon_melee_spawn","Kill")*/

function OnGameplayStart(){
	if(!g_ModeScript.ExecuteMapFileCode()){
		SpawnEntityFromTable("prop_dynamic", {model = "models/props_fortifications/barricade001_128_reference.mdl", origin = Vector(6042, 7307, -742), angles = "6.785100 28.466400 -10.531400", solid = 6})
		SpawnEntityFromTable("prop_dynamic", {model = "models/props_fortifications/barricade001_128_reference.mdl", origin = Vector(6090, 7210, -713), angles = "4.587390 20.296700 -17.424400", solid = 6})
		SpawnEntityFromTable("prop_dynamic", {model = "models/props_fortifications/barricade001_128_reference.mdl", origin = Vector(6122, 7115, -694), angles = "-1.000000 14.000000 -1.000000", solid = 6})
		SpawnEntityFromTable("prop_dynamic", {model = "models/props_fortifications/barricade001_128_reference.mdl", origin = Vector(6148, 7019, -693), angles = "-2.000000 13.000000 0.000000", solid = 6})
		SpawnEntityFromTable("prop_dynamic", {model = "models/props_fortifications/barricade001_128_reference.mdl", origin = Vector(6160, 6912.5, -693), angles = "-1.500000 0.000000 0.000000", solid = 6})
		SpawnEntityFromTable("prop_dynamic", {model = "models/props_street/police_barricade.mdl", origin = Vector(6157, 6836, -693), angles = "-1.500000 0.000000 0.000000", solid = 6})

		SpawnEntityFromTable("prop_dynamic", {model = "models/props_fortifications/barricade001_128_reference.mdl", origin = Vector(6194, 7859, -692), angles = "-1.989040 353.996002 0.209141", solid = 6})
		SpawnEntityFromTable("prop_dynamic", {model = "models/props_fortifications/barricade001_128_reference.mdl", origin = Vector(6194, 7961, -692), angles = "0.000000 2.000000 -1.000000", solid = 6})
		SpawnEntityFromTable("prop_dynamic", {model = "models/props_fortifications/barricade001_128_reference.mdl", origin = Vector(6196, 8064, -700), angles = "-4.000000 -6.000000 0.000000", solid = 6})
		SpawnEntityFromTable("prop_dynamic", {model = "models/props_fortifications/barricade001_128_reference.mdl", origin = Vector(6211, 8169, -700), angles = "-2.931160 353.975006 0.811702", solid = 6})
		SpawnEntityFromTable("prop_dynamic", {model = "models/props_fortifications/barricade001_128_reference.mdl", origin = Vector(6237, 8375, -698), angles = "-3.423520 349.970001 0.898896", solid = 6})
		SpawnEntityFromTable("prop_dynamic", {model = "models/props_fortifications/barricade001_128_reference.mdl", origin = Vector(6255, 8479, -697), angles = "-3.423520 349.970001 0.898896", solid = 6})
		SpawnEntityFromTable("prop_dynamic", {model = "models/props_fortifications/barricade001_128_reference.mdl", origin = Vector(6272, 8565, -727), angles = "-4.619340 352.738007 -26.294300", solid = 6})
		
		SpawnEntityFromTable("env_player_blocker", {initialstate = 1, mins = Vector(-8, -35, -65), maxs = Vector(8, 35, 65), origin = Vector(6242.94, 8555.29, -646.66)})
	}
}