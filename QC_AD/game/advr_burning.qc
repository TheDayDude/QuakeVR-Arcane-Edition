// Monster-burning adapter for QuakeVR's flame models, scorch wounds and settings.
// AD retains ownership of AI, resistance, death callbacks and kill attribution.
void(entity fire) ADVR_FireOut = {
    local entity fl,next;
    if(fire.enemy.advr_burn==fire)fire.enemy.advr_burn=world;
    fl=fire.advr_fire_flames;
    while(fl){next=fl.advr_fire_next;remove(fl);fl=next;}
    remove(fire);
};
float(entity v) ADVR_FireWet = {
    local float contents;
    contents=pointcontents(modelcentre(v));
    return contents==CONTENT_WATER || contents==CONTENT_SLIME ||
        (v.waterlevel>=2 && (v.watertype==CONTENT_WATER || v.watertype==CONTENT_SLIME));
};
vector(entity v,vector offset) ADVR_FirePoint = {
    local vector mid,at;local float fraction;
    mid=modelcentre(v);at=mid+offset;
    // Refit against the drawn mesh, including animated corpses and ragdolls.
    fraction=hitmodel_any(v,at,mid,2);
    if(fraction>=0)return at+(mid-at)*fraction;
    return mid+normalize(offset)*4;
};
void(entity fire) ADVR_FireAdd = {
    local entity fl;local vector offset;
    fl=spawn();fl.classname="vr_burn_flame";fl.owner=fire;
    fl.movetype=MOVETYPE_NONE;fl.solid=SOLID_NOT;
    setmodel(fl,"progs/flame2.mdl");
    offset_x=crandom()*48;offset_y=crandom()*48;offset_z=12+random()*32;
    fl.advr_fire_offset=offset;
    fl.scale=max(0.05,cvar("vr_burn_flame_size"));
    if(fire.advr_fire_count){fl.scale=fl.scale*max(0.05,cvar("vr_burn_flame_small"));fl.alpha=1;}
    fl.angles_y=random()*360;
    setorigin(fl,ADVR_FirePoint(fire.enemy,offset));
    fl.advr_fire_next=fire.advr_fire_flames;fire.advr_fire_flames=fl;
    fire.advr_fire_count=fire.advr_fire_count+1;
};
void() ADVR_FireThink = {
    local entity v,fl;local vector at;local float tick;
    v=self.enemy;
    if(!v || v.advr_burn!=self || !v.modelindex || v.modelindex!=self.advr_fire_model ||
       !(v.flags & FL_MONSTER) || ADVR_FireWet(v) || time>=self.advr_fire_end) {
        ADVR_FireOut(self);return;
    }
    if(v.health<=0 && !self.advr_fire_dead) {
        if(!cvar("vr_burn_corpses")){ADVR_FireOut(self);return;}
        self.advr_fire_dead=1;self.advr_fire_end=time+max(0,cvar("vr_burn_corpse_time"));
    }
    tick=time>=self.advr_fire_tick;
    fl=self.advr_fire_flames;
    while(fl) {
        at=ADVR_FirePoint(v,fl.advr_fire_offset);setorigin(fl,at);
        // flame2 uses its model frame group; the original burn system keeps frame 0.
        if(tick) {
            particle2(at,'0 0 40',10,2);
            woundevent(v,at+normalize(fl.advr_fire_offset)*4,-normalize(fl.advr_fire_offset),5,20,1);
        }
        fl=fl.advr_fire_next;
    }
    if(time>=self.advr_fire_spread && self.advr_fire_count<bound(1,cvar("vr_burn_flames"),min(12,max(1,cvar("vr_burn_flames_max"))))) {
        ADVR_FireAdd(self);self.advr_fire_spread=time+max(0.1,cvar("vr_burn_spread"));
    }
    self.nextthink=time+0.1;
    if(tick) {
        self.advr_fire_tick=time+0.5;
        particle2(self.advr_fire_flames.origin,'0 0 20',4,2);
        // No corpse damage: AD owns its gib/death animation lifecycle.
        // NOARMOR bypasses headshots; the burn entity cannot re-ignite itself.
        if(v.health>0 && v.takedamage)T_Damage(v,self,self.owner,max(0,cvar("vr_burn_damage"))*0.5,NOARMOR);
    }
};
void(entity target,entity attacker) ADVR_Ignite = {
    local entity fire;
    if(QVR_AD_API!=1 || !(target.flags & FL_MONSTER) || target.health<=0 || !target.modelindex ||
       !target.takedamage || (target.flags & FL_GODMODE) || target.invincible_finished>time ||
       cvar("vr_burn_time")<=0 || cvar("vr_burn_damage")<=0 || ADVR_FireWet(target))return;
    fire=target.advr_burn;
    if(!fire || fire.classname!="advr_burn" || fire.enemy!=target) {
        fire=spawn();fire.classname="advr_burn";fire.enemy=target;
        fire.advr_fire_model=target.modelindex;target.advr_burn=fire;
        fire.think=ADVR_FireThink;fire.nextthink=time+0.1;fire.advr_fire_tick=time+0.5;
        fire.advr_fire_spread=time+max(0.1,cvar("vr_burn_spread"));
        ADVR_FireAdd(fire);sound(target,CHAN_AUTO,"vr/torch_light.wav",0.6,ATTN_NORM);
    }
    fire.owner=attacker;fire.advr_fire_end=time+cvar("vr_burn_time");
};
void(entity target,entity inflictor,entity attacker,float damage,float kind) ADVR_FireHit = {
    if(damage<=0 || inflictor.classname=="advr_burn")return;
    if(inflictor.advr_fireball){ADVR_Ignite(target,attacker);return;}
    if(kind==DAMSPLASH || inflictor.classgroup==CG_PROJROCKETS || inflictor.classgroup==CG_PROJGRENADES)
        if(random()<bound(0,cvar("advr_burn_explosion_chance"),1))ADVR_Ignite(target,attacker);
};

