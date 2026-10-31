// QuakeVR integration for AD 1.80. AD owns damage, projectiles, ammo and upgrades.
// Per-hand records isolate saved_weapon timers; AD attack functions still run as the player.
float() ADVR_Tracked = { return QVR_AD_API == 1 && (self.vrbits0 & 16384) != 0; };

entity(float w) ADVR_Record = {
    local entity r;
    if (!w) return world;
    r = spawn(); r.classname = "advr_weapon_record"; r.advr_weapon = w;
    advr_serial = advr_serial + 1; r.wi_uid = advr_serial;
    if(w==IT_LIGHTNING && (self.moditems & IT_UPGRADE_LG))r.advr_kind=ADVR_PLASMA;
    if(w==IT_SUPER_SHOTGUN && (self.moditems & IT_UPGRADE_SSG))r.advr_kind=ADVR_WIDOWMAKER;
    if(w==IT_AXE && (self.moditems & IT_UPGRADE_AXE) && !(self.moditems & IT_UPGRADE_GHOOK))r.advr_kind=ADVR_SHADOWAXE;
    ADVR_InitClip(r);
    return r;
};

string(float w, float ground) ADVR_Model = {
    if (w == IT_AXE) {
        if (self.moditems & IT_UPGRADE_GHOOK) { if (ground) return MODEL_GWEAP_GHOOK; return "progs/v_grpple.mdl"; }
        if (self.moditems & IT_UPGRADE_AXE) { if (ground) return MODEL_GWEAP_UPAXE; return "progs/advr_shadowaxe.mdl"; }
        if (ground) return MODEL_GWEAP_AXE; return "progs/v_axe.mdl";
    }
    if (w == IT_SHOTGUN) { if (ground) return MODEL_GWEAP_SG; return MODEL_VWEAP_SG; }
    if (w == IT_SUPER_SHOTGUN) {
        if (self.moditems & IT_UPGRADE_SSG) { if (ground) return MODEL_GWEAP_UPSSG; return "progs/advr_widowmaker.mdl"; }
        if (ground) return MODEL_GWEAP_SSG; return MODEL_VWEAP_SSG;
    }
    if (w == IT_NAILGUN) { if (ground) return MODEL_GWEAP_NG; return MODEL_VWEAP_NG; }
    if (w == IT_SUPER_NAILGUN) { if (ground) return MODEL_GWEAP_SNG; return MODEL_VWEAP_SNG; }
    if (w == IT_GRENADE_LAUNCHER) { if (ground) return MODEL_GWEAP_GL; return MODEL_VWEAP_GL; }
    if (w == IT_ROCKET_LAUNCHER) { if (ground) return MODEL_GWEAP_RL; return MODEL_VWEAP_RL; }
    if (w == IT_LIGHTNING) {
        if (self.moditems & IT_UPGRADE_LG) { if (ground) return MODEL_GWEAP_UPLG; return "progs/advr_plasma.mdl"; }
        if (ground) return MODEL_GWEAP_LG; return MODEL_VWEAP_LG;
    }
    return "";
};
float(float w) ADVR_Ammo = {
    if (w == IT_SHOTGUN || w == IT_SUPER_SHOTGUN) return self.ammo_shells;
    if (w == IT_NAILGUN || w == IT_SUPER_NAILGUN) return self.ammo_nails;
    if (w == IT_GRENADE_LAUNCHER || w == IT_ROCKET_LAUNCHER) return self.ammo_rockets;
    if (w == IT_LIGHTNING) return self.ammo_cells;
    return 0;
};
float(float w) ADVR_AmmoType = {
    if (w == IT_SHOTGUN || w == IT_SUPER_SHOTGUN) return 1;
    if (w == IT_NAILGUN || w == IT_SUPER_NAILGUN) return 2;
    if (w == IT_GRENADE_LAUNCHER || w == IT_ROCKET_LAUNCHER) return 3;
    if (w == IT_LIGHTNING) return 4;
    return 0;
};
// Ammo fields remain AD's total carried ammunition, including loaded rounds.
// Records reserve their own loaded rounds; reloading never creates ammunition.
float(float w) ADVR_Capacity = {
    if(w==IT_SHOTGUN)return 8;
    if(w==IT_SUPER_SHOTGUN)return 2;
    if(w==IT_NAILGUN)return 24;
    if(w==IT_SUPER_NAILGUN || w==IT_LIGHTNING)return 36;
    if(w==IT_GRENADE_LAUNCHER || w==IT_ROCKET_LAUNCHER)return 4;
    return 0;
};
void(float w,float n) ADVR_SetAmmo = {
    if(w==IT_SHOTGUN || w==IT_SUPER_SHOTGUN)self.ammo_shells=n;
    else if(w==IT_NAILGUN || w==IT_SUPER_NAILGUN)self.ammo_nails=n;
    else if(w==IT_GRENADE_LAUNCHER || w==IT_ROCKET_LAUNCHER)self.ammo_rockets=n;
    else if(w==IT_LIGHTNING)self.ammo_cells=n;
};
float(float w) ADVR_Loaded = {
    local float n,i,a;local entity r;
    a=ADVR_AmmoType(w);if(!a)return 0;
    r=self.advr_main;if(r && ADVR_AmmoType(r.advr_weapon)==a)n=n+r.wi_clip;
    r=self.advr_off;if(r && ADVR_AmmoType(r.advr_weapon)==a)n=n+r.wi_clip;
    for(i=0;i<6;i=i+1){r=self.advr_holster[i];if(r && ADVR_AmmoType(r.advr_weapon)==a)n=n+r.wi_clip;}
    return n;
};
void(entity r) ADVR_InitClip = {
    if(!r || r.advr_clip_ready)return;
    r.advr_clip_ready=1;
    r.wi_clip=min(ADVR_RecordCapacity(r),max(0,ADVR_Ammo(r.advr_weapon)-ADVR_Loaded(r.advr_weapon)-ADVR_AmmoReserved(r)));
};
void(entity r) ADVR_ClampClip = {
    if(!r)return;
    if(r.advr_kind==ADVR_CROSSBOW){
        // Preserve ammunition from saves made with the old 12-shot magazine.
        if(r.wi_clip>1)self.advr_bolts=self.advr_bolts+r.wi_clip-1;
        r.wi_clip=bound(0,r.wi_clip,1);return;
    }
    if(r.advr_kind==ADVR_SAW){r.wi_clip=bound(0,r.wi_clip,ADVR_RecordCapacity(r));return;}
    ADVR_InitClip(r);
    r.wi_clip=bound(0,r.wi_clip,ADVR_RecordCapacity(r));
    r.wi_clip=min(r.wi_clip,max(0,ADVR_Ammo(r.advr_weapon)-(ADVR_Loaded(r.advr_weapon)-r.wi_clip)));
};
void(float h) ADVR_Reload = {
    local entity r;local float n;
    if(cvar("vr_reload_mode")==3)return;
    r=ADVR_Hand(h);if(r.advr_kind==ADVR_SAW)return;
    if(!r || (!cvar("vr_reload_mode") && r.advr_kind!=ADVR_CROSSBOW) || time<r.advr_reload_until)return;
    ADVR_InitClip(r);
    if(r.advr_kind==ADVR_CROSSBOW){
        ADVR_ClampClip(r);n=min(1-r.wi_clip,max(0,self.advr_bolts));
    }else n=min(ADVR_RecordCapacity(r)-r.wi_clip,max(0,ADVR_Ammo(r.advr_weapon)-ADVR_Loaded(r.advr_weapon)));
    if(n<=0)return;
    n=ADVR_AmmoReload(r,n);if(n<=0)return;
    if(r.advr_kind==ADVR_CROSSBOW)self.advr_bolts=self.advr_bolts-n;
    r.wi_clip=r.wi_clip+n;r.advr_reload_until=time+0.35;
    r.advr_cooldown=max(r.advr_cooldown,r.advr_reload_until);
    sound(self,CHAN_BODY,"reload1.wav",1,ATTN_NORM);haptic(h,0,0.12,70,0.5);
};
// Standard ammo totals already include loaded rounds; clearing their reservation
// makes them available to other guns. Bolts instead have a separate reserve pool.
void(float h) ADVR_Unload = {
    local entity r;local float n;
    // A hand releasing the charging handle must leave its rail before it can
    // accidentally poke the nearby unload button with the same fingers.
    if(self.advr_charge_record[1-h] || self.advr_charge_guard[1-h]==ADVR_Hand(h))return;
    if(cvar("vr_reload_mode")==3)return; // Manual reload uses B/Y only; touching the red button does nothing.
    r=ADVR_Hand(h);
    if(!r || r.advr_kind==ADVR_SAW || ADVR_RecordCapacity(r)<=0)return;
    ADVR_ClampClip(r);n=r.wi_clip;if(n<=0)return;
    ADVR_AmmoUnload(r);
    dprint("ADVR unload hand ");dprint(ftos(h));dprint(" rounds ");dprint(ftos(n));dprint("\n");
    r.advr_reload_until=time+0.35;
    r.advr_cooldown=max(r.advr_cooldown,r.advr_reload_until);
    sound(self,CHAN_BODY,"reload1.wav",0.5,ATTN_NORM);haptic(h,0,0.08,80,0.35);
};
void(float h) ADVR_ReloadFrame = {
    local float pressed,flick,slot;
    if(cvar("vr_reload_mode")==3)return;
    if(h){pressed=(self.vrbits0 & 256) && !(self.vrbits0 & 512);flick=(self.vrbits0 & 4096) && !(self.vrbits0 & 8192);}
    else {pressed=(self.vrbits0 & 64) && !(self.vrbits0 & 128);flick=(self.vrbits0 & 1024) && !(self.vrbits0 & 2048);}
    slot=ADVR_Holster(h);
    if(pressed || (flick && ADVR_Hand(h).advr_weapon==IT_SUPER_SHOTGUN && ADVR_Hand(h).advr_kind!=ADVR_WIDOWMAKER) ||
        (slot>=0 && (cvar("vr_reload_mode")==1 || slot==2 || slot==3)))ADVR_Reload(h);
};
entity(float h) ADVR_Hand = { if (h) return self.advr_main; return self.advr_off; };
void(float h, entity r) ADVR_SetHand = {
    if(r && r.advr_kind==ADVR_HAMMER){r.advr_hammer_time=0;r.advr_hammer_armed=0;}
    if(r.advr_nether_until){r.advr_nether_ready=1;r.advr_nether_swing='0 0 0';}
    if (h) self.advr_main = r; else self.advr_off = r;
};
vector(float h) ADVR_Pos = { if (h) return self.handpos; return self.offhandpos; };
vector(float h) ADVR_Angles = { if (h) return self.handrot; return self.offhandrot; };
float(float h) ADVR_Grip = { if (h) return (self.vrbits0 & 8) != 0; return (self.vrbits0 & 2) != 0; };
float(float h) ADVR_OldGrip = { if (h) return (self.vrbits0 & 16) != 0; return (self.vrbits0 & 4) != 0; };
float(float h) ADVR_Holster = {
    local float n;
    if(self.advr_elder_until>time)return -1;
    // A casting hand owns its charge, release grace period and sustained spell.
    // Ignore holster proximity for lookup, hover feedback, reload and cancellation.
    if(self.advr_magic_book && self.advr_magic_hand==h && !ADVR_Hand(h))return -1;
    if (h) n = self.mainhand_hotspot; else n = self.offhand_hotspot;
    if (n >= 3 && n <= 6) return n - 3;
    if (n == 8 || n == 9) return n - 4;
    return -1;
};
float(entity r) ADVR_IntegratedBolt = {
    return r && (r.advr_weapon==IT_NAILGUN || r.advr_weapon==IT_SUPER_NAILGUN || r.advr_weapon==IT_LIGHTNING || r.advr_kind==ADVR_PLASMA || r.advr_kind==ADVR_WIDOWMAKER);
};
float(entity r) ADVR_PumpPull = {
    local float remaining,duration;
    if(!r)return 0;
    if((r.advr_weapon!=IT_SHOTGUN && !ADVR_IntegratedBolt(r)) || r.advr_needs_charge)return r.advr_charge_pull;
    duration=.30;if(ADVR_IntegratedBolt(r))duration=.09;
    remaining=bound(0,(r.advr_pump_until-time)/duration,1);
    return 1-fabs(2*remaining-1);
};
void() ADVR_Sync = {
    local float i;
    ADVR_PouchPreview();
    self.weaponflags=32*self.advr_main.advr_ssg_open+128*self.advr_main.advr_mag_absent+256*self.advr_main.advr_needs_charge+512*floor(ADVR_PumpPull(self.advr_main)*15);self.weaponflags2=32*self.advr_off.advr_ssg_open+128*self.advr_off.advr_mag_absent+256*self.advr_off.advr_needs_charge+512*floor(ADVR_PumpPull(self.advr_off)*15);
    self.advr_reload_hands=(self.advr_round[0]!=world || (self.advr_charge_record[0]!=world && self.advr_charge_record[0].advr_weapon!=IT_SHOTGUN))+2*(self.advr_round[1]!=world || (self.advr_charge_record[1]!=world && self.advr_charge_record[1].advr_weapon!=IT_SHOTGUN));
    ADVR_MagicInit(self);
    self.advr_tome_flags=(self.advr_off.advr_kind==ADVR_DEBUGTOME)+2*(self.advr_main.advr_kind==ADVR_DEBUGTOME);
    ADVR_ClampClip(self.advr_main);ADVR_ClampClip(self.advr_off);
    for(i=0;i<6;i=i+1)ADVR_ClampClip(self.advr_holster[i]);
    if(ADVR_IsTome(self.advr_main))self.weaponframe=self.advr_spell;
    if(ADVR_IsTome(self.advr_off))self.weaponframe2=self.advr_spell;
    if(self.advr_main.advr_kind==ADVR_CROSSBOW && self.advr_main.advr_animtime<=time)self.advr_main.advr_frame=4*(self.advr_main.wi_clip>0);
    if(self.advr_off.advr_kind==ADVR_CROSSBOW && self.advr_off.advr_animtime<=time)self.advr_off.advr_frame=4*(self.advr_off.wi_clip>0);
    self.weaponclipsize=ADVR_RecordCapacity(self.advr_main);
    self.weaponclipsize2=ADVR_RecordCapacity(self.advr_off);
    self.weaponinst = self.advr_main; self.weaponinst2 = self.advr_off;
    self.weapon = 0; self.weaponmodel = "progs/hand.mdl"; self.weaponframe = 0;
    self.weapon2 = 0; self.weaponmodel2 = "progs/hand.mdl"; self.weaponframe2 = 0;
    if (self.advr_main) { self.weapon = self.advr_main.advr_weapon; self.weaponmodel = ADVR_RecordModel(self.advr_main); self.weaponframe = 0; }
    if (self.advr_off) { self.weapon2 = self.advr_off.advr_weapon; self.weaponmodel2 = ADVR_RecordModel(self.advr_off); self.weaponframe2 = 0; }
    if(ADVR_IsTome(self.advr_main))self.weaponframe=self.advr_spell;
    if(ADVR_IsTome(self.advr_off))self.weaponframe2=self.advr_spell;
    if(self.advr_main.advr_kind==ADVR_CROSSBOW || self.advr_main.advr_kind==ADVR_SAW || self.advr_main.advr_weapon==IT_SUPER_NAILGUN)self.weaponframe=self.advr_main.advr_frame;
    if(self.advr_off.advr_kind==ADVR_CROSSBOW || self.advr_off.advr_kind==ADVR_SAW || self.advr_off.advr_weapon==IT_SUPER_NAILGUN)self.weaponframe2=self.advr_off.advr_frame;
    if(self.advr_fury_charge>0) {
        if(ADVR_IsFury(self.advr_main))self.weaponframe=bound(1,ceil(self.advr_fury_charge*4),4);
        if(ADVR_IsFury(self.advr_off))self.weaponframe2=bound(1,ceil(self.advr_fury_charge*4),4);
    }
    self.currentammo = ADVR_Ammo(self.weapon); self.ammocounter = self.currentammo;
    if(cvar("vr_reload_mode"))self.ammocounter=max(0,self.currentammo-ADVR_Loaded(self.weapon));
    self.currentammo2 = ADVR_AmmoType(self.weapon2); self.ammocounter2 = ADVR_Ammo(self.weapon2);
    if(cvar("vr_reload_mode"))self.ammocounter2=max(0,self.ammocounter2-ADVR_Loaded(self.weapon2));
    if(self.advr_main.advr_kind==ADVR_SAW)self.ammocounter=self.advr_main.wi_clip;
    if(self.advr_off.advr_kind==ADVR_SAW)self.ammocounter2=self.advr_off.wi_clip;
    if(ADVR_IsTome(self.advr_main))self.ammocounter=self.mana;
    if(ADVR_IsTome(self.advr_off))self.ammocounter2=self.mana;
    if(ADVR_IsTome(self.advr_main))self.weaponframe=self.advr_spell;
    if(ADVR_IsTome(self.advr_off))self.weaponframe2=self.advr_spell;
    if(self.advr_main.advr_kind==ADVR_CROSSBOW)self.ammocounter=self.advr_bolts;
    if(self.advr_off.advr_kind==ADVR_CROSSBOW)self.ammocounter2=self.advr_bolts;
    self.holsterweaponinst0 = self.advr_holster[0]; self.holsterweaponinst1 = self.advr_holster[1];
    self.holsterweaponinst2 = self.advr_holster[2]; self.holsterweaponinst3 = self.advr_holster[3];
    self.holsterweaponinst4 = self.advr_holster[4]; self.holsterweaponinst5 = self.advr_holster[5];
    self.holsterweaponflags0=32*self.advr_holster[0].advr_ssg_open+128*self.advr_holster[0].advr_mag_absent;
    self.holsterweapon0 = self.advr_holster[0].advr_weapon; self.holsterweaponmodel0 = ADVR_RecordModel(self.advr_holster[0]);
    self.holsterweaponflags1=32*self.advr_holster[1].advr_ssg_open+128*self.advr_holster[1].advr_mag_absent;
    self.holsterweapon1 = self.advr_holster[1].advr_weapon; self.holsterweaponmodel1 = ADVR_RecordModel(self.advr_holster[1]);
    self.holsterweaponflags2=32*self.advr_holster[2].advr_ssg_open+128*self.advr_holster[2].advr_mag_absent;
    self.holsterweapon2 = self.advr_holster[2].advr_weapon; self.holsterweaponmodel2 = ADVR_RecordModel(self.advr_holster[2]);
    self.holsterweaponflags3=32*self.advr_holster[3].advr_ssg_open+128*self.advr_holster[3].advr_mag_absent;
    self.holsterweapon3 = self.advr_holster[3].advr_weapon; self.holsterweaponmodel3 = ADVR_RecordModel(self.advr_holster[3]);
    self.holsterweaponflags4=32*self.advr_holster[4].advr_ssg_open+128*self.advr_holster[4].advr_mag_absent;
    self.holsterweapon4 = self.advr_holster[4].advr_weapon; self.holsterweaponmodel4 = ADVR_RecordModel(self.advr_holster[4]);
    self.holsterweaponflags5=32*self.advr_holster[5].advr_ssg_open+128*self.advr_holster[5].advr_mag_absent;
    self.holsterweapon5 = self.advr_holster[5].advr_weapon; self.holsterweaponmodel5 = ADVR_RecordModel(self.advr_holster[5]);
};
void(float w) ADVR_Select = {
    local float i;
    local entity r,old;
    if(self.advr_elder_until>time)return;
    if (!w || !(self.items & w)) return;
    if (self.advr_main.advr_weapon == w) return;
    old = self.advr_main;
    if (self.advr_off.advr_weapon == w) { self.advr_main = self.advr_off; self.advr_off = old; return; }
    for (i=0;i<6;i=i+1) if (self.advr_holster[i].advr_weapon == w) {
        self.advr_main = self.advr_holster[i]; self.advr_holster[i] = old; return;
    }
    if (old) {
        for (i=0;i<6;i=i+1) if (!self.advr_holster[i]) { self.advr_holster[i]=old; break; }
        if (i == 6) return;
    }
    self.advr_main = ADVR_Record(w);
};

