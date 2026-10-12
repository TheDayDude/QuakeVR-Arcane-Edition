// ADVR combat integration. AD still owns armor, resistances, death callbacks and gib thresholds.
float advr_ray_min,advr_ray_max;
float(float p,float d,float lo,float hi) ADVR_HeadSlab = {
    local float a,b,tmp;
    if(fabs(d)<0.0001){if(p<lo)return 0;if(p>hi)return 0;return 1;}
    a=(lo-p)/d;b=(hi-p)/d;if(a>b){tmp=a;a=b;b=tmp;}
    advr_ray_min=max(advr_ray_min,a);advr_ray_max=min(advr_ray_max,b);
    return advr_ray_min<=advr_ray_max;
};
float(entity target,entity attacker,vector at,vector direction,float damage) ADVR_HeadDamage = {
    local vector p,d,lo,hi,forward,left,headangles,savedforward,savedright,savedup;
    local float hit,mult;
    ADVR_HitClear();
    if(damage<=0 || !(attacker.flags & FL_CLIENT) || !(attacker.vrbits0 & 16384) ||
       !(target.flags & FL_MONSTER) || target.health<=0 || target.takedamage==DAMAGE_NO ||
       !cvar("vr_positional_damage") || !ADVR_HeadProfile(target))return damage;
    mult=max(1,cvar("vr_headshot_mult"));

    savedforward=v_forward;savedright=v_right;savedup=v_up;
    headangles='0 0 0';headangles_y=target.angles_y;makevectors(headangles);
    forward=v_forward;left=-v_right;
    v_forward=savedforward;v_right=savedright;v_up=savedup;
    lo=modelpoint(target,'0 0 0',advr_head_lo)-'1 1 1';
    hi=modelpoint(target,'0 0 0',advr_head_hi)+'1 1 1';
    if(hitmodel_target(target)) {
        // Same triangle in the standing frame: crouching/attack/pain animation follows the head.
        p=hitmodel_rest(target,at)-target.origin;
        d_x=p*forward;d_y=p*left;d_z=p_z;
        if(d_x<lo_x)return damage;if(d_x>hi_x)return damage;
        if(d_y<lo_y)return damage;if(d_y>hi_y)return damage;
        if(d_z<lo_z)return damage;if(d_z>hi_z)return damage;
        hit=1;
    } else {
        // With precise hit testing disabled, use the incoming ray through the head box,
        // not distance from the collision-box entry point (which is in front of the face).
        p=at-target.origin;d_x=p*forward;d_y=p*left;d_z=p_z;p=d;
        direction=normalize(direction);d_x=direction*forward;d_y=direction*left;d_z=direction_z;
        advr_ray_min=0;advr_ray_max=vlen(target.maxs-target.mins)+96;
        if(!ADVR_HeadSlab(p_x,d_x,lo_x,hi_x))return damage;
        if(!ADVR_HeadSlab(p_y,d_y,lo_y,hi_y))return damage;
        if(!ADVR_HeadSlab(p_z,d_z,lo_z,hi_z))return damage;
        hit=1;
    }
    if(!hit)return damage;
    advr_hit_ent=target;advr_hit_by=attacker;advr_hit_kind=1;
    advr_hit_at=at;advr_hit_vel=normalize(direction)*220;
    advr_head_hits=advr_head_hits+1;
    if(time>=attacker.advr_headsound_next) {
        attacker.advr_headsound_next=time+0.1;
        if(cvar("vr_headshot_sound")>0)sound(attacker,CHAN_AUTO,"vr/headshot.wav",min(1,cvar("vr_headshot_sound")),ATTN_NORM);
    }
    return damage*mult;
};
float(entity target,vector at,vector velocity,float amount) ADVR_Blood = {
    // Preserve AD's stone, metal, poison and other special palettes/materials.
    if(!(target.flags & (FL_MONSTER | FL_CLIENT)) || target.classgroup==CG_ROBOT ||
       target.gibtype!=GIBTYPE_BLOOD || target.poisonous ||
       (target.bleedcolour && target.bleedcolour!=MON_BCOLOR_RED))return 0;
    if(amount<=0)return 1;
    // Per-victim rate limit: a pellet cloud must not flood VR particle/decal budgets.
    if(time<target.advr_blood_next)return 1;
    target.advr_blood_next=time+0.05;
    particle2(at,normalize(velocity)*8+'0 0 2',1,bound(2,amount*0.25,12));
    advr_blood_events=advr_blood_events+1;
    return 1;
};
void() ADVR_GibThink = {
    if(self.touchedvoid){remove(self);return;}
    if(time>=self.pain_finished){RemoveGib();return;}
    if(!self.vr_rigid && time>=self.advr_gib_ready) {
        // Allow fresh pieces to leave their owner's volume before building rigid hulls.
        self.vr_rigid=1;self.vr_spin=self.avelocity*0.01745329252;self.avelocity='0 0 0';
        self.solid=5;
        setsize(self,modelbounds(self,0),modelbounds(self,1));
        advr_gib_events=advr_gib_events+1;
    }
    self.think=ADVR_GibThink;self.nextthink=time+0.1;
};
void() ADVR_GibTouch = {
    // AD's sounds and damage checks remain; its floor animation isn't used on rigid pieces.
    TouchGib();
    if(self.think!=model_fade && self.think!=SUB_Remove) {
        self.think=ADVR_GibThink;self.nextthink=time+0.1;
    }
};
void(entity gib) ADVR_GibSetup = {
    local entity e;
    local float n;
    // Animated/explosive special fragments retain their AD behavior.
    if(gib.gibAnimfinal || gib.gib1dmg || gib.gibpartstyle)return;
    // A bounded set of physics props; excess pieces keep AD's ordinary bounce/fade.
    e=find(world,classname,"item_gib");n=0;
    while(e){if(e.advr_gib_ready)n=n+1;e=find(e,classname,"item_gib");}
    if(n>=96)return;
    gib.advr_gib_ready=time+0.2;gib.vr_prop_mass=0.25;
    gib.vr_gib=1;gib.touch=ADVR_GibTouch;
    gib.think=ADVR_GibThink;gib.nextthink=time+0.1;
    // Model EF_GIB flags already feed the client VR blood trail, drops and impact splats.
};

