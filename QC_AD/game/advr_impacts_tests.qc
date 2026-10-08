entity advr_flight_target,advr_flight_prop,advr_grip_record;
float advr_flight_kind,advr_grip_kind;
void() ADVR_TestImpacts = {
    local entity actor,foe,shot,r,p,oldother;
    local float hp,i,speed;
    actor=self;ADVR_Reset();self.advr_initialized=1;self.health=1000;self.flags=FL_CLIENT|FL_GODMODE;
    self.moditems=0;self.items=IT_AXE|IT_SHOTGUN;self.vrbits0=16384;
    cvar_set("vr_push","0.5");cvar_set("vr_hit_push","1");cvar_set("vr_kill_push","1");
    foe=spawn();foe.classname="advr_test_fiend";foe.classtype=CT_MONDEMON;
    foe.flags=FL_MONSTER;foe.movetype=MOVETYPE_STEP;foe.solid=SOLID_SLIDEBOX;
    foe.takedamage=DAMAGE_AIM;foe.health=foe.max_health=1000;foe.gibhealth=-80;
    foe.enemy=actor;foe.switchattacker=actor;foe.switchtimer=time+100;
    setsize(foe,'-16 -16 -24','16 16 32');setorigin(foe,self.origin+'80 0 0');
    foe.velocity='-600 0 180';foe.touch=Demon_JumpTouch;foe.th_jumpexit=demon1_jump11;
    shot=spawn();shot.owner=actor;shot.movetype=MOVETYPE_FLYMISSILE;shot.velocity='900 0 0';
    shot.classgroup=CG_PROJSHELLS;shot.classtype=CT_PROJ_SSG;setorigin(shot,foe.origin-'16 0 0');
    T_Damage(foe,shot,actor,4,DAMARMOR);
    ADVR_Assert(foe.velocity_x==-600,"one weak pellet does not interrupt a fiend");
    for(i=0;i<11;i=i+1)T_Damage(foe,shot,actor,4,DAMARMOR);
    ADVR_Assert(foe.velocity_x>0 && foe.velocity_x<=175,"pellet cloud reverses leap with capped knockback");
    ADVR_Assert(foe.touch==SUB_Null && foe.think==demon1_jump11,"heavy hit cancels damaging fiend leap with native exit");
    ADVR_Assert(foe.advr_shove && foe.advr_shove.owner==foe,"heavy hit retains short slide helper");
    speed=foe.velocity_x;
    for(i=0;i<50;i=i+1)T_Damage(foe,shot,actor,4,DAMARMOR);
    ADVR_Assert(foe.velocity_x<=175,"pellets cannot multiply the capped impulse");
    foe.advr_push_until=time-1;foe.velocity='0 0 0';T_Damage(foe,shot,actor,4,DAMARMOR);
    ADVR_Assert(foe.velocity=='0 0 0',"separate weak shots do not accumulate forever");
    foe.bossflag=1;ADVR_HitPush(foe,actor,actor,100);ADVR_Assert(foe.velocity=='0 0 0',"scripted bosses stay anchored");foe.bossflag=0;
    cvar_set("vr_hit_push","0");ADVR_HitPush(foe,actor,actor,100);ADVR_Assert(foe.velocity=='0 0 0',"hit push setting respected");cvar_set("vr_hit_push","1");
    shot.classgroup=CG_PROJROCKETS;setorigin(shot,foe.origin+'16 0 0');
    ADVR_HitPush(foe,shot,actor,100);ADVR_Assert(foe.velocity_x<0,"explosion pushes away from blast, not shooter");
    r=ADVR_Record(IT_AXE);self.advr_main=r;
    ADVR_Assert(ADVR_CanParry(r),"axe may parry");self.moditems=IT_UPGRADE_AXE;
    ADVR_Assert(ADVR_CanParry(r),"Shadow Axe may parry");self.moditems=IT_UPGRADE_GHOOK;
    ADVR_Assert(!ADVR_CanParry(r),"grapple cannot parry");self.moditems=0;
    r.advr_kind=ADVR_SWORD;ADVR_Assert(ADVR_CanParry(r),"knight sword may parry");
    r.advr_kind=ADVR_HELLSWORD;ADVR_Assert(ADVR_CanParry(r),"hellknight sword may parry");
    r.advr_kind=ADVR_SAW;ADVR_Assert(!ADVR_CanParry(r),"chainsaw excluded for now");
    r.advr_kind=0;
    for(i=1;i<=64;i=i*2){r.advr_weapon=i;ADVR_Assert(!ADVR_CanParry(r) && !ADVR_GuardLine(1),"every ranged weapon is excluded from guards");}
    r.advr_weapon=IT_AXE;r.advr_kind=ADVR_SWORD;
    self.handpos=self.origin+self.view_ofs;self.handthrowvel='12 0 0';self.handthrowflick='0 0 0';
    self.handthrowpos='0 0 0';self.handthrowage=0;ADVR_Drop(1);
    p=find(world,classname,"advr_dropped_weapon");while(p && p.weaponinst!=r)p=find(p,classname,"advr_dropped_weapon");
    ADVR_Assert(p && p.advr_throw_armed && p.gravity<0.6,"throw uses original gain, weight and real-world gravity");
    p.velocity='700 0 0';hp=foe.health;oldother=other;self=p;other=foe;ADVR_PropTouch();self=actor;other=oldother;
    ADVR_Assert(foe.health<hp && p.throwhit,"sword contact deals damage and consumes one impact");
    hp=foe.health;self=p;other=foe;ADVR_PropTouch();self=actor;other=oldother;
    ADVR_Assert(foe.health==hp,"resting weapon cannot repeatedly damage target");
    ADVR_Catch(p,1);self.handthrowvel='0 0 0';ADVR_Drop(1);
    p=find(world,classname,"advr_dropped_weapon");while(p && p.weaponinst!=r)p=find(p,classname,"advr_dropped_weapon");
    ADVR_Assert(!p.advr_throw_armed,"gently dropping a weapon cannot hurt enemies");
    remove(p);remove(r);if(foe.advr_shove)remove(foe.advr_shove);remove(foe);remove(shot);ADVR_Sync();
    bprint("ADVR IMPACTS PASS: pellet knockback, leap cancellation, caps/exclusions, melee-only parry, thrown damage and safe drops\n");
};

