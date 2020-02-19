IncludeScript("response_testbed")

Map_ResponseRules <- [{
	name = "ConceptIntroC4M1",
	criteria = [["concept", "introC4M1"]],
	responses = [{scenename = ""}],
	group_params = RGroupParams({permitrepeats = true, sequential = false, norepeat = false})
},
{
	name = "IsSaidc4m1_nogas",
	criteria = [["concept", "worldSaidc4m1_nogas"]],
	responses = [{scenename = ""}],
	group_params = RGroupParams({permitrepeats = true, sequential = false, norepeat = false})
}]

Map_PlayerSpawns <- [
	PlayerSpawn(Vector(-7013, 7848, 104), QAngle(0, -16, 0)),
	PlayerSpawn(Vector(-4048, 6767, 105), QAngle(0, 60, 0)),
	PlayerSpawn(Vector(-4574, 8134, 96), QAngle(0, -155, 0)),
	PlayerSpawn(Vector(-6195, 7747, 104), QAngle(0, -45, 0)),
	PlayerSpawn(Vector(-6317, 6812, 96), QAngle(0, 45, 0)),
	PlayerSpawn(Vector(-6376, 8040, 95), QAngle(0, -135, 0)),
	PlayerSpawn(Vector(-5688, 6548, 96), QAngle(0, 75, 0)),
]

Map_ItemSpawns <- [
	DeathmatchItemSpawn("smg", Vector(-6145.44, 7428.61, 407.214), QAngle(0, -46, -91)),
	DeathmatchItemSpawn("pistol", Vector(-5832.08, 7493.28, 360.531), QAngle(0, -12, -89)),
	DeathmatchItemSpawn("sniper_awp", Vector(-5881.36, 7418.99, 915.403), QAngle(-17, -28, -87)),
	DeathmatchItemSpawn("molotov", Vector(-7174.64, 7763.53, 118.924), QAngle(0, 0, 0)),
	DeathmatchItemSpawn("pain_pills", Vector(-6080.1, 7149.42, 140.031), QAngle(0, 0, 0)),
	DeathmatchItemSpawn("rifle_desert", Vector(-4905.5, 7675.3, 138.508), QAngle(-53, -167, -81)),
	DeathmatchItemSpawn("shotgun_chrome", Vector(-4165.32, 7071.52, 140.531), QAngle(-2, 0, -84)),
	DeathmatchItemSpawn("rifle", Vector(-5826.76, 7560.1, 139.547), QAngle(-1, 0, 90)),
	DeathmatchItemSpawn("pipe_bomb", Vector(-5803.53, 6617.53, 131.347), QAngle(0, 0, 0)),
	DeathmatchItemSpawn("smg_silenced", Vector(-5223.7, 7229.14, 142.766), QAngle(0, 0, -86)),
	DeathmatchItemSpawn("hunting_rifle", Vector(-5413.48, 6782.4, 109.516), QAngle(-101, -3, 0)),
	DeathmatchItemSpawn("pistol_magnum", Vector(-5469.32, 7406.84, 143.117), QAngle(-6, 0, -88)),
	DeathmatchItemSpawn("shotgun_spas", Vector(-3414.07, 7038.4, 129.031), QAngle(0, -43, 90)),
	DeathmatchItemSpawn("grenade_launcher", Vector(-4615.1, 7131.75, 257.78), QAngle(-1, 0, -91)),
	DeathmatchItemSpawn("gnome", Vector(-6331.36, 8648.53, 106.531), QAngle(0, -125, 0)),
	DeathmatchItemSpawn("first_aid_kit", Vector(-6100.57, 7677.59, 142.273), QAngle(88, 0, 0)),
	DeathmatchItemSpawn("adrenaline", Vector(-4725.64, 8073.97, 140.67), QAngle(-2, -60, -8)),
	DeathmatchItemSpawn("sniper_military", Vector(-6660.86, 8326.02, 107.107), QAngle(-71, -2, -65)),
	DeathmatchItemSpawn("pain_pills", Vector(-6657.85, 8308.67, 95.693), QAngle(0, 0, 0)),
	DeathmatchItemSpawn("pumpshotgun", Vector(-6585.72, 7603.52, 151.741), QAngle(-5, 0, 89)),
	DeathmatchItemSpawn("first_aid_kit", Vector(-4429.98, 7548.07, 146.759), QAngle(87, 11, 0)),
	DeathmatchItemSpawn("molotov", Vector(-4744.46, 7469.61, 146.393), QAngle(0, 0, 0)),
	DeathmatchItemSpawn("pistol", Vector(-5888.5, 7342.37, 140.731), QAngle(0, -21, -88)),
	DeathmatchItemSpawn("pistol", Vector(-5883, 7356.37, 140.758), QAngle(0, 37, 89)),
]

Map_InitialPlayerSpawns <- [
	PlayerSpawn(Vector(-7014, 7849, 104), QAngle(0, 344, 0)),
	PlayerSpawn(Vector(-6966, 7870, 104), QAngle(0, 323, 0)),
	PlayerSpawn(Vector(-6991, 7805, 104), QAngle(0, 15, 0)),
	PlayerSpawn(Vector(-6950, 7791, 108), QAngle(0, 19, 0)),
]

function OnGameplayStart(){
	if(!g_ModeScript.ExecuteMapFileCode()){
		SpawnEntityFromTable("env_player_blocker", {initialstate = 1, mins = Vector(-16, -19, -62), maxs = Vector(16, 19, 62), origin = Vector(-3635.61, 7635.14, 164.049)})
	}
}