// A flying saved_weapon remains one record; retrieving it cannot duplicate that record.
void() ADVR_PropTouch = {
    ADVR_ThrownHit();
};
void(float h) ADVR_Drop = {
    local entity r,p;
    local float i,owned;
    local vector pos,vel;
    r = ADVR_Hand(h); if (!r) return;
    pos = ADVR_Pos(h);
    p = spawn(); p.classname = "advr_dropped_weapon";
    p.weaponinst = r; p.advr_weapon = r.advr_weapon; p.owner = self;
    p.advr_moditems = self.moditems-(self.moditems & (IT_UPGRADE_LG|IT_UPGRADE_SSG|IT_UPGRADE_AXE));if(r.advr_kind)p.advr_moditems=0; p.advr_cooldown = time + 0.4;
    p.movetype = MOVETYPE_BOUNCE; p.solid = SOLID_BBOX; p.touch = ADVR_PropTouch;
    // Use the held mesh: the engine applies its calibrated transform to world entities too.
    setmodel(p,ADVR_RecordModel(r)); if(!r.advr_kind && (r.advr_weapon==IT_NAILGUN || r.advr_weapon==IT_SUPER_NAILGUN || r.advr_weapon==IT_LIGHTNING))p.frame=16*r.advr_mag_absent; if(r.advr_kind==ADVR_PLASMA)p.frame=r.advr_mag_absent; if(r.advr_kind==ADVR_CROSSBOW)p.frame=4*(r.wi_clip>0); setsize(p,'-4 -4 -4','4 4 4'); setorigin(p,pos);
    p.angles = ADVR_Angles(h);
    if (h) { vel = self.handthrowvel; p.avelocity = self.handavel; }
    else { vel = self.offhandthrowvel; p.avelocity = self.offhandavel; }
    // Tracking velocities are metres/s and radians/s, not Quake units/s.
    p.velocity = vel * (26.246719 * max(0.01,cvar("vr_world_scale")));
    p.vr_rigid = 1; p.vr_spin = p.avelocity;
    p.avelocity = p.avelocity * 57.29578; p.gravity = 1;
    ADVR_ThrowSetup(h,p);
    ADVR_SetHand(h,world);
    ADVR_SetAmmo(r.advr_weapon,max(0,ADVR_Ammo(r.advr_weapon)-r.wi_clip));
    owned=ADVR_Hand(1-h).advr_weapon==r.advr_weapon;
    for(i=0;i<6;i=i+1)if(self.advr_holster[i].advr_weapon==r.advr_weapon)owned=1;
    if(!owned)self.items = self.items - (self.items & r.advr_weapon);
    r.advr_anim = SUB_Null; r.advr_animtime = 0; r.advr_frame = 0;
};
// Replacement is a gentle physical drop, preserving the record and loaded ammo.
void(float h) ADVR_Displace = {
    local entity r,p;
    r=ADVR_Hand(h);if(!r)return;
    ADVR_Drop(h);
    p=find(world,classname,"advr_dropped_weapon");
    while(p && p.weaponinst!=r)p=find(p,classname,"advr_dropped_weapon");
    if(p){setorigin(p,ADVR_Pos(h));p.velocity='0 0 0';p.avelocity='0 0 0';p.vr_spin='0 0 0';p.advr_throw_armed=0;}
};
// AD's accepted map pickup calls this after adding ammo and firing its normal
// inventory rules. A physical weapon is distinct even when its AD bit matches.
void(entity player,float weaponbit,float upgrade) ADVR_Pickup = {
    local entity savedself,r;local float h;
    if(QVR_AD_API!=1 || !player.advr_initialized)return;
    savedself=self;self=player;h=1;
    if(self.advr_pickup_hand)h=self.advr_pickup_hand-1;
    ADVR_Displace(h);
    self.items=self.items | weaponbit;
    r=ADVR_Record(weaponbit);
    if(weaponbit==IT_LIGHTNING){r.advr_kind=0;if(upgrade & IT_UPGRADE_LG)r.advr_kind=ADVR_PLASMA;}
    if(weaponbit==IT_SUPER_SHOTGUN){r.advr_kind=0;if(upgrade & IT_UPGRADE_SSG)r.advr_kind=ADVR_WIDOWMAKER;}
    if(weaponbit==IT_AXE){r.advr_kind=ADVR_AXE;if(upgrade & IT_UPGRADE_AXE)r.advr_kind=ADVR_SHADOWAXE;if(upgrade & IT_UPGRADE_GHOOK)r.advr_kind=0;}
    ADVR_SetHand(h,r);if(self.advr_elder_until>time)ADVR_Displace(h);ADVR_Sync();self=savedself;
};
void(entity p, float h) ADVR_Catch = {
    if(self.advr_elder_until>time)return;
    if (!p.weaponinst || p.weaponinst==ADVR_Hand(h)) return;
    ADVR_Displace(h);
    // Old saved floor props carried their identity in the upgrade mask.
    if(p.advr_weapon==IT_LIGHTNING && (p.advr_moditems & IT_UPGRADE_LG))p.weaponinst.advr_kind=ADVR_PLASMA;
    if(p.advr_weapon==IT_SUPER_SHOTGUN && (p.advr_moditems & IT_UPGRADE_SSG))p.weaponinst.advr_kind=ADVR_WIDOWMAKER;
    if(p.advr_weapon==IT_AXE && !p.weaponinst.advr_kind && (p.advr_moditems & IT_UPGRADE_AXE))p.weaponinst.advr_kind=ADVR_SHADOWAXE;
    if(p.weaponinst.advr_kind==ADVR_CROSSBOW){
        // The enemy's bolt bundle is collected once, never on subsequent catches.
        self.advr_bolts=self.advr_bolts+p.weaponinst.advr_bolt_pack;
        p.weaponinst.advr_bolt_pack=0;ADVR_ClampClip(p.weaponinst);
    }
    if(ADVR_IsTome(p.weaponinst))ADVR_TomePickup(self,p.weaponinst);
    ADVR_SetAmmo(p.advr_weapon,ADVR_Ammo(p.advr_weapon)+p.weaponinst.wi_clip);
    ADVR_SetHand(h,p.weaponinst); self.items = self.items | p.advr_weapon;
    self.moditems = self.moditems | (p.advr_moditems & (IT_UPGRADE_AXE | IT_UPGRADE_GHOOK));
    p.weaponinst = world; remove(p);
};
void(float h) ADVR_Touch = {
    local entity p,next,player,oldother;
    local vector pos,nearest;
    local float previous,slot;
    if(ADVR_HandBusy(h))return;
    pos=ADVR_Pos(h);player=self;oldother=other;
    p=findradius(pos,32);
    while (p) {
        next=p.chain;
        nearest=pos;
        nearest_x=bound(p.absmin_x,pos_x,p.absmax_x);
        nearest_y=bound(p.absmin_y,pos_y,p.absmax_y);
        nearest_z=bound(p.absmin_z,pos_z,p.absmax_z);
        traceline(pos,nearest,TRUE,self);
        if (trace_fraction == 1 && vlen(nearest-pos)<12) {
            if(p.classname=="advr_reload_round" && !p.fg_state && !p.advr_round_holder && time>=p.advr_cooldown){ADVR_ManualCatch(p,h);return;}
            if (p.classname == "advr_dropped_weapon" && !(p.owner==self && time<p.advr_cooldown)) { ADVR_Catch(p,h); return; }
            if ((p.flags & FL_ITEM) && p.touch && p.solid == SOLID_TRIGGER) {
                previous=self.weapon;
                self.advr_pickup_hand=h+1;
                self=p;other=player; self.touch(); self=player;other=oldother;
                self.advr_pickup_hand=0;
                if (self.weapon != previous) {
                    if (!ADVR_Hand(h)) ADVR_SetHand(h,ADVR_Record(self.weapon));
                    else ADVR_Select(self.weapon);
                }
                return;
            }
            if (p.classname == "func_button" && p.touch) {
                self=p;other=player;self.touch();self=player;other=oldother;return;
            }
        }
        p=next;
    }
};
// Return whether feedback was emitted, so the interaction test can verify edges.
float(float h) ADVR_HolsterHaptic = {
    local float slot,hover,previous,mode,t;
    slot=ADVR_Holster(h);hover=0;previous=self.advr_hover[h];
    mode=cvar("vr_holster_haptics");
    if(mode && slot>=0)
        if(ADVR_Hand(h) || self.advr_holster[slot])hover=slot+1;
    self.advr_hover[h]=hover;
    if(!hover){self.advr_hover_next[h]=0;return 0;}
    if(mode==1) {
        if(previous==hover && time<self.advr_hover_next[h])return 0;
        self.advr_hover_next[h]=time+0.1;
        haptic(h,0,0.1,75,0.02);return 1;
    }
    if(mode!=2 || previous==hover)return 0;
    t=max(0.05,cvar("vr_holster_haptic_time"));
    haptic(h,0,t*0.45,80,0.65);
    haptic(h,t*0.4,t*0.35,80,0.4);
    haptic(h,t*0.7,t*0.3,80,0.2);
    return 1;
};
float(float h) ADVR_HandBusy = {
    if(self.advr_charge_record[h] || self.advr_round[h] || self.advr_round_guard[h]>time)return 1;
    if(h)return (self.vrbits0 & 262144)!=0;
    return (self.vrbits0 & 131072)!=0;
};
void(float h) ADVR_GripFrame = {
    local float slot,grip,old;
    local entity r,tmp;
    if(ADVR_HandBusy(h))return;
    if(self.advr_magic_book && self.advr_magic_hand==h && !ADVR_Hand(h))return;
    grip=ADVR_Grip(h);old=ADVR_OldGrip(h);slot=ADVR_Holster(h);r=ADVR_Hand(h);
    if(!r && ADVR_FGPulled(h))return;
    // The engine has already solved the sword's hilt/blade support grip.
    // Do not turn that grip into a hand swap or an unrelated nearby pickup.
    if(!r && grip && weaponanygrip(self,h)>0)return;
    if(grip && !old) {
        if((h && self.mainhand_hotspot==7) || (!h && self.offhand_hotspot==7)) {
            // The sword's lower hilt is inside the generic hand-switch radius.
            // Prefer supporting it even before the client grip blend catches up.
            tmp=ADVR_Hand(1-h);
            if(!r && (tmp.advr_kind==ADVR_SWORD || tmp.advr_kind==ADVR_HELLSWORD || tmp.advr_kind==ADVR_HAMMER))return;
            tmp=ADVR_Hand(1-h);ADVR_SetHand(1-h,r);ADVR_SetHand(h,tmp);return;
        }
        if(slot>=0) { tmp=self.advr_holster[slot];self.advr_holster[slot]=r;ADVR_SetHand(h,tmp);if(r || tmp)sound(self,CHAN_AUTO,"reload1.wav",0.3,ATTN_NORM); }
        else if(r && cvar("vr_weapon_grip_mode")==1) {
            // Held guns report their own weapon hotspot, not necessarily zero.
            // Consume the toggle so this press cannot immediately catch the drop.
            ADVR_Drop(h);return;
        }
        else ADVR_Touch(h);
    }
    if(!grip && old && r && ADVR_Hand(h)==r && cvar("vr_weapon_grip_mode")!=1) {
        if(!ADVR_Hand(1-h) && ADVR_Grip(1-h) && weaponanygrip(self,1-h)>0) {
            ADVR_SetHand(1-h,r);ADVR_SetHand(h,world);return;
        }
        if(slot>=0) {tmp=self.advr_holster[slot];self.advr_holster[slot]=r;ADVR_SetHand(h,tmp);sound(self,CHAN_AUTO,"reload1.wav",0.3,ATTN_NORM);}
        else if(cvar("vr_weapon_grip_mode")==0) ADVR_Drop(h);
    }
    if(grip && !ADVR_Hand(h) && cvar("vr_weapon_grip_mode")!=1) ADVR_Touch(h);
};

