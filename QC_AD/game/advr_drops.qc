// Enemy loot uses the same record/prop path as weapons released by a player.
// Kinds keep native AD bits for inventory compatibility, but never change the
// player's upgrade flags. Zero is the original AD pickup behaviour.
string(entity r) ADVR_RecordModel = {
    if(!r)return "";
    if(r.advr_kind==ADVR_SWORD)return "progs/v_ksword.mdl";
    if(r.advr_kind==ADVR_HELLSWORD)return "progs/v_hksword.mdl";
    if(r.advr_kind==ADVR_SAW)return "progs/v_chainsaw.mdl";
    if(r.advr_kind==ADVR_PLASMA)return "progs/advr_plasma.mdl";
    if(r.advr_weapon==IT_LIGHTNING)return MODEL_VWEAP_LG;
    if(r.advr_kind==ADVR_SHADOWAXE)return "progs/advr_shadowaxe.mdl";
    if(r.advr_weapon==IT_AXE && !r.advr_kind && !(self.moditems & IT_UPGRADE_GHOOK))return "progs/v_axe.mdl";
    if(r.advr_kind==ADVR_AXE)return "progs/v_axe.mdl";
    if(r.advr_kind==ADVR_WIDOWMAKER)return "progs/advr_widowmaker.mdl";
    if(r.advr_weapon==IT_SUPER_SHOTGUN)return MODEL_VWEAP_SSG;
    return ADVR_Model(r.advr_weapon,0);
};
float(entity r) ADVR_RecordCapacity = {
    if(!r)return 0;
    if(r.advr_kind==ADVR_SAW)return 100;
    if(r.advr_kind==ADVR_PLASMA || r.advr_kind==ADVR_WIDOWMAKER)return 24;
    if(r.advr_weapon==IT_SUPER_SHOTGUN)return 2;
    return ADVR_Capacity(r.advr_weapon);
};
float(entity r) ADVR_PackRecord = {return r.advr_weapon+r.advr_kind*65536;};
vector(float h) ADVR_WeaponTip = {
    local vector at,tip;local float reach;local entity r;
    at=ADVR_Pos(h);r=ADVR_Hand(h);
    if(h)tip=self.muzzlepos;else tip=self.offmuzzlepos;
    if(vlen(tip-at)>=8 && vlen(tip-at)<128)return tip;
    reach=28;if(r.advr_kind==ADVR_SWORD)reach=36;
    if(r.advr_kind==ADVR_HELLSWORD)reach=42;
    makevectors(ADVR_Angles(h));return at+v_forward*reach;
};

// Return an encoded record type. The two random inputs make the loot table
// deterministic in tests without changing the gameplay random number stream.
float(entity foe,float roll,float choice) ADVR_LootType = {
    local float c,chance,w,kind;
    c=foe.classtype;chance=0.5;
    if(c==CT_MONARMY){w=IT_SHOTGUN;chance=1;}
    else if(c==CT_MONKNIGHT || c==CT_MONDGUARD || c==CT_MONDFURY || c==CT_MONZOMBIEK || c==CT_MONINVSWORD){w=IT_AXE;kind=ADVR_SWORD;chance=1;}
    else if(c==CT_MONHELLK || c==CT_MONDBLOOD || c==CT_MONDKNIGHT || c==CT_MONDPRINCE ||
        c==CT_MONDSERG || c==CT_MONCOMM || c==CT_MONDGUARDQ || c==CT_MONDLORD || c==CT_MONJUSTICE || c==CT_MONJUDGE){w=IT_AXE;kind=ADVR_HELLSWORD;chance=1;}
    else if(c==CT_MONOGRE || c==CT_MONHOGRE){
        if(choice<0.5){w=IT_AXE;kind=ADVR_SAW;}else w=IT_GRENADE_LAUNCHER;
    }
    else if(c==CT_MONHOGREHAM){w=IT_AXE;kind=ADVR_AXE;}
    else if(c==CT_MONHOGREMAC){w=IT_GRENADE_LAUNCHER;}
    else if(c==CT_MONARMYPLASMA || c==CT_MONENFORCER || c==CT_MONELIMATOR || c==CT_MONDEFLECTOR || c==CT_MONCENTURION){w=IT_LIGHTNING;kind=ADVR_PLASMA;}
    else if(c==CT_MONDEFENDER){
        if(choice<0.5){w=IT_SUPER_SHOTGUN;kind=ADVR_SSG;}else w=IT_GRENADE_LAUNCHER;
    }
    if(!w || roll>=bound(0,chance*cvar("vr_enemy_drops_chance_mult"),1))return 0;
    // Stone weapons crumble with their statues; point knights are map effects.
    if(foe.classgroup==CG_STONE || foe.spawnstatue)return 0;
    if(c==CT_MONHELLK && (foe.spawnflags & MON_POINT_KNIGHT))return 0;
    return w+kind*65536;
};

