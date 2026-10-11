entity advr_test_cut,advr_test_head;
float(entity e) ADVR_TestHeadCount = {
    local entity g;local float n;
    g=find(world,classname,"item_gib");
    while(g){if(g.owner==e && g.model==e.headmdl)n=n+1;g=find(g,classname,"item_gib");}
    return n;
};
void() ADVR_TestDecap = {
    local entity e,actor,g;local float damage,kills,precise,mult;
    actor=self;kills=killed_monsters;precise=cvar("vr_hit_precise");mult=cvar("vr_headshot_mult");
    self.flags=self.flags | FL_GODMODE;
    cvar_set("vr_ragdoll","1");cvar_set("vr_decap","1");cvar_set("vr_positional_damage","1");
    cvar_set("vr_hit_precise","0");cvar_set("vr_headshot_mult","1.5");
    e=ADVR_HammerTestFoe();e.health=30;e.angles='0 0 0';
    damage=ADVR_HeadDamage(e,self,e.origin+'3 0 22','-1 0 0',5);
    T_Damage(e,self,self,damage,DAMARMOR);
    ADVR_Assert(e.health>0 && !e.vr_headless,"nonfatal headshot retains head");
    T_Damage(e,self,self,30,DAMARMOR);
    ADVR_Assert(!e.vr_headless && !e.advr_decap_kind,"later body hit cannot inherit headshot");
    e=ADVR_HammerTestFoe();e.health=10;e.angles='0 0 0';
    damage=ADVR_HeadDamage(e,self,e.origin+'3 0 22','-1 0 0',10);T_Damage(e,self,self,damage,DAMARMOR);
    ADVR_Assert(e.vr_headless && isragdoll(e),"fatal ranged headshot removes ragdoll head");
    ADVR_Assert(ADVR_TestHeadCount(e)==0,"ranged pop does not spawn intact head");
    e=ADVR_HammerTestFoe();e.health=10;e.angles='0 0 0';
    damage=ADVR_MeleeHeadDamage(e,self,e.origin+'3 0 22','-1 0 0',10);T_Damage(e,self,self,damage,DAMARMOR);
    ADVR_Assert(e.vr_headless && isragdoll(e),"fatal melee headshot removes ragdoll head");
    ADVR_Assert(ADVR_TestHeadCount(e)==1,"melee decap spawns exactly one matching head");
    advr_test_cut=e;
    g=find(world,classname,"item_gib");while(g){if(g.owner==e && g.advr_severed_head)advr_test_head=g;g=find(g,classname,"item_gib");}
    ADVR_Assert(advr_test_head.advr_gib_ready && advr_test_head.vr_gib,"severed head enters physics/blood pipeline");
    self=e;ADVR_DecapDeath();self=actor;
    ADVR_Assert(ADVR_TestHeadCount(e)==1,"duplicate death callback cannot spawn another head");
    e=ADVR_HammerTestFoe();e.health=10;e.angles='0 0 0';
    damage=ADVR_HeadDamage(e,self,e.origin+'3 0 22','-1 0 0',1000);T_Damage(e,self,self,damage,DAMARMOR);
    self=e;monster_check_gib();self=actor;
    ADVR_Assert(e.gibbed && ADVR_TestHeadCount(e)==0,"ranged overkill preserves body gibs but suppresses head");
    e=ADVR_HammerTestFoe();e.health=10;e.angles='0 0 0';
    damage=ADVR_HeadDamage(e,self,e.origin+'3 0 22','-1 0 0',10);T_Damage(e,self,self,damage,DAMSPLASH);
    ADVR_Assert(!e.vr_headless && !e.advr_decap_kind,"splash never inherits headshot context");
    e=ADVR_HammerTestFoe();e.health=10;e.angles='0 0 0';
    ClearMultiDamage();
    AddMultiDamage(e,ADVR_HeadDamage(e,self,e.origin+'3 0 22','-1 0 0',2));
    AddMultiDamage(e,ADVR_HeadDamage(e,self,e.origin,'-1 0 0',20));
    dprint("DECAP MIXED ");dprint(ftos(advr_multi_head));dprint(" / ");dprint(ftos(multi_damage));dprint("\n");ApplyMultiDamage();
    ADVR_Assert(!e.vr_headless,"body-dominated pellet blast does not pop head");
    e=ADVR_HammerTestFoe();e.health=10;e.angles='0 0 0';
    ClearMultiDamage();
    AddMultiDamage(e,ADVR_HeadDamage(e,self,e.origin+'3 0 22','-1 0 0',10));
    AddMultiDamage(e,ADVR_HeadDamage(e,self,e.origin,'-1 0 0',1));ApplyMultiDamage();
    ADVR_Assert(e.vr_headless,"head-dominated pellet blast pops head");
    ADVR_Assert(killed_monsters==kills+7,"all death counts remain exactly once");
    cvar_set("vr_hit_precise",ftos(precise));cvar_set("vr_headshot_mult",ftos(mult));
    bprint("ADVR DECAP PASS: fatal ranged/melee, nonfatal/body/splash exclusion, head gib, overkill, death counts\n");
};
void() ADVR_TestDecapState = {
    local entity actor;actor=self;
    ADVR_Assert(advr_test_cut.vr_headless && isragdoll(advr_test_cut),"save/load keeps headless ragdoll");
    ADVR_Assert(advr_test_head.vr_rigid && ADVR_TestHeadCount(advr_test_cut)==1,"save/load keeps single physical head");
    self=advr_test_cut;monster_ThrowGib();self=actor;
    ADVR_Assert(ADVR_TestHeadCount(advr_test_cut)==1,"gibbing a beheaded corpse cannot duplicate its head");
    bprint("ADVR DECAP STATE PASS: headless corpse and physical head survive save/load\n");
};

float advr_decap_rig_index,advr_decap_rig_count;
void() ADVR_TestDecapRig = {
    local entity actor,e;local string mdl;
    actor=self;mdl=ADVR_RagdollModel(advr_decap_rig_index);
    ADVR_Assert(mdl!="","decap roster index valid");advr_decap_rig_index=advr_decap_rig_index+1;
    e=spawn();e.classname="advr_test_corpse";setmodel(e,mdl);e.flags=FL_MONSTER;
    e.health=-1;e.model_scale='-0.4 -0.4 -0.4';setorigin(e,actor.origin+'0 70 50');
    if(mdl=="progs/mon_lostsoul.mdl") {
        ADVR_Assert(!ragdolldecap(e,'0 0 0',1),"whole-head creature retains native death");
    } else if(ADVR_HeadProfile(e)) {
        self=e;ADVR_CorpseReady();self=actor;
        ADVR_Assert(ragdolldecap(e,'0 0 0',1),"profiled monster rig supports head removal");
        ADVR_Assert(e.vr_headless && isragdoll(e),"headless state exists for roster model");
        advr_decap_rig_count=advr_decap_rig_count+1;
        bprint("ADVR DECAP RIG PASS: ");bprint(mdl);bprint("\n");
    }
    remove(e);
    if(advr_decap_rig_index==60){bprint("ADVR DECAP ROSTER PASS: ");bprint(ftos(advr_decap_rig_count));bprint(" profiled rigs\n");}
};