// AD's fire routines operate on self. Enter a hand context without relinking the
// player, then restore its body and animation; retain ammo, recoil and damage.
void(float h) ADVR_Fire = {
    local entity r;
    local vector org,ang,saved_punch;
    local float total,available,spent,limited,saved_moditems;
    local float saved_weapon,ammo,button,attack,saved_frame,nexttime,didrun;
    local string mdl;
    local void() thinkfn;
    r=ADVR_Hand(h); if(!r)return;
    if(h) button=self.button0;else button=self.button3;
    if(!button)self.advr_fg_rearm[h]=0;
    if(self.advr_fg_rearm[h])button=0;
    // Rate limit dry clicks independently for each weapon, including held triggers.
    if(button && ADVR_ManualType(r) && r.advr_kind!=ADVR_SAW && time>=r.advr_reload_until && time>=r.advr_cooldown && time>=r.advr_dry_next){
        if((cvar("vr_reload_mode")!=0 && r.wi_clip<1+2*(r.advr_kind==ADVR_WIDOWMAKER)) || (r.advr_kind!=ADVR_CROSSBOW && ADVR_Ammo(r.advr_weapon)<=0)){
            sound(self,CHAN_AUTO,"gunclick.wav",0.6,ATTN_NORM);r.advr_dry_next=time+0.5;
        }
    }
    if(cvar("vr_reload_mode")==3 && (ADVR_ManualMagazine(r) || r.advr_weapon==IT_SHOTGUN) && (r.advr_needs_charge || r.advr_mag_absent)){
        if(button && time>=r.advr_dry_next){sound(self,CHAN_AUTO,"gunclick.wav",0.6,ATTN_NORM);r.advr_dry_next=time+0.5;}
        return;
    }
    if(r.advr_kind==ADVR_CROSSBOW){ADVR_CrossbowFire(h,button);return;}
    if(r.advr_kind==ADVR_SAW && self.advr_fg_rearm[h])return;
    if(r.advr_kind==ADVR_SAW){ADVR_SawFrame(h);return;}
    if(r.advr_weapon==IT_AXE && (r.advr_kind || !(self.moditems & IT_UPGRADE_GHOOK)))return;
    saved_moditems=self.moditems;
    if(r.advr_weapon==IT_LIGHTNING){
        self.moditems=self.moditems-(self.moditems & IT_UPGRADE_LG);
        if(r.advr_kind==ADVR_PLASMA)self.moditems=self.moditems|IT_UPGRADE_LG;
    }
    if(r.advr_weapon==IT_SUPER_SHOTGUN){
        self.moditems=self.moditems-(self.moditems & IT_UPGRADE_SSG);
        if(r.advr_kind==ADVR_WIDOWMAKER)self.moditems=self.moditems|IT_UPGRADE_SSG;
    }
    ADVR_InitClip(r);
    total=ADVR_Ammo(r.advr_weapon);limited=cvar("vr_reload_mode")!=0;available=total;
    if(!limited)available=max(0,total-ADVR_AmmoReserved(r));
    if(limited)available=min(total,r.wi_clip);
    if(r.advr_kind==ADVR_WIDOWMAKER && available<3)button=0;
    if(ADVR_ManualSsg(r) && r.advr_ssg_open)button=0;
    if(time<r.advr_reload_until || (limited && available<=0))button=0;
    ADVR_SetAmmo(r.advr_weapon,available);saved_punch=self.punchangle;
    org=self.origin;ang=self.v_angle;saved_weapon=self.weapon;ammo=self.currentammo;mdl=self.weaponmodel;
    attack=self.attack_finished;saved_frame=self.frame;nexttime=self.nextthink;thinkfn=self.think;
    self.weapon=r.advr_weapon;self.currentammo=ADVR_Ammo(self.weapon);self.weaponmodel=ADVR_Model(self.weapon,0);
    self.attack_finished=r.advr_cooldown;self.weaponframe=r.advr_frame;
    if(h) { self.origin=self.muzzlepos-'0 0 16';self.v_angle=self.shotrot; }
    else {self.origin=self.offmuzzlepos-'0 0 16';self.v_angle=self.offshotrot;}
    // Ray-limit the muzzle to the room. A hand cannot shoot through a wall.
    traceline(org+self.view_ofs,self.origin+'0 0 16',TRUE,self);
    self.origin=trace_endpos-'0 0 16';
    advr_activehand=h;
    local float oldbutton;
    oldbutton=self.button0;self.button0=button;
    makevectors(self.v_angle);ADVR_AmmoNormalize(r);advr_ammo_shot=1;
    if(r.advr_animtime>0 && time>=r.advr_animtime) {
        didrun=1;self.think=r.advr_anim;self.nextthink=r.advr_animtime;
        self.think();
    } else if(button && time>=r.advr_cooldown && (self.currentammo>0 || self.weapon==IT_AXE) && r.advr_animtime==0) {didrun=1;W_Attack();}
    if(didrun) {
        if(self.attack_finished>time && self.attack_finished!=r.advr_cooldown)
            self.attack_finished=time+(self.attack_finished-time)/ADVR_HasteRate(r);
        if(self.nextthink>time)self.nextthink=time+(self.nextthink-time)/ADVR_HasteRate(r);
        if(self.think==player_run || self.think==player_stand1) {r.advr_animtime=0;r.advr_anim=SUB_Null;}
        else {r.advr_anim=self.think;r.advr_animtime=self.nextthink;}
    }
    advr_ammo_shot=0;
    spent=max(0,available-ADVR_Ammo(r.advr_weapon));ADVR_AmmoConsume(r,spent);
    ADVR_SetAmmo(r.advr_weapon,max(0,total-spent));
    r.wi_clip=max(0,r.wi_clip-spent);
    if(ADVR_ManualSsg(r))r.advr_ssg_spent=min(2,r.advr_ssg_spent+spent);
    if(spent>0){
        if(r.advr_weapon==IT_SHOTGUN){
            r.advr_pump_until=time+.30;
            // Eject at the midpoint of the pump stroke, with the side port open.
            ejectcasings(h,0,1,.15,0);
        }
        if(ADVR_IntegratedBolt(r))r.advr_pump_until=time+.09;
        weaponfired(self,h);haptic(h,0,0.08,90,0.65);
        if(cvar("vr_debug_weaponfx")){dprint("ADVR shot hand ");dprint(ftos(h));dprint(" spent ");dprint(ftos(spent));dprint("\n");}
    }
    self.punchangle=saved_punch;self.moditems=saved_moditems;
    r.advr_cooldown=self.attack_finished;r.advr_frame=self.weaponframe;
    self.origin=org;self.v_angle=ang;self.weapon=saved_weapon;self.currentammo=ammo;self.weaponmodel=mdl;self.button0=oldbutton;
    if(self.health>0) {self.think=thinkfn;self.nextthink=nexttime;self.frame=saved_frame;self.attack_finished=attack;}
    advr_activehand=1;
};

