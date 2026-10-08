// Developer-only fixtures dispatched by advr_selftest on an isolated test map.
entity advr_test_corpse;
float advr_test_rig_index,advr_test_death_targets,advr_test_death_kills,advr_test_loot;
vector advr_test_corpse_start;

void() ADVR_TestRagdolls = {
    local entity actor,e;
    local string m;
    actor=self;actor.flags=actor.flags | FL_GODMODE;
    if(advr_test_corpse)remove(advr_test_corpse);
    m=ADVR_RagdollModel(advr_test_rig_index);
    ADVR_Assert(m!="","ragdoll roster index valid");
    e=spawn();e.classname="advr_test_corpse";setmodel(e,m);
    e.flags=FL_MONSTER;e.health=-1;e.gibhealth=-100;e.frame=0;
    // Each model gets its own world step, at half scale to fit large bosses in
    // this corridor. Normal gameplay uses each monster's original model scale.
    e.model_scale='-0.5 -0.5 -0.5';e.movetype=MOVETYPE_TOSS;e.solid=SOLID_TRIGGER;
    setorigin(e,actor.origin+'0 70 70');e.pain_finished=time+600;
    self=e;e.health=10;ADVR_CorpseReady();
    ADVR_Assert(e.vr_corpse!=2,"living/knocked-down creature is not a corpse");
    e.health=-1;e.gibbed=1;ADVR_CorpseReady();
    ADVR_Assert(e.vr_corpse!=2,"gib death is not duplicated as a corpse");
    e.gibbed=0;ADVR_CorpseReady();self=actor;
    ADVR_Assert(e.vr_corpse==2,"roster model supports a ragdoll");
    self=e;e.gibtype=GIBTYPE_STONE;ADVR_CorpseReady();
    ADVR_Assert(e.vr_ragdoll_noblood,"stone ragdolls suppress flesh trails");
    e.gibtype=GIBTYPE_BLOOD;ADVR_CorpseReady();self=actor;
    ADVR_Assert(!e.vr_ragdoll_noblood,"flesh ragdolls retain blood trails");
    advr_test_corpse=e;advr_test_corpse_start=e.origin;
    bprint("ADVR RIG SPAWN: ");bprint(m);bprint("\n");
};

void() ADVR_TestRagdollState = {
    ADVR_Assert(isragdoll(advr_test_corpse),"roster model creates a physical ragdoll");
    ADVR_Assert(vlen(advr_test_corpse.origin-advr_test_corpse_start)<500,"rig position remains bounded");
    bprint("ADVR RIG PHYSICS PASS: ");bprint(advr_test_corpse.model);bprint("\n");
    advr_test_rig_index=advr_test_rig_index+1;
};

void() ADVR_TestRagdollTarget = {advr_test_death_targets=advr_test_death_targets+1;};
void() ADVR_TestRagdollDeath = {
    local entity actor,e,t;
    actor=self;if(advr_test_corpse)remove(advr_test_corpse);
    t=spawn();t.targetname="advr_ragdoll_death_target";t.use=ADVR_TestRagdollTarget;
    e=spawn();e.classname="monster_army";setorigin(e,actor.origin+'0 80 0');
    self=e;monster_army();self=actor;setmodel(e,e.mdl);setsize(e,e.bbmins,e.bbmaxs);
    e.flags=e.flags | FL_MONSTER;e.solid=SOLID_SLIDEBOX;e.movetype=MOVETYPE_STEP;
    e.target=t.targetname;e.health=10;e.armorvalue=0;e.armortype=0;e.takedamage=DAMAGE_AIM;
    e.frame=0;e.nextthink=time+600;e.velocity='0 80 50';
    advr_test_death_kills=killed_monsters;T_Damage(e,actor,actor,11,DAMARMOR);
    ADVR_Assert(e.health<=0 && !e.gibbed,"ordinary lethal hit does not overkill");
    ADVR_Assert(e.vr_corpse==1,"death animation retains control before corpse callback");
    advr_test_corpse=e;
};

void() ADVR_TestRagdollDeathState = {
    local entity pack;
    ADVR_Assert(isragdoll(advr_test_corpse),"native AD death becomes a ragdoll");
    ADVR_Assert(advr_test_corpse.bodyonflr==MON_ONFLR,"corpse remains choppable by AD");
    ADVR_Assert(killed_monsters==advr_test_death_kills+1,"native ragdoll kill counted once");
    ADVR_Assert(advr_test_death_targets==1,"native death target fired once");
    ADVR_Assert(advr_test_corpse.think==monster_deadbody_check,"corpse retains AD cleanup");
    if(!advr_test_loot) {
        pack=find(world,classname,"item_backpack");
        while(pack) {
            if(vlen(pack.origin-advr_test_corpse.origin)<100) {
                advr_test_loot=1;
                // Keep dropped loot out of the visual inspection, after verifying it.
                setorigin(pack,pack.origin+'64 0 0');
            }
            pack=find(pack,classname,"item_backpack");
        }
        ADVR_Assert(advr_test_loot,"native death still drops ammo");
    }
    bprint("ADVR RAGDOLL DEATH PASS: native death, targets, kill count, corpse cleanup\n");
};

void() ADVR_TestRagdollGib = {
    local entity actor;
    actor=self;self=advr_test_corpse;self.health=-200;monster_check_gib();self=actor;
    ADVR_Assert(advr_test_corpse.gibbed && !advr_test_corpse.vr_corpse,"gibbing clears corpse marker");
};
void() ADVR_TestRagdollGibState = {
    ADVR_Assert(!isragdoll(advr_test_corpse),"gibbing removes the physical whole body");
    bprint("ADVR RAGDOLL GIB PASS: corpse replaced by fragments\n");
};

entity advr_cap_first,advr_cap_last;
void() ADVR_TestRagdollCap = {
    local entity actor,e;
    local float i;
    actor=self;cvar_set("vr_ragdoll_max","2");i=0;
    while(i<3) {
        e=spawn();e.classname="advr_test_cap";setmodel(e,"progs/mon_soldier.mdl");
        e.flags=FL_MONSTER;e.health=-1;e.frame=17;
        setorigin(e,actor.origin+'0 80 20'+'32 0 0'*i);
        self=e;ADVR_CorpseReady();self=actor;
        e.advr_corpse_since=time+i*0.001; // distinct ages despite one fixture frame
        if(i==0)advr_cap_first=e;advr_cap_last=e;i=i+1;
    }
};
void() ADVR_TestRagdollCapState = {
    local entity e;
    local float count;
    e=nextent(world);count=0;
    while(e){if(isragdoll(e))count=count+1;e=nextent(e);}
    ADVR_Assert(count==2,"active ragdoll budget is respected");
    ADVR_Assert(isragdoll(advr_cap_last),"newest death gets a ragdoll when pool is full");
    ADVR_Assert(!isragdoll(advr_cap_first),"oldest corpse retires at capacity");
    cvar_set("vr_ragdoll_max","8");
    bprint("ADVR RAGDOLL CAP PASS: oldest corpse retired, newest remains physical\n");
};
