IncludeScript("response_testbed")

Map_ResponseRules <- []

Map_PlayerSpawns <- [
	PlayerSpawn(Vector(-5153, 8237, -191), QAngle(0, 55, 0)),
	PlayerSpawn(Vector(-7109, 8657, -191), QAngle(0, -5, 0)),
	PlayerSpawn(Vector(-6582, 10712, -48), QAngle(-5, 15, 0)),
	PlayerSpawn(Vector(-3529, 8938, -168), QAngle(5, 155, 0)),
	PlayerSpawn(Vector(-5481, 9352, 90), QAngle(5, 145, 0)),
	PlayerSpawn(Vector(-5425, 11943, -156), QAngle(-10, -70, 0)),
	PlayerSpawn(Vector(-4346, 10867, -153), QAngle(0, -130, 0)),
]

Map_ItemSpawns <- [
	DeathmatchItemSpawn("rifle", Vector(-6553.04, 9345.09, 119.32), QAngle(0, -114, 62)),
	DeathmatchItemSpawn("autoshotgun", Vector(-5361.26, 10347.5, 67.0313), QAngle(-54, -44, -59)),
	DeathmatchItemSpawn("grenade_launcher", Vector(-4730.26, 9575.39, -188.746), QAngle(-4, 2, -95)),
	DeathmatchItemSpawn("pistol", Vector(-4819.11, 9149.8, -151.719), QAngle(0, -34, -91)),
	DeathmatchItemSpawn("pipe_bomb", Vector(-4812.84, 9159.04, -147.719), QAngle(0, 0, 0)),
	DeathmatchItemSpawn("pain_pills", Vector(-4468.83, 9984.22, -128.646), QAngle(0, 0, 0)),
	DeathmatchItemSpawn("first_aid_kit", Vector(-5631.03, 9727.35, -157.969), QAngle(99, -2, 3)),
	DeathmatchItemSpawn("pistol_magnum", Vector(-4689.08, 10883.4, -134.45), QAngle(-5, 3, 102)),
	DeathmatchItemSpawn("sniper_scout", Vector(-5792.09, 11192.5, 175.632), QAngle(-89, -2, 0)),
	DeathmatchItemSpawn("gascan", Vector(-4256.31, 9307.5, -129.314), QAngle(0, -25, 0)),
	DeathmatchItemSpawn("rifle_m60", Vector(-4188.5, 9375.33, -126.319), QAngle(-75, 44, -18)),
	DeathmatchItemSpawn("molotov", Vector(-4962.39, 10276.4, -125.646), QAngle(-130, 3, 90)),
	DeathmatchItemSpawn("smg_silenced", Vector(-3942.54, 9970.95, -120.969), QAngle(6, 2, -81)),
	DeathmatchItemSpawn("rifle_desert", Vector(-7275.47, 9088.61, -184.969), QAngle(-76, -130, 34)),
	DeathmatchItemSpawn("smg", Vector(-6835.04, 10123.1, -190.969), QAngle(0, 0, -88)),
	DeathmatchItemSpawn("molotov", Vector(-6854.4, 8495.18, -186.469), QAngle(0, 0, 0)),
	DeathmatchItemSpawn("rifle_ak47", Vector(-5216.17, 8572.24, -147.969), QAngle(0, -54, -91)),
	DeathmatchItemSpawn("pistol", Vector(-4962.91, 10241, -127.146), QAngle(2, -2, -88)),
	DeathmatchItemSpawn("smg_mp5", Vector(-6816.24, 10462.3, -189.469), QAngle(-13, -114, 13)),
	DeathmatchItemSpawn("first_aid_kit", Vector(-5453.35, 11378.4, -72.0771), QAngle(60, 63, -70)),
	DeathmatchItemSpawn("pipe_bomb", Vector(-5343.85, 10470.4, 64.7154), QAngle(0, 0, 0)),
	DeathmatchItemSpawn("pistol_magnum", Vector(-3592.55, 9097.47, -145.128), QAngle(-19, -9, -103)),
	DeathmatchItemSpawn("rifle", Vector(-5268.15, 11601.7, -45.5503), QAngle(10, 19, 95)),
	DeathmatchItemSpawn("smg", Vector(-4487.74, 10695.7, -143.443), QAngle(-9, 0, 67)),
	DeathmatchItemSpawn("pumpshotgun", Vector(-5900.66, 9137.56, -114.374), QAngle(0, 11, 77)),
	DeathmatchItemSpawn("melee_katana", Vector(-5045.44, 9582.09, -327.156), QAngle(0, -76, -84)),
	DeathmatchItemSpawn("rifle_sg552", Vector(-3679.47, 9153.61, -158.958), QAngle(-1, 0, -89)),
	DeathmatchItemSpawn("pistol", Vector(-4700.32, 8539.24, -162.969), QAngle(0, 0, -83)),
	DeathmatchItemSpawn("pistol", Vector(-6384.4, 8833.37, -159.969), QAngle(2, 2, 92)),
]

Map_InitialPlayerSpawns <- [
	PlayerSpawn(Vector(-4476, 9164, -130), QAngle(0, 175, 0)),
	PlayerSpawn(Vector(-4469, 9218, -130), QAngle(0, 175, 0)),
	PlayerSpawn(Vector(-4459, 9272, -130), QAngle(0, 175, 0)),
	PlayerSpawn(Vector(-4449, 9325, -130), QAngle(0, 175, 0)),
]

function OnGameplayStart(){
	if(!g_ModeScript.ExecuteMapFileCode()){
		EntFire("airplane_door1", "Kill")
		EntFire("airplanemodel", "SetAnimation", "idle_open")
		EntFire("ribbon_fire_relay", "Trigger")
		EntFire("prop_hurt_triggers", "Enable")
		EntFire("radio_fake_button", "Kill")
		
		NetProps.SetPropInt(Entities.FindByClassnameNearest("prop_physics", Vector(-5540, 9453, -140), 256), "m_spawnflags", 8)
		
		local gnome = SpawnEntityFromTable("weapon_gnome", {spawnflags = 2, origin = Vector(-7480.74, 9148.8, 3558.03)})
		NetProps.SetPropFloat(gnome, "m_flModelScale", 10)
		NetProps.SetPropInt(gnome, "m_fFlags", 32)
		gnome.SetAngles(QAngle(-32, 179, -4))
		gnome.ValidateScriptScope()
		gnome.GetScriptScope()["no_cleanup"] <- true
	}
}