// Physical contact feedback: separate hands, no repeated clang from scraping.
float(float h,entity victim,vector velocity,vector normal) ADVR_MeleeFeedback = {
    local float flesh;
    flesh=victim.flags & FL_MONSTER;
    if(time<self.advr_impact_sound[h])return 0;
    if(!flesh) {
        if(self.advr_melee_contact[h] || vlen(velocity)<1.5 || velocity*normal>-0.6)return 0;
        self.advr_melee_contact[h]=1;
        sound(self,CHAN_AUTO,"weapons/bolt_hit1.wav",0.45,ATTN_NORM);
    } else sound(self,CHAN_AUTO,"weapons/bolt_hit4.wav",0.55,ATTN_NORM);
    self.advr_impact_sound[h]=time+0.3;
    haptic(h,0,0.055,85,0.3);return 1;
};

// Sweep the weapon tip between tracked poses, plus its current reach. A teleport
// never becomes a melee swing, and walking without moving the hand adds no power.
void(float h) ADVR_Melee = {
    local vector pos,previous,vel,ang,start,impactvel;
    local entity victim;
    local float speed,damage,w,nexttime,previous_time,dt;
    if(h) {pos=self.handpos;vel=self.handvel;nexttime=self.mainhand_melee_attack_finished;previous=self.advr_prevmain;previous_time=self.advr_prevmain_time;}
    else {pos=self.offhandpos;vel=self.offhandvel;nexttime=self.offhand_melee_attack_finished;previous=self.advr_prevoff;previous_time=self.advr_prevoff_time;}
    if(ADVR_HandBusy(h) && self.advr_elder_until<=time)return;
    if(ADVR_IsTome(ADVR_Hand(h)))return;
    if(self.advr_magic_book && self.advr_magic_hand==h)return;
    if(ADVR_Hand(h).advr_kind==ADVR_HAMMER){ADVR_HammerFrame(h);return;}
    makevectors(ADVR_Angles(h));w=ADVR_Hand(h).advr_weapon;start=pos-v_forward*5;
    if(ADVR_Hand(h).advr_kind)pos=ADVR_WeaponTip(h);
    else if(w==IT_AXE)pos=pos+v_forward*28;else pos=pos+v_forward*(self.advr_elder_until>time ? 20 : 8);
    if(h){self.advr_prevmain=pos;self.advr_prevmain_time=time;}
    else{self.advr_prevoff=pos;self.advr_prevoff_time=time;}
    speed=vlen(vel);dt=time-previous_time;impactvel=vel;
    if(dt>0 && dt<0.1 && vlen(pos-previous)<64 && speed>0.3)
    {
        impactvel=(pos-previous)/(dt*26.246719*max(0.01,cvar("vr_world_scale")));
        speed=max(speed,vlen(impactvel));
    }
    traceline(start,pos,2560,self);
    if(trace_fraction==1 && dt>0 && dt<0.1 && vlen(pos-previous)<64)traceline(previous,pos,2560,self);
    victim=trace_ent;
    ADVR_NetherSwing(h,pos,impactvel,speed,dt,trace_fraction<1);
    if(trace_fraction==1){self.advr_melee_contact[h]=0;return;}
    if(speed<1.5 || time<nexttime)return;
    ADVR_MeleeFeedback(h,victim,impactvel,trace_plane_normal);
    if(!ADVR_Hand(h) && self.advr_earth_until>time) {
        if(h)self.advr_earth_main_until=time+0.3;else self.advr_earth_off_until=time+0.3;
        sound(self,CHAN_WEAPON,"items/damage3.wav",0.8,ATTN_NORM);haptic(h,0,0.1,100,0.65);
    }
    if(!victim.takedamage)return;
    damage=10;if(w==IT_AXE){damage=DAMAGE_PLAYAXE1;if(ADVR_Hand(h).advr_kind==ADVR_SHADOWAXE)damage=DAMAGE_PLAYAXE2;}
    if(ADVR_Hand(h).advr_kind==ADVR_SWORD)damage=15;
    if(ADVR_Hand(h).advr_kind==ADVR_HELLSWORD)damage=20;
    if(ADVR_IsFury(ADVR_Hand(h)))damage=25;
    if(ADVR_Hand(h).advr_kind==ADVR_AXE)damage=DAMAGE_PLAYAXE1;
    if(ADVR_Hand(h).advr_kind==ADVR_CROSSBOW)damage=10;
    if(ADVR_Hand(h).advr_kind==ADVR_SAW){if(ADVR_Hand(h).advr_frame)return;damage=max(0,cvar("vr_dmg_chainsaw_swing"));}
    if(ADVR_Hand(h).advr_nether_until>time)damage=100*ADVR_MagicMultiplier();
    damage=damage*0.75*bound(0.5,speed/3,2);
    // Native quad already multiplies all attacks; don't multiply it twice.
    if(!ADVR_Hand(h) && self.advr_earth_until>time && self.super_damage_finished<=0)damage=damage*4;
    if(self.advr_elder_until>time){
        damage=40*bound(0.7,speed/3,1.5);
        if(!(self.flags & FL_ONGROUND))damage=damage*1.5;
        sound(self,CHAN_WEAPON,"demon/dhit2.wav",1,ATTN_NORM);haptic(h,0,0.08,90,0.55);
    }
    victim.axhitme=1;
    if(ADVR_Hand(h).advr_kind==ADVR_SHADOWAXE)victim.axhitme=2;
    if(victim.reflectaxe) Resist_Axe(self,trace_endpos);
    else {
        damage=ADVR_MeleeHeadDamage(victim,self,trace_endpos,pos-start,damage);
        SpawnBlood(victim,trace_endpos,vel,damage);
        T_Damage(victim,self,self,damage,DAMARMOR);
        if((ADVR_Hand(h).advr_nether_until>time || (!ADVR_Hand(h) && self.advr_hell_until>time)) && victim.health>0)ADVR_Ignite(victim,self);
    }
    if(h)self.mainhand_melee_attack_finished=time+0.35;else self.offhand_melee_attack_finished=time+0.35;
};
void() ADVR_Frame = {
    local float desired;
    ADVR_RuneFrame();
    if(ADVR_ElderFrame()){ADVR_ParryFrame();return;}
    if(self.health<=0)self.advr_earth_until=0;
    ADVR_SawAudio(1);ADVR_SawAudio(0);
    if(self.health<=0 || intermission_running || cinematic_running){ADVR_FuryClear();ADVR_MagicClear();ADVR_EnchantClear();}
    if(self.health<=0 || intermission_running || cinematic_running){ADVR_ManualRefund();return;}
    self.ishuman=1;
    if(!self.advr_initialized) {
        self.advr_initialized=1;self.advr_main=ADVR_Record(self.weapon);
        if(self.weapon!=IT_AXE && (self.items & IT_AXE))self.advr_off=ADVR_Record(IT_AXE);
    }
    // Honor AD's regular saved_weapon selection and automatic pickups.
    desired=self.weapon;
    if(self.impulse==42 || self.impulse==43) {
        ADVR_Unload(self.impulse==43);self.impulse=0;
    }
    // 44 is the left-hand manual eject button; ManualFrame consumes it below.
    if(self.impulse && self.impulse!=44) {ImpulseCommands();desired=self.weapon;}
    if(desired!=self.advr_main.advr_weapon)ADVR_Select(desired);
    ADVR_ManualFrame();
    if(self.impulse==44)self.impulse=0;
    ADVR_HolsterHaptic(1);ADVR_HolsterHaptic(0);
    ADVR_ForceGrab(1);ADVR_ForceGrab(0);
    ADVR_GripFrame(1);ADVR_GripFrame(0);
    ADVR_ReloadFrame(1);ADVR_ReloadFrame(0);
    advr_attack_actor=self;advr_attack_record=self.advr_main;ADVR_Fire(1);
    advr_attack_record=world;advr_attack_actor=world;if(self.health<=0)return;
    advr_attack_actor=self;advr_attack_record=self.advr_off;ADVR_Fire(0);
    advr_attack_record=world;advr_attack_actor=world;if(self.health<=0)return;
    ADVR_MagicFrame();ADVR_ProtectionFrame();ADVR_FuryFrame();ADVR_ParryFrame();
    advr_attack_actor=self;advr_attack_record=self.advr_main;ADVR_Melee(1);
    advr_attack_record=self.advr_off;ADVR_Melee(0);advr_attack_record=world;advr_attack_actor=world;ADVR_Sync();
};