entity(entity foe,float packed) ADVR_SpawnLoot = {
    local entity r,p;local float kind,w,least;local vector at;
    if(!packed)return world;
    kind=floor(packed/65536);w=packed-kind*65536;
    r=ADVR_Record(w);r.advr_kind=kind;r.advr_clip_ready=1;
    // A small loaded magazine accompanies the gun; native AD backpacks remain.
    r.wi_clip=0;
    if(w==IT_SHOTGUN)r.wi_clip=4;
    if(w==IT_SUPER_SHOTGUN || w==IT_GRENADE_LAUNCHER)r.wi_clip=2;
    if(kind==ADVR_PLASMA)r.wi_clip=12;
    if(kind==ADVR_SAW){least=bound(0,cvar("vr_chainsaw_drop_fuel_min"),100);r.wi_clip=least+floor(random()*(101-least));}
    p=spawn();p.classname="advr_dropped_weapon";p.weaponinst=r;p.advr_weapon=w;
    p.owner=foe;p.advr_cooldown=time+1;p.vr_monster_drop=time;
    p.movetype=MOVETYPE_BOUNCE;p.solid=SOLID_BBOX;p.touch=ADVR_PropTouch;
    setmodel(p,ADVR_RecordModel(r));setsize(p,'-4 -4 -4','4 4 4');
    at=foe.origin+'0 0 12';setorigin(p,at);p.angles=foe.angles;
    p.velocity='0 0 100';p.velocity_x=crandom()*40;p.velocity_y=crandom()*40;
    p.vr_rigid=1;p.vr_spin='1 2 0';p.avelocity='57 114 0';p.gravity=1;
    return p;
};
void() ADVR_EnemyDrop = {
    if(QVR_AD_API!=1 || self.advr_drop_done)return;
    self.advr_drop_done=1;
    ADVR_SpawnLoot(self,ADVR_LootType(self,random(),random()));
};

// Trigger-driven chainsaw: its fuel stays in its record through holsters,
// drops and saves. An empty saw remains a usable swung club.
void(float h) ADVR_SawFrame = {
    local entity r,victim;local float pressed,damage;local vector at,tip;
    r=ADVR_Hand(h);if(!r || r.advr_kind!=ADVR_SAW)return;
    if(h)pressed=self.button0;else pressed=self.button3;
    r.advr_frame=0;
    if(!pressed || r.wi_clip<=0)return;
    r.advr_frame=1;
    if(time<r.advr_cooldown)return;
    r.advr_cooldown=time+0.1;r.wi_clip=max(0,r.wi_clip-max(0,cvar("vr_chainsaw_fuel_use"))*0.1);
    at=ADVR_Pos(h);tip=ADVR_WeaponTip(h);
    // Only the forward bar cuts, not the engine block or rear grip. Check the
    // whole path first so moving the bar inside a wall cannot cut through it.
    traceline(at,tip,TRUE,self);tip=trace_endpos;
    at=at+(tip-at)*0.55;
    traceline(at,tip,2560,self);victim=trace_ent;
    haptic(h,0,0.1,70,0.3);
    if(trace_fraction==1 || !victim.takedamage)return;
    damage=max(0,cvar("vr_chainsaw_damage"))*0.1;victim.axhitme=1;
    if(victim.reflectaxe){Resist_Axe(self,trace_endpos);return;}
    damage=ADVR_HeadDamage(victim,self,trace_endpos,tip-at,damage);
    SpawnBlood(victim,trace_endpos,normalize(tip-at)*50,damage);
    T_Damage(victim,self,self,damage,DAMARMOR);
    haptic(h,0,0.1,90,0.7);
};
void(float h) ADVR_SawAudio = {
    local float active,channel;local entity r;
    r=ADVR_Hand(h);channel=CHAN_WEAPON;if(!h)channel=CHAN_BODY;
    if(r.advr_kind==ADVR_SAW && r.wi_clip>0 && self.health>0){
        if(h)active=self.button0;else active=self.button3;
    }
    if(active && (!self.advr_saw_audio[h] || time>=self.advr_saw_audio[h]+0.5)){
        sound(self,channel,"vr/saw_run.wav",1,ATTN_NORM);self.advr_saw_audio[h]=time;
    }
    if(!active && self.advr_saw_audio[h])sound(self,channel,"vr/saw_stall.wav",1,ATTN_NORM);
    if(!active)self.advr_saw_audio[h]=0;
};
