entity advr_test_hammer_foe;
void() ADVR_TestHammerView = {
    ADVR_Reset();self.advr_initialized=1;self.flags=self.flags | FL_GODMODE;self.health=1000;
    self.items=IT_AXE;self.moditems=0;self.advr_main=ADVR_Record(IT_AXE);
    self.advr_main.advr_kind=ADVR_HAMMER;ADVR_Sync();
};
entity() ADVR_HammerTestFoe = {
    local entity actor,e;actor=self;
    e=spawn();e.classname="monster_army";setorigin(e,self.origin+'0 80 0');
    self=e;monster_army();self=actor;setmodel(e,e.mdl);setsize(e,e.bbmins,e.bbmaxs);
    e.flags=e.flags | FL_MONSTER;e.solid=SOLID_SLIDEBOX;e.movetype=MOVETYPE_STEP;
    e.health=1000;e.max_health=1000;e.armorvalue=0;e.armortype=0;e.takedamage=DAMAGE_AIM;
    e.frame=0;e.nextthink=time+600;e.enemy=actor;e.switchattacker=actor;e.switchtimer=time+100;
    return e;
};
void() ADVR_TestHammer = {
    local entity e,r;local float hp;local vector before,floorpoint;
    // Isolated developer map: native enemies must not obstruct the recovery fixture.
    e=nextent(world);while(e){r=nextent(e);if(e.flags & FL_MONSTER)remove(e);e=r;}
    ADVR_TestHammerView();r=self.advr_main;
    ADVR_Assert(ADVR_RecordModel(r)=="progs/advr_hammer.mdl" && ADVR_RecordCapacity(r)==0,"hammer has its own melee model and no ammo");
    ADVR_Assert(ADVR_CanParry(r),"hammer can parry");
    ADVR_Assert(weaponvalue(ADVR_RecordModel(r),"w_mass")==12,"heavy calibrated weapon slot");
    ADVR_SaveParms();ADVR_Reset();ADVR_LoadParms();
    ADVR_Assert(self.advr_main.advr_kind==ADVR_HAMMER,"map transition preserves hammer identity");
    e=ADVR_HammerTestFoe();e.bossflag=1;
    ADVR_Assert(!ADVR_HammerKnockdown(e),"boss resists knockdown");e.bossflag=0;e.classgroup=CG_STONE;
    ADVR_Assert(!ADVR_HammerKnockdown(e),"stone resists knockdown");e.classgroup=CG_ARMY;e.flags=e.flags | FL_FLY;
    ADVR_Assert(!ADVR_HammerKnockdown(e),"flying creature resists knockdown");e.flags=e.flags-FL_FLY;
    e.movespeed=-1;ADVR_Assert(!ADVR_HammerKnockdown(e),"anchored creature resists knockdown");e.movespeed=1;
    hp=self.health;before=self.velocity;ADVR_HammerSlam(self.origin+self.mins_z*'0 0 1');
    ADVR_Assert(self.health==hp && self.velocity==before,"slam never damages or launches its player");
    ADVR_Assert(e.health<1000 && e.velocity_y>0 && e.velocity_z>0,"slam damages and pushes enemy outward");
    remove(e);
    r=self.advr_main;traceline(self.origin,self.origin-'0 0 80',TRUE,self);floorpoint=trace_endpos;
    self.flags=self.flags | FL_ONGROUND;self.handpos=floorpoint+'20 0 25';self.muzzlepos=floorpoint+'0 0 2';
    self.handvel='0 0 -5';r.advr_hammer_tip=floorpoint+'0 0 12';r.advr_hammer_time=time-0.014;
    r.advr_hammer_armed=1;r.advr_hammer_slam=0;r.advr_cooldown=0;
    ADVR_HammerFrame(1);
    ADVR_Assert(r.advr_hammer_slam>time && !r.advr_hammer_armed,"fast downward head contact triggers slam");
    hp=r.advr_hammer_slam;r.advr_cooldown=0;r.advr_hammer_time=time-0.014;
    r.advr_hammer_tip=floorpoint+'0 0 12';ADVR_HammerFrame(1);
    ADVR_Assert(r.advr_hammer_slam==hp,"floor contact cannot repeat slam without lifting and cooldown");
    r.advr_hammer_slam=0;r.advr_hammer_armed=1;r.advr_hammer_time=time-0.014;
    r.advr_hammer_tip=self.muzzlepos+'0 0 100';ADVR_HammerFrame(1);
    ADVR_Assert(!r.advr_hammer_slam,"teleport is not a slam");
    r.advr_hammer_time=time-0.014;r.advr_hammer_tip=self.muzzlepos-'0 0 12';ADVR_HammerFrame(1);
    ADVR_Assert(!r.advr_hammer_slam,"upward swing is not a slam");
    r.advr_hammer_time=0;ADVR_HammerFrame(1);ADVR_Assert(!r.advr_hammer_slam,"drawing a hammer is not a slam");
    self.handvel='0 0 0';r.advr_hammer_time=0;
    bprint("ADVR HAMMER PASS: identity, weight, parry, transitions, exclusions, radial slam, tracked floor contact and guards\n");
};
void() ADVR_TestHammerDown = {
    local entity e;
    if(advr_test_hammer_foe)remove(advr_test_hammer_foe);
    e=ADVR_HammerTestFoe();advr_test_hammer_foe=e;
    ADVR_HammerHit(e,e.origin,'0 4 -2',3);
    ADVR_Assert(e.health==935,"three metre per second hammer hit deals 65 damage");
    ADVR_Assert(e.advr_hammer_down && e.vr_knockdown==1 && isragdoll(e),"surviving hit creates live ragdoll");
    T_Damage(e,self,self,10,DAMARMOR);
    ADVR_Assert(e.health==925 && e.think==ADVR_HammerDownThink,"damage while down preserves recovery");
    e.advr_hammer_until=time+10;
    bprint("ADVR HAMMER DOWN PASS: actual hit, live ragdoll, subsequent damage\n");
};
void() ADVR_TestHammerState = {
    ADVR_Assert(advr_test_hammer_foe.health>0 && advr_test_hammer_foe.advr_hammer_down &&
        isragdoll(advr_test_hammer_foe),"live knocked-down body persists through physics and saves");
    advr_test_hammer_foe.advr_hammer_until=time;
    bprint("ADVR HAMMER STATE PASS\n");
};
void() ADVR_TestHammerUp = {
    ADVR_Assert(advr_test_hammer_foe.health>0 && !advr_test_hammer_foe.vr_knockdown &&
        !advr_test_hammer_foe.advr_hammer_down && advr_test_hammer_foe.solid==SOLID_SLIDEBOX,
        "survivor recovers with solid body and AI");
    bprint("ADVR HAMMER RECOVERY PASS\n");
};
void() ADVR_TestHammerKill = {
    local entity e,t;e=advr_test_hammer_foe;
    ADVR_Assert(e.advr_hammer_down,"death fixture starts knocked down");
    t=spawn();t.targetname="advr_hammer_kill_target";t.use=ADVR_TestRagdollTarget;e.target=t.targetname;
    advr_test_death_targets=0;advr_test_death_kills=killed_monsters;
    e.health=10;T_Damage(e,self,self,11,DAMARMOR);
    ADVR_Assert(e.health<=0 && !e.advr_hammer_down && !e.vr_knockdown,"death cancels living recovery");
};
void() ADVR_TestHammerDead = {
    local entity e;e=advr_test_hammer_foe;
    ADVR_Assert(e.health<=0 && isragdoll(e) && e.think==monster_deadbody_check,"downed death retains physical corpse and AD cleanup");
    ADVR_Assert(killed_monsters==advr_test_death_kills+1 && advr_test_death_targets==1,"downed death counts once and fires targets once");
    bprint("ADVR HAMMER DEATH PASS\n");
};
void() ADVR_TestHammerGrip = {
    ADVR_Assert(self.advr_main.advr_kind==ADVR_HAMMER && !self.advr_off && (self.vrbits0 & 32),"support hand grips hammer without swapping it");
    bprint("ADVR HAMMER GRIP PASS\n");
};