void() ADVR_Reset = {
    local float i;
    ADVR_RuneClear();ADVR_ElderEnd();
    ADVR_ManualRefund();
    for(i=0;i<10;i=i+1)ADVR_PouchSet(i,"");
    self.advr_charge_trigger[0]=self.advr_charge_trigger[1]=0;
    self.advr_reload_hands=0;self.advr_charge_record[0]=self.advr_charge_record[1]=world;self.advr_charge_guard[0]=self.advr_charge_guard[1]=world;self.advr_round_guard[0]=self.advr_round_guard[1]=0;
    ADVR_EnchantClear();self.advr_enchant_latched=0;self.advr_magic_sticks=0;self.advr_magic_oldsticks=0;
    self.advr_magic_version=1;self.advr_known=0;self.advr_mana_max=50;
    for(i=0;i<8;i=i+1)self.advr_favorites[i]=0;
    self.advr_fav_button=0;self.advr_fav_book=world;self.advr_magic_buttons=0;
    self.vr_flashlight_state=0;
    ADVR_MagicClear();self.advr_earth_until=0;self.advr_earth_main_until=0;self.advr_earth_off_until=0;self.advr_protection_until=0;self.advr_protection_armor=0;self.advr_haste_until=0;self.advr_darksight_until=0;self.mana=0;self.advr_mana_seen=0;self.advr_spell=0;self.advr_magic_trigger=0;
    ADVR_FuryClear();self.advr_fury_latched=0;self.advr_fury_cooldown=0;
    self.advr_fury_main=self.advr_fury_off=world;
    self.advr_initialized=0;self.advr_main=world;self.advr_off=world;self.advr_bolts=0;
    self.advr_fg_rearm[0]=self.advr_fg_rearm[1]=0;
    ADVR_FGSet(0,world,0);ADVR_FGSet(1,world,0);
    self.vr_stamina_used=0;self.vr_stamina_time=0;self.vr_melee_hud=0;
    self.advr_hover[0]=self.advr_hover[1]=0;
    self.advr_hover_next[0]=self.advr_hover_next[1]=0;
    self.advr_melee_contact[0]=self.advr_melee_contact[1]=0;
    self.advr_impact_sound[0]=self.advr_impact_sound[1]=0;
    self.weaponinst=self.weaponinst2=world;
    for(i=0;i<6;i=i+1)self.advr_holster[i]=world;
};
void() ADVR_SaveParms = {
    local float i;
    ADVR_ManualRefund();
    ADVR_AmmoSave();
    ADVR_MagicInit(self);parm40=self.advr_known;parm41=self.advr_mana_max;parm42=self.advr_magic_version;
    parm45=ADVR_EnchantPack(self.advr_main);parm46=ADVR_EnchantPack(self.advr_off);
    parm47=ADVR_EnchantPack(self.advr_holster[0]);parm48=ADVR_EnchantPack(self.advr_holster[1]);
    parm49=ADVR_EnchantPack(self.advr_holster[2]);parm50=ADVR_EnchantPack(self.advr_holster[3]);
    parm51=ADVR_EnchantPack(self.advr_holster[4]);parm52=ADVR_EnchantPack(self.advr_holster[5]);
    parm43=parm44=0;
    for(i=0;i<4;i=i+1){parm43=parm43+self.advr_favorites[i]*pow(16,i);parm44=parm44+self.advr_favorites[i+4]*pow(16,i);}
    parm17=self.advr_initialized;parm18=ADVR_PackRecord(self.advr_main);parm19=ADVR_PackRecord(self.advr_off);
    parm20=ADVR_PackRecord(self.advr_holster[0]);parm21=ADVR_PackRecord(self.advr_holster[1]);
    parm22=ADVR_PackRecord(self.advr_holster[2]);parm23=ADVR_PackRecord(self.advr_holster[3]);
    parm24=ADVR_PackRecord(self.advr_holster[4]);parm25=ADVR_PackRecord(self.advr_holster[5]);
    parm26=self.advr_main.wi_clip-1000*self.advr_main.advr_mag_absent-2000*self.advr_main.advr_needs_charge;
    parm27=self.advr_off.wi_clip-1000*self.advr_off.advr_mag_absent-2000*self.advr_off.advr_needs_charge;
    parm28=self.advr_holster[0].wi_clip-1000*self.advr_holster[0].advr_mag_absent-2000*self.advr_holster[0].advr_needs_charge;
    parm29=self.advr_holster[1].wi_clip-1000*self.advr_holster[1].advr_mag_absent-2000*self.advr_holster[1].advr_needs_charge;
    parm30=self.advr_holster[2].wi_clip-1000*self.advr_holster[2].advr_mag_absent-2000*self.advr_holster[2].advr_needs_charge;
    parm31=self.advr_holster[3].wi_clip-1000*self.advr_holster[3].advr_mag_absent-2000*self.advr_holster[3].advr_needs_charge;
    parm32=self.advr_holster[4].wi_clip-1000*self.advr_holster[4].advr_mag_absent-2000*self.advr_holster[4].advr_needs_charge;
    parm33=self.advr_holster[5].wi_clip-1000*self.advr_holster[5].advr_mag_absent-2000*self.advr_holster[5].advr_needs_charge;
parm34=1;parm35=self.advr_bolts;parm36=self.mana;parm37=self.advr_mana_seen;parm38=self.advr_spell;parm39=self.vr_flashlight_state;
};
entity(float w) ADVR_Restore = {
    local float kind,read;local entity r;
    read=floor(w/1048576);
    kind=mod(floor(w/65536),16);w=mod(w,65536);
    if(!(self.items & w))return world;
    r=ADVR_Record(w);r.advr_kind=kind;r.advr_tome_read=read;return r;
};
void() ADVR_LoadParms = {
    local float i;
    dprint("ADVR RESTORE ");dprint(ftos(parm17));dprint(" ");dprint(ftos(parm18));dprint(" ");dprint(ftos(parm19));dprint(" items ");dprint(ftos(self.items));dprint("\n");
    if(!parm17)return;
    self.advr_initialized=1;self.advr_bolts=max(0,parm35);self.mana=bound(0,parm36,9999);self.advr_mana_seen=parm37;self.advr_spell=bound(0,floor(parm38),ADVR_SPELL_COUNT-1);self.vr_flashlight_state=parm39;
    self.advr_known=parm40;self.advr_mana_max=parm41;self.advr_magic_version=parm42;ADVR_MagicInit(self);
    for(i=0;i<4;i=i+1){self.advr_favorites[i]=mod(floor(parm43/pow(16,i)),16);self.advr_favorites[i+4]=mod(floor(parm44/pow(16,i)),16);}
    self.advr_main=ADVR_Restore(parm18);self.advr_off=ADVR_Restore(parm19);
    self.advr_holster[0]=ADVR_Restore(parm20);self.advr_holster[1]=ADVR_Restore(parm21);
    self.advr_holster[2]=ADVR_Restore(parm22);self.advr_holster[3]=ADVR_Restore(parm23);
    self.advr_holster[4]=ADVR_Restore(parm24);self.advr_holster[5]=ADVR_Restore(parm25);
    ADVR_EnchantRestore(self.advr_main,parm45);ADVR_EnchantRestore(self.advr_off,parm46);
    ADVR_EnchantRestore(self.advr_holster[0],parm47);ADVR_EnchantRestore(self.advr_holster[1],parm48);
    ADVR_EnchantRestore(self.advr_holster[2],parm49);ADVR_EnchantRestore(self.advr_holster[3],parm50);
    ADVR_EnchantRestore(self.advr_holster[4],parm51);ADVR_EnchantRestore(self.advr_holster[5],parm52);
    if(parm34){
        if(self.advr_main){self.advr_main.advr_needs_charge=parm26<-1500;parm26=parm26+2000*self.advr_main.advr_needs_charge;self.advr_main.advr_mag_absent=parm26<0;self.advr_main.wi_clip=parm26+1000*self.advr_main.advr_mag_absent;}if(self.advr_off){self.advr_off.advr_needs_charge=parm27<-1500;parm27=parm27+2000*self.advr_off.advr_needs_charge;self.advr_off.advr_mag_absent=parm27<0;self.advr_off.wi_clip=parm27+1000*self.advr_off.advr_mag_absent;}
        if(self.advr_holster[0]){self.advr_holster[0].advr_needs_charge=parm28<-1500;parm28=parm28+2000*self.advr_holster[0].advr_needs_charge;self.advr_holster[0].advr_mag_absent=parm28<0;self.advr_holster[0].wi_clip=parm28+1000*self.advr_holster[0].advr_mag_absent;}if(self.advr_holster[1]){self.advr_holster[1].advr_needs_charge=parm29<-1500;parm29=parm29+2000*self.advr_holster[1].advr_needs_charge;self.advr_holster[1].advr_mag_absent=parm29<0;self.advr_holster[1].wi_clip=parm29+1000*self.advr_holster[1].advr_mag_absent;}
        if(self.advr_holster[2]){self.advr_holster[2].advr_needs_charge=parm30<-1500;parm30=parm30+2000*self.advr_holster[2].advr_needs_charge;self.advr_holster[2].advr_mag_absent=parm30<0;self.advr_holster[2].wi_clip=parm30+1000*self.advr_holster[2].advr_mag_absent;}if(self.advr_holster[3]){self.advr_holster[3].advr_needs_charge=parm31<-1500;parm31=parm31+2000*self.advr_holster[3].advr_needs_charge;self.advr_holster[3].advr_mag_absent=parm31<0;self.advr_holster[3].wi_clip=parm31+1000*self.advr_holster[3].advr_mag_absent;}
        if(self.advr_holster[4]){self.advr_holster[4].advr_needs_charge=parm32<-1500;parm32=parm32+2000*self.advr_holster[4].advr_needs_charge;self.advr_holster[4].advr_mag_absent=parm32<0;self.advr_holster[4].wi_clip=parm32+1000*self.advr_holster[4].advr_mag_absent;}if(self.advr_holster[5]){self.advr_holster[5].advr_needs_charge=parm33<-1500;parm33=parm33+2000*self.advr_holster[5].advr_needs_charge;self.advr_holster[5].advr_mag_absent=parm33<0;self.advr_holster[5].wi_clip=parm33+1000*self.advr_holster[5].advr_mag_absent;}
    }
    ADVR_AmmoRestore();ADVR_Sync();
};
void() SetNewParms = {
    local float ai;for(ai=0;ai<18;ai=ai+1){if(advr_ammo_parm[ai])strunzone(advr_ammo_parm[ai]);advr_ammo_parm[ai]="";}
    ADVR_AD_SetNewParms();
    parm40=parm41=parm42=parm43=parm44=0;
    parm45=parm46=parm47=parm48=parm49=parm50=parm51=parm52=0;
    parm17=parm18=parm19=parm20=parm21=parm22=parm23=parm24=parm25=0;
    parm26=parm27=parm28=parm29=parm30=parm31=parm32=parm33=parm34=parm35=parm36=parm37=parm38=parm39=0;
};
void() SetChangeParms = {
    ADVR_RuneClear();ADVR_ElderEnd();
    ADVR_ManualRefund();
    ADVR_AD_SetChangeParms();
    if(self.health>0)ADVR_SaveParms();
};
void() PutClientInServer = {
    ADVR_Reset();ADVR_AD_PutClientInServer();ADVR_LoadParms();
};

