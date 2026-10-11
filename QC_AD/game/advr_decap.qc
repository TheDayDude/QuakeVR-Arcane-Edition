// The hit context is consumed by one T_Damage call, never carried by a timestamp.
void() ADVR_HitClear = {advr_hit_ent=advr_hit_by=world;advr_hit_kind=0;};
float(entity target,entity attacker,vector at,vector dir,float damage) ADVR_MeleeHeadDamage = {
    damage=ADVR_HeadDamage(target,attacker,at,dir,damage);
    if(advr_hit_ent==target && advr_hit_by==attacker)advr_hit_kind=2;
    return damage;
};
float(entity e) ADVR_DecapAllowed = {
    return cvar("vr_decap") && cvar("vr_ragdoll") && (e.flags & FL_MONSTER) &&
        !e.vr_headless && !e.gibbed && e.headmdl!="" && e.gibtype==GIBTYPE_BLOOD &&
        e.classgroup!=CG_ROBOT && e.classgroup!=CG_STONE && !e.spawnstatue && !e.poisonous &&
        (!e.bleedcolour || e.bleedcolour==MON_BCOLOR_RED) && canragdoll(e);
};
void(vector at,vector vel) ADVR_HeadBurst = {
    local vector d;local float i;
    // Original QuakeVR's blood mist and directional gore particle presets.
    for(i=0;i<3;i=i+1) {
        d_x=crandom()*6;d_y=crandom()*6;d_z=crandom()*6;
        particle2(at+d,d*0.5,1,18);
    }
    for(i=0;i<4;i=i+1) {
        d_x=crandom();d_y=crandom();d_z=crandom()*0.7;
        particle2(at,normalize(d)*22,1,12);
    }
    particle2(at,normalize(vel)*20,1,20);
    if(cvar("vr_gore"))particle2(at,normalize(vel)*7,41,15);
};
void() ADVR_NeckThink = {
    local entity c;local vector at,dir;
    c=self.owner;
    if(!c || !c.vr_headless || c.gibbed || !isragdoll(c) || time>=self.ltime){remove(self);return;}
    at=ragdollcut(c,4);dir=ragdollcut(c,5);
    particle2(at,dir*12+'0 0 3',1,3);
    self.nextthink=time+0.1;
};
void() ADVR_DecapDeath = {
    local entity h,fx;local vector at;
    if(!self.advr_decap_kind || self.advr_decap_done)return;
    self.advr_decap_done=1;
    // AD still owns full-body overkills. Their normal head drop is suppressed
    // for ranged head pops, and retained once for melee overkills.
    if(self.gibbed) {
        if(self.advr_decap_kind==1)ADVR_HeadBurst(self.advr_decap_at,self.advr_decap_vel);
        return;
    }
    ADVR_CorpseReady();
    if(!ragdolldecap(self,self.advr_decap_vel,1)){self.advr_decap_kind=0;return;}
    at=ragdollcut(self,0);
    if(self.advr_decap_kind==1)ADVR_HeadBurst(at,self.advr_decap_vel);
    else {
        h=spawn();h.classname="item_gib";h.classtype=CT_TEMPGIB;h.classgroup=CG_TEMPENT;
        h.owner=self;h.advr_severed_head=1;h.skin=self.skin;h.model_scale=self.model_scale;
        setmodel(h,self.headmdl);setorigin(h,at);h.angles=ragdollcut(self,1);
        h.velocity=ragdollcut(self,2);h.avelocity=ragdollcut(self,3)*57.29578;
        h.movetype=MOVETYPE_BOUNCE;h.solid=SOLID_TRIGGER;setsize(h,'0 0 0','0 0 0');
        h.pain_finished=time+GIB_FADETIME;h.nextthink=h.pain_finished;h.think=RemoveGib;h.touch=TouchGib;
        ADVR_GibSetup(h);h.vr_prop_mass=0.8;
        particle2(at,normalize(self.advr_decap_vel)*15,1,24);
    }
    particle2(ragdollcut(self,4),ragdollcut(self,5)*12,1,20);
    fx=spawn();fx.classname="advr_neck_blood";fx.owner=self;
    fx.ltime=time+bound(0,cvar("vr_decap_fountain"),3);fx.think=ADVR_NeckThink;fx.nextthink=time+0.1;
};
