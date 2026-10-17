// Void: homing explosive orb, with deferred mutation after damage has finished.
void(float kind) ADVR_VoidSpawn = {
    if(kind==0){self.classname="monster_demon1";monster_demon1();}
    else if(kind==1){self.classname="monster_voreling";monster_voreling();}
    else if(kind==2){self.classname="monster_spider";monster_spider();}
    else if(kind==3){self.classname="monster_shalrath";monster_shalrath();}
    else if(kind==4){self.classname="monster_drole";monster_drole();}
    else if(kind==5){self.classname="monster_zombie";monster_zombie();}
    else if(kind==6){self.classname="monster_gaunt";monster_gaunt();}
    else {self.classname="monster_gargoyle";monster_gargoyle();}
};
void() ADVR_VoidPrecache = {
    local entity saved,e;local float i,total;
    saved=self;total=total_monsters;
    for(i=0;i<8;i=i+1){e=spawn();self=e;self.nomonstercount=1;ADVR_VoidSpawn(i);remove(e);}
    self=saved;total_monsters=total;
};
float(entity v) ADVR_VoidEligible = {
    return v && (v.flags & FL_MONSTER) && v.health>0 && v.takedamage && !v.deadflag &&
        !v.bossflag && !v.spawnstatue && v.classmove!=MON_MOVESTATIC &&
        !v.targetname && !v.target && !v.target2 && !v.target3 && !v.target4 && !v.deathtarget &&
        !v.turrettarget && !v.turrettarget2 && !v.counttarget && !v.killtarget;
};
// Build a fresh native monster, test its hull, and only then retire the old one.
// Never run death callbacks or pay drops/mana for the transformation itself.
entity(entity v,entity attacker,float first) ADVR_VoidTransform = {
    local entity saved,n;local float i,total,oldsolid,ratio;
    if(!ADVR_VoidEligible(v))return world;
    saved=self;total=total_monsters;oldsolid=v.solid;ratio=bound(0.05,v.health/max(1,v.max_health),1);
    for(i=0;i<8;i=i+1) {
        n=spawn();self=n;setorigin(n,v.origin);n.angles=v.angles;n.nomonstercount=1;
        ADVR_VoidSpawn(mod(first+i,8));total_monsters=total;
        if(n.classtype==v.classtype){remove(n);continue;}
        setmodel(n,n.mdl);setsize(n,n.bbmins,n.bbmaxs);n.solid=SOLID_SLIDEBOX;n.movetype=MOVETYPE_STEP;
        if(n.classmove==MON_MOVEFLY)n.flags=n.flags | FL_FLY;
        v.solid=SOLID_NOT;setorigin(v,v.origin);
        tracebox(n.origin,n.mins,n.maxs,n.origin,FALSE,n);
        if(trace_startsolid || trace_allsolid){v.solid=oldsolid;setorigin(v,v.origin);remove(n);continue;}
        n.health=max(1,n.max_health*ratio);n.nomonstercount=v.nomonstercount;
        n.enemy=attacker;n.oldorigin=n.origin;
        monster_spawn();
        n.enemy=attacker;n.goalentity=attacker;n.think=FoundTarget;n.nextthink=time+0.1;
        n.advr_mana_paid=v.advr_mana_paid;
        if(v.advr_burn)ADVR_FireOut(v.advr_burn);
        if(v.advr_acid){remove(v.advr_acid);v.advr_acid=world;}
        // Visual-only burst through the existing physics-gib adapter. No death callbacks.
        self=v;self.health=-60;self.gib1dmg=0;self.gib1exp=0;
        ADVR_Blood(v,v.origin+'0 0 12','0 0 100',50);
        ThrowGib(1,2);ThrowGib(2,1);ThrowGib(3,2);ThrowGib(4,4);
        sound(v,CHAN_VOICE,GIB_SOUND_UDEATH,0.8,ATTN_NORM);
        sound(n,CHAN_AUTO,"misc/r_tele1.wav",0.7,ATTN_NORM);
        remove(v);self=saved;return n;
    }
    self=saved;return world;
};
void() ADVR_VoidTransformThink = {
    local entity v;
    v=self.enemy;
    if(v && v.advr_void_pending==self) {
        v.advr_void_pending=world;
        ADVR_VoidTransform(v,self.owner,floor(random()*8));
    }
    remove(self);
};
void(entity target,entity attacker,float roll) ADVR_VoidRoll = {
    local entity job;
    if(!ADVR_VoidEligible(target) || target.advr_void_pending || time<target.advr_void_rolltime)return;
    // A multi-pellet impact gets one roll, not one roll per pellet.
    target.advr_void_rolltime=time+0.1;
    if(roll>=0.05)return;
    job=spawn();job.classname="advr_void_transform";job.enemy=target;job.owner=attacker;
    job.think=ADVR_VoidTransformThink;job.nextthink=time+0.01;target.advr_void_pending=job;
};
entity(vector at,vector aim,entity shooter) ADVR_VoidTarget = {
    local entity e,best;local vector delta;local float distance,nearest;
    nearest=1500;e=world;
    while((e=nextent(e))) {
        if(!(e.flags & FL_MONSTER) || e.health<=0 || !e.takedamage || e==shooter)continue;
        delta=modelcentre(e)-at;distance=vlen(delta);
        if(distance>=nearest || (vlen(aim)>0 && normalize(delta)*aim<0.82))continue;
        traceline(at,modelcentre(e),FALSE,shooter);
        if(trace_fraction<1 && trace_ent!=e)continue;
        best=e;nearest=distance;
    }
    return best;
};
void() ADVR_VoidThink = {
    local vector direction;
    if(time>=self.attack_finished){remove(self);return;}
    if(!self.enemy || self.enemy.health<=0 || !(self.enemy.flags & FL_MONSTER))
        self.enemy=ADVR_VoidTarget(self.origin,normalize(self.velocity),self.owner);
    if(self.enemy) {
        direction=normalize(modelcentre(self.enemy)-self.origin);
        self.velocity=normalize(normalize(self.velocity)*0.65+direction*0.35)*500;
        self.angles=vectoangles(self.velocity);
    }
    self.nextthink=time+0.05;
};
void() ADVR_VoidTouch = {
    local entity e,hit;local float damage;
    hit=other;
    if(other==self.owner)return;
    if(pointcontents(self.origin)==CONTENT_SKY){remove(self);return;}
    // Direct victim gets 40; nearby monsters get radial falloff, once each.
    e=world;
    while((e=nextent(e))) {
        if(!(e.flags & FL_MONSTER) || e.health<=0 || !e.takedamage)continue;
        damage=40*(1-vlen(modelcentre(e)-self.origin)/120);
        if(e==hit)damage=40;
        if(damage<=0)continue;
        traceline(self.origin,modelcentre(e),FALSE,self);
        if(trace_fraction<1 && trace_ent!=e)continue;
        T_Damage(e,self,self.owner,damage*max(1,self.advr_magic_damage),NOARMOR);
    }
    particle(self.origin,'0 0 40',46,100);
    sound(self,CHAN_WEAPON,"weapons/r_exp3.wav",0.7,ATTN_NORM);remove(self);
};
void(vector at,vector direction,vector aim) ADVR_VoidLaunch = {
    newmis=spawn();newmis.classname="advr_voidorb";newmis.owner=self;newmis.advr_voidorb=1;
    newmis.solid=SOLID_BBOX;newmis.movetype=MOVETYPE_FLYMISSILE;
    newmis.velocity=normalize(direction)*500;newmis.angles=vectoangles(newmis.velocity);
    newmis.touch=ADVR_VoidTouch;newmis.think=ADVR_VoidThink;newmis.nextthink=time+0.05;
    newmis.attack_finished=time+8;newmis.advr_magic_damage=ADVR_MagicMultiplier();
    setmodel(newmis,MODEL_PROJ_SHAL);setsize(newmis,'0 0 0','0 0 0');setorigin(newmis,at);
    newmis.enemy=ADVR_VoidTarget(at,aim,self);
};