void(float condition,string message) ADVR_Assert = {
    if(!condition) {bprint("ADVR TEST FAIL: ");bprint(message);bprint("\n");error(message);}
};
// Integration fixtures use AD's real damage and pickup functions.
void() ADVR_TestContact = {
    local entity p,player;
    local float health_before;
    player=self;
    ADVR_Select(IT_AXE);ADVR_Sync();
    self.handpos=self.origin+self.view_ofs;self.handrot='0 0 0';self.handvel='3 0 0';
    self.mainhand_melee_attack_finished=0;self.advr_prevmain_time=0;
    p=spawn();p.classname="advr_test_target";p.classtype=CT_TARGETDUMMY;
    p.movetype=MOVETYPE_NONE;p.solid=SOLID_BBOX;p.takedamage=DAMAGE_YES;p.health=500;
    setsize(p,'-4 -4 -4','4 4 4');setorigin(p,self.handpos+'18 0 0');
    ADVR_Melee(1);
    ADVR_Assert(p.health<500,"physical axe uses AD damage");health_before=p.health;
    ADVR_Melee(1);ADVR_Assert(p.health==health_before,"melee cooldown");remove(p);
    self.handvel='0 0 0';self.health=50;self.max_health=100;
    p=spawn();self=p;item_health();self=player;
    p.think=SUB_Null;p.nextthink=0;p.flags=p.flags|FL_ITEM;p.solid=SOLID_TRIGGER;
    p.touch=health_touch;p.noise=SOUND_EMPTY;p.healamount=25;
    setsize(p,'-4 -4 -4','4 4 4');setorigin(p,self.handpos);
    ADVR_Touch(1);ADVR_Assert(self.health==75,"hand health pickup executes AD callback");
    ADVR_Select(IT_SUPER_SHOTGUN);ADVR_Sync();
};
// Regression: loaded rounds belong to each record, while AD's ammo stays total carried.
void() ADVR_TestReload = {
    local entity r,p;local float mode,total;
    mode=cvar("vr_reload_mode");cvar_set("vr_reload_mode","2");
    ADVR_Reset();self.moditems=self.moditems-(self.moditems & IT_UPGRADE_SSG);
    self.items=self.items | IT_AXE | IT_SHOTGUN | IT_SUPER_SHOTGUN;
    self.ammo_shells=12;self.weapon=IT_SHOTGUN;self.vrbits0=16384;
    self.mainhand_hotspot=self.offhand_hotspot=0;self.button0=self.button3=0;ADVR_Frame();
    self.advr_off=ADVR_Record(IT_SUPER_SHOTGUN);ADVR_Sync();
    r=self.advr_main;
    ADVR_Assert(r.wi_clip==8 && self.advr_off.wi_clip==2,"separate initial magazines");
    self.muzzlepos=self.offmuzzlepos=self.origin+self.view_ofs;self.shotrot=self.offshotrot='-80 0 0';
    self.button0=1;ADVR_Fire(1);self.button0=0;
    ADVR_Assert(r.wi_clip==7 && self.ammo_shells==11,"shot consumes one loaded and total round");
    self.ammo_shells=self.ammo_shells-r.wi_clip;r.wi_clip=0;r.advr_animtime=0;r.advr_cooldown=0;
    total=self.ammo_shells;self.button0=1;ADVR_Fire(1);self.button0=0;
    ADVR_Assert(self.ammo_shells==total,"empty magazine cannot fire reserve");
    self.vrbits0=16384|256;ADVR_ReloadFrame(1);
    ADVR_Assert(r.wi_clip==2 && self.advr_off.wi_clip==2 && self.ammo_shells==4,"reload button uses only unallocated rounds");
    r.advr_reload_until=0;ADVR_Reload(1);
    ADVR_Assert(r.wi_clip==2 && self.ammo_shells==4,"reload cannot duplicate ammo");
    self.handpos=self.origin+self.view_ofs;self.handthrowvel='0 0 0';
    ADVR_Drop(1);p=find(world,classname,"advr_dropped_weapon");
    while(p && p.weaponinst!=r)p=find(p,classname,"advr_dropped_weapon");
    ADVR_Assert(self.ammo_shells==2 && p.weaponinst.wi_clip==2,"drop transfers loaded ammo out of inventory");
    ADVR_Catch(p,1);
    ADVR_Assert(self.ammo_shells==4 && self.advr_main==r && r.wi_clip==2,"catch restores same loaded rounds");
    ADVR_SaveParms();ADVR_Reset();ADVR_LoadParms();r=self.advr_main;
    ADVR_Assert(r.wi_clip==2 && self.advr_off.wi_clip==2,"transition preserves partial magazines");
    self.ammo_shells=12;r.wi_clip=self.advr_off.wi_clip=0;
    r.advr_reload_until=self.advr_off.advr_reload_until=0;
    self.vrbits0=16384|64;ADVR_ReloadFrame(0);
    ADVR_Assert(self.advr_off.wi_clip==2,"offhand reload button");
    self.mainhand_hotspot=5;self.vrbits0=16384;ADVR_ReloadFrame(1);
    ADVR_Assert(r.wi_clip==8,"hip holster proximity reload");
    self.mainhand_hotspot=0;self.advr_off.wi_clip=0;self.advr_off.advr_reload_until=0;
    self.vrbits0=16384|1024;ADVR_ReloadFrame(0);
    ADVR_Assert(self.advr_off.wi_clip==2,"double barrel flick reload");
    cvar_set("vr_reload_mode","0");r.wi_clip=0;r.advr_reload_until=r.advr_cooldown=r.advr_animtime=0;
    total=self.ammo_shells;self.button0=1;ADVR_Fire(1);self.button0=0;
    ADVR_Assert(self.ammo_shells==total-1,"disabled reload retains reserve firing");
    cvar_set("vr_reload_mode",ftos(mode));self.vrbits0=16384;
    bprint("ADVR RELOAD PASS: magazines, buttons, hip/flick, empty lockout, ammo conservation, drop/catch and persistence\n");
};
// Exercise every native ranged attack and AD's two ranged upgrades in both hands.
void() ADVR_TestWeapons = {
    local float w,h,j,ammo,mods;
    local entity r;
    mods=self.moditems;self.items=self.items | 127 | IT_AXE;
    self.muzzlepos=self.offmuzzlepos=self.origin+self.view_ofs;
    self.shotrot=self.offshotrot='-80 0 0';
    self.button0=self.button3=1;
    for(h=0;h<2;h=h+1) for(w=1;w<=64;w=w*2) {
        self.ammo_shells=self.ammo_nails=self.ammo_rockets=self.ammo_cells=100;
        r=ADVR_Record(w);ADVR_SetHand(h,r);ammo=ADVR_Ammo(w);
        ADVR_Fire(h);
        for(j=0;j<3 && ADVR_Ammo(w)==ammo && r.advr_animtime>0;j=j+1) {
            r.advr_animtime=time;ADVR_Fire(h);
        }
        ADVR_Assert(ADVR_Ammo(w)<ammo,"native ranged attack consumes ammo");
    }
    self.moditems=self.moditems | IT_UPGRADE_SSG | IT_UPGRADE_LG;
    for(h=0;h<2;h=h+1) for(w=2;w<=64;w=w*32) {
        self.ammo_shells=self.ammo_cells=100;
        r=ADVR_Record(w);ADVR_SetHand(h,r);ammo=ADVR_Ammo(w);ADVR_Fire(h);
        for(j=0;j<3 && ADVR_Ammo(w)==ammo && r.advr_animtime>0;j=j+1) {
            r.advr_animtime=time;ADVR_Fire(h);
        }
        ADVR_Assert(ADVR_Ammo(w)<ammo,"AD upgraded attack consumes ammo");
    }
    self.moditems=mods;self.button0=self.button3=0;
    bprint("ADVR WEAPONS PASS: seven ranged weapons and two AD upgrades, both hands\n");
};
void() ADVR_TestHolsterHaptics = {
    local float mode;
    local entity held;
    mode=cvar("vr_holster_haptics");cvar_set("vr_holster_haptics","2");
    self.mainhand_hotspot=self.offhand_hotspot=3;
    ADVR_Assert(ADVR_HolsterHaptic(1),"haptic on main hand entering holster");
    ADVR_Assert(!ADVR_HolsterHaptic(1),"haptic once while hovering");
    ADVR_Assert(ADVR_HolsterHaptic(0),"independent off hand haptic");
    self.mainhand_hotspot=0;
    ADVR_Assert(!ADVR_HolsterHaptic(1),"no haptic outside holster");
    self.mainhand_hotspot=3;
    ADVR_Assert(ADVR_HolsterHaptic(1),"haptic on reentry");
    self.mainhand_hotspot=4;
    ADVR_Assert(ADVR_HolsterHaptic(1),"haptic on different holster");
    held=self.advr_main;self.advr_main=world;
    ADVR_Assert(!ADVR_HolsterHaptic(1),"no haptic with empty hand and holster");
    self.advr_holster[1]=held;
    ADVR_Assert(ADVR_HolsterHaptic(1),"haptic when drawing stored weapon");
    self.advr_holster[1]=world;self.advr_main=held;
    cvar_set("vr_holster_haptics","0");
    ADVR_Assert(!ADVR_HolsterHaptic(1),"haptics disabled");
    cvar_set("vr_holster_haptics","1");
    ADVR_Assert(ADVR_HolsterHaptic(1),"continuous haptic starts");
    ADVR_Assert(!ADVR_HolsterHaptic(1),"continuous haptic throttled");
    self.advr_hover_next[1]=time;
    ADVR_Assert(ADVR_HolsterHaptic(1),"continuous haptic repeats");
    cvar_set("vr_holster_haptics",ftos(mode));
    self.mainhand_hotspot=self.offhand_hotspot=0;
    ADVR_ManualFrame();
    ADVR_HolsterHaptic(1);ADVR_HolsterHaptic(0);
    bprint("ADVR HAPTICS PASS: entry, reentry, both hands, empty slots, disabled and continuous\n");
};
void() ADVR_Test = {
    local entity mainrec,offrec,p;
    local float shells,i,mask;
    local vector org;
    self.flags=self.flags | FL_GODMODE; // Projectile fixtures must not kill the test player later.
    ADVR_TestReload();
    ADVR_TestWeapons();
    ADVR_Reset();self.items=self.items | IT_AXE | IT_SHOTGUN | IT_SUPER_SHOTGUN;
    self.ammo_shells=30;self.weapon=IT_SHOTGUN;self.vrbits0=16384;
    self.button0=self.button3=self.impulse=0;
    ADVR_Frame();
    ADVR_Assert(self.advr_main.advr_weapon==IT_SHOTGUN,"main initialization");
    ADVR_Assert(self.advr_off.advr_weapon==IT_AXE,"off initialization");
    ADVR_TestHolsterHaptics();
    // Selecting the off-hand weapon swaps real records, without making copies.
    mainrec=self.advr_main;offrec=self.advr_off;
    ADVR_Select(IT_AXE);
    ADVR_Assert(self.advr_main==offrec && self.advr_off==mainrec,"hand swap identity");
    ADVR_Select(IT_SUPER_SHOTGUN);ADVR_Sync();
    ADVR_Assert(self.advr_main.advr_weapon==IT_SUPER_SHOTGUN,"new weapon selection");
    ADVR_Assert(self.advr_holster[0]==offrec,"old weapon stored");
    // Both AD attack routines spend the shared ammo exactly once.
    self.muzzlepos=self.offmuzzlepos=self.origin+self.view_ofs;
    self.shotrot=self.offshotrot=self.v_angle;
    self.button0=self.button3=1;org=self.origin;shells=self.ammo_shells;
    ADVR_Fire(1);ADVR_Fire(0);ADVR_Sync();
    ADVR_Assert(self.ammo_shells==shells-3,"dual firing ammo");
    ADVR_Assert(self.origin==org,"body restored after firing");
    ADVR_Fire(1);ADVR_Fire(0);
    ADVR_Assert(self.ammo_shells==shells-3,"independent cooldowns");
    self.button0=self.button3=0;
    // Release over a hip stores the record; pressing there draws that same one.
    mainrec=self.advr_main;self.mainhand_hotspot=5;self.vrbits0=16384|16;
    ADVR_GripFrame(1);ADVR_Sync();
    ADVR_Assert(!self.advr_main && self.advr_holster[2]==mainrec,"holster store");
    ADVR_Assert(self.weaponmodel=="progs/hand.mdl","holstering preserves visible empty main hand");
    offrec=self.advr_off;self.advr_off=world;ADVR_Sync();
    ADVR_Assert(self.weaponmodel2=="progs/hand.mdl" && !self.weapon2,"visible empty off hand");
    self.advr_off=offrec;ADVR_Sync();
    self.vrbits0=16384|8;ADVR_GripFrame(1);ADVR_Sync();
    ADVR_Assert(self.advr_main==mainrec && !self.advr_holster[2],"holster draw");
    self.handpos=self.origin+self.view_ofs;self.handthrowvel='2 0 0';
    ADVR_Drop(1);ADVR_Sync();
    p=find(world,classname,"advr_dropped_weapon");
    while(p && p.weaponinst!=mainrec)p=find(p,classname,"advr_dropped_weapon");
    ADVR_Assert(p && p.weaponinst==mainrec && !self.advr_main,"throw transfers record");
    ADVR_Assert(self.weaponmodel=="progs/hand.mdl","dropping preserves visible empty hand");
    ADVR_Assert(p.model==ADVR_Model(mainrec.advr_weapon,0),"dropped weapon uses calibrated held mesh");
    ADVR_Assert(vlen(p.velocity)>40,"throw metres conversion");
    self.handrot='0 0 0';setorigin(p,self.handpos+'12 0 0');
    ADVR_Catch(p,1);ADVR_Sync();
    ADVR_Assert(self.advr_main==mainrec,"catch preserves identity");
    ADVR_TestContact();
    ADVR_SaveParms();ADVR_Reset();ADVR_LoadParms();
    ADVR_Assert(self.advr_main.advr_weapon==IT_SUPER_SHOTGUN && self.advr_off.advr_weapon==IT_SHOTGUN,"map hand inventory");
    ADVR_Assert(self.advr_holster[0].advr_weapon==IT_AXE,"map holster inventory");
    self.vrbits0=16384;self.mainhand_hotspot=0;
    bprint("ADVR TEST PASS: hands, firing, cooldowns, holsters, throw/force-grab, melee, health pickup, transition inventory\n");
};


