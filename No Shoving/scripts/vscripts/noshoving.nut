HookController <- {}
IncludeScript("HookController", HookController)
HookController.RegisterOnTick(this)
HookController.IncludeImprovedMethods()

function OnTick(){
	foreach(ent in HookController.PlayerGenerator()){
		if(ent.IsSurvivor()){
			if(ent.GetActiveWeapon() != null && ent.GetActiveWeapon().IsValid()){
				if(ent.GetActiveWeapon().GetClip() > 0){
					ent.RemoveForcedButton(HookController.Keys.RELOAD)
					ent.GetActiveWeapon().SetProp("m_flNextSecondaryAttack", 999999999)
				} else {
					ent.AddForcedButton(HookController.Keys.RELOAD)
				}
			}
		}
	}
}