// Exercise the real Box3D flight/collision path, not just its touch callback.
void() ADVR_TestThrowFlight = {
    local entity r,p;local vector start,dir;local float i;
    ADVR_Reset();self.advr_initialized=1;self.items=IT_AXE;self.moditems=0;
    self.flags=FL_CLIENT|FL_GODMODE;self.health=1000;
    start=self.origin+'0 0 32';
    for(i=0;i<4;i=i+1){makevectors('0 90 0'*i);dir=v_forward;traceline(start,start+dir*96,TRUE,self);if(trace_fraction==1)break;}
    ADVR_Assert(i<4,"flight fixture has clear space");
    advr_flight_target=spawn();advr_flight_target.classname="advr_flight_target";
    advr_flight_target.classtype=CT_TARGETDUMMY;advr_flight_target.takedamage=DAMAGE_YES;
    setmodel(advr_flight_target,"progs/mon_soldier.mdl");
    advr_flight_target.health=1000;advr_flight_target.solid=SOLID_BBOX;
    setsize(advr_flight_target,'-12 -12 -24','12 12 24');setorigin(advr_flight_target,start+dir*80);
    r=ADVR_Record(IT_AXE);r.advr_kind=advr_flight_kind;self.advr_main=r;
    self.handpos=start;self.handrot=vectoangles(dir);self.handthrowvel=dir*16;
    self.handthrowflick='0 0 0';self.handthrowpos='0 0 0';self.handthrowage=0;self.handavel='0 0 0';
    ADVR_Drop(1);p=find(world,classname,"advr_dropped_weapon");
    while(p && p.weaponinst!=r)p=find(p,classname,"advr_dropped_weapon");
    advr_flight_prop=p;ADVR_Sync();
};
void() ADVR_TestThrowState = {
    dprint("THROW FLIGHT ");dprint(ftos(advr_flight_kind));dprint(" hp ");dprint(ftos(advr_flight_target.health));
    dprint(" vel ");dprint(vtos(advr_flight_prop.velocity));dprint(" armed ");dprint(ftos(advr_flight_prop.advr_throw_armed));dprint("\n");
    ADVR_Assert(advr_flight_target.health<1000,"real thrown weapon flight damages target");
    remove(advr_flight_target);remove(advr_flight_prop.weaponinst);remove(advr_flight_prop);
    advr_flight_kind=advr_flight_kind+1;
    bprint("ADVR THROW FLIGHT PASS: physical collision dealt damage\n");
};
void() ADVR_TestSwordGrip = {
    ADVR_Reset();self.advr_initialized=1;self.flags=FL_CLIENT|FL_GODMODE;self.health=1000;
    advr_grip_kind=advr_grip_kind+1;if(advr_grip_kind>2)advr_grip_kind=1;
    self.items=IT_AXE;self.moditems=0;self.advr_main=ADVR_Record(IT_AXE);self.advr_main.advr_kind=advr_grip_kind;
    advr_grip_record=self.advr_main;ADVR_Sync();
};
void() ADVR_TestSwordGripState = {
    dprint("SWORD INPUT bits ");dprint(ftos(self.vrbits0));dprint(" support ");dprint(ftos(weaponanygrip(self,0)));
    dprint(" main ");dprint(vtos(self.handpos));dprint(" off ");dprint(vtos(self.offhandpos));dprint(" tip ");dprint(vtos(self.muzzlepos));dprint("\n");
    ADVR_Assert(self.advr_main==advr_grip_record && !self.advr_off,"support grip must not swap or duplicate sword");
    ADVR_Assert(weaponanygrip(self,0)>0 && (self.vrbits0 & 32),"real tracked sword uses both hands");
    bprint("ADVR SWORD GRIP PASS: tracked support grip retains sword and two-hand control\n");
};
void() ADVR_TestSwordHandoff = {
    ADVR_Assert(self.advr_off==advr_grip_record && !self.advr_main,"releasing sword handle hands it to supporting hand");
    bprint("ADVR SWORD HANDOFF PASS: support hand retains sword on release\n");
};
