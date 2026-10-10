// Isolated developer fixture; never run on a user's save.
float() ADVR_TestDropCount = {
    local entity p;local float n;
    p=find(world,classname,"advr_dropped_weapon");
    while(p){n=n+1;p=find(p,classname,"advr_dropped_weapon");}return n;
};
void(entity foe,float c,float packed) ADVR_TestLootClass = {
    foe.classtype=c;
    ADVR_Assert(ADVR_LootType(foe,0,0)==packed,"enemy class yields expected weapon");
};
void() ADVR_TestDropDebris = {
    local entity actor,foe,e;local float n,i;
    actor=self;foe=spawn();foe.classtype=CT_MONARMY;setorigin(foe,self.origin+'0 80 0');
    foe.gib1mdl=foe.gib2mdl=foe.gib3mdl=foe.gib4mdl=foe.gib5mdl="progs/w_soldiergun.mdl";
    ADVR_SpawnLoot(foe,IT_SHOTGUN);
    ADVR_Assert(foe.advr_loot_spawned,"successful usable drop marks debris replacement");
    for(i=11;i<=15;i=i+1){
        ADVR_Assert(ADVR_SkipWeaponGib(foe,i),"all custom weapon debris slots are suppressed");
        self=foe;ThrowGib(i,2);self=actor;
    }
    e=find(world,classname,"item_gib");while(e){ADVR_Assert(e.owner!=foe,"no decorative weapon entity spawned");e=find(e,classname,"item_gib");}
    foe.gib1mdl=GIB1_BLOOD;
    ADVR_Assert(!ADVR_SkipWeaponGib(foe,11) && !ADVR_SkipWeaponGib(foe,1) && !ADVR_SkipWeaponGib(foe,25),"body and head gibs are retained");
    self=foe;ThrowGib(11,1);self=actor;
    ADVR_Assert(gibitem.owner==foe && gibitem.model==GIB1_BLOOD,"flesh debris still spawns");remove(gibitem);
    foe.advr_loot_spawned=0;foe.gib1mdl="progs/w_soldiergun.mdl";
    ADVR_Assert(!ADVR_SkipWeaponGib(foe,11),"no usable drop leaves native debris intact");
    self=foe;ThrowGib(11,1);self=actor;
    ADVR_Assert(gibitem.owner==foe && gibitem.model==foe.gib1mdl,"unreplaced decorative weapon still spawns");remove(gibitem);
    remove(foe);
    bprint("ADVR DROP DEBRIS PASS: weapon slots suppressed after loot, flesh/head and no-loot debris retained\n");
};
void() ADVR_TestDrops = {
    local entity actor,foe,p,r,target,missile;
    local float n,i,hp,mods;
    ADVR_TestDropDebris();
    actor=self;ADVR_Reset();self.advr_initialized=1;self.health=1000;self.flags=FL_CLIENT|FL_GODMODE;
    self.items=IT_AXE|IT_SHOTGUN|IT_SUPER_SHOTGUN|IT_LIGHTNING|IT_GRENADE_LAUNCHER;
    self.moditems=0;self.ammo_shells=40;self.ammo_cells=40;self.ammo_rockets=20;
    self.vrbits0=16384;self.waterlevel=0;cvar_set("vr_enemy_drops_chance_mult","1");
    cvar_set("vr_reload_mode","1");
    cvar_set("vr_chainsaw_fuel_use","5");cvar_set("vr_chainsaw_damage","80");
    foe=spawn();setorigin(foe,self.origin+'0 80 0');
    ADVR_TestLootClass(foe,CT_MONARMY,IT_SHOTGUN);
    ADVR_TestLootClass(foe,CT_MONKNIGHT,IT_AXE+ADVR_SWORD*65536);
    ADVR_TestLootClass(foe,CT_MONDGUARD,IT_AXE+ADVR_SWORD*65536);
    ADVR_TestLootClass(foe,CT_MONDFURY,IT_AXE+ADVR_SWORD*65536);
    ADVR_TestLootClass(foe,CT_MONZOMBIEK,IT_AXE+ADVR_SWORD*65536);
    ADVR_TestLootClass(foe,CT_MONHELLK,IT_AXE+ADVR_HELLSWORD*65536);
    ADVR_TestLootClass(foe,CT_MONDKNIGHT,IT_AXE+ADVR_HELLSWORD*65536);
    ADVR_TestLootClass(foe,CT_MONDBLOOD,IT_AXE+ADVR_HELLSWORD*65536);
    ADVR_TestLootClass(foe,CT_MONDPRINCE,IT_AXE+ADVR_HELLSWORD*65536);
    ADVR_TestLootClass(foe,CT_MONDSERG,IT_AXE+ADVR_HELLSWORD*65536);
    ADVR_TestLootClass(foe,CT_MONCOMM,IT_AXE+ADVR_HELLSWORD*65536);
    ADVR_TestLootClass(foe,CT_MONJUSTICE,IT_AXE+ADVR_HELLSWORD*65536);
    ADVR_TestLootClass(foe,CT_MONJUDGE,IT_AXE+ADVR_HELLSWORD*65536);
    ADVR_TestLootClass(foe,CT_MONOGRE,IT_AXE+ADVR_SAW*65536);
    ADVR_Assert(ADVR_LootType(foe,0.49,0.75)==IT_GRENADE_LAUNCHER,"ogre launcher alternative");
    ADVR_Assert(!ADVR_LootType(foe,0.5,0),"ogre half chance");
    ADVR_TestLootClass(foe,CT_MONHOGRE,IT_AXE+ADVR_SAW*65536);
    ADVR_TestLootClass(foe,CT_MONHOGREHAM,IT_AXE+ADVR_HAMMER*65536);
    ADVR_TestLootClass(foe,CT_MONHOGREMAC,IT_GRENADE_LAUNCHER);
    ADVR_TestLootClass(foe,CT_MONARMYPLASMA,IT_LIGHTNING+ADVR_PLASMA*65536);
    ADVR_TestLootClass(foe,CT_MONENFORCER,IT_LIGHTNING+ADVR_PLASMA*65536);
    ADVR_TestLootClass(foe,CT_MONELIMATOR,IT_LIGHTNING+ADVR_PLASMA*65536);
    ADVR_TestLootClass(foe,CT_MONDEFENDER,IT_SUPER_SHOTGUN+ADVR_SSG*65536);
    ADVR_Assert(ADVR_LootType(foe,0,0.75)==IT_GRENADE_LAUNCHER,"defender launcher alternative");
    ADVR_TestLootClass(foe,CT_MONSHAM,0);
    foe.classtype=CT_MONKNIGHT;foe.classgroup=CG_STONE;
    ADVR_Assert(!ADVR_LootType(foe,0,0),"statues do not drop metal swords");foe.classgroup=0;
    cvar_set("vr_enemy_drops_chance_mult","0");ADVR_Assert(!ADVR_LootType(foe,0,0),"drop multiplier zero");
    cvar_set("vr_enemy_drops_chance_mult","1");
    // Native kill pipeline, including an overkill, must drop exactly once.
    remove(foe);
    for(i=0;i<2;i=i+1){
        foe=spawn();foe.classname="monster_army";setorigin(foe,self.origin+'0 80 0');
        self=foe;monster_army();self=actor;
        setmodel(foe,foe.mdl);setsize(foe,foe.bbmins,foe.bbmaxs);
        foe.flags=foe.flags|FL_MONSTER;foe.solid=SOLID_SLIDEBOX;foe.movetype=MOVETYPE_STEP;
        foe.health=10;foe.takedamage=DAMAGE_AIM;foe.nextthink=time+600;
        n=ADVR_TestDropCount();T_Damage(foe,actor,actor,11+i*1000,NOARMOR);
        ADVR_Assert(ADVR_TestDropCount()==n+1 && foe.advr_loot_spawned,"native death or overkill drops one shotgun and replaces weapon debris");
        self=foe;ADVR_EnemyDrop();self=actor;
        ADVR_Assert(ADVR_TestDropCount()==n+1,"repeated death cannot duplicate loot");
        remove(foe);
    }
    foe=spawn();setorigin(foe,self.origin+'0 80 0');
    self.handpos=self.origin+self.view_ofs;self.handrot='0 0 0';self.muzzlepos=self.handpos+'36 0 0';
    // Upgrade flags do not turn a sword or ordinary enemy axe into Shadow Axe.
    self.moditems=IT_UPGRADE_AXE|IT_UPGRADE_SSG;mods=self.moditems;
    p=ADVR_SpawnLoot(foe,IT_AXE+ADVR_SWORD*65536);r=p.weaponinst;
    ADVR_Assert(p.vr_rigid && p.model=="progs/v_ksword.mdl","sword is a calibrated physical prop");
    ADVR_Catch(p,1);ADVR_Sync();ADVR_Assert(self.weaponmodel=="progs/v_ksword.mdl","sword keeps model on pickup");
    self.mainhand_hotspot=5;self.vrbits0=16384|16;ADVR_GripFrame(1);ADVR_Sync();
    ADVR_Assert(self.holsterweaponmodel2=="progs/v_ksword.mdl","holstered sword keeps model");
    self.vrbits0=16384|8;ADVR_GripFrame(1);ADVR_Sync();
    ADVR_Assert(self.advr_main==r,"holster draws the same sword");
    ADVR_Drop(1);p=find(world,classname,"advr_dropped_weapon");
    while(p && p.weaponinst!=r)p=find(p,classname,"advr_dropped_weapon");
    ADVR_Assert(p && p.model=="progs/v_ksword.mdl","released sword keeps model");ADVR_Catch(p,1);
    target=spawn();target.classname="advr_test_target";target.classtype=CT_TARGETDUMMY;
    target.health=1000;target.takedamage=DAMAGE_YES;target.solid=SOLID_BBOX;
    setsize(target,'-4 -4 -4','4 4 4');setorigin(target,self.handpos+'30 0 0');
    self.handvel='3 0 0';self.mainhand_melee_attack_finished=0;self.advr_prevmain_time=0;
    ADVR_Melee(1);ADVR_Assert(target.health<1000,"tracked sword deals melee damage at blade reach");
    self.advr_holster[0]=self.advr_main;self.advr_main=world;
    p=ADVR_SpawnLoot(foe,IT_AXE+ADVR_SAW*65536);ADVR_Catch(p,1);ADVR_Sync();
    self.advr_main.wi_clip=50;self.button0=1;hp=target.health;
    ADVR_Fire(1);ADVR_Assert(target.health<hp && self.advr_main.wi_clip==49.5,"stationary running chainsaw cuts and consumes fuel");
    hp=target.health;ADVR_Fire(1);ADVR_Assert(target.health==hp,"chainsaw tick limits damage");
    self.button0=0;self.advr_holster[1]=self.advr_main;self.advr_main=world;remove(target);
    p=ADVR_SpawnLoot(foe,IT_SUPER_SHOTGUN+ADVR_SSG*65536);ADVR_Catch(p,1);ADVR_Sync();
    ADVR_Assert(self.weaponmodel==MODEL_VWEAP_SSG && self.weaponclipsize==2,"defender SSG stays standard with Widowmaker upgrade");
    self.advr_holster[2]=self.advr_main;self.advr_main=world;
    p=ADVR_SpawnLoot(foe,IT_LIGHTNING+ADVR_PLASMA*65536);ADVR_Catch(p,1);ADVR_Sync();
    n=self.ammo_cells;self.shotrot='0 0 0';self.button0=1;ADVR_Fire(1);self.button0=0;
    ADVR_Assert(self.ammo_cells==n-1 && self.moditems==mods,"enemy plasma shoots without granting global lightning upgrade");
    missile=find(world,classname,"proj_plasma");
    ADVR_Assert(missile && missile.owner==self,"enemy plasma launches AD plasma projectile");
    self.advr_main.advr_animtime=0;self.advr_main.advr_anim=SUB_Null;
    self.advr_off=ADVR_Record(IT_LIGHTNING);ADVR_Sync();
    ADVR_Assert(self.weaponmodel=="progs/advr_plasma.mdl" && self.weaponmodel2==MODEL_VWEAP_LG,"plasma and thunderbolt coexist");
    ADVR_SaveParms();ADVR_Reset();ADVR_LoadParms();
    ADVR_Assert(self.advr_holster[0].advr_kind==ADVR_SWORD && self.advr_holster[1].wi_clip==49.5,"map parms preserve sword kind and saw fuel");
    ADVR_Assert(self.advr_main.advr_kind==ADVR_PLASMA && self.advr_off.advr_kind==0,"map parms preserve plasma versus thunderbolt");
    self.vrbits0=16384;self.mainhand_hotspot=0;self.handvel='0 0 0';remove(foe);
    bprint("ADVR DROPS PASS: loot table, native deaths/gibs, no duplicates, sword melee/holsters, chainsaw, plasma, map parms\n");
};
void() ADVR_TestDropsLoad = {
    ADVR_Assert(self.advr_holster[0].advr_kind==ADVR_SWORD,"save restores sword");
    ADVR_Assert(self.advr_holster[1].advr_kind==ADVR_SAW && self.advr_holster[1].wi_clip==49.5,"save restores saw and fuel");
    ADVR_Assert(self.advr_main.advr_kind==ADVR_PLASMA,"save restores plasma");
    ADVR_Assert(!(self.moditems & IT_UPGRADE_LG),"save retains independent plasma upgrade state");
    bprint("ADVR DROPS SAVE PASS: enemy weapon kinds and fuel retained\n");
};