void() ADVR_CheckState = {
    dprint("ADVR STATE ");dprint(ftos(self.advr_main.advr_weapon));dprint(" ");dprint(ftos(self.advr_off.advr_weapon));dprint(" items ");dprint(ftos(self.items));dprint("\n");
    ADVR_Assert(self.advr_initialized,"state initialized");
    ADVR_Assert(self.advr_main.wi_clip==0,"empty magazine preserved through save/map");
    ADVR_Assert(self.advr_main.advr_weapon==IT_SUPER_SHOTGUN,"state main weapon");
    // AD maps may deliberately strip a starting weapon. Preserve that rule.
    if(world.take_weapons & IT_SHOTGUN) ADVR_Assert(!self.advr_off,"map removes off-hand shotgun");
    else {
        ADVR_Assert(self.advr_off.advr_weapon==IT_SHOTGUN,"state off weapon");
        ADVR_Assert(self.advr_off.wi_clip==7,"partial offhand magazine preserved by save/load");
    }
    ADVR_Assert(self.advr_holster[0].advr_weapon==IT_AXE,"state holster weapon");
    ADVR_Assert(self.weaponinst==self.advr_main && self.weaponinst2==self.advr_off,"state network references");
    bprint("ADVR STATE PASS: hands and holster preserved\n");
};