// A separate controller preserves native missile think/fuse/trail behavior.
void() ADVR_VoidHomingThink = {
    local entity missile,target;local float speed;
    missile=self.enemy;
    if(!missile || missile.advr_homing_controller!=self || missile.advr_enchant_type!=5 ||
       time>=missile.advr_enchant_until || missile.solid==SOLID_NOT) {
        if(missile && missile.advr_homing_controller==self)missile.advr_homing_controller=world;
        remove(self);return;
    }
    speed=vlen(missile.velocity);
    if(speed>1) {
        target=ADVR_VoidTarget(missile.origin,'0 0 0',missile.owner);
        if(target) {
            missile.velocity=normalize(normalize(missile.velocity)*0.8+normalize(modelcentre(target)-missile.origin)*0.2)*speed;
            if(missile.movetype==MOVETYPE_FLY || missile.movetype==MOVETYPE_FLYMISSILE)missile.angles=vectoangles(missile.velocity);
        }
    }
    self.nextthink=time+0.05;
};
void(entity missile) ADVR_VoidHoming = {
    local entity controller;
    if(missile.advr_enchant_type!=5 || missile.advr_homing_controller)return;
    controller=spawn();controller.classname="advr_void_homing";controller.enemy=missile;
    missile.advr_homing_controller=controller;controller.think=ADVR_VoidHomingThink;controller.nextthink=time+0.01;
};
void(entity r) ADVR_VoidRestore = {
    local entity prop;
    if(!r || !r.advr_void_original)return;
    r.advr_kind=r.advr_void_original-1;r.advr_void_original=0;r.advr_frame=0;r.advr_anim=SUB_Null;r.advr_animtime=0;
    r.think=SUB_Null;r.nextthink=0;
    prop=find(world,classname,"advr_dropped_weapon");
    while(prop){if(prop.weaponinst==r){setmodel(prop,ADVR_RecordModel(r));prop.frame=0;}prop=find(prop,classname,"advr_dropped_weapon");}
};
void() ADVR_VoidWeaponThink = { ADVR_VoidRestore(self); };
void(entity r) ADVR_VoidWeapon = {
    local float choice,kind,previous;
    if(!ADVR_CanParry(r))return;
    previous=r.advr_kind;if(!previous)previous=ADVR_AXE;
    choice=floor(random()*7);
    while(1) {
        if(choice==0)kind=ADVR_AXE;else if(choice==1)kind=ADVR_SHADOWAXE;
        else if(choice==2)kind=ADVR_SWORD;else if(choice==3)kind=ADVR_HELLSWORD;
        else if(choice==4)kind=ADVR_HAMMER;else if(choice==5)kind=ADVR_FURY1;else kind=ADVR_FURY2;
        if(kind!=previous)break;choice=mod(choice+1,7);
    }
    sound(self,CHAN_AUTO,"misc/r_tele1.wav",0.6,ATTN_NORM);
    r.advr_void_original=r.advr_kind+1;r.advr_kind=kind;r.advr_frame=0;r.advr_anim=SUB_Null;r.advr_animtime=0;
    r.think=ADVR_VoidWeaponThink;r.nextthink=r.advr_enchant_until;
};