// Reproduce accepted native AD pickups, not just the VR record constructors.
void() ADVR_TestPickups = {
    local entity actor,item,bolt,side,stored,p,plasma,missile;
    local float total;
    actor=self;ADVR_Reset();self.advr_initialized=1;self.moditems=0;
    self.items=IT_LIGHTNING|IT_SHOTGUN;self.ammo_cells=80;self.ammo_shells=20;
    self.flags=FL_CLIENT|FL_GODMODE;self.health=1000;self.vrbits0=16384;
    self.mainhand_hotspot=self.offhand_hotspot=0;
    self.handpos=self.origin+self.view_ofs;self.offhandpos=self.handpos+'0 8 0';
    self.muzzlepos=self.handpos;self.offmuzzlepos=self.offhandpos;self.shotrot=self.offshotrot='0 90 0';
    self.advr_main=bolt=ADVR_Record(IT_LIGHTNING);bolt.wi_clip=7;
    self.advr_off=side=ADVR_Record(IT_SHOTGUN);side.wi_clip=3;
    self.advr_holster[0]=stored=ADVR_Record(IT_LIGHTNING);stored.wi_clip=8;
    ADVR_Sync();
    item=spawn();item.classname="advr_test_pickup";item.classtype=CT_UPGRADE_LG;
    item.aflag=20;item.progspawnlist=1;item.noise=SOUND_EMPTY;
    self=item;other=actor;weapon_touch();self=actor;
    plasma=self.advr_main;
    ADVR_Assert(plasma.advr_kind==ADVR_PLASMA,"native plasma pickup creates its own kind");
    ADVR_Assert(ADVR_RecordModel(stored)==MODEL_VWEAP_LG && self.advr_off==side,"native upgrade leaves other guns alone");
    p=find(world,classname,"advr_dropped_weapon");while(p && p.weaponinst!=bolt)p=find(p,classname,"advr_dropped_weapon");
    ADVR_Assert(p && p.model==MODEL_VWEAP_LG && bolt.wi_clip==7 && !p.advr_throw_armed,"full main hand drops intact old gun gently");
    ADVR_Assert(!(p.advr_moditems & IT_UPGRADE_LG),"dropped Thunderbolt cannot carry unrelated plasma upgrade");
    total=self.ammo_cells;ADVR_Catch(p,0);ADVR_Sync();
    ADVR_Assert(self.advr_off==bolt && self.ammo_cells==total+7,"occupied off-hand catch preserves incoming ammo");
    p=find(world,classname,"advr_dropped_weapon");while(p && p.weaponinst!=side)p=find(p,classname,"advr_dropped_weapon");
    ADVR_Assert(p && side.wi_clip==3,"occupied off-hand catch drops its previous gun");
    ADVR_Assert(self.weaponmodel2==MODEL_VWEAP_LG,"caught Thunderbolt stays a Thunderbolt despite global AD flag");
    missile=find(world,classname,"proj_plasma");self.button3=1;ADVR_Fire(0);self.button3=0;
    ADVR_Assert(find(world,classname,"proj_plasma")==missile,"Thunderbolt fires lightning after plasma pickup");
    self.button0=1;ADVR_Fire(1);self.button0=0;
    ADVR_Assert(find(world,classname,"proj_plasma")!=missile,"independent Plasma Gun still fires plasma");
    plasma.advr_animtime=0;plasma.advr_anim=SUB_Null;
    self=item;other=actor;self.classtype=CT_LIGHTNING;weapon_touch();self=actor;
    ADVR_Assert(self.advr_main.advr_kind==0 && ADVR_RecordModel(self.advr_main)==MODEL_VWEAP_LG,"normal map pickup stays Thunderbolt after upgrade");
    p=find(world,classname,"advr_dropped_weapon");while(p && p.weaponinst!=plasma)p=find(p,classname,"advr_dropped_weapon");
    ADVR_Assert(p && p.model=="progs/advr_plasma.mdl","same AD weapon bit still displaces old physical gun");
    ADVR_Catch(p,1);ADVR_Sync();
    ADVR_SaveParms();ADVR_Reset();ADVR_LoadParms();ADVR_Sync();
    ADVR_Assert(self.advr_main.advr_kind==ADVR_PLASMA && self.advr_off.advr_kind==0 && self.weaponmodel2==MODEL_VWEAP_LG,"independent kinds survive map parms with global upgrade flag");
    side=self.advr_off;self.advr_pickup_hand=1;
    self=item;other=actor;self.classtype=CT_SHOTGUN;weapon_touch();self=actor;self.advr_pickup_hand=0;
    ADVR_Assert(self.advr_off.advr_weapon==IT_SHOTGUN && self.advr_main.advr_kind==ADVR_PLASMA,"native hand pickup replaces the touched hand only");
    p=find(world,classname,"advr_dropped_weapon");while(p && p.weaponinst!=side)p=find(p,classname,"advr_dropped_weapon");
    ADVR_Assert(p!=world,"native off-hand pickup drops its old weapon");
    remove(item);bprint("ADVR PICKUPS PASS: native plasma/Thunderbolt isolation, firing, occupied hands, same-bit replacement, magazines and map parms\n");
};