void(entity inflictor,entity attacker,float damage) ADVR_TestPain = {};
entity advr_test_gib;
vector advr_test_gib_origin;
void() ADVR_TestCombat = {
    local entity actor,e,projectile,g;
    local float positional,mult,precise,beforehp,count,blood,kills,originaltotal;
    local vector head,org;
    originaltotal=total_monsters;actor=self;positional=cvar("vr_positional_damage");mult=cvar("vr_headshot_mult");precise=cvar("vr_hit_precise");
    cvar_set("vr_positional_damage","1");cvar_set("vr_headshot_mult","1.5");cvar_set("vr_hit_precise","1");
    // Run on ad_e1m1, whose soldiers and their assets are already precached.
    e=spawn();e.classname="monster_army";setorigin(e,actor.origin+'0 80 0');actor.flags=actor.flags | FL_GODMODE;
    self=e;monster_army();self=actor;setmodel(e,e.mdl);setsize(e,e.bbmins,e.bbmaxs);e.solid=SOLID_SLIDEBOX;e.nextthink=time+600;e.frame=0;e.angles='0 0 0';
    e.health=1000;e.takedamage=DAMAGE_AIM;e.flags=e.flags | FL_MONSTER;
    head=e.origin+'3 0 22';
    ADVR_Assert(ADVR_HeadDamage(e,actor,head,'-1 0 0',10)==15,"precise soldier head multiplier");
    ADVR_Assert(ADVR_HeadDamage(e,actor,e.origin,'-1 0 0',10)==10,"torso has no multiplier");
    // Vertex 204 of AD soldier painb5 lies far below its standing head.
    e.frame=50;
    ADVR_Assert(ADVR_HeadDamage(e,actor,e.origin+'8.97 3.63 4.25','-1 0 0',10)==15,"animated crouched head follows mesh");
    e.frame=0;
    e.angles_y=90;head=e.origin+'0 3 22';
    ADVR_Assert(ADVR_HeadDamage(e,actor,head,'0 -1 0',10)==15,"rotated head multiplier");
    e.angles_y=0;head=e.origin+'3 0 22';
    cvar_set("vr_hit_precise","0");
    ADVR_Assert(ADVR_HeadDamage(e,actor,e.origin+'30 0 22','-1 0 0',10)==15,"box fallback head ray");
    ADVR_Assert(ADVR_HeadDamage(e,actor,e.origin+'30 0 0','-1 0 0',10)==10,"box fallback torso ray");
    cvar_set("vr_hit_precise","1");
    cvar_set("vr_positional_damage","0");
    ADVR_Assert(ADVR_HeadDamage(e,actor,head,'-1 0 0',10)==10,"headshot setting disabled");
    cvar_set("vr_positional_damage","1");
    projectile=spawn();projectile.owner=actor;projectile.movetype=MOVETYPE_FLYMISSILE;
    projectile.classgroup=CG_PROJNAILS;projectile.velocity='-600 0 0';setorigin(projectile,head);
    e.th_pain=ADVR_TestPain;e.armorvalue=0;e.armortype=0;actor.super_damage_finished=0;
    beforehp=e.health;T_Damage(e,projectile,actor,10,DAMARMOR);
    ADVR_Assert(beforehp-e.health==15,"direct projectile head damage once");
    beforehp=e.health;T_Damage(e,projectile,actor,10,DAMSPLASH);
    ADVR_Assert(beforehp-e.health==10,"splash never receives head multiplier");
    // Actual AD pellet touch stops/hides its projectile before applying damage.
    projectile.classname="proj_bullet";projectile.classtype=CT_PROJ_SG;projectile.classgroup=CG_PROJSHELLS;
    beforehp=e.health;self=projectile;other=e;Touch_Bullet();self=actor;other=world;
    ADVR_Assert(beforehp-e.health==DAMAGE_PSHELL*1.5,"actual stopped pellet headshot");
    // Native bolt impact stops movement before T_Damage; retain its head hit.
    projectile.advr_crossbolt=1;projectile.classtype=CT_PROJ_BOLT1;projectile.classgroup=CG_PROJNAILS;
    projectile.velocity='-900 0 0';projectile.touch=Touch_Projectile;setorigin(projectile,head);
    beforehp=e.health;self=projectile;other=e;Touch_Projectile();self=actor;other=world;
    ADVR_Assert(beforehp-e.health==100,"crossbow bolt receives two-times headshot bonus exactly once");
    projectile.advr_crossbolt=0;
    projectile.movetype=MOVETYPE_FLYMISSILE;projectile.velocity='-600 0 0';projectile.nextthink=time+600;
    // Multi-damage accumulates each pellet's own result, not a whole-blast head multiplier.
    ClearMultiDamage();e.resist_shells=0;
    AddMultiDamage(e,ADVR_HeadDamage(e,actor,head,'-1 0 0',10));
    AddMultiDamage(e,ADVR_HeadDamage(e,actor,e.origin,'-1 0 0',10));
    beforehp=e.health;ApplyMultiDamage();
    ADVR_Assert(beforehp-e.health==25,"mixed head/body pellets accumulate individually");
    e.advr_blood_next=0;blood=advr_blood_events;
    SpawnBlood(e,head,'0 0 60',20);SpawnBlood(e,head,'0 0 60',20);
    ADVR_Assert(advr_blood_events==blood+1,"hit blood routed and rate limited");
    e.gibtype=GIBTYPE_STONE;
    ADVR_Assert(!ADVR_Blood(e,head,'0 0 60',20),"stone keeps its material effects");e.gibtype=0;
    kills=killed_monsters;e.health=20;
    T_Damage(e,projectile,actor,200,DAMARMOR);
    self=e;monster_check_gib();self=actor;
    ADVR_Assert(e.gibbed,"overkill uses AD gib threshold");
    ADVR_Assert(killed_monsters==kills+1,"overkill counted exactly once");
    count=0;g=find(world,classname,"item_gib");
    while(g){if(g.owner==e && g.advr_gib_ready){count=count+1;advr_test_gib=g;}g=find(g,classname,"item_gib");}
    ADVR_Assert(count>0,"overkill produces physics-enabled pieces");
    advr_test_gib_origin=advr_test_gib.origin;
    // Pieces keep their owner until the grace timer; do not free it prematurely.
    remove(projectile);killed_monsters=kills;total_monsters=originaltotal;
    cvar_set("vr_positional_damage",ftos(positional));cvar_set("vr_headshot_mult",ftos(mult));cvar_set("vr_hit_precise",ftos(precise));
    bprint("ADVR COMBAT PASS: precise/rotated/fallback headshots, body/splash exclusion, pellet accumulation, blood, overkill\n");
};
void() ADVR_TestCombatState = {
    ADVR_Assert(advr_test_gib && advr_test_gib.vr_rigid,"gib becomes rigid after grace");
    ADVR_Assert(advr_gib_events>0 && vlen(advr_test_gib.origin-advr_test_gib_origin)>1,"physics gib moves after spawn");
    ADVR_Assert(advr_test_gib.think==ADVR_GibThink,"gib preserves cleanup think");
    bprint("ADVR GIB PHYSICS PASS: moving rigid pieces with cleanup\n");
};
