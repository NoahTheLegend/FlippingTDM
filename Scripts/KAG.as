#include "Default/DefaultGUI.as"
#include "Default/DefaultLoaders.as"
#include "PrecacheTextures.as"
#include "EmotesCommon.as"
#include "Hitters.as"

//todo: multiplayer test, maps

void onInit(CRules@ this)
{
	LoadDefaultMapLoaders();
	LoadDefaultGUI();
	getNet().legacy_cmd = true;

	if (isServer())
	{
		getSecurity().reloadSecurity();
	}

	sv_gravity = init_grav;
	particles_gravity.y = 0.25f;
	sv_visiblity_scale = 1.25f;
	cc_halign = 2;
	cc_valign = 2;

	s_effects = false;

	sv_max_localplayers = 1;

	PrecacheTextures();

	//smooth shader
	Driver@ driver = getDriver();

	driver.AddShader("hq2x", 1.0f);
	driver.SetShader("hq2x", true);

	//reset var if you came from another gamemode that edits it
	SetGridMenusSize(24,2.0f,32);

	//also restart stuff
	onRestart(this);
}

bool need_sky_check = true;
void onRestart(CRules@ this)
{
	//map borders
	CMap@ map = getMap();
	if (map !is null)
	{
		map.SetBorderFadeWidth(24.0f);
		map.SetBorderColourTop(SColor(0xff000000));
		map.SetBorderColourLeft(SColor(0xff000000));
		map.SetBorderColourRight(SColor(0xff000000));
		map.SetBorderColourBottom(SColor(0xff000000));

		//do it first tick so the map is definitely there
		//(it is on server, but not on client unfortunately)
		need_sky_check = true;
	}

	this.set_f32("global_rotation", 0);
	Flip(this, false, 10*30 + XORRandom(11)*30);
}

void Flip(CRules@ this, bool flip, u32 time = (grav_flip_period+XORRandom(time_extra_rnd+1))*30)
{
	this.set_u32("flip_time", getGameTime() + time);
	this.set_bool("flipped", flip);
	this.set_f32("grav", 1.0f);

	CMap@ map = getMap();
	if (map is null) return;

	string prefix = (flip?"flipped_":"");
	map.CreateSky(color_black, Vec2f(1.0f, 1.0f), 200, "Sprites/Back/cloud", 0);
	map.CreateSkyGradient("skygradient.png");

	map.AddBackground(prefix+"BackgroundPlains.png", Vec2f(0.0f, flip ? -340.0f : -40.0f), Vec2f(0.06f, 20.0f), color_white);
	map.AddBackground(prefix+"BackgroundTrees.png",  Vec2f(0.0f, flip ? -420.0f : -100.0f), Vec2f(0.18f, 70.0f), color_white);
	map.AddBackground(prefix+"BackgroundIsland.png", Vec2f(0.0f, flip ? -420.0f : -220.0f), Vec2f(0.3f, 180.0f), color_white);

	if (isServer())
	{
		CBlob@[] df;
		map.getBlobsInBox(Vec2f(0, 0), Vec2f(map.tilemapwidth * 8, map.tilemapheight * 8), @df);

		for (int i = 0; i < df.size(); i++)
		{
			if (df[i] is null || df[i].getMass() < 1.0f) continue;
			df[i].AddForce(Vec2f(0, -0.00001f));
		}
	}
}

const f32 init_grav = 9.81f;
const f32 grav_flip_period = 3; // seconds
const f32 grav_flip_rate = 30; // ticks
const f32 time_extra_rnd = 27;
const u8 warn_time = 10;

Vec2f msg_pos_init = Vec2f(getDriver().getScreenWidth()/2, 110);
Vec2f msg_pos_warn = msg_pos_init + Vec2f(0, 90);
Vec2f msg_pos_old = msg_pos_init;

