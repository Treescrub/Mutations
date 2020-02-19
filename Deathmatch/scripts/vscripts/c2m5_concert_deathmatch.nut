IncludeScript("response_testbed")


Map_ResponseRules <- [{
name = "Conceptc2m5InArena",
criteria = [["concept", "c2m5InArena"]],
responses = [{scenename = ""}],
group_params = RGroupParams({permitrepeats = true, sequential = false, norepeat = false})
}]

Map_PlayerSpawns <- [PlayerSpawn(Vector(-4022,3174,126), QAngle(0,-60,0)), PlayerSpawn(Vector(-3204,2012,126), QAngle(0,65,0)), PlayerSpawn(Vector(-2591,1778,126), QAngle(0,125,0)), PlayerSpawn(Vector(-2020,1771,126), QAngle(0,50,0)), PlayerSpawn(Vector(-1407,2023,126), QAngle(0,125,0)), PlayerSpawn(Vector(-765,2360,126), QAngle(0,125,0)), PlayerSpawn(Vector(-1214,3592,-258), QAngle(0,90,0)), PlayerSpawn(Vector(-1745,3681,-258), QAngle(0,-60,0)), PlayerSpawn(Vector(-2854,3683,-258), QAngle(0,-120,0)), PlayerSpawn(Vector(-2314,2521,-258), QAngle(0,90,0))]

Map_ItemSpawns <- [DeathmatchItemSpawn("rifle", Vector(-2745.97, 3477.17, -169.969), QAngle(0, 0, 0)),
	DeathmatchItemSpawn("rifle_ak47", Vector(-2742.23, 3444.25, -167.969), QAngle(0, 0, 0)),
	DeathmatchItemSpawn("rifle_desert", Vector(-2744.84, 3412.96, -169.969), QAngle(0, 0, 0)),
	DeathmatchItemSpawn("rifle_m60", Vector(-2742.32, 3384.73, -170.969), QAngle(0, 0, 0)),
	DeathmatchItemSpawn("rifle_sg552", Vector(-2744.91, 3355.25, -170.969), QAngle(0, 0, 0)),
	DeathmatchItemSpawn("smg", Vector(-2672.56, 3478.63, -168.969), QAngle(0, 0, 0)),
	DeathmatchItemSpawn("smg_silenced", Vector(-2674.8, 3444.22, -169.969), QAngle(0, 0, 0)),
	DeathmatchItemSpawn("smg_mp5", Vector(-2677.14, 3411.4, -169.969), QAngle(0, 0, 0)),
	DeathmatchItemSpawn("sniper_awp", Vector(-2618.57, 3476.48, -168.969), QAngle(0, 0, 0)),
	DeathmatchItemSpawn("sniper_military", Vector(-2614.92, 3442.78, -170.969), QAngle(0, 0, 0)),
	DeathmatchItemSpawn("sniper_scout", Vector(-2620.47, 3410.95, -168.969), QAngle(0, 0, 0)),
	DeathmatchItemSpawn("hunting_rifle", Vector(-2619.51, 3384.81, -170.969), QAngle(0, 0, 0)),
	DeathmatchItemSpawn("autoshotgun", Vector(-2535.72, 3412.19, -171.969), QAngle(0, 0, 0)),
	DeathmatchItemSpawn("shotgun_spas", Vector(-2540.42, 3384.99, -170.969), QAngle(0, 0, 0)),
	DeathmatchItemSpawn("shotgun_chrome", Vector(-2534.13, 3357.3, -170.969), QAngle(0, 0, 0)),
	DeathmatchItemSpawn("pumpshotgun", Vector(-2534.32, 3327.32, -169.969), QAngle(0, 0, 0)),
	DeathmatchItemSpawn("pistol", Vector(-2472.03, 3412.41, -168.969), QAngle(0, 0, 0)),
	DeathmatchItemSpawn("pistol_magnum", Vector(-2470.83, 3383.98, -171.969), QAngle(0, 0, 0)),
	DeathmatchItemSpawn("grenade_launcher", Vector(-2410.78, 3412.24, -171.969), QAngle(0, 0, 0)),
	DeathmatchItemSpawn("chainsaw", Vector(-2406.48, 3382.01, -169.969), QAngle(0, 0, 0)),
	DeathmatchItemSpawn("first_aid_kit", Vector(-2132.88, 3587.29, -175.969), QAngle(0, 0, 0)),
	DeathmatchItemSpawn("adrenaline", Vector(-2102.67, 3585.57, -175.969), QAngle(0, 0, 0)),
	DeathmatchItemSpawn("pain_pills", Vector(-2075.17, 3586.77, -175.969), QAngle(0, 0, 0)),
	DeathmatchItemSpawn("molotov", Vector(-2133.26, 3521.12, -171.969), QAngle(0, 0, 0)),
	DeathmatchItemSpawn("pipe_bomb", Vector(-2105.08, 3520.3, -171.969), QAngle(0, 0, 0)),
	DeathmatchItemSpawn("rifle_m60", Vector(-2292.76, 3166.53, -164.969), QAngle(-59, 0, 0))
]

Map_InitialPlayerSpawns <- [PlayerSpawn(Vector(-3337,2951,-255), QAngle(0,0,0)), PlayerSpawn(Vector(-3435,2946,-255), QAngle(0,0,0)), PlayerSpawn(Vector(-3396,3012,-255), QAngle(0,0,0)), PlayerSpawn(Vector(-3396,3012,-255), QAngle(0,0,0))]
	
	
EntFire("relay_survival","Trigger")
	
EntFire("stadium_lights_survival_relay","Trigger")
	
EntFire("stage_backlight_dimmed","TurnOn")

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

EntFire("stadium_entrance_door_template","ForceSpawn")
EntFire("stadium_entrance_door_navblocker","BlockNav")
EntFire("stadium_entrance_door_brush","Enable")
EntFire("stadium_entrance_door_portal","Close")
EntFire("stadium_entrance_doorprop_before","Kill")
EntFire("stadium_entrance_doorprop_after","Enable")
EntFire("stadium_entrance_doorprop_after","EnableCollision")

function OnGameplayStart(){
	if(!g_ModeScript.ExecuteMapFileCode()){
		
	}
}