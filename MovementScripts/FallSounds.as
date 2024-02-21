#define CLIENT_ONLY

void Sound(CBlob@ this, Vec2f normal)
{
	const f32 vellen = this.getShape().vellen;

	if (vellen > 4.5f)
	{
		if (Maths::Abs(normal.x) > 0.5f)
		{
			this.getSprite().PlayRandomSound("FallWall");
		}
		else
		{
			this.getSprite().PlayRandomSound("FallMedium");
		}

        bool is_flipped = getRules().get_bool("flipped");
        f32 ff = is_flipped ? -1 : 1;

		if (vellen > 6.0f)
		{
			MakeDustParticle(this.getPosition() + Vec2f(0.0f, is_flipped ? 11.0f : 6.0f), "/dust.png", is_flipped ? 180 : 0);
		}
		else
		{
			MakeDustParticle(this.getPosition() + Vec2f(0.0f, is_flipped ? 6.0f : 11.0f), "/DustSmall.png", is_flipped ? 180 : 0);
		}
	}
	else if (vellen > 2.75f)
	{
		this.getSprite().PlayRandomSound("FallSmall");
	}
}

void MakeDustParticle(Vec2f pos, string file, f32 deg = 0)
{
	CParticle@ temp = ParticleAnimated(file, pos - Vec2f(0, 8), Vec2f(0, 0), deg, 1.0f, 3, 0.0f, false);

	if (temp !is null)
	{
		temp.width = 8;
		temp.height = 8;
	}
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal)
{
	if (solid && this.getOldVelocity() * normal < 0.0f)   // only if approaching
	{
		Sound(this, normal);
	}
}