void onRender(CRules@ this)
{
	bool is_flipped = this.get_bool("flipped");

	f32 cam_rot = this.get_f32("global_rotation");
	f32 f = Maths::Clamp(Maths::Lerp(cam_rot, is_flipped ? 181.0f : -1, 0.2f), 0, 180);

	if (isClient() && isServer())
	{
		if (getControls().isKeyJustPressed(KEY_LCONTROL))
			Flip(this, !is_flipped, 9999999999999);
	}

	if (isClient())
	{
		CCamera@ cam = getCamera();
		//cam.setRotation(getLocalPlayerBlob() is null ? 0 : is_flipped ? f : -f);
		cam.setRotation(is_flipped ? f : -f);
	}
	this.set_f32("global_rotation", f);

	if (!isClient()) return;
	f32 gt = getGameTime();
	f32 endtime = this.get_u32("flip_time");
	int diff = (endtime-gt);
	u8 s = Maths::Clamp(Maths::Ceil(diff/30), 0, 255);
	bool warn = s <= warn_time;
	SColor col = SColor(255,255,255,255);

	Vec2f msg_pos = msg_pos_old;
	if (warn)
	{
		if (getLocalPlayerBlob() !is null)
		{
			if (diff % 30 == 0)
			{
				if (!this.hasTag("flip_soundplay"))
				{
					this.Tag("flip_soundplay");
					Sound::Play("select.ogg", getLocalPlayerBlob().getPosition(), 1.0f, 1.25f);
				}
			}
			else
			{
				this.Untag("flip_soundplay");
			}
		}

		msg_pos = Vec2f_lerp(msg_pos_old, msg_pos_warn, 0.5f);
		col = SColor(255,200,33,25);
	}
	else
	{
		msg_pos = Vec2f_lerp(msg_pos_old, msg_pos_init, 0.5f);
	}
	msg_pos_old = msg_pos;

	GUI::SetFont("menu");
	GUI::DrawTextCentered("Flip in "+s+"s", msg_pos, col);
}

void onTick(CRules@ this)
{
	f32 gt = getGameTime();
	f32 grav = this.get_f32("grav");

	bool is_flipped = this.get_bool("flipped");
	f32 flip_time = this.get_u32("flip_time");

	f32 start = flip_time - grav_flip_rate;
	f32 end = Maths::Clamp(start-gt, 0, grav_flip_rate);

	//printf("gt: "+gt+" st: "+start+" ft: "+flip_time+" e: "+end+" f: "+is_flipped);
	
	if (gt >= flip_time)
	{
		Flip(this, !is_flipped);
	}
	//if(getControls().isKeyJustPressed(KEY_LCONTROL))
	//{
	//	Flip(this, !is_flipped);
	//}

	grav = Maths::Lerp(grav, is_flipped ? -1.0f : 1.0f, 0.15f);

	//printf("grav: "+grav);
	
	this.set_f32("grav", grav);
	sv_gravity = init_grav * grav;

	this.Sync("grav", true);
	this.Sync("flipped", true);
	this.Sync("flip_time", true);

	CMap@ map = getMap();
	if (map is null) return;

	//TODO: figure out a way to optimise so we don't need to keep running this hook
	if (need_sky_check)
	{
		need_sky_check = false;

		//find out if there's any solid tiles in top row
		// if not - semitransparent sky
		// if yes - totally solid, looks buggy with "floating" tiles
		bool has_solid_tiles = false;
		for(int i = 0; i < map.tilemapwidth; i++) {
			if(map.isTileSolid(map.getTile(i))) {
				has_solid_tiles = true;
				break;
			}
		}
		map.SetBorderColourTop(SColor(has_solid_tiles ? 0xff000000 : 0x80000000));
	}

	// kill blobs above map ceiling if we're flipped

	if (isServer() && is_flipped)
	{
		CBlob@[] d;
		map.getBlobsInBox(Vec2f(-16, -512), Vec2f(map.tilemapwidth * 8 + 16, 0.0f), @d);
		for (u16 i = 0; i < d.size(); i++)
		{
			if (d[i] is null) continue;
			if (d[i].getPlayer() !is null && d[i].getPosition().y > -16.0f) continue;
			d[i].server_Hit(d[i], d[i].getPosition(), Vec2f_zero, 10.0f, Hitters::fall);
			if (d[i].hasTag("invincible")) d[i].server_SetHealth(0);
		}
	}
}

void onBlobCreated(CRules@ this, CBlob@ blob)
{
	if (blob !is null)
	{
		blob.SetMapEdgeFlags(blob.getMapEdgeFlags() & ~CBlob::map_collide_up);
	}
}

//chat stuff!

void onEnterChat(CRules @this)
{
	if (getChatChannel() != 0) return; //no dots for team chat

	CBlob@ localblob = getLocalPlayerBlob();
	if (localblob !is null)
		set_emote(localblob, "dots", 100000);
}

void onExitChat(CRules @this)
{
	CBlob@ localblob = getLocalPlayerBlob();
	if (localblob !is null)
		set_emote(localblob, "", 0);
}
