// One whitelist for guarding and projectile batting; add future melee kinds here.
float(entity r) ADVR_CanParry = {
    if(!r || r.advr_weapon!=IT_AXE)return 0;
    if(r.advr_kind==ADVR_SWORD || r.advr_kind==ADVR_HELLSWORD || r.advr_kind==ADVR_AXE || r.advr_kind==ADVR_SHADOWAXE || r.advr_kind==ADVR_HAMMER)return 1;
    if(r.advr_kind)return 0; // Chainsaw is deliberately excluded.
    return !(self.moditems & IT_UPGRADE_GHOOK); // Ordinary axe or Shadow Axe, not the grapple.
};

// QuakeVR's release estimator, weight/gain curve and real-world gravity.
// Previously only the unamplified hand speed was used, under Quake's ~2.5g.
void(float h,entity p) ADVR_ThrowSetup = {
    local vector vel,flick,from,at;
    local float mass,mu,grav,age;
    if(h){vel=self.handthrowvel;flick=self.handthrowflick;from=self.handthrowpos;age=self.handthrowage;}
    else{vel=self.offhandthrowvel;flick=self.offhandthrowflick;from=self.offhandthrowpos;age=self.offhandthrowage;}
    mu=26.246719*max(0.01,cvar("vr_world_scale"));mass=weaponvalue(p.model,"w_mass");
    p.velocity=throwvelocity(vel,flick,mass,1)*mu*max(0,cvar("vr_weapon_throw_velocity_mult"));
    grav=cvar("sv_gravity");if(cvar("vr_throw_gravity")>0)grav=cvar("vr_throw_gravity")*mu;
    p.gravity=grav/max(1,cvar("sv_gravity"));
    age=bound(0,age,0.3);
    if(from!='0 0 0' && age>0 && vlen(from-ADVR_Pos(h))<96){
        at=from+p.velocity*age-'0 0 1'*(0.5*grav*age*age);
        traceline(from,at,3584,self); // MOVE_HITMODEL_THROWN
        at=trace_endpos;if(trace_fraction<1)at=at-normalize(p.velocity)*2;
        traceline(ADVR_Pos(h),at,TRUE,self);at=trace_endpos;
        setorigin(p,at);p.velocity_z=p.velocity_z-grav*age;
    }
    p.throwhit=0;p.advr_throw_armed=0;
    if(vlen(p.velocity)>=throwweight(1,mass,weaponvalue(p.model,"w_throwmin"),1,0,0))p.advr_throw_armed=1;
};
void() ADVR_ThrownHit = {
    local float speed,mass,damage,base;
    if(other==self.owner || !other.takedamage || !self.advr_throw_armed || self.throwhit)return;
    if(!(self.owner.flags & FL_CLIENT))return;
    speed=vlen(self.velocity);mass=weaponvalue(self.model,"w_mass");
    damage=throwweight(2,mass,weaponvalue(self.model,"w_throwmin"),weaponvalue(self.model,"w_throwcurve"),speed,700);
    if(cvar("vr_debug_throw")){
        dprint("ADVR throw hit ");dprint(self.model);dprint(" -> ");dprint(other.classname);
        dprint(" speed ");dprint(ftos(speed));dprint(" factor ");dprint(ftos(damage));dprint("\n");
    }
    self.throwhit=1;self.advr_throw_armed=0; // One contact per throw, never repeated resting-contact damage.
    if(damage<=0)return;
    base=20;if(self.advr_weapon==IT_AXE)base=35;
    if(self.weaponinst.advr_kind==ADVR_SWORD || self.weaponinst.advr_kind==ADVR_HELLSWORD)base=60;
    if(self.weaponinst.advr_kind==ADVR_SAW)base=50;
    if(self.weaponinst.advr_kind==ADVR_HAMMER)base=65;
    damage=damage*base*weaponvalue(self.model,"w_throwdmg")*weightdamage(mass)*max(0,cvar("vr_weapon_throw_damage_mult"));
    if(damage<=0)return;
    SpawnBlood(other,self.origin,self.velocity,damage);
    T_Damage(other,self,self.owner,damage,DAMARMOR);
};

