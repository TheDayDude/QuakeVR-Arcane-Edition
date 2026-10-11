// Enemy loot uses the same record/prop path as weapons released by a player.
// Kinds keep native AD bits for inventory compatibility, but never change the
// player's upgrade flags. Zero is the original AD pickup behaviour.
string(entity r) ADVR_RecordModel = {
    if(!r)return "";
    if(r.advr_kind==ADVR_TOME)return "progs/advr_tome.mdl";
    if(r.advr_kind==ADVR_FURY1)return "progs/advr_fury1.mdl";
    if(r.advr_kind==ADVR_FURY2)return "progs/advr_fury2.mdl";
    if(r.advr_kind==ADVR_HAMMER)return "progs/advr_hammer.mdl";
    if(r.advr_kind==ADVR_CROSSBOW)return "progs/advr_crossbow.mdl";
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
    if(r.advr_kind==ADVR_CROSSBOW)return 1;
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
    else if(c==CT_MONSKULLW){w=IT_AXE;kind=ADVR_TOME;chance=1;}
    else if(c==CT_MONDFURY){w=IT_AXE;kind=ADVR_FURY1;chance=1;}
    else if(c==CT_MONDCROSS){w=IT_AXE;kind=ADVR_CROSSBOW;chance=1;}
    else if(c==CT_MONKNIGHT || c==CT_MONDGUARD || c==CT_MONZOMBIEK || c==CT_MONINVSWORD){w=IT_AXE;kind=ADVR_SWORD;chance=1;}
    else if(c==CT_MONHELLK || c==CT_MONDBLOOD || c==CT_MONDKNIGHT || c==CT_MONDPRINCE ||
        c==CT_MONDSERG || c==CT_MONCOMM || c==CT_MONDGUARDQ || c==CT_MONDLORD || c==CT_MONJUSTICE || c==CT_MONJUDGE){w=IT_AXE;kind=ADVR_HELLSWORD;chance=1;}
    else if(c==CT_MONOGRE || c==CT_MONHOGRE){
        if(choice<0.5){w=IT_AXE;kind=ADVR_SAW;}else w=IT_GRENADE_LAUNCHER;
    }
    else if(c==CT_MONHOGREHAM){w=IT_AXE;kind=ADVR_HAMMER;}
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
    if(kind==ADVR_CROSSBOW)r.advr_bolt_pack=12;
    if(kind==ADVR_SAW){least=bound(0,cvar("vr_chainsaw_drop_fuel_min"),100);r.wi_clip=least+floor(random()*(101-least));}
    p=spawn();p.classname="advr_dropped_weapon";p.weaponinst=r;p.advr_weapon=w;
    p.owner=foe;p.advr_cooldown=time+1;p.vr_monster_drop=time;
    p.movetype=MOVETYPE_BOUNCE;p.solid=SOLID_BBOX;p.touch=ADVR_PropTouch;
    setmodel(p,ADVR_RecordModel(r));setsize(p,'-4 -4 -4','4 4 4');
    at=foe.origin+'0 0 12';setorigin(p,at);p.angles=foe.angles;
    p.velocity='0 0 100';p.velocity_x=crandom()*40;p.velocity_y=crandom()*40;
    p.vr_rigid=1;p.vr_spin='1 2 0';p.avelocity='57 114 0';p.gravity=1;
    foe.advr_loot_spawned=1;
    return p;
};
void() ADVR_EnemyDrop = {
    local float packed;local entity p;
    if(QVR_AD_API!=1 || self.advr_drop_done)return;
    self.advr_drop_done=1;
    packed=ADVR_LootType(self,random(),random());
    p=ADVR_SpawnLoot(self,packed);
    if(p && self.classtype==CT_MONDFURY) {
        p.velocity_x=p.velocity_x-45;
        p=ADVR_SpawnLoot(self,IT_AXE+ADVR_FURY2*65536);p.velocity_x=p.velocity_x+45;
    }
};

// Range-only stock, spawned after the BSP entities and precaches are ready.
// The saved stock markers avoid duplicates on load or player respawn.
void() ADVR_RangeSetup = {
    local entity marker,p;local float kind;
    if(mapname!="ad_test11" || find(world,classname,"advr_range_stock"))return;

    for(kind=ADVR_CROSSBOW;kind<=ADVR_TOME;kind=kind+1) {
        marker=spawn();marker.classname="advr_range_stock";marker.advr_kind=kind;
        if(kind==ADVR_CROSSBOW)setorigin(marker,'-96 64 40');else if(kind==ADVR_HAMMER)setorigin(marker,'96 64 40');
        else if(kind==ADVR_FURY1)setorigin(marker,'176 64 40');else if(kind==ADVR_FURY2)setorigin(marker,'208 64 40');else setorigin(marker,'248 64 40');
        p=ADVR_SpawnLoot(marker,IT_AXE+kind*65536);
        p.owner=world;p.advr_cooldown=0;p.velocity='0 0 0';p.avelocity='0 0 0';p.vr_spin='0 0 0';
        p.angles='0 90 90';setorigin(p,marker.origin);marker.weaponinst=p.weaponinst;
    }
};

// AD's w_* models are decorative weapon debris. The real drop replaces them,
// including delayed death-animation debris and later corpse overkills.
float(entity foe,float gib_no) ADVR_SkipWeaponGib = {
    local string mdl;
    if(QVR_AD_API!=1 || !foe.advr_loot_spawned)return 0;
    if(gib_no==11)mdl=foe.gib1mdl;
    else if(gib_no==12)mdl=foe.gib2mdl;
    else if(gib_no==13)mdl=foe.gib3mdl;
    else if(gib_no==14)mdl=foe.gib4mdl;
    else if(gib_no==15)mdl=foe.gib5mdl;
    else return 0;
    return substring(mdl,0,8)=="progs/w_";
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
    damage=ADVR_MeleeHeadDamage(victim,self,trace_endpos,tip-at,damage);
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

// One chambered bolt; reloading draws from the separate player bolt reserve.
void(float h,float pressed) ADVR_CrossbowFire = {
    local entity r;local float was,channel;local vector at,ang;
    r=ADVR_Hand(h);was=r.advr_trigger;r.advr_trigger=pressed;
    r.advr_frame=4*(r.wi_clip>0);
    if(r.advr_animtime>time){
        if(r.advr_animtime-time>0.12)r.advr_frame=1;
        else if(r.advr_animtime-time>0.06)r.advr_frame=2;
        else r.advr_frame=3;
    }
    if(!pressed || was || r.wi_clip<=0 || time<r.advr_cooldown)return;
    r.wi_clip=r.wi_clip-1;r.advr_cooldown=time+0.8;
    r.advr_animtime=time+0.18;r.advr_frame=1;
    if(h){at=self.muzzlepos;ang=self.shotrot;channel=CHAN_WEAPON;}
    else{at=self.offmuzzlepos;ang=self.offshotrot;channel=CHAN_BODY;}
    traceline(self.origin+self.view_ofs,at,TRUE,self);at=trace_endpos;
    makevectors(ang);launch_projectile(at,v_forward,CT_PROJ_BOLT1,900);
    newmis.advr_crossbolt=1;newmis.poisonous=0;newmis.bodyfadeaway=TRUE;
    newmis.movetype=MOVETYPE_FLY;setmodel(newmis,MODEL_PROJ_BOLT1);
    sound(self,channel,"weapons/crossbow_fire.wav",1,ATTN_NORM);
    weaponfired(self,h);haptic(h,0,0.1,80,0.6);
};