void() ADVR_TestWidow = {
    local entity r,normal,item,actor,p;local float h,i,j,ammo,mode;
    actor=self;ADVR_Reset();self.advr_initialized=1;self.flags=FL_CLIENT|FL_GODMODE;
    self.health=1000;self.moditems=0;self.items=IT_SUPER_SHOTGUN|IT_LIGHTNING;
    self.ammo_shells=self.ammo_cells=100;self.vrbits0=16384;
    self.muzzlepos=self.offmuzzlepos=self.handpos=self.offhandpos=self.origin+self.view_ofs;
    self.shotrot=self.offshotrot='-80 0 0';self.mainhand_hotspot=self.offhand_hotspot=0;
    mode=cvar("vr_reload_mode");cvar_set("vr_reload_mode","2");
    self.advr_off=normal=ADVR_Record(IT_SUPER_SHOTGUN);
    item=spawn();item.classname="advr_test_widow";item.classtype=CT_UPGRADE_SSG;
    item.aflag=24;item.progspawnlist=1;item.noise=SOUND_EMPTY;
    self=item;other=actor;weapon_touch();self=actor;remove(item);
    ADVR_Assert(self.advr_main.advr_kind==ADVR_WIDOWMAKER && ADVR_RecordModel(normal)==MODEL_VWEAP_SSG && ADVR_RecordCapacity(normal)==2,"native Widowmaker pickup preserves ordinary SSG");
    for(h=0;h<2;h=h+1){
        self.advr_main=self.advr_off=world;self.ammo_shells=100;
        r=ADVR_Record(IT_SUPER_SHOTGUN);ADVR_SetHand(h,r);
        ADVR_Assert(r.advr_kind==ADVR_WIDOWMAKER && r.wi_clip==24,"Widowmaker starts with 24 loaded shells");
        for(i=0;i<8;i=i+1){
            ammo=self.ammo_shells;r.advr_cooldown=r.advr_reload_until=r.advr_animtime=0;r.advr_anim=SUB_Null;
            self.button0=self.button3=1;ADVR_Fire(h);
            for(j=0;j<5 && self.ammo_shells==ammo && r.advr_animtime>0;j=j+1){r.advr_animtime=time;ADVR_Fire(h);}
            self.button0=self.button3=0;
            ADVR_Assert(self.ammo_shells==ammo-3 && r.wi_clip==24-(i+1)*3,"each Widowmaker shot costs three shells");
        }
        ADVR_Assert(self.ammo_shells==76 && r.wi_clip==0,"exactly eight shots per magazine");
        r.advr_cooldown=r.advr_animtime=0;self.button0=self.button3=1;ADVR_Fire(h);self.button0=self.button3=0;
        ADVR_Assert(self.ammo_shells==76,"empty Widowmaker cannot shoot reserve");
        r.wi_clip=2;r.advr_cooldown=r.advr_animtime=0;self.button0=self.button3=1;ADVR_Fire(h);self.button0=self.button3=0;
        ADVR_Assert(r.wi_clip==2 && self.ammo_shells==76,"partial magazine below three shells cannot fire reduced shot");
        r.wi_clip=0;r.advr_reload_until=0;self.vrbits0=16384|4096|1024;ADVR_ReloadFrame(h);
        ADVR_Assert(r.wi_clip==0,"Widowmaker no longer flick reloads");
        self.vrbits0=16384;self.mainhand_hotspot=self.offhand_hotspot=5;ADVR_ReloadFrame(h);
        ADVR_Assert(r.wi_clip==24 && self.ammo_shells==76,"holster reload fills 24 without creating ammo");
        self.mainhand_hotspot=self.offhand_hotspot=0;
    }
    self.advr_main=r;self.advr_off=normal;ADVR_Sync();
    self.button3=1;ammo=self.ammo_shells;normal.advr_cooldown=normal.advr_animtime=0;ADVR_Fire(0);self.button3=0;
    ADVR_Assert(self.ammo_shells==ammo-2,"ordinary SSG still fires two shells after Widowmaker upgrade");
    self.handthrowvel='0 0 0';ADVR_Drop(1);
    p=find(world,classname,"advr_dropped_weapon");while(p && p.weaponinst!=r)p=find(p,classname,"advr_dropped_weapon");
    ADVR_Assert(p && p.weaponinst.wi_clip==24,"dropped Widowmaker retains its 24-round magazine");
    ADVR_Catch(p,1);ADVR_SaveParms();ADVR_Reset();ADVR_LoadParms();ADVR_Sync();
    ADVR_Assert(self.advr_main.advr_kind==ADVR_WIDOWMAKER && self.advr_main.wi_clip==24 && self.advr_off.advr_kind==0,"Widowmaker and SSG identity survive map parms");
    self.moditems=self.moditems|IT_UPGRADE_LG;self.advr_main=ADVR_Record(IT_LIGHTNING);
    ADVR_Assert(ADVR_RecordCapacity(self.advr_main)==24,"Plasma Gun capacity is 24");
    self.moditems=self.moditems-(self.moditems & IT_UPGRADE_LG);self.advr_off=ADVR_Record(IT_LIGHTNING);
    ADVR_Assert(ADVR_RecordCapacity(self.advr_off)==36,"Thunderbolt keeps 36-round capacity");
    cvar_set("vr_reload_mode",ftos(mode));ADVR_Sync();
    bprint("ADVR WIDOW PASS: independent models/attacks, eight triple shots, partial lockout, holster reload, no flick, drop/catch, map parms and plasma capacity\n");
};