// Disposable developer fixtures for testing the real input/render path.
void() ADVR_TestUpgrades = {
    ADVR_Reset();self.items=self.items | IT_AXE | IT_SUPER_SHOTGUN | IT_LIGHTNING;
    self.moditems=self.moditems | IT_UPGRADE_AXE | IT_UPGRADE_SSG | IT_UPGRADE_LG;
    self.ammo_shells=30;self.ammo_cells=50;
    self.advr_initialized=1;self.advr_main=ADVR_Record(IT_SUPER_SHOTGUN);self.advr_off=ADVR_Record(IT_AXE);
    ADVR_Sync();
    ADVR_Assert(self.advr_main.wi_clip==24,"Widowmaker has 24-round capacity");
    ADVR_Assert(self.weaponmodel=="progs/advr_widowmaker.mdl" && self.weaponmodel2=="progs/advr_shadowaxe.mdl","distinct upgraded models");
};
void() ADVR_TestPlasma = {
    self.items=self.items | IT_LIGHTNING;self.moditems=self.moditems | IT_UPGRADE_LG;self.ammo_cells=50;
    self.advr_main=ADVR_Record(IT_LIGHTNING);ADVR_Sync();
    ADVR_Assert(self.weaponmodel=="progs/advr_plasma.mdl","distinct plasma model");
};

void() ADVR_TestInput = {
    self.health=100;self.flags=self.flags | FL_GODMODE;
    ADVR_Reset();self.items=self.items | IT_SHOTGUN;self.ammo_shells=12;
    self.advr_initialized=1;self.advr_main=ADVR_Record(IT_SHOTGUN);self.advr_off=ADVR_Record(IT_SHOTGUN);
    self.advr_main.wi_clip=self.advr_off.wi_clip=1;ADVR_Sync();
};
void() ADVR_TestInputState = {
    dprint("ADVR INPUT state clips ");dprint(ftos(self.advr_main.wi_clip));dprint("/");dprint(ftos(self.advr_off.wi_clip));
    dprint(" ammo ");dprint(ftos(self.ammo_shells));dprint(" health ");dprint(ftos(self.health));dprint("\n");
    ADVR_Assert(self.ammo_shells==8 && self.advr_main.wi_clip==7 && self.advr_off.wi_clip==1,"controller firing and reloading both hands");
    bprint("ADVR INPUT PASS: both controller triggers and reload buttons, correct magazines and total ammo\n");
};

void() ADVR_TestUnload = {
    local float total;
    ADVR_Reset();self.advr_initialized=1;self.health=100;self.vrbits0=16384;
    cvar_set("vr_reload_mode","1");
    // Unloading returns reservations, not duplicate ammo, and does not touch the other gun.
    self.advr_main=ADVR_Record(IT_SHOTGUN);self.advr_off=ADVR_Record(IT_SHOTGUN);
    self.ammo_shells=20;self.advr_main.wi_clip=8;self.advr_off.wi_clip=4;
    total=self.ammo_shells;ADVR_Unload(1);
    ADVR_Assert(self.advr_main.wi_clip==0 && self.advr_off.wi_clip==4 && self.ammo_shells==total,"unload releases only requested magazine without duplicating ammo");
    ADVR_Unload(1);ADVR_Assert(self.ammo_shells==total,"empty unload cannot grant ammo");
    ADVR_Unload(0);ADVR_Assert(self.advr_off.wi_clip==0 && self.ammo_shells==total,"off-hand magazine unloads");
    self.advr_main.advr_reload_until=0;ADVR_Reload(1);
    ADVR_Assert(self.advr_main.wi_clip==8 && self.ammo_shells==total,"unloaded rounds can be reloaded without changing total");
    self.advr_main.advr_kind=ADVR_CROSSBOW;self.advr_main.wi_clip=1;self.advr_bolts=12;
    ADVR_Unload(1);ADVR_Unload(1);
    ADVR_Assert(self.advr_main.wi_clip==0 && self.advr_bolts==13,"crossbow returns its bolt exactly once");

    bprint("ADVR UNLOAD PASS: both hands, ammo conservation, empty repeat, reload and crossbow refund\n");
};
