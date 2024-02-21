void MakeDustParticle(Vec2f pos, string file, f32 deg = 0)
{
	CParticle@ temp = ParticleAnimated(CFileMatcher(file).getFirst(), pos - Vec2f(0, 8), Vec2f(0, 0), deg, 1.0f, 3, 0.0f, false);

	if (temp !is null)
	{
		temp.width = 8;
		temp.height = 8;
	}
}