void() ADVR_TestWidowView = {
    ADVR_TestUpgrades();self.advr_off=world;ADVR_Sync();
};
void() ADVR_TestShadow = {
    local entity actor,item,normal,r,p;
    actor=self;ADVR_Reset();self.advr_initialized=1;self.flags=FL_CLIENT|FL_GODMODE;
    self.health=1000;self.moditems=0;self.items=IT_AXE;self.vrbits0=16384;
    self.handpos=self.offhandpos=self.origin+self.view_ofs;
    self.advr_off=normal=ADVR_Record(IT_AXE);
    item=spawn();item.classname="advr_test_shadow";item.classtype=CT_UPGRADE_AXE;
    item.progspawnlist=1;item.noise=SOUND_EMPTY;
    self=item;other=actor;weapon_touch();self=actor;remove(item);
    r=self.advr_main;
    ADVR_Assert(r.advr_kind==ADVR_SHADOWAXE,"native pickup creates a distinct Shadow Axe");
    ADVR_Assert(ADVR_RecordModel(r)=="progs/advr_shadowaxe.mdl" && ADVR_RecordModel(normal)=="progs/v_axe.mdl","normal axe does not inherit Shadow model");
    ADVR_Assert(ADVR_CanParry(r) && ADVR_CanParry(normal),"both axe types retain parrying");
    self.handthrowvel='0 0 0';ADVR_Drop(1);
    p=find(world,classname,"advr_dropped_weapon");while(p && p.weaponinst!=r)p=find(p,classname,"advr_dropped_weapon");
    ADVR_Assert(p!=world && p.model=="progs/advr_shadowaxe.mdl","dropped Shadow Axe uses its own mesh");
    ADVR_Catch(p,1);ADVR_SaveParms();ADVR_Reset();ADVR_LoadParms();ADVR_Sync();
    ADVR_Assert(self.advr_main.advr_kind==ADVR_SHADOWAXE && ADVR_RecordModel(self.advr_off)=="progs/v_axe.mdl","separate axes survive map parms");
    r=self.advr_main;self.advr_holster[0]=r;self.advr_main=world;ADVR_Sync();
    ADVR_Assert(self.holsterweaponmodel0=="progs/advr_shadowaxe.mdl","holstered Shadow Axe preserves its model");
    self.advr_main=r;self.advr_holster[0]=world;ADVR_Sync();
    p=spawn();p.classname="advr_test_target";p.classtype=CT_TARGETDUMMY;
    p.movetype=MOVETYPE_NONE;p.solid=SOLID_BBOX;p.takedamage=DAMAGE_YES;p.health=1000;
    self.handrot='0 0 0';self.handvel='3 0 0';self.muzzlepos=self.handpos+'28 0 0';
    setsize(p,'-4 -4 -4','4 4 4');setorigin(p,self.handpos+'18 0 0');
    self.mainhand_melee_attack_finished=0;self.advr_prevmain_time=0;ADVR_Melee(1);
    ADVR_Assert(p.health==1000-DAMAGE_PLAYAXE2 && p.axhitme==2,"Shadow Axe retains upgraded damage and zombie finishing");
    self.advr_main=self.advr_off;p.health=1000;
    self.mainhand_melee_attack_finished=0;self.advr_prevmain_time=0;ADVR_Melee(1);
    ADVR_Assert(p.health==1000-DAMAGE_PLAYAXE1 && p.axhitme==1,"ordinary axe retains normal damage after Shadow pickup");
    remove(p);self.handvel='0 0 0';self.advr_main=r;ADVR_Sync();
    bprint("ADVR SHADOW PASS: native pickup, separate axes, parry, drop/catch, holster and map parms\n");
};
void() ADVR_TestNailSpin = {
    local entity r;local float h,i,mode;
    ADVR_Reset();self.advr_initialized=1;self.flags=FL_CLIENT|FL_GODMODE;self.health=1000;
    self.moditems=0;self.items=IT_SUPER_NAILGUN;self.vrbits0=16384;
    self.muzzlepos=self.offmuzzlepos=self.origin+self.view_ofs;self.shotrot=self.offshotrot='-80 0 0';
    mode=cvar("vr_reload_mode");cvar_set("vr_reload_mode","0");
    for(h=0;h<2;h=h+1){
        self.advr_main=self.advr_off=world;self.ammo_nails=100;
        r=ADVR_Record(IT_SUPER_NAILGUN);ADVR_SetHand(h,r);
        for(i=1;i<=10;i=i+1){
            self.button0=self.button3=1;r.advr_cooldown=0;
            if(r.advr_animtime)r.advr_animtime=time;
            ADVR_Fire(h);ADVR_Sync();
            ADVR_Assert(r.advr_frame==1+((i-1)%8),"Super Nailgun advances and wraps all eight firing frames");
            if(h)ADVR_Assert(self.weaponframe==r.advr_frame && self.weaponframe2==0,"main-hand barrel frame reaches renderer only on main hand");
            else ADVR_Assert(self.weaponframe2==r.advr_frame && self.weaponframe==0,"off-hand barrel frame reaches renderer only on off hand");
        }
        self.button0=self.button3=0;r.advr_animtime=time;ADVR_Fire(h);ADVR_Sync();
        ADVR_Assert(r.advr_animtime==0,"Super Nailgun stops firing on trigger release");
    }
    cvar_set("vr_reload_mode",ftos(mode));
    bprint("ADVR NAIL SPIN PASS: both hands, eight frames, wraparound and trigger release\n");
};
void() ADVR_TestForceGrab = {
    local entity actor,r,e,oldother;local float h,ammo;
    actor=self;oldother=other;ADVR_Reset();self.advr_initialized=1;self.flags=FL_CLIENT|FL_GODMODE;self.health=1000;
    self.items=IT_SHOTGUN;self.moditems=0;self.ammo_shells=100;
    cvar_set("vr_forcegrab_mode","1");cvar_set("vr_forcegrab_cone","25");
    for(h=0;h<2;h=h+1){
        self.advr_main=self.advr_off=world;self.vrbits0=16384;
        self.handpos=self.offhandpos=self.origin+self.view_ofs;self.handrot=self.offhandrot='0 0 0';
        self.handvel=self.offhandvel=self.handavel=self.offhandavel='0 0 0';
        self.handthrowvel=self.offhandthrowvel='0 0 0';
        r=ADVR_Record(IT_SHOTGUN);ADVR_SetHand(h,r);ADVR_Drop(h);
        e=find(world,classname,"advr_dropped_weapon");while(e && e.weaponinst!=r)e=find(e,classname,"advr_dropped_weapon");
        setorigin(e,ADVR_Pos(h)+'80 0 0');e.velocity='0 0 0';
        self.button0=self.button3=1;ADVR_ForceGrab(h);
        ADVR_Assert(ADVR_FGTarget(h)==e && !e.fg_state && e.velocity=='0 0 0',"trigger selects and highlights without moving weapon");
        self.handvel=self.offhandvel='0 0 0';if(h)self.vrbits0=16384|8;else self.vrbits0=16384|2;
        ADVR_ForceGrab(h);ADVR_Assert(!e.fg_state,"grip without flick locks but never launches");
        self.button0=self.button3=0;ADVR_ForceGrab(h);ADVR_Assert(!ADVR_FGTarget(h),"trigger release cancels selection");
        self.vrbits0=16384;self.button0=self.button3=1;ADVR_ForceGrab(h);
        self.vrbits0=16384;
        self.handvel=self.offhandvel='-3 0 3';ADVR_ForceGrab(h);
        ADVR_Assert(e.fg_state==1 && ADVR_FGPulled(h)==e && e.solid==SOLID_NOT,"trigger plus flick starts flight with an open hand");
        self.button0=self.button3=0;ADVR_ForceGrab(h);
        self=e;ADVR_FGFlight();self=actor;
        ADVR_Assert(e.fg_state==1 && vlen(e.velocity)>0,"flight continues with trigger and grip both released");
        setorigin(e,e.origin+ADVR_Pos(h)-forcegrabpoint(e));self=e;ADVR_FGFlight();self=actor;
        ADVR_Assert(!ADVR_Hand(h) && e.fg_state==1,"nearby weapon cannot catch into an open hand");
        if(h)self.vrbits0=16384|8;else self.vrbits0=16384|2;
        self.button0=self.button3=1;self=e;ADVR_FGFlight();self=actor;
        ADVR_Assert(ADVR_Hand(h)==r && !ADVR_FGPulled(h),"flight catches original record in correct hand");
        ammo=self.ammo_shells;r.advr_cooldown=0;ADVR_Fire(h);
        ADVR_Assert(self.ammo_shells==ammo && self.advr_fg_rearm[h],"held selection trigger cannot fire caught gun");
        self.button0=self.button3=0;ADVR_Fire(h);ADVR_Assert(!self.advr_fg_rearm[h],"release rearms caught gun");
        self.shotrot=self.offshotrot='-80 0 0';self.muzzlepos=self.offmuzzlepos=self.origin+self.view_ofs;
        self.button0=self.button3=1;ADVR_Fire(h);ADVR_Assert(self.ammo_shells<ammo,"deliberate trigger press fires after catch");
        self.button0=self.button3=0;self.advr_main=self.advr_off=world;
    }
    e=spawn();e.classname="advr_test_native_weapon";e.classtype=CT_SHOTGUN;
    e.progspawnlist=1;e.noise=SOUND_EMPTY;e.aflag=8;e.touch=item_touch;e.touch2=weapon_touch;
    e.flags=FL_ITEM;e.movetype=MOVETYPE_TOSS;e.solid=SOLID_TRIGGER;
    setmodel(e,MODEL_GWEAP_SG);setsize(e,'-6 -6 -6','6 6 6');setorigin(e,self.handpos+'80 0 0');
    ADVR_Assert(ADVR_FGEligible(e),"ordinary map weapon is eligible");
    self.vrbits0=16384|8;ADVR_FGLaunch(1,e);self.vrbits0=16384;
    self=e;ADVR_FGFlight();self=actor;
    ADVR_Assert(e.fg_state==1,"native pickup keeps flying without grip");
    e.advr_fg_arrive=time-0.01;self=e;ADVR_FGFlight();self=actor;
    ADVR_Assert(!e.fg_state && e.movetype==MOVETYPE_TOSS && e.solid==SOLID_TRIGGER && !self.mainhand_fgpulled,"missed catch restores the native pickup");
    self.vrbits0=16384|8;ADVR_FGLaunch(1,e);
    setorigin(e,e.origin+self.handpos-forcegrabpoint(e));self=e;ADVR_FGFlight();self=actor;
    ADVR_Assert(self.advr_main.advr_weapon==IT_SHOTGUN && self.advr_fg_rearm[1],"native weapon callback catches safely into selected hand");
    remove(e); // Synthetic progspawnlist fixture deliberately skips native cleanup.
    self.advr_main=world;self.button0=1;self.vrbits0=16384;cvar_set("vr_forcegrab_mode","0");ADVR_ForceGrab(1);
    ADVR_Assert(!self.mainhand_fgtarget,"disabled force grab clears pointer");cvar_set("vr_forcegrab_mode","1");
    other=oldother;self.handvel=self.offhandvel='0 0 0';ADVR_Sync();
    bprint("ADVR FORCE GRAB PASS: both hands, trigger/flick, released-trigger flight, grip-only catch, miss and trigger safety\n");
};
entity advr_grab_view_record;
float advr_grab_view_ammo,advr_recoil_base;
void() ADVR_TestGrabView = {
    local entity e;
    ADVR_Reset();self.advr_initialized=1;self.flags=FL_CLIENT|FL_GODMODE;self.health=1000;
    self.moditems=0;self.items=IT_SHOTGUN;self.ammo_shells=80;
    self.advr_main=ADVR_Record(IT_SHOTGUN);advr_grab_view_record=self.advr_main;ADVR_Drop(1);
    e=find(world,classname,"advr_dropped_weapon");while(e && e.weaponinst!=advr_grab_view_record)e=find(e,classname,"advr_dropped_weapon");
    makevectors(self.handrot);setorigin(e,self.handpos+v_forward*70);
    e.velocity='0 0 0';e.movetype=MOVETYPE_NONE;
    advr_grab_view_ammo=self.ammo_shells;ADVR_Sync();
};
void() ADVR_TestGrabSelected = {
    ADVR_Assert(self.mainhand_fgtarget.weaponinst==advr_grab_view_record && !self.mainhand_fgpulled && !self.advr_main,"rendered selection remains stationary before grip/flick");
    bprint("ADVR GRAB POINTER PASS\n");
};
void() ADVR_TestGrabArrived = {
    ADVR_Assert(self.advr_main==advr_grab_view_record,"real-time flick flight reaches held hand");
    ADVR_Assert(self.ammo_shells==advr_grab_view_ammo+self.advr_main.wi_clip,"catch never fires accidentally");
    bprint("ADVR GRAB FLIGHT PASS: real frame flight and safe catch\n");
};
void() ADVR_TestRecoilBase = {advr_recoil_base=self.shotrot_x-self.handrot_x;};
void() ADVR_TestRecoilAim = {
    ADVR_Assert(self.shotrot_x-self.handrot_x<advr_recoil_base-1,"upgrade recoil raises actual shot direction");
    bprint("ADVR RECOIL AIM PASS: shot direction remains above tracked aim\n");
};