// A short-lived helper preserves AD's own animation/think and attack callbacks.
// As in base QuakeVR, a hard shove keeps sliding briefly after its initial hop.
void() ADVR_ShoveThink = {
    local entity m;
    local float dt;
    m=self.owner;dt=bound(0,time-self.ltime,0.05);self.ltime=time;
    if(m.advr_shove!=self || m.health<=0 || !(m.flags & FL_MONSTER) ||
       m.movetype!=MOVETYPE_STEP || (m.flags & (FL_FLY|FL_SWIM)) || time>=self.attack_finished){
        if(m.advr_shove==self)m.advr_shove=world;remove(self);return;
    }
    self.nextthink=time+0.01;
    if(!(m.flags & FL_ONGROUND))return;
    self.speed=min(self.speed,max(0,m.velocity*self.movedir));
    self.speed=max(0,self.speed-500*dt);
    if(self.speed<20){m.advr_shove=world;remove(self);return;}
    m.flags=m.flags-(m.flags & FL_ONGROUND);
    m.velocity=self.movedir*self.speed+'0 0 1'*(cvar("sv_gravity")*dt);
};
void(entity target,entity inflictor,entity attacker,float damage) ADVR_HitPush = {
    local vector dir;local float pushspeed,up,mass,scale;local entity slide,oldself;
    if(QVR_AD_API!=1 || damage<=0 || !(attacker.flags & FL_CLIENT) || !(target.flags & FL_MONSTER) ||
       inflictor==world || target.deadflag || target.vr_corpse || target.bossflag || target.movespeed<0 ||
       target.solid==SOLID_BSP || target.movetype!=MOVETYPE_STEP)return;
    // AD emits pellets individually. Combine only a short, fixed window of the
    // same player's pellets, then replace the push (never add it per pellet).
    if(inflictor.classgroup==CG_PROJSHELLS){
        if(time>=target.advr_push_until || target.advr_push_attacker!=attacker){
            target.advr_push_damage=0;target.advr_push_until=time+0.1;target.advr_push_attacker=attacker;
        }
        target.advr_push_damage=target.advr_push_damage+damage;damage=target.advr_push_damage;
    }
    if(damage<15 && target.health>0)return;
    dir=target.origin-attacker.origin;
    if(inflictor!=attacker)dir=target.origin-inflictor.origin;
    if(inflictor!=attacker && inflictor.classgroup!=CG_PROJROCKETS && inflictor.classgroup!=CG_PROJGRENADES && vlen(inflictor.velocity)>1)dir=inflictor.velocity;
    dir_z=0;dir=normalize(dir);if(dir=='0 0 0')return;
    mass=max(0.6,vlen(target.size)/vlen('32 32 56'));
    scale=max(0,cvar("vr_push"))/mass;
    if(target.health<=0){scale=scale*max(0,cvar("vr_kill_push"));pushspeed=min(700,damage*14);up=min(260,damage*5);}
    else{scale=scale*max(0,cvar("vr_hit_push"));pushspeed=min(350,damage*6);up=min(80,damage*1.5);}
    pushspeed=pushspeed*scale;up=up*scale;if(pushspeed<=0)return;
    if(target.flags & (FL_FLY|FL_SWIM)){
        oldself=self;self=target;walkmove(vectoyaw(dir),pushspeed*0.08);self=oldself;return;
    }
    target.velocity=dir*pushspeed+'0 0 1'*up;target.flags=target.flags-(target.flags & FL_ONGROUND);
    // A strong hit ends the fiend's damaging leap, using AD's own exit frames.
    if(target.classtype==CT_MONDEMON && target.touch==Demon_JumpTouch && damage>=40 && target.health>0){
        target.touch=SUB_Null;target.think=target.th_jumpexit;target.nextthink=time+0.1;
    }
    if(target.health>0 && pushspeed>=100){
        slide=target.advr_shove;
        if(!slide || slide.owner!=target || slide.classname!="advr_shove"){
            slide=spawn();slide.classname="advr_shove";slide.owner=target;target.advr_shove=slide;
        }
        slide.movedir=dir;slide.speed=pushspeed;slide.ltime=time;slide.attack_finished=time+0.6;
        slide.think=ADVR_ShoveThink;slide.nextthink=time+0.01;
    }
};
