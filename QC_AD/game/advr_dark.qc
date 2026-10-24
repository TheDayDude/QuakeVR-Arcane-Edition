// Dark Rune allies retain native monster attacks, with faction targeting isolated here.
float(string name) ADVR_DarkSpawnClass = {
    if(name=="monster_army"){self.classname=name;monster_army();return 1;}
    if(name=="monster_army_grenade"){self.classname=name;monster_army_grenade();return 1;}
    if(name=="monster_army_plasma"){self.classname=name;monster_army_plasma();return 1;}
    if(name=="monster_army_rocket"){self.classname=name;monster_army_rocket();return 1;}
    if(name=="monster_baron"){self.classname=name;monster_baron();return 1;}
    if(name=="monster_base_enforcer"){self.classname=name;monster_base_enforcer();return 1;}
    if(name=="monster_bob"){self.classname=name;monster_bob();return 1;}
    if(name=="monster_boglord"){self.classname=name;monster_boglord();return 1;}
    if(name=="monster_boil"){self.classname=name;monster_boil();return 1;}
    if(name=="monster_boss"){self.classname=name;monster_boss();return 1;}
    if(name=="monster_centurion"){self.classname=name;monster_centurion();return 1;}
    if(name=="monster_chthon"){self.classname=name;monster_chthon();return 1;}
    if(name=="monster_dcrossbow"){self.classname=name;monster_dcrossbow();return 1;}
    if(name=="monster_death_guard"){self.classname=name;monster_death_guard();return 1;}
    if(name=="monster_death_knight"){self.classname=name;monster_death_knight();return 1;}
    if(name=="monster_death_lord"){self.classname=name;monster_death_lord();return 1;}
    if(name=="monster_defender"){self.classname=name;monster_defender();return 1;}
    if(name=="monster_deflector"){self.classname=name;monster_deflector();return 1;}
    if(name=="monster_demon1"){self.classname=name;monster_demon1();return 1;}
    if(name=="monster_dfury"){self.classname=name;monster_dfury();return 1;}
    if(name=="monster_dguard"){self.classname=name;monster_dguard();return 1;}
    if(name=="monster_dknight"){self.classname=name;monster_dknight();return 1;}
    if(name=="monster_dknightghost"){self.classname=name;monster_dknightghost();return 1;}
    if(name=="monster_dog"){self.classname=name;monster_dog();return 1;}
    if(name=="monster_dprince"){self.classname=name;monster_dprince();return 1;}
    if(name=="monster_drole"){self.classname=name;monster_drole();return 1;}
    if(name=="monster_dsergeant"){self.classname=name;monster_dsergeant();return 1;}
    if(name=="monster_edie"){self.classname=name;monster_edie();return 1;}
    if(name=="monster_eel"){self.classname=name;monster_eel();return 1;}
    if(name=="monster_eidolon"){self.classname=name;monster_eidolon();return 1;}
    if(name=="monster_eidolon_wavetrig"){self.classname=name;monster_eidolon_wavetrig();return 1;}
    if(name=="monster_eliminator"){self.classname=name;monster_eliminator();return 1;}
    if(name=="monster_enforcer"){self.classname=name;monster_enforcer();return 1;}
    if(name=="monster_firetopboss"){self.classname=name;monster_firetopboss();return 1;}
    if(name=="monster_fish"){self.classname=name;monster_fish();return 1;}
    if(name=="monster_floyd"){self.classname=name;monster_floyd();return 1;}
    if(name=="monster_freddie"){self.classname=name;monster_freddie();return 1;}
    if(name=="monster_fumigator"){self.classname=name;monster_fumigator();return 1;}
    if(name=="monster_gargoyle"){self.classname=name;monster_gargoyle();return 1;}
    if(name=="monster_gaunt"){self.classname=name;monster_gaunt();return 1;}
    if(name=="monster_golem"){self.classname=name;monster_golem();return 1;}
    if(name=="monster_gug"){self.classname=name;monster_gug();return 1;}
    if(name=="monster_hell_knight"){self.classname=name;monster_hell_knight();return 1;}
    if(name=="monster_hell_pointknight"){self.classname=name;monster_hell_pointknight();return 1;}
    if(name=="monster_hogre"){self.classname=name;monster_hogre();return 1;}
    if(name=="monster_hogreham"){self.classname=name;monster_hogreham();return 1;}
    if(name=="monster_hogremac"){self.classname=name;monster_hogremac();return 1;}
    if(name=="monster_icegolem"){self.classname=name;monster_icegolem();return 1;}
    if(name=="monster_icegolem_wavetrig"){self.classname=name;monster_icegolem_wavetrig();return 1;}
    if(name=="monster_jim"){self.classname=name;monster_jim();return 1;}
    if(name=="monster_judgeminion"){self.classname=name;monster_judgeminion();return 1;}
    if(name=="monster_judicator"){self.classname=name;monster_judicator();return 1;}
    if(name=="monster_juggernaut"){self.classname=name;monster_juggernaut();return 1;}
    if(name=="monster_justice"){self.classname=name;monster_justice();return 1;}
    if(name=="monster_knight"){self.classname=name;monster_knight();return 1;}
    if(name=="monster_lostsoul"){self.classname=name;monster_lostsoul();return 1;}
    if(name=="monster_mammoth"){self.classname=name;monster_mammoth();return 1;}
    if(name=="monster_minotaur"){self.classname=name;monster_minotaur();return 1;}
    if(name=="monster_minotaurminion"){self.classname=name;monster_minotaurminion();return 1;}
    if(name=="monster_mummy"){self.classname=name;monster_mummy();return 1;}
    if(name=="monster_nour"){self.classname=name;monster_nour();return 1;}
    if(name=="monster_nourminion"){self.classname=name;monster_nourminion();return 1;}
    if(name=="monster_ogre"){self.classname=name;monster_ogre();return 1;}
    if(name=="monster_ogre_fishing"){self.classname=name;monster_ogre_fishing();return 1;}
    if(name=="monster_ogre_fishing_ghost"){self.classname=name;monster_ogre_fishing_ghost();return 1;}
    if(name=="monster_ogre_flak"){self.classname=name;monster_ogre_flak();return 1;}
    if(name=="monster_ogre_marksman"){self.classname=name;monster_ogre_marksman();return 1;}
    if(name=="monster_ogre_precache"){self.classname=name;monster_ogre_precache();return 1;}
    if(name=="monster_oldone"){self.classname=name;monster_oldone();return 1;}
    if(name=="monster_polyp"){self.classname=name;monster_polyp();return 1;}
    if(name=="monster_pyro"){self.classname=name;monster_pyro();return 1;}
    if(name=="monster_scorpion"){self.classname=name;monster_scorpion();return 1;}
    if(name=="monster_seeker"){self.classname=name;monster_seeker();return 1;}
    if(name=="monster_sentinel"){self.classname=name;monster_sentinel();return 1;}
    if(name=="monster_shalrath"){self.classname=name;monster_shalrath();return 1;}
    if(name=="monster_shalrathminion"){self.classname=name;monster_shalrathminion();return 1;}
    if(name=="monster_shambler"){self.classname=name;monster_shambler();return 1;}
    if(name=="monster_shub"){self.classname=name;monster_shub();return 1;}
    if(name=="monster_shubupsd"){self.classname=name;monster_shubupsd();return 1;}
    if(name=="monster_skullwiz"){self.classname=name;monster_skullwiz();return 1;}
    if(name=="monster_skullwizminion"){self.classname=name;monster_skullwizminion();return 1;}
    if(name=="monster_spider"){self.classname=name;monster_spider();return 1;}
    if(name=="monster_steelclaw"){self.classname=name;monster_steelclaw();return 1;}
    if(name=="monster_swampling"){self.classname=name;monster_swampling();return 1;}
    if(name=="monster_sweeper"){self.classname=name;monster_sweeper();return 1;}
    if(name=="monster_sword"){self.classname=name;monster_sword();return 1;}
    if(name=="monster_tarbaby"){self.classname=name;monster_tarbaby();return 1;}
    if(name=="monster_turretbal"){self.classname=name;monster_turretbal();return 1;}
    if(name=="monster_vermis"){self.classname=name;monster_vermis();return 1;}
    if(name=="monster_voreling"){self.classname=name;monster_voreling();return 1;}
    if(name=="monster_wizard"){self.classname=name;monster_wizard();return 1;}
    if(name=="monster_wraith"){self.classname=name;monster_wraith();return 1;}
    if(name=="monster_wraithminion"){self.classname=name;monster_wraithminion();return 1;}
    if(name=="monster_wraithminion2"){self.classname=name;monster_wraithminion2();return 1;}
    if(name=="monster_xmas_elf"){self.classname=name;monster_xmas_elf();return 1;}
    if(name=="monster_xmas_raindeer"){self.classname=name;monster_xmas_raindeer();return 1;}
    if(name=="monster_xmas_santa"){self.classname=name;monster_xmas_santa();return 1;}
    if(name=="monster_xmas_snowman"){self.classname=name;monster_xmas_snowman();return 1;}
    if(name=="monster_zombie"){self.classname=name;monster_zombie();return 1;}
    if(name=="monster_zombiek"){self.classname=name;monster_zombiek();return 1;}
    return 0;
};
void() ADVR_DarkPrecache = {
    local entity saved,e;local float i,total;
    saved=self;total=total_monsters;
    for(i=0;i<3;i=i+1){e=spawn();self=e;self.nomonstercount=1;
        if(i==0)ADVR_DarkSpawnClass("monster_zombie");else if(i==1)ADVR_DarkSpawnClass("monster_zombiek");else ADVR_DarkSpawnClass("monster_lostsoul");remove(e);}
    self=saved;total_monsters=total;
};
float(entity e) ADVR_DarkHostile = {return e && (e.flags & FL_MONSTER) && e.health>0 && !e.deadflag && e.takedamage && !e.advr_dark_owner;};
float() ADVR_DarkFindTarget = {
    local entity e,best;local float distance,nearest;
    if(ADVR_DarkHostile(self.enemy))return 1;
    nearest=1200;e=world;
    while((e=nextent(e))){
        if(!ADVR_DarkHostile(e) || e==self)continue;
        distance=vlen(modelcentre(e)-modelcentre(self));if(distance>=nearest)continue;
        traceline(modelcentre(self),modelcentre(e),TRUE,self);if(trace_fraction<1)continue;
        best=e;nearest=distance;
    }
    if(!best){
        self.enemy=world;self.oldenemy=world;
        if(self.advr_dark_owner.health>0 && vlen(self.origin-self.advr_dark_owner.origin)>100){self.goalentity=self.advr_dark_owner;self.pausetime=0;}
        else {self.goalentity=world;self.pausetime=time+1;}
        return 0;
    }
    self.enemy=best;self.oldenemy=world;self.goalentity=best;
    if(!self.inpain)FoundTarget();return 1;
};
void(entity e) ADVR_DarkBurst = {
    local entity saved;
    if(!e)return;saved=self;self=e;
    if(e.advr_burn)ADVR_FireOut(e.advr_burn);
    if(e.advr_acid){remove(e.advr_acid);e.advr_acid=world;}
    ADVR_Blood(e,modelcentre(e),'0 0 100',60);particle2(modelcentre(e),'0 0 40',1,36);
    self.health=-80;self.gib1dmg=self.gib1exp=0;
    ThrowGib(1,2);ThrowGib(2,2);ThrowGib(3,2);ThrowGib(4,3);
    sound(e,CHAN_VOICE,GIB_SOUND_UDEATH,0.8,ATTN_NORM);
    if(e.advr_dark_control){remove(e.advr_dark_control);e.advr_dark_control=world;}
    remove(e);self=saved;
};
void() ADVR_DarkControl = {
    local entity e,saved;local vector delta;
    e=self.enemy;
    if(!e || e.advr_dark_control!=self){remove(self);return;}
    if(e.health<=0){ADVR_DarkBurst(e);return;}
    particle2(modelcentre(e),'0 0 12',4,2);
    // Movement and target acquisition belong to native animation/AI ticks.
    self.nextthink=time+0.25;
};
// Native summons created by a reanimated monster inherit its faction and expiry.
void() ADVR_DarkAdopt = {
    local entity c;
    self.advr_dark_owner=self.owner.advr_dark_owner;self.advr_dark_until=0;
    self.advr_dark_used=1;self.advr_drop_done=1;self.advr_mana_paid=1;self.nomonstercount=1;self.nospawndamage=1;
    c=spawn();c.classname="advr_dark_controller";c.enemy=self;c.owner=self.advr_dark_owner;
    c.think=ADVR_DarkControl;c.nextthink=time+0.25;self.advr_dark_control=c;
};
float(entity corpse) ADVR_DarkHumanoid = {
    return corpse.classgroup==CG_ARMY || corpse.classgroup==CG_ENFORCER || corpse.classgroup==CG_KNIGHT ||
        corpse.classgroup==CG_DKNIGHT || corpse.classgroup==CG_DCAPTAIN || corpse.classgroup==CG_ZOMBIE ||
        corpse.classgroup==CG_OGRE || corpse.classtype==CT_MONSKULLW;
};
// Validate a fresh native hull before consuming the source corpse. No death targets
// or map counters are replayed, and an ally corpse can never be recycled.
entity(entity corpse,vector at,string name,entity caster,float undead) ADVR_DarkCreate = {
    local entity saved,n,c;local float total,oldsolid,i,placed;local vector spot;
    saved=self;total=total_monsters;n=spawn();self=n;n.nomonstercount=1;
    n.advr_dark_owner=caster;n.advr_dark_until=0;n.advr_dark_used=1;n.advr_drop_done=1;n.advr_mana_paid=1;n.nospawndamage=1;
    setorigin(n,at);n.angles_y=caster.angles_y;if(corpse && !undead)n.skin=corpse.skin;
    if(!ADVR_DarkSpawnClass(name)){remove(n);self=saved;return world;}
    total_monsters=total;
    if(!n.mdl || !n.th_stand){remove(n);self=saved;return world;}
    setmodel(n,n.mdl);setsize(n,n.bbmins,n.bbmaxs);n.solid=SOLID_SLIDEBOX;n.movetype=MOVETYPE_STEP;
    if(n.classmove==MON_MOVEFLY)n.flags=n.flags | FL_FLY;
    if(n.classmove==MON_MOVESWIM)n.flags=n.flags | FL_SWIM;
    if(corpse){oldsolid=corpse.solid;corpse.solid=SOLID_NOT;setorigin(corpse,corpse.origin);}
    for(i=0;i<13;i=i+1){
        spot=at;
        if(i>0){makevectors('0 0 0'+ '0 30 0'*(i-1));spot=at+v_forward*48+'0 0 24';}
        setorigin(n,spot);tracebox(spot,n.mins,n.maxs,spot,FALSE,n);
        if(!trace_startsolid && !trace_allsolid){placed=1;break;}
    }
    if(!placed){if(corpse){corpse.solid=oldsolid;setorigin(corpse,corpse.origin);}remove(n);self=saved;return world;}
    n.oldorigin=n.origin;n.enemy=world;monster_spawn();total_monsters=total;
    n.nomonstercount=1;n.target=n.target2=n.target3=n.target4=n.deathtarget=n.killtarget=n.counttarget="";
    if(undead){
        if(n.classtype==CT_MONZOMBIEK)zombiek_onground(MONAI_ZOMBIEFLR);else zombie_onground(MONAI_ZOMBIEFLR);
        n.think=n.th_wakeup;n.nextthink=time+1.2;
    }else {n.think=n.th_stand;n.nextthink=time+0.1;}
    c=spawn();c.classname="advr_dark_controller";c.enemy=n;c.owner=caster;c.think=ADVR_DarkControl;c.nextthink=time+0.25;n.advr_dark_control=c;
    self=saved;if(corpse)ADVR_DarkBurst(corpse);
    particle2(n.origin,'0 0 40',4,10);return n;
};
void() ADVR_DarkCast = {
    local entity e,next,n,caster;local float reach,i,count,raised;local string name;local vector at;
    caster=self;reach=400*max(0.1,cvar("vr_world_scale"));e=nextent(world);
    while(e){next=nextent(e);
        if(raised<20 && ADVR_Raiseable(e) && vlen(e.origin-caster.origin)<=reach){
            name=e.classname;
            if(ADVR_DarkHumanoid(e)){if(random()<0.5)name="monster_zombie";else name="monster_zombiek";}
            n=ADVR_DarkCreate(e,e.origin+'0 0 8',name,caster,ADVR_DarkHumanoid(e));if(n)raised=raised+1;
        }e=next;
    }
    count=3+floor(random()*3);
    for(i=0;i<count;i=i+1){
        makevectors('0 0 0'+'0 1 0'*(caster.angles_y+i*360/count));at=caster.origin+v_forward*64+'0 0 48';
        ADVR_DarkCreate(world,at,"monster_lostsoul",caster,0);
    }
    sound(caster,CHAN_AUTO,"misc/r_tele1.wav",0.8,ATTN_NORM);
};