void() ADVR_TestGrabFlying = {
    ADVR_Assert(self.mainhand_fgpulled.weaponinst==advr_grab_view_record && !self.advr_main && !self.button0 && !ADVR_Grip(1),"real flight persists after trigger release without grip");
    bprint("ADVR GRAB RELEASE PASS\n");
};
void() ADVR_TestPlasmaView = {
    ADVR_Reset();self.advr_initialized=1;self.flags=FL_CLIENT|FL_GODMODE;self.health=1000;
    self.items=IT_LIGHTNING;self.moditems=IT_UPGRADE_LG;self.ammo_cells=100;
    self.advr_main=ADVR_Record(IT_LIGHTNING);ADVR_Sync();
};
void() ADVR_TestCrossbow = {
    local entity actor,foe,p,r,side,bolt,target;local float h,i,ammo;
    actor=self;ADVR_Reset();self.advr_initialized=1;self.flags=FL_CLIENT|FL_GODMODE;self.health=1000;
    self.items=IT_AXE;self.moditems=0;self.ammo_shells=50;self.ammo_nails=60;self.ammo_cells=70;
    self.muzzlepos=self.offmuzzlepos=self.handpos=self.offhandpos=self.origin+self.view_ofs;
    self.shotrot=self.offshotrot='-80 0 0';self.vrbits0=16384;
    cvar_set("vr_enemy_drops_chance_mult","1");cvar_set("vr_reload_mode","2");
    foe=spawn();foe.classtype=CT_MONDCROSS;setorigin(foe,self.origin+'80 0 0');
    ADVR_Assert(ADVR_LootType(foe,0.99,0)==IT_AXE+ADVR_CROSSBOW*65536,"Crossbow Knights drop crossbows");
    self=foe;ADVR_EnemyDrop();ADVR_EnemyDrop();self=actor;
    p=find(world,classname,"advr_dropped_weapon");while(p && p.owner!=foe)p=find(p,classname,"advr_dropped_weapon");
    ADVR_Assert(p && p.weaponinst.advr_kind==ADVR_CROSSBOW && p.weaponinst.wi_clip==0 && p.weaponinst.advr_bolt_pack==12,"death loot has an empty chamber and twelve reserve bolts");
    ADVR_Catch(p,1);r=self.advr_main;
    ADVR_Assert(self.advr_bolts==12 && !r.advr_bolt_pack && !ADVR_CanParry(r),"first catch collects bolt bundle once and cannot parry");
    for(h=0;h<2;h=h+1){
        self.advr_main=self.advr_off=world;r.wi_clip=0;self.advr_bolts=12;ADVR_SetHand(h,r);
        for(i=0;i<12;i=i+1){
            self.button0=self.button3=0;ADVR_Fire(h);r.advr_cooldown=r.advr_reload_until=0;
            self.button0=self.button3=1;ADVR_Fire(h);
            ADVR_Assert(r.wi_clip==0 && self.advr_bolts==12-i,"empty chamber cannot fire reserve bolts");
            self.mainhand_hotspot=self.offhand_hotspot=5;ADVR_ReloadFrame(h);
            self.mainhand_hotspot=self.offhand_hotspot=0;
            ADVR_Assert(r.wi_clip==1 && self.advr_bolts==11-i,"holster reload transfers exactly one bolt");
            ADVR_Sync();if(h)ADVR_Assert(self.weaponframe==4,"main loaded bolt visible");
            else ADVR_Assert(self.weaponframe2==4,"offhand loaded bolt visible");
            self.button0=self.button3=0;ADVR_Fire(h);r.advr_cooldown=0;
            self.button0=self.button3=1;ADVR_Fire(h);bolt=newmis;ADVR_Sync();
            ADVR_Assert(r.wi_clip==0 && bolt.advr_crossbolt && bolt.owner==self && bolt.classtype==CT_PROJ_BOLT1,"each reloaded shot launches an owned bolt");
            if(h)ADVR_Assert(self.weaponframe==1,"main hand publishes firing pose");
            else ADVR_Assert(self.weaponframe2==1,"off hand publishes firing pose");
            ADVR_Fire(h);ADVR_Assert(r.wi_clip==0 && self.advr_bolts==11-i,"held trigger does not bypass reload");
            r.advr_animtime=time+0.09;ADVR_Fire(h);ADVR_Assert(r.advr_frame==2,"bow rebounds after release");
            r.advr_animtime=time+0.03;ADVR_Fire(h);ADVR_Assert(r.advr_frame==3,"bow settles");
            r.advr_animtime=time;ADVR_Fire(h);ADVR_Assert(r.advr_frame==0,"firing animation returns to rest");
            if(i==0){
                target=spawn();target.classname="advr_crossbow_target";target.classtype=CT_TARGETDUMMY;target.health=1000;
                target.takedamage=DAMAGE_YES;target.solid=SOLID_BBOX;setsize(target,'-4 -4 -4','4 4 4');setorigin(target,bolt.origin);
                self=bolt;other=target;Touch_Projectile();self=actor;
                ADVR_Assert(target.health==950,"player bolt deals fifty body damage through native impact code");remove(target);
            }
            remove(bolt);
        }
        r.advr_reload_until=0;ADVR_Reload(h);ADVR_Assert(r.wi_clip==0 && self.advr_bolts==0,"empty reserve cannot reload");
    }
    // A second fresh crossbow adds a bundle; both chambers draw from one pool.
    p=ADVR_SpawnLoot(foe,IT_AXE+ADVR_CROSSBOW*65536);ADVR_Catch(p,0);side=self.advr_off;
    ADVR_Assert(self.advr_bolts==12,"another enemy crossbow adds twelve bolts");
    self.advr_main=r;r.advr_reload_until=0;ADVR_Reload(1);ADVR_Reload(0);
    ADVR_Assert(r.wi_clip==1 && side.wi_clip==1 && self.advr_bolts==10,"dual crossbows share reserve but keep independent chambers");
    ADVR_Drop(1);p=find(world,classname,"advr_dropped_weapon");while(p && p.weaponinst!=r)p=find(p,classname,"advr_dropped_weapon");
    ADVR_Assert(p && p.weaponinst.wi_clip==1 && p.frame==4 && self.advr_bolts==10,"drop keeps chambered bolt and leaves reserve with player");
    ADVR_Catch(p,1);ADVR_Assert(self.advr_bolts==10,"recatching cannot farm twelve more bolts");
    r.wi_clip=5;ADVR_Sync();ADVR_Sync();
    ADVR_Assert(r.wi_clip==1 && self.advr_bolts==14,"old five-shot magazine converts once without losing ammo");
    self.advr_holster[0]=r;self.advr_main=world;ADVR_SaveParms();ADVR_Reset();ADVR_LoadParms();
    ADVR_Assert(self.advr_holster[0].wi_clip==1 && self.advr_off.wi_clip==1 && self.advr_bolts==14,"holster/map parms preserve chambers and reserve");
    ADVR_Assert(self.ammo_shells==50 && self.ammo_nails==60 && self.ammo_cells==70,"bolts never change regular ammunition");
    cvar_set("vr_reload_mode","0");self.advr_off.wi_clip=0;self.advr_off.advr_reload_until=0;ADVR_Reload(0);
    ADVR_Assert(self.advr_off.wi_clip==1 && self.advr_bolts==13,"crossbow remains single-load when ordinary reloads are disabled");
    cvar_set("vr_reload_mode","2");self.button0=self.button3=0;self.vrbits0=16384;
    self.advr_main=self.advr_holster[0];self.advr_holster[0]=world;ADVR_Sync();
    remove(foe);other=world;
    bprint("ADVR CROSSBOW PASS: single chamber, reserve, holster reload, both hands, animation, no pickup duplication and persistence\n");
};
void() ADVR_TestCrossbowSaved = {
    ADVR_Assert(self.advr_main.advr_kind==ADVR_CROSSBOW && self.advr_main.wi_clip==1 &&
        self.advr_off.advr_kind==ADVR_CROSSBOW && self.advr_off.wi_clip==1 && self.advr_bolts==13,
        "saved/transitioned crossbows retain independent chambers and shared reserve");
    bprint("ADVR CROSSBOW SAVE PASS\n");
};
void() ADVR_TestCrossbowView = {
    local entity foe,p;
    ADVR_Reset();self.advr_initialized=1;self.flags=FL_CLIENT|FL_GODMODE;self.health=1000;self.items=IT_AXE;self.moditems=0;
    foe=spawn();setorigin(foe,self.origin);p=ADVR_SpawnLoot(foe,IT_AXE+ADVR_CROSSBOW*65536);
    ADVR_Catch(p,1);remove(foe);ADVR_Sync();
};

