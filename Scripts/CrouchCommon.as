//used to determine if a player is crouching or not
//(not safe to use before their logic script has been run during ontick)
bool isCrouching(CBlob@ this)
{
    bool is_flipped = getRules().get_bool("flipped");
	bool has_ground = is_flipped ? this.isOnCeiling() : this.isOnGround();

	return
		//must be on ground and pressing down
		has_ground
		&& this.isKeyPressed(key_down)
		//cannot have movement intent
		&& !this.isKeyPressed(key_left)
		&& !this.isKeyPressed(key_right)
		//cannot have banned crouch (done in actor logic scripts)
		&& !this.hasTag("prevent crouch");
}

bool hasJustCrouched(CBlob@ this)
{
	return isCrouching(this) && this.isKeyJustPressed(key_down);
}