void() ADVR_TestDarkRune = {
    local entity player,book,e,n,z,foe,job;local float cfg,dt,i,count,total,kills,hp;
    player=self;cfg=configflag;dt=frametime;frametime=0.05;total=total_monsters;kills=killed_monsters;
    ADVR_TestMagicView();book=self.advr_off;
    configflag=configflag-(configflag & SVR_RUNE_KEY2);book.advr_kind=ADVR_TOME;
    ADVR_Assert(!(ADVR_SpellMask(self,book) & 2048),"Dark rune locked without Black rune");
    book.advr_kind=ADVR_DEBUGTOME;
    ADVR_Assert(ADVR_SpellMask(self,book) & 2048,"debug tome unlocks Dark without rune");
    self.advr_spell=11;self.mana=50;self.vrbits0=16384;
    self.handpos=ADVR_Head(self)+'24 0 -8';self.handrot=self.offhandrot='0 0 0';
    self.handvel=self.offhandvel=self.handavel=self.offhandavel='0 0 0';
    self.mainhand_hotspot=self.offhand_hotspot=0;self.advr_magic_sticks=2;
    for(i=0;i<62;i=i+1)ADVR_MagicFrame();
    ADVR_Assert(self.advr_magic_ready && self.advr_magic_fx.model=="progs/advr_dark_rune.mdl","Black rune materializes and charges");
    self.advr_magic_sticks=0;ADVR_MagicFrame();
    ADVR_Assert(self.mana==50,"debug Dark cast is free");
    e=world;while((e=nextent(e))){if(e.advr_dark_owner==player){count=count+1;ADVR_Assert(!e.advr_dark_until && e.th_stand,"native ally has no timeout");}}
    ADVR_Assert(count>=3 && count<=5,"three to five lost souls without corpses");
    n=ADVR_DarkCreate(world,player.origin+'0 110 64',"monster_demon1",player,0);
    ADVR_Assert(n && n.classname=="monster_demon1","nonhumanoid reanimation retains species");
    z=ADVR_DarkCreate(world,player.origin+'0 -110 64',"monster_zombiek",player,1);
    ADVR_Assert(z && z.inpain==2 && z.think==z.th_wakeup,"undead starts prone with native rising sequence");
    self=z;z.th_wakeup();
    for(i=0;i<35;i=i+1){if(z.inpain)z.think();}self=player;
    ADVR_Assert(!z.inpain && z.solid==SOLID_SLIDEBOX,"native undead rise completes and restores collision");
    e=spawn();e.owner=n;self=e;monster_lostsoul();self=player;
    ADVR_Assert(e.advr_dark_owner==player && e.advr_dark_until==n.advr_dark_until && e.nomonstercount,"native child summons inherit faction and expiry");ADVR_DarkBurst(e);
    hp=player.health;T_Damage(player,n,n,10,NOARMOR);ADVR_Assert(player.health==hp,"allies cannot hurt player");
    hp=z.health;T_Damage(z,n,n,10,NOARMOR);ADVR_Assert(z.health==hp,"allies cannot hurt allies");
    foe=spawn();foe.flags=FL_MONSTER;foe.health=100;foe.takedamage=DAMAGE_YES;setorigin(foe,n.origin+'80 0 0');
    self=n;ADVR_DarkFindTarget();self=player;ADVR_Assert(n.enemy==foe,"ally acquires hostile monster instead of player");remove(foe);
    job=n.advr_dark_control;n.health=0;self=job;ADVR_DarkControl();self=player;
    ADVR_Assert(!n.modelindex,"dead ally bursts and is removed");
    e=world;while((e=nextent(e))){if(e.advr_dark_owner==player && e.health>0)ADVR_DarkBurst(e);}
    ADVR_Assert(total_monsters==total && killed_monsters==kills,"summons and expiry preserve map kill counts");
    e=spawn();e.classname="monster_knight";e.classgroup=CG_KNIGHT;e.flags=FL_MONSTER;e.health=-1;
    setmodel(e,"progs/knight.mdl");setorigin(e,player.origin+'0 110 48');
    n=ADVR_DarkCreate(e,e.origin,"monster_zombie",player,1);
    ADVR_Assert(n && !e.modelindex && n.classgroup==CG_ZOMBIE,"humanoid corpse consumed and replaced with undead");
    ADVR_DarkBurst(n);
    configflag=cfg;frametime=dt;ADVR_TestMagicView();
    bprint("ADVR DARK RUNE PASS: gate, charge, cost, souls, native species, prone undead, factions, expiry and counters\n");
};

void() ADVR_TestDarkRuneView = {
    local float i,dt;
    ADVR_TestMagicView();configflag=configflag | SVR_RUNE_KEY2;self.advr_spell=11;self.mana=50;
    ADVR_DarkCast();
    dt=frametime;frametime=0.05;self.vrbits0=16384;self.advr_magic_sticks=2;
    self.handpos=ADVR_Head(self)+'24 0 -8';self.handrot=self.offhandrot='0 0 0';
    self.handvel=self.offhandvel=self.handavel=self.offhandavel='0 0 0';
    self.mainhand_hotspot=self.offhand_hotspot=0;
    for(i=0;i<62;i=i+1)ADVR_MagicFrame();frametime=dt;ADVR_Sync();
};