void() ADVR_TestStickyGrip = {
    local float h,bit,oldbit,mode;local entity r,p;
    mode=cvar("vr_weapon_grip_mode");ADVR_Reset();self.advr_initialized=1;
    self.flags=FL_CLIENT|FL_GODMODE;self.health=1000;self.items=IT_SHOTGUN;self.ammo_shells=100;
    self.handpos=self.offhandpos=self.origin+self.view_ofs;
    self.handvel=self.offhandvel=self.handthrowvel=self.offhandthrowvel='0 0 0';
    cvar_set("vr_weapon_grip_mode","1");
    for(h=0;h<2;h=h+1){
        bit=2;oldbit=4;if(h){bit=8;oldbit=16;}
        self.advr_main=self.advr_off=world;r=ADVR_Record(IT_SHOTGUN);ADVR_SetHand(h,r);
        self.mainhand_hotspot=self.offhand_hotspot=2;
        self.vrbits0=16384|oldbit;ADVR_GripFrame(h);
        ADVR_Assert(ADVR_Hand(h)==r,"sticky first release keeps held weapon");
        self.vrbits0=16384|bit;ADVR_GripFrame(h);
        ADVR_Assert(!ADVR_Hand(h),"sticky second press drops at nonzero weapon hotspot");
        p=find(world,classname,"advr_dropped_weapon");while(p && p.weaponinst!=r)p=find(p,classname,"advr_dropped_weapon");
        ADVR_Assert(p && p.weaponinst==r,"sticky release preserves physical weapon record");
        p.advr_cooldown=0;setorigin(p,ADVR_Pos(h));self.vrbits0=16384|bit|oldbit;ADVR_GripFrame(h);
        ADVR_Assert(!ADVR_Hand(h),"holding release press cannot recatch dropped weapon");
        self.vrbits0=16384|oldbit;ADVR_GripFrame(h);
        self.vrbits0=16384|bit;ADVR_GripFrame(h);
        ADVR_Assert(ADVR_Hand(h)==r,"fresh sticky press picks weapon back up");
        self.mainhand_hotspot=self.offhand_hotspot=5;self.vrbits0=16384|oldbit;ADVR_GripFrame(h);
        ADVR_Assert(ADVR_Hand(h)==r && !self.advr_holster[2],"releasing pickup press near holster does not toggle again");
        self.vrbits0=16384|bit;ADVR_GripFrame(h);
        ADVR_Assert(!ADVR_Hand(h) && self.advr_holster[2]==r,"sticky press stores weapon in holster");
        self.vrbits0=16384|oldbit;ADVR_GripFrame(h);
        self.vrbits0=16384|bit;ADVR_GripFrame(h);
        ADVR_Assert(ADVR_Hand(h)==r && !self.advr_holster[2],"next sticky press retrieves holstered weapon");
        self.mainhand_hotspot=self.offhand_hotspot=2;cvar_set("vr_weapon_grip_mode","0");
        self.vrbits0=16384|oldbit;ADVR_GripFrame(h);
        ADVR_Assert(!ADVR_Hand(h),"hold mode still drops on physical release");
        cvar_set("vr_weapon_grip_mode","1");
    }
    cvar_set("vr_weapon_grip_mode",ftos(mode));self.vrbits0=16384;ADVR_Sync();
    bprint("ADVR STICKY GRIP PASS: both hands, nonzero hotspot release, no recatch, holster toggles and hold mode\n");
};