void() ADVR_TestFire = {
    local entity actor,v,shot,fire;local float hp;
    actor=self;
    cvar_set("vr_burn_time","3");cvar_set("vr_burn_damage","4");
    v=spawn();v.classname="advr_fire_test";v.classtype=CT_MONKNIGHT;
    v.flags=FL_MONSTER;v.health=1000;v.takedamage=DAMAGE_AIM;
    v.enemy=actor;v.switchattacker=actor;v.switchtimer=time+100;
    setmodel(v,"progs/player.mdl");setsize(v,'-16 -16 -24','16 16 32');
    setorigin(v,actor.origin+'80 0 0');
    shot=spawn();shot.owner=actor;shot.advr_fireball=1;
    T_Damage(v,shot,actor,10,NOARMOR);
    ADVR_Assert(v.advr_burn && v.advr_burn.owner==actor,"fireball damage always ignites with kill credit");
    fire=v.advr_burn;ADVR_Ignite(v,actor);
    ADVR_Assert(v.advr_burn==fire && fire.advr_fire_count==1,"repeated ignition refreshes one nonstacking fire");
    hp=v.health;self=fire;self.advr_fire_tick=0;ADVR_FireThink();self=actor;
    ADVR_Assert(v.health==hp-2,"one half-second burn tick deals two damage");
    v.waterlevel=2;v.watertype=CONTENT_WATER;
    self=fire;ADVR_FireThink();self=actor;
    ADVR_Assert(!v.advr_burn,"water extinguishes and clears fire");
    ADVR_Ignite(v,actor);ADVR_Assert(!v.advr_burn,"underwater ignition rejected");
    v.waterlevel=0;v.watertype=CONTENT_EMPTY;
    shot.advr_fireball=0;shot.classgroup=CG_PROJROCKETS;
    cvar_set("advr_burn_explosion_chance","0");
    T_Damage(v,shot,actor,10,DAMSPLASH);ADVR_Assert(!v.advr_burn,"zero explosion chance never ignites");
    cvar_set("advr_burn_explosion_chance","1");
    T_Damage(v,shot,actor,10,DAMSPLASH);ADVR_Assert(v.advr_burn!=world,"explosion damage hooks ignition");
    fire=v.advr_burn;fire.advr_fire_end=time;
    self=fire;ADVR_FireThink();self=actor;ADVR_Assert(!v.advr_burn,"expired flames cleaned up");
    ADVR_Ignite(v,world);ADVR_Assert(v.advr_burn && v.advr_burn.owner==world,"environmental ignition supports world attribution");
    fire=v.advr_burn;v.health=0;
    cvar_set("vr_burn_corpses","1");self=fire;ADVR_FireThink();self=actor;
    ADVR_Assert(fire.advr_fire_dead && fire.advr_fire_end>time,"normal death preserves temporary corpse flames");
    v.modelindex=0;self=fire;ADVR_FireThink();self=actor;
    ADVR_Assert(!v.advr_burn,"removed or gibbed model clears flames");
    remove(v);remove(shot);cvar_set("advr_burn_explosion_chance","0.3");
    bprint("ADVR FIRE PASS: guaranteed fireball, chance-controlled splash, nonstacking damage, water, expiry, model cleanup\n");
};

// A stationary humanoid for flame/scorch inspection and disposable save testing.
void() ADVR_TestFireView = {
    local entity v;
    v=spawn();v.classname="advr_fire_preview";v.classtype=CT_MONKNIGHT;
    v.flags=FL_MONSTER;v.health=1000;v.takedamage=DAMAGE_AIM;
    v.enemy=self;v.switchattacker=self;v.switchtimer=time+100;
    setmodel(v,"progs/player.mdl");setsize(v,'-16 -16 -24','16 16 32');
    setorigin(v,self.origin+'0 80 0');v.angles_y=270;
    ADVR_Ignite(v,self);
};
