// Ogre hammer: actual weighted head motion supplies damage, not trigger presses.
// Balance values are deliberately local, independent of AD's monster attacks.
float(entity e) ADVR_HammerMovable = {
    return (e.flags & FL_MONSTER) && !(e.flags & (FL_FLY|FL_SWIM)) &&
        e.health>0 && !e.deadflag && !e.bossflag && e.classgroup!=CG_STONE &&
        !e.spawnstatue && e.movespeed>=0 && e.movetype==MOVETYPE_STEP;
};
void() ADVR_HammerRecover = {
    if(self.health<=0)return;
    self.advr_hammer_down=0;self.vr_knockdown=0;
    self.think=self.advr_hammer_resume;
    if(self.th_run)self.think=self.th_run;
    self.nextthink=time+0.1;
};
void() ADVR_HammerDownThink = {
    if(self.health<=0)return;
    self.think=ADVR_HammerDownThink;self.nextthink=time+0.1;
    if(time<self.advr_hammer_until)return;
    if(isragdoll(self)) {
        if(!ragdollgetup(self,self.advr_hammer_frame,-1,self.advr_hammer_mins,self.advr_hammer_maxs,64)) {
            self.advr_hammer_until=time+0.5;return;
        }
    } else {
        // Ragdolls disabled or a saved body has not been rebuilt: never stand inside a wall.
        setsize(self,self.advr_hammer_mins,self.advr_hammer_maxs);self.solid=SOLID_SLIDEBOX;
        if(!walkmove(0,0)){self.solid=5;self.advr_hammer_until=time+0.5;return;}
        self.vr_knockdown=2;
    }
    self.solid=self.advr_hammer_solid;self.movetype=self.advr_hammer_move;
    setsize(self,self.advr_hammer_mins,self.advr_hammer_maxs);setorigin(self,self.origin);
    self.velocity='0 0 0';self.flags=self.flags | FL_ONGROUND;self.frame=self.advr_hammer_frame;
    self.think=ADVR_HammerRecover;self.nextthink=time+max(0.1,cvar("vr_knockdown_blend"));
};
float(entity e) ADVR_HammerKnockdown = {
    local float savedflags;
    if(!ADVR_HammerMovable(e) || !canragdoll(e))return 0;
    if(e.advr_hammer_down){if(e.vr_knockdown==1)e.advr_hammer_until=max(e.advr_hammer_until,time+1);return 1;}
    // Native zombie collapses and scripted get-ups keep their own state machine.
    if(e.classgroup==CG_ZOMBIE || e.vr_knockdown || e.solid!=SOLID_SLIDEBOX)return 0;
    e.advr_hammer_mins=e.mins;e.advr_hammer_maxs=e.maxs;
    e.advr_hammer_solid=e.solid;e.advr_hammer_move=e.movetype;e.advr_hammer_frame=e.frame;
    e.advr_hammer_resume=e.think;savedflags=e.flags;
    e.vr_knockdown=1;e.solid=5;e.flags=e.flags-(e.flags & FL_ONGROUND);
    if(!ragdollknockdown(e)){e.vr_knockdown=0;e.solid=e.advr_hammer_solid;e.flags=savedflags;return 0;}
    if(e.advr_shove && e.advr_shove.owner==e)remove(e.advr_shove);
    e.advr_shove=world;e.touch=SUB_Null;e.advr_hammer_down=1;e.advr_hammer_until=time+2.5;
    e.think=ADVR_HammerDownThink;e.nextthink=time+0.1;
    return 1;
};
void() ADVR_HammerDeath = {
    // Run native death frames once, including death targets, backpacks and gibs.
    // The engine retains the living ragdoll as a corpse, rather than standing it up.
    local float i;local void() fn;
    self.advr_hammer_down=0;self.vr_knockdown=0;
    for(i=0;i<64;i=i+1) {
        if(!self.think || !self.modelindex || self.gibbed || self.nextthink<=0 || self.nextthink>time+0.15)break;
        fn=self.think;fn();if(self.think==fn)break;
    }
    if(self.modelindex && !self.gibbed)ADVR_CorpseReady();
};
void(entity victim,vector at,vector vel,float speed) ADVR_HammerHit = {
    local float damage,before;
    damage=65*bound(0.5,speed/3,2);victim.axhitme=1;
    if(victim.reflectaxe){Resist_Axe(self,at);return;}
    damage=ADVR_MeleeHeadDamage(victim,self,at,vel,damage);
    before=victim.health;SpawnBlood(victim,at,vel,damage);T_Damage(victim,self,self,damage,DAMARMOR);
    if(victim.health<before && victim.health>0)ADVR_HammerKnockdown(victim);
};
void(vector at) ADVR_HammerSlam = {
    local entity e,next,fx;local vector dir,center;local float distance,falloff,before;
    e=findradius(self.origin,192);
    while(e) {
        next=e.chain;
        if(ADVR_HammerMovable(e) && e.takedamage && !e.reflectaxe && fabs(e.origin_z-self.origin_z)<64) {
            center=e.origin+(e.mins+e.maxs)*0.5;
            traceline(at+'0 0 6',center,TRUE,self);
            if(trace_fraction==1 || trace_ent==e) {
                dir=e.origin-self.origin;dir_z=0;distance=vlen(dir);falloff=bound(0,1-distance/192,1);
                before=e.health;T_Damage(e,self,self,25*falloff,DAMARMOR);
                if(e.health>0 && e.health<before) {
                    if(e.advr_shove && e.advr_shove.owner==e)remove(e.advr_shove);e.advr_shove=world;
                    if(distance<1)dir='1 0 0';else dir=normalize(dir);
                    e.velocity=dir*(450*falloff)+'0 0 1'*(100*falloff);
                    e.flags=e.flags-(e.flags & FL_ONGROUND);
                    if(isragdoll(e))physicspush(e,e.origin,e.velocity);
                }
            }
        }
        e=next;
    }
    fx=spawn();setmodel(fx,MODEL_PROJ_RINGSHOCK);setsize(fx,'0 0 0','0 0 0');setorigin(fx,at);
    fx.movetype=MOVETYPE_NONE;fx.solid=SOLID_NOT;fx.ltime=time;
    fx.think=ai_shockwave_think;fx.nextthink=time+TIME_MINTICK;
    sound(self,CHAN_WEAPON,"ogre/ham_wave.wav",1,ATTN_NORM);
};
void(float h) ADVR_HammerFrame = {
    local entity r,victim;local vector tip,previous,vel,raw,at,normal,nearhead;
    local float dt,mu,speed,fresh,hit;
    r=ADVR_Hand(h);tip=ADVR_WeaponTip(h);previous=r.advr_hammer_tip;dt=time-r.advr_hammer_time;
    fresh=0;
    if(r.advr_hammer_time>0)
        if(dt>0 && dt<0.1)
            if(vlen(tip-previous)<64)fresh=1;
    r.advr_hammer_tip=tip;r.advr_hammer_time=time;
    if(h)raw=self.handvel;else raw=self.offhandvel;
    // Require lifting the head before every slam, including after drawing/catching.
    traceline(tip,tip-'0 0 18',TRUE,self);
    if(trace_fraction==1)r.advr_hammer_armed=1;
    if(!fresh || vlen(raw)<0.3 || time<r.advr_cooldown)return;
    mu=26.246719*max(0.01,cvar("vr_world_scale"));vel=(tip-previous)/(dt*mu);speed=vlen(vel);
    if(speed<1.8)return;
    // Check the path to the head before sweeping, so a head beyond a wall cannot hit enemies.
    traceline(ADVR_Pos(h),tip,TRUE,self);
    hit=trace_fraction<1;at=trace_endpos;normal=trace_plane_normal;victim=trace_ent;
    if(!hit) {
        traceline(previous,tip,2560,self);
        hit=trace_fraction<1;at=trace_endpos;normal=trace_plane_normal;victim=trace_ent;
    }
    if(!hit) {
        // A little head thickness allows floor contact before its centre crosses the floor.
        nearhead=tip+normalize(vel)*4;traceline(tip,nearhead,2560,self);
        hit=trace_fraction<1;at=trace_endpos;normal=trace_plane_normal;victim=trace_ent;
    }
    if(!hit)return;
    if(victim.takedamage) {
        ADVR_HammerHit(victim,at,vel,speed);r.advr_cooldown=time+0.8;
        haptic(h,0,0.14,65,0.9);sound(self,CHAN_WEAPON,GIB_SOUND_HEAVY,1,ATTN_NORM);return;
    }
    if(normal_z>0.65 && vel_z<-2.6 && r.advr_hammer_armed && time>=r.advr_hammer_slam &&
       (self.flags & FL_ONGROUND) && fabs(at_z-(self.origin_z+self.mins_z))<24) {
        r.advr_hammer_armed=0;r.advr_hammer_slam=time+2;r.advr_cooldown=time+0.8;
        ADVR_HammerSlam(at);haptic(h,0,0.2,55,1);
        if(weaponanygrip(self,1-h)>0)haptic(1-h,0,0.2,55,0.7);
    }
};

