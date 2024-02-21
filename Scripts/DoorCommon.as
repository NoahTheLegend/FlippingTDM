//common functionality for door-like objects

bool canOpenDoor(CBlob@ this, CBlob@ blob)
{
	if ((blob.getShape().getConsts().collidable) && //solid              // vvv lets see
	        (blob.getRadius() > 5.0f) && //large
	        (this.getTeamNum() == 255 || this.getTeamNum() == blob.getTeamNum()) &&
	        (blob.hasTag("player") || blob.hasTag("vehicle") || blob.hasTag("migrant"))) //tags that can open doors
	{
		Vec2f doorpos = this.getPosition();
		Vec2f blobpos = blob.getPosition();
	
		if (blob.hasTag("vehicle"))
		{
			if (doorpos.y > blobpos.y + blob.getHeight()/2 + 2) return false;
			
			AttachmentPoint@[] aps;
			if (blob.getAttachmentPoints(@aps))
			{
				for (u8 i = 0; i < aps.length; i++)
				{
					AttachmentPoint@ ap = aps[i];
					if (ap.name != "ROWER" && ap.name != "DRIVER" && ap.name != "SAIL") continue;
					if (ap.getOccupied() is null) continue;
					
					if (ap.isKeyPressed(key_left)) return true;
					if (ap.isKeyPressed(key_right)) return true;
				}
			}
			
			return false;
		}
		
		bool left  = blob.isKeyPressed(key_left);
		bool right = blob.isKeyPressed(key_right);
		bool up    = blob.isKeyPressed(key_up);
		bool down  = blob.isKeyPressed(key_down);

		bool is_flipped = getRules().get_bool("flipped");
		if (is_flipped)
		{
			bool temp = left;
			left = right;
			right = temp;

			bool temp1 = up;
			up = down;
			down = temp1;
		} 

		if (left &&  blobpos.x > doorpos.x && Maths::Abs(blobpos.y - doorpos.y) < 11) return true;
		if (right && blobpos.x < doorpos.x && Maths::Abs(blobpos.y - doorpos.y) < 11) return true;
		if (up &&    blobpos.y > doorpos.y && Maths::Abs(blobpos.x - doorpos.x) < 11) return true;
		if (down &&  blobpos.y  < doorpos.y && Maths::Abs(blobpos.x - doorpos.x) < 11) return true;
	}
	
	return false;
}

bool isOpen(CBlob@ this) // used by SwingDoor, Bridge, TrapBlock
{
	return !this.getShape().getConsts().collidable;
}