void() ADVR_TestMagicView = {
    local entity p,foe;
    ADVR_Reset();self.advr_initialized=1;self.health=100;
    foe=spawn();setorigin(foe,self.origin+'0 0 16');
    p=ADVR_SpawnLoot(foe,IT_AXE+ADVR_DEBUGTOME*65536);ADVR_Catch(p,0);remove(foe);ADVR_Sync();
};
void() ADVR_TestFlashlightView = {
    ADVR_Reset();self.advr_initialized=1;self.health=100;self.flags=self.flags | FL_GODMODE;
    self.items=self.items | IT_SHOTGUN;self.advr_main=ADVR_Record(IT_SHOTGUN);ADVR_Sync();
};
void() ADVR_TestMagicMainView = {
    ADVR_TestMagicView();self.advr_main=self.advr_off;self.advr_off=world;ADVR_Sync();
};
void() ADVR_TestPouchInput = {
    local float h;local entity p;
    ADVR_Assert(self.advr_pouch_selection==cvar("temp1"),"controller click reaches tome pouch selection");
    if(self.advr_pouch_selection==2){
        h=1;if(ADVR_IsTome(self.advr_main))h=0;
        self.ammo_nails=100;self.advr_round_guard[h]=0;ADVR_ManualTake(h);p=self.advr_round[h];
        ADVR_Assert(p && p.advr_round_weapon==IT_NAILGUN,"controller-selected pouch draws nailgun magazine");
        ADVR_ManualRelease(h,1);
    }
    dprint("ADVR POUCH INPUT PASS\n");
};
void() ADVR_TestMagicStandardView = {
    ADVR_TestMagicView();self.advr_off.advr_kind=ADVR_TOME;self.advr_off.advr_tome_read=1;
    self.advr_known=1;ADVR_Sync();
};
void() ADVR_TestFlashlight = {
    local entity r;
    ADVR_TestFlashlightView();r=self.advr_main;
    self.vr_flashlight_state=9;ADVR_SaveParms();ADVR_Reset();ADVR_LoadParms();
    ADVR_Assert(self.vr_flashlight_state==9,"flashlight on/head attachment survives map parms");
    self.advr_holster[0]=self.advr_main;self.advr_main=world;
    self.mainhand_hotspot=3;self.vrbits0=16384+8+262144;
    ADVR_GripFrame(1);ADVR_Assert(!self.advr_main,"flashlight hand cannot draw a holstered weapon");
    ADVR_Assert(ADVR_HandBusy(1) && !ADVR_HandBusy(0),"flashlight busy bit is per hand");
    self.vrbits0=16384+131072;
    ADVR_Assert(ADVR_HandBusy(0) && !ADVR_HandBusy(1),"off-hand flashlight busy bit");
    ADVR_TestFlashlightView();self.vrbits0=16384;self.mainhand_hotspot=self.offhand_hotspot=0;
    bprint("ADVR FLASHLIGHT PASS: state persistence, busy-hand isolation, holster guard\n");
};
void() ADVR_TestGuidance = {
    local entity player,bolt,guide,target;local vector mainrot,offrot;local float expiry;
    player=self;mainrot=self.handrot;offrot=self.offhandrot;
    self.handrot='0 90 0';self.offhandrot='0 -90 0';
    ADVR_FrostLaunch(self.origin,'1 0 0');bolt=newmis;expiry=bolt.nextthink;
    ADVR_GuideBolt(bolt,1);guide=bolt.advr_guidance;
    self=guide;ADVR_GuidedBoltThink();self=player;
    ADVR_Assert(bolt.velocity_y>0 && fabs(vlen(bolt.velocity)-550)<1,"main hand steers without changing speed");
    ADVR_Assert(bolt.mins=='-4 -4 -4' && bolt.maxs=='4 4 4',"cast projectile has forgiving collision hull");
    ADVR_Assert(bolt.think==SUB_Remove && bolt.nextthink==expiry && bolt.touch==ADVR_FrostTouch,"guidance preserves native callbacks");
    bolt.velocity='550 0 0';guide.advr_guidance_hand=0;
    self=guide;ADVR_GuidedBoltThink();self=player;
    ADVR_Assert(bolt.velocity_y<0,"off hand guidance is independent");
    bolt.advr_voidorb=1;target=spawn();target.health=100;bolt.enemy=target;
    bolt.velocity='550 0 0';self=guide;ADVR_GuidedBoltThink();self=player;
    ADVR_Assert(bolt.velocity=='550 0 0',"Void homing target overrides hand steering");
    target.health=0;self=guide;ADVR_GuidedBoltThink();self=player;
    ADVR_Assert(bolt.velocity_y<0,"Void resumes hand guidance without live target");remove(target);
    bolt.solid=SOLID_NOT;self=guide;ADVR_GuidedBoltThink();self=player;
    ADVR_Assert(!bolt.advr_guidance,"impact stops guidance");remove(bolt);
    self.handrot=mainrot;self.offhandrot=offrot;
    bprint("ADVR GUIDANCE PASS\n");
};
void() ADVR_TestMagic = {
    local entity book,p,foe,shot,player;local float oldframe,i,before;local vector head;
    player=self;oldframe=frametime;ADVR_TestMagicView();self.advr_off.advr_kind=ADVR_TOME;self.advr_known=1791;ADVR_TestGuidance();book=self.advr_off;
    ADVR_Assert(self.mana==30 && self.advr_mana_seen,"first tome grants thirty mana");
    foe=spawn();foe.classtype=CT_MONSKULLW;setorigin(foe,self.origin+'0 0 16');
    ADVR_Assert(ADVR_LootType(foe,0,0)==IT_AXE+ADVR_TOME*65536,"Skull Wizard loot is a tome");
    p=ADVR_SpawnLoot(foe,IT_AXE+ADVR_TOME*65536);foe.gib2mdl="progs/w_skullbook.mdl";
    ADVR_Assert(ADVR_IsTome(p.weaponinst) && ADVR_SkipWeaponGib(foe,12),"usable tome replaces decorative book");
    remove(p.weaponinst);remove(p);remove(foe);

    ADVR_Assert(ADVR_RecordModel(book)=="progs/advr_tome.mdl","distinct tome model");
    ADVR_Drop(0);p=find(world,classname,"advr_dropped_weapon");
    while(p && p.weaponinst!=book)p=find(p,classname,"advr_dropped_weapon");
    ADVR_Catch(p,0);ADVR_Assert(self.mana==30,"recatching does not refill mana");
    ADVR_TomePickup(self,book);ADVR_Assert(self.mana==30,"second tome does not refill mana");
    foe=spawn();foe.flags=FL_MONSTER;foe.classtype=CT_MONARMY;
    ADVR_ManaReward(foe,self);ADVR_ManaReward(foe,self);ADVR_Assert(self.mana==31,"one reward per ordinary enemy");remove(foe);
    for(i=0;i<5;i=i+1) {
        foe=spawn();foe.flags=FL_MONSTER;
        if(i==0)foe.classtype=CT_MONWIZARD;else if(i==1)foe.classtype=CT_MONSKULLW;else if(i==2)foe.classtype=CT_MONSHAM;else if(i==3)foe.classtype=CT_MONSHAL;else foe.classtype=CT_MONMINOTAUR;
        before=self.mana;ADVR_ManaReward(foe,self);ADVR_Assert(self.mana==min(self.advr_mana_max,before+10),"magical monster yields ten");remove(foe);
    }
    foe=spawn();foe.flags=FL_MONSTER;before=self.mana;ADVR_ManaReward(foe,world);ADVR_Assert(self.mana==before,"uncredited kills do not grant mana");remove(foe);
    ADVR_SaveParms();before=self.mana;ADVR_Reset();ADVR_LoadParms();book=self.advr_off;
    ADVR_Assert(self.mana==before && self.advr_mana_seen && ADVR_IsTome(book),"mana and first-pickup flag survive map parms");
    ADVR_Sync();ADVR_Assert(self.ammocounter2==self.mana,"book publishes mana display");
    head=self.origin+self.view_ofs;self.headpos=head;self.handpos=head+'24 0 -8';self.offhandpos=head+'16 12 -8';
    self.mainhand_hotspot=self.offhand_hotspot=0;self.handrot=self.offhandrot='0 0 0';
    self.handvel=self.offhandvel=self.handavel=self.offhandavel='0 0 0';frametime=0.05;
    self.vrbits0=16384+8;ADVR_MagicFrame();self.vrbits0=16384+8+16;
    for(i=0;i<14;i=i+1)ADVR_MagicFrame();
    ADVR_Assert(self.advr_magic_charge>=0.65 && self.advr_magic_fx,"empty main hand charges visible flame");
    ADVR_Assert(self.advr_magic_ready && self.advr_magic_fx.origin==self.handpos,"ready feedback is armed and orb stays at hand");
    p=ADVR_Record(IT_SHOTGUN);self.advr_holster[0]=p;
    for(i=3;i<=9;i=i+1)if(i!=7) {
        self.mainhand_hotspot=i;
        ADVR_Assert(ADVR_Holster(1)<0 && !ADVR_HolsterHaptic(1),"casting hand ignores all six holster zones and feedback");
        ADVR_GripFrame(1);ADVR_MagicFrame();
        ADVR_Assert(self.advr_magic_fx && !self.advr_main && self.advr_holster[0]==p,"holster proximity retains charge and inventory");
    }
    self.mainhand_hotspot=3;
    self.vrbits0=16384+16;ADVR_MagicFrame();
    ADVR_Assert(self.mana==before && self.advr_magic_fx && self.advr_magic_release_until>time,"charged release waits for a late flick without spending");
    self.vrbits0=16384;ADVR_MagicFrame();
    ADVR_Assert(self.advr_magic_fx && self.advr_magic_release_until<=time+0.201,"open hand retains fixed grace deadline");
    self.advr_magic_release_until=time-0.01;ADVR_MagicFrame();
    ADVR_Assert(self.mana==before && !self.advr_magic_fx,"grace expiry cancels without spending");
    ADVR_Assert(ADVR_Holster(1)==0,"holster lookup resumes after cancellation");
    self.mainhand_hotspot=0;self.advr_holster[0]=world;remove(p);
    self.vrbits0=16384+8;ADVR_MagicFrame();self.vrbits0=16384+8+16;
    for(i=0;i<14;i=i+1)ADVR_MagicFrame();
    self.vrbits0=16384+16;ADVR_MagicFrame();
    self.vrbits0=16384;self.handvel='0 0.5 0.25';ADVR_MagicFrame();shot=newmis;
    ADVR_Assert(self.mana==before-1 && shot.owner==self && shot.advr_fireball,"charged flick spends one and creates player fireball");
    ADVR_Assert(shot.velocity_y>480 && shot.velocity_z>240 && fabs(shot.velocity_x)<1,"fireball follows flick, not head aim");
    ADVR_Assert(shot.advr_guidance.owner==self && shot.advr_guidance.advr_guidance_hand==1,"fire guidance remembers caster and hand");
    ADVR_Assert(fabs(vlen(shot.velocity)-550)<1,"cast bolt reduced speed");

    ADVR_MagicFrame();ADVR_Assert(self.mana==before-1,"release casts once");
    foe=spawn();foe.classname="advr_test_target";foe.classtype=CT_TARGETDUMMY;foe.solid=SOLID_BBOX;foe.takedamage=DAMAGE_YES;foe.health=1000;
    setsize(foe,'-4 -4 -4','4 4 4');setorigin(foe,shot.origin+'12 0 0');self=shot;other=foe;Touch_Missile();self=player;
    ADVR_Assert(foe.health<1000,"fireball damages target through native AD impact");remove(foe);
    // Spell menu uses book-hand trigger edges, persists and cannot change mid-cast.
    self.button3=1;ADVR_MagicFrame();ADVR_Assert(self.advr_spell==1,"book trigger selects lightning");
    ADVR_MagicFrame();ADVR_Assert(self.advr_spell==1,"held trigger does not cycle");
    self.button3=0;ADVR_MagicFrame();ADVR_SaveParms();self.advr_spell=0;ADVR_LoadParms();book=self.advr_off;
    ADVR_Assert(self.advr_spell==1 && self.weaponframe2==1,"selected spell persists and reaches book UI");
    self.vrbits0=16384+8;ADVR_MagicFrame();self.vrbits0=16384+8+16;
    for(i=0;i<14;i=i+1)ADVR_MagicFrame();
    ADVR_Assert(self.advr_magic_fx.skin==1 && self.advr_magic_ready,"lightning charges a ready blue orb");
    self.button3=1;ADVR_MagicFrame();self.button3=0;ADVR_Assert(self.advr_spell==1,"menu locked during charge");
    foe=spawn();foe.classname="advr_test_target";foe.classtype=CT_TARGETDUMMY;foe.solid=SOLID_BBOX;foe.takedamage=DAMAGE_YES;foe.health=1000;
    setsize(foe,'-6 -6 -6','6 6 6');setorigin(foe,self.handpos+'48 0 0');
    self.handvel='0 0 0';self.advr_magic_peak='0 0 0';before=self.mana;
    self.vrbits0=16384+16;ADVR_MagicFrame();
    ADVR_Assert(self.advr_magic_release_until>time,"lightning also waits for a late flick");
    self.vrbits0=16384;self.handvel='2 0 0';ADVR_MagicFrame();
    ADVR_Assert(self.mana==before-1 && self.advr_magic_burst>0 && self.advr_magic_fx.classname=="advr_magic_beam","lightning launches dedicated beam for one mana");
    ADVR_Assert(foe.health<1000,"lightning beam damages target");before=foe.health;
    self.handrot='0 90 0';self.advr_magic_tick=0;ADVR_MagicFrame();
    ADVR_Assert(foe.health==before && self.advr_magic_direction_y>0.99,"turning hand moves lightning off original target");
    self.handpos=self.handpos+'0 0 8';setorigin(foe,self.handpos+'0 48 0');
    self.advr_magic_tick=0;ADVR_MagicFrame();
    ADVR_Assert(foe.health<before && self.advr_magic_fx.origin==self.handpos,"lightning follows moving hand and damages new aim target");before=foe.health;
    for(i=0;i<14;i=i+1)ADVR_MagicFrame();
    ADVR_Assert(foe.health<before && !self.advr_magic_book && !self.advr_magic_fx,"lightning sustains damage then stops");remove(foe);
    self.advr_spell=0;self.handvel='0 0 0';self.handrot='0 0 0';
    // Reverse the hands and cancel by occupying the casting hand.
    self.advr_off=world;self.advr_main=book;self.vrbits0=16384+2;ADVR_MagicFrame();
    ADVR_Assert(self.advr_magic_book==book && self.advr_magic_hand==0,"tome can be held in either hand");
    self.offhand_hotspot=3;ADVR_MagicFrame();
    ADVR_Assert(self.advr_magic_fx && ADVR_Holster(0)<0,"off-hand charge also ignores holsters");
    self.mainhand_hotspot=4;ADVR_Assert(ADVR_Holster(1)==1,"book hand retains holster mechanics");
    self.mainhand_hotspot=self.offhand_hotspot=0;
    self.advr_off=ADVR_Record(IT_AXE);ADVR_MagicFrame();ADVR_Assert(!self.advr_magic_fx,"occupied hand cancels magic");
    self.advr_off=world;self.mana=0;self.vrbits0=16384+2;ADVR_MagicFrame();ADVR_Assert(!self.advr_magic_fx,"empty mana blocks charging");
    self.mana=30;self.vrbits0=16384+2;ADVR_MagicFrame();self.health=0;ADVR_MagicFrame();ADVR_Assert(!self.advr_magic_fx,"death clears flame");self.health=100;
    self.vrbits0=16384;frametime=oldframe;ADVR_Sync();
    bprint("ADVR MAGIC PASS: tome pickup, once-only mana, kill rewards, map parms, both hands, charge, cancel, flick, fireball damage\n");
};

void() ADVR_TestMagicState = {
    ADVR_Assert(self.mana==30 && self.advr_mana_seen,"save/load preserves mana and first-pickup state");
    ADVR_Assert(ADVR_IsTome(self.advr_main) || ADVR_IsTome(self.advr_off),"save/load preserves physical tome");
    bprint("ADVR MAGIC STATE PASS: tome and mana retained across save/load\n");
};

void() ADVR_TestProgression = {
    local entity player,book,second,debug,foe,power;
    local float i,first,oldframe,oldconfig,code,key;
    player=self;oldframe=frametime;oldconfig=configflag;frametime=0.05;
    ADVR_Reset();self.advr_initialized=1;self.health=100;self.items=self.items | IT_AXE;
    book=ADVR_Record(IT_AXE);book.advr_kind=ADVR_TOME;
    ADVR_Assert(!self.advr_known && self.advr_mana_max==50,"new player has no spells and fifty capacity");
    ADVR_TomePickup(self,book);first=self.advr_known;
    ADVR_Assert((first==1 || first==2 || first==4 || first==8 || first==16 || first==32 || first==64 || first==128 || first==512 || first==1024) && self.mana==30,"first standard tome teaches exactly one spell and grants thirty mana");
    ADVR_TomePickup(self,book);
    ADVR_Assert(self.advr_known==first && self.mana==30,"same physical tome cannot teach or refill twice");
    self.advr_off=book;self.button3=1;ADVR_MagicSelect();self.button3=0;ADVR_MagicSelect();
    ADVR_Assert(first & pow(2,self.advr_spell),"selection skips unknown spells");
    debug=ADVR_Record(IT_AXE);debug.advr_kind=ADVR_DEBUGTOME;ADVR_TomePickup(self,debug);
    ADVR_Assert(ADVR_SpellMask(self,debug)==1791 && self.advr_known==first,"debug exposes all spells without learning them");
    second=ADVR_Record(IT_AXE);second.advr_kind=ADVR_TOME;ADVR_TomePickup(self,second);
    second=ADVR_Record(IT_AXE);second.advr_kind=ADVR_TOME;ADVR_TomePickup(self,second);
    second=ADVR_Record(IT_AXE);second.advr_kind=ADVR_TOME;ADVR_TomePickup(self,second);
    second=ADVR_Record(IT_AXE);second.advr_kind=ADVR_TOME;ADVR_TomePickup(self,second);
    second=ADVR_Record(IT_AXE);second.advr_kind=ADVR_TOME;ADVR_TomePickup(self,second);
    second=ADVR_Record(IT_AXE);second.advr_kind=ADVR_TOME;ADVR_TomePickup(self,second);
    second=ADVR_Record(IT_AXE);second.advr_kind=ADVR_TOME;ADVR_TomePickup(self,second);
    second=ADVR_Record(IT_AXE);second.advr_kind=ADVR_TOME;ADVR_TomePickup(self,second);
    second=ADVR_Record(IT_AXE);second.advr_kind=ADVR_TOME;ADVR_TomePickup(self,second);
    ADVR_Assert(self.advr_known==1791 && ADVR_SpellMask(self,book)==1791,"ten new tomes teach all spells, visible in first tome");
    self.mana=49;foe=spawn();foe.flags=FL_MONSTER;foe.classtype=CT_MONSKULLW;
    ADVR_ManaReward(foe,self);ADVR_Assert(self.mana==50,"magical kill reward clamps at mana capacity");remove(foe);
    power=spawn();self=power;other=player;ADVR_PowerPickup();ADVR_PowerPickup();self=player;
    ADVR_Assert(self.advr_mana_max==60 && self.mana==50,"one Tome of Power adds ten capacity exactly once without refilling");remove(power);
    configflag=configflag-(configflag & 15);
    ADVR_Assert(ADVR_MagicMultiplier()==1,"no runes means base magic damage");
    for(i=0;i<4;i=i+1){configflag=configflag | pow(2,i);ADVR_Assert(fabs(ADVR_MagicMultiplier()-(1+0.05*(i+1)))<0.001,"each rune adds five percent magic damage");}
    configflag=oldconfig;
    // Physical left D-pad works with the book in either hand. Face codes do nothing.
    for(first=0;first<2;first=first+1)for(key=4;key<8;key=key+1) {
        self.advr_main=world;self.advr_off=book;
        if(first){self.advr_main=book;self.advr_off=world;}
        code=key-1;self.advr_spell=1;self.advr_magic_buttons=code;
        for(i=0;i<41;i=i+1)ADVR_MagicSelect();
        ADVR_Assert(self.advr_favorites[key]==2,"D-pad hold assigns with book in either hand");
        self.advr_magic_buttons=0;ADVR_MagicSelect();self.advr_spell=0;
        self.advr_magic_buttons=code;ADVR_MagicSelect();self.advr_magic_buttons=0;ADVR_MagicSelect();
        ADVR_Assert(self.advr_spell==1,"D-pad tap recalls with book in either hand");
    }
    for(code=9;code<=12;code=code+1) {
        self.advr_magic_buttons=code;
        for(i=0;i<41;i=i+1)ADVR_MagicSelect();
        self.advr_magic_buttons=0;ADVR_MagicSelect();
    }
    ADVR_Assert(!self.advr_favorites[0] && !self.advr_favorites[1] && !self.advr_favorites[2] && !self.advr_favorites[3],"face buttons never assign favorites");
    self.advr_off=book;self.advr_main=world;self.advr_spell=0;self.advr_magic_buttons=3;
    for(i=0;i<41;i=i+1)ADVR_MagicSelect();self.advr_magic_buttons=0;ADVR_MagicSelect();
    ADVR_Assert(self.advr_favorites[4]==1,"long D-pad hold rebinds instead of recalling old favorite");
    self.advr_main=debug;ADVR_SaveParms();ADVR_Reset();ADVR_LoadParms();book=self.advr_off;
    ADVR_Assert(self.advr_known==1791 && self.advr_mana_max==60 && self.advr_favorites[4]==1 && self.advr_favorites[7]==2,"knowledge capacity and favorites survive map parms");
    ADVR_Assert(book.advr_tome_read && self.advr_main.advr_kind==ADVR_DEBUGTOME,"read state and debug identity survive map parms");
    self.advr_known=1;self.advr_main=world;self.advr_spell=0;self.advr_magic_buttons=4;ADVR_MagicSelect();
    self.advr_magic_buttons=0;ADVR_MagicSelect();ADVR_Assert(self.advr_spell==0,"debug-only favorite cannot unlock an unknown spell in a standard tome");
    self.advr_magic_version=0;self.advr_mana_seen=1;self.advr_known=0;self.mana=9999;self.advr_mana_max=0;ADVR_MagicInit(self);
    ADVR_Assert(self.advr_known==3 && self.mana==50,"old save migrates spells and clamps mana");
    frametime=oldframe;ADVR_Sync();
    bprint("ADVR PROGRESSION PASS: learning, debug tome, mana caps, runes, all favorites, map persistence and migration\n");
};

void() ADVR_TestEnchant = {
    local entity book,r,shot,v,player,p;
    local float i,h,oldframe,before;
    player=self;oldframe=frametime;frametime=0.05;
    ADVR_TestMagicView();self.advr_off.advr_kind=ADVR_TOME;self.advr_known=1791;book=self.advr_off;self.vrbits0=16384;
    self.handpos=ADVR_Head(self)+'24 0 -8';self.offhandpos=ADVR_Head(self)+'24 16 -8';
    self.handrot=self.offhandrot='0 0 0';self.handvel=self.offhandvel='0 0 0';
    self.mainhand_hotspot=self.offhand_hotspot=0;
    for(h=0;h<2;h=h+1) {
        self.advr_main=self.advr_off=world;ADVR_SetHand(1-h,book);
        self.advr_magic_sticks=pow(2,h);
        for(i=0;i<15;i=i+1)ADVR_MagicFrame();
        ADVR_Assert(self.advr_magic_ready && self.advr_magic_control,"either stick click charges with empty hand");
        before=self.mana;self.advr_magic_sticks=0;
        if(h)self.handvel='0 1 0';else self.offhandvel='0 1 0';
        ADVR_MagicFrame();shot=newmis;
        ADVR_Assert(self.mana==before-1 && shot.advr_fireball,"stick release and flick casts once");remove(shot);
        self.handvel=self.offhandvel='0 0 0';ADVR_MagicFrame();
    }
    self.advr_off=book;r=ADVR_Record(IT_SHOTGUN);self.advr_main=r;self.items=self.items | IT_SHOTGUN;
    before=self.mana;self.advr_magic_sticks=2;
    for(i=0;i<20;i=i+1)ADVR_MagicFrame();
    ADVR_Assert(self.advr_enchant_record==r && self.advr_enchant_charge>0 && !self.advr_enchant_fx,"charging uses weapon state without a casting orb");
    self.advr_magic_sticks=0;ADVR_MagicFrame();
    ADVR_Assert(!r.advr_enchant_type && self.mana==before && !self.advr_enchant_fx,"short enchant hold cancels free");
    self.advr_magic_sticks=2;
    for(i=0;i<65;i=i+1)ADVR_MagicFrame();
    ADVR_Assert(r.advr_enchant_type==1 && r.advr_enchant_until==time+30 && self.mana==before-5,"three second hold enchants for thirty seconds at five mana");
    for(i=0;i<70;i=i+1)ADVR_MagicFrame();
    ADVR_Assert(self.mana==before-5 && !self.advr_enchant_record,"held click cannot spend repeatedly");
    self.advr_magic_sticks=0;ADVR_MagicFrame();
    ADVR_Drop(1);p=find(world,classname,"advr_dropped_weapon");while(p && p.weaponinst!=r)p=find(p,classname,"advr_dropped_weapon");
    ADVR_Assert(p.weaponinst.advr_enchant_type==1,"drop retains enchantment on physical record");
    ADVR_Catch(p,1);ADVR_Assert(self.advr_main==r && r.advr_enchant_type==1,"catch keeps same enchantment");
    self.advr_holster[0]=r;self.advr_main=world;ADVR_SaveParms();ADVR_Reset();ADVR_LoadParms();
    r=self.advr_holster[0];book=self.advr_off;
    ADVR_Assert(r.advr_enchant_type==1 && r.advr_enchant_until==time+30,"holstered enchant survives map transition with remaining duration");
    self.advr_main=r;self.advr_holster[0]=world;
    v=spawn();v.classname="advr_enchant_target";v.flags=FL_MONSTER;v.takedamage=DAMAGE_YES;v.health=1000;
    setmodel(v,"progs/player.mdl");setorigin(v,ADVR_Head(self)+'100 0 0');
    v.enemy=player;v.switchattacker=player;v.switchtimer=time+100;v.invincible_finished=0;
    advr_attack_actor=self;advr_attack_record=r;T_Damage(v,self,self,40,NOARMOR);
    ADVR_Assert(v.health==958 && v.advr_burn,"enchanted direct weapon hit adds 5 percent and ignites");
    ADVR_FireOut(v.advr_burn);
    r.advr_enchant_type=2;
    Launch_Missile(self.handpos,'1 0 0','0 0 0',CT_PROJ_FIRETOP,750);shot=newmis;
    advr_attack_record=world;advr_attack_actor=world;
    self.advr_main=world;T_Damage(v,shot,self,40,NOARMOR);
    ADVR_Assert(v.health==916 && shot.advr_enchant_type==2,"projectile retains lightning after weapon leaves hand");
    T_Damage(v,self,self,40,NOARMOR);
    ADVR_Assert(v.health==876,"unrelated damage cannot inherit enchantment");
    shot.advr_enchant_until=time-1;T_Damage(v,shot,self,40,NOARMOR);
    ADVR_Assert(v.health==836,"expired infusion adds no damage");remove(shot);
    v.th_pain=knight_pain;v.classgroup=CG_KNIGHT;v.pain_sound="weapons/lhit.wav";
    ADVR_Assert(!ADVR_EnchantStagger(v,0.5),"ordinary lightning roll does not stagger");
    ADVR_Assert(!ADVR_EnchantStagger(v,0),"rapid hits cannot repeat a stagger attempt");
    v.advr_stagger_next=0;ADVR_Assert(ADVR_EnchantStagger(v,0.05),"ten percent roll staggers");
    ADVR_Assert(v.advr_stagger_next==time+2 && !ADVR_EnchantStagger(v,0),"successful stagger has two second cooldown");
    v.advr_stagger_next=0;v.bossflag=1;ADVR_Assert(!ADVR_EnchantStagger(v,0),"bosses retain their pain protections");v.bossflag=0;
    v.vr_knockdown=1;ADVR_Assert(!ADVR_EnchantStagger(v,0),"stagger cannot interrupt a knockdown");v.vr_knockdown=0;
    v.pain_finstate=time-PAIN_ALWAY-1;v.pain_flinch=1000;self=v;knight_pain(player,player,1);self=player;
    ADVR_Assert(v.pain_check==1,"stagger requests real native pain animation at low damage");
    self.advr_main=book;self.advr_off=r;self.advr_spell=1;self.mana=20;self.advr_magic_sticks=1;
    for(i=0;i<65;i=i+1)ADVR_MagicFrame();
    ADVR_Assert(r.advr_enchant_type==2 && self.mana==15,"left weapon stick enchants while book is right");
    self.advr_magic_sticks=0;ADVR_MagicFrame();self.advr_magic_sticks=1;ADVR_MagicFrame();
    self.health=0;ADVR_MagicFrame();
    ADVR_Assert(!self.advr_enchant_fx && !self.advr_enchant_record,"death cancels pending enchantment");
    self.health=100;self.advr_magic_sticks=0;ADVR_MagicFrame();remove(v);
    frametime=oldframe;ADVR_Sync();
    bprint("ADVR ENCHANT PASS: both stick casts, cancellation, duration, mana, hold latch, record persistence, damage, projectile isolation and expiry\n");
};


void() ADVR_TestEnchantGlow = {
    local entity prop;
    ADVR_Reset();self.advr_initialized=1;self.health=100;self.flags=self.flags | FL_GODMODE;
    self.items=self.items | IT_SHOTGUN | IT_SUPER_SHOTGUN;
    self.advr_main=ADVR_Record(IT_SHOTGUN);self.advr_off=ADVR_Record(IT_SUPER_SHOTGUN);
    self.advr_main.advr_enchant_type=1;self.advr_main.advr_enchant_until=time+30;
    self.advr_off.advr_enchant_type=2;self.advr_off.advr_enchant_until=time+30;
    self.advr_main.advr_enchant_scale=self.advr_off.advr_enchant_scale=1;
    prop=ADVR_SpawnLoot(self,IT_SHOTGUN);prop.weaponinst.advr_enchant_type=1;prop.weaponinst.advr_enchant_until=time+2;
    setorigin(prop,self.origin+'64 0 8');
    self.advr_holster[0]=ADVR_Record(IT_SHOTGUN);self.advr_holster[0].advr_enchant_type=2;self.advr_holster[0].advr_enchant_until=time+2;
    ADVR_Sync();
};



// Real server think scheduling: first interval chilled, then expired, then dead.
void() ADVR_TestFrostTick = {
    if(self.count==1) {
        ADVR_Assert(fabs(time-self.attack_finished-0.1/0.65)<0.002,"frost slows actual AI think interval by 35 percent");
        self.advr_frost_until=time-1;
    } else if(self.count==2) {
        ADVR_Assert(fabs(time-self.attack_finished-0.1)<0.002,"expired frost restores normal interval");
        self.advr_frost_until=time+4;self.health=0;
    } else if(self.count==3) {
        ADVR_Assert(fabs(time-self.attack_finished-0.1)<0.002,"frost does not slow corpse thinks");
        bprint("ADVR FROST TIMING PASS: chilled, expired and dead AI intervals\n");remove(self);return;
    }
    self.count=self.count+1;self.attack_finished=time;self.nextthink=time+0.1;
};
void() ADVR_TestFrostView = {
    ADVR_TestMagicView();self.advr_spell=2;ADVR_Sync();
};
void() ADVR_TestFrost = {
    local entity player,book,v,shot,r,timer;
    local float i,oldframe,before;
    player=self;oldframe=frametime;frametime=0.05;
    ADVR_TestFrostView();self.advr_off.advr_kind=ADVR_TOME;self.advr_known=1791;book=self.advr_off;
    self.advr_known=1787;r=ADVR_Record(IT_AXE);r.advr_kind=ADVR_TOME;ADVR_TomePickup(self,r);
    ADVR_Assert(self.advr_known==1791 && self.advr_spell==2,"new standard tome teaches missing frost");remove(r);
    self.advr_favorites[4]=3;ADVR_SaveParms();ADVR_Reset();ADVR_LoadParms();book=self.advr_off;
    ADVR_Assert(self.advr_spell==2 && self.weaponframe2==2 && self.advr_favorites[4]==3,"frost selection and favorite survive map parms");
    self.vrbits0=16384;self.handpos=ADVR_Head(self)+'24 0 -8';self.offhandpos=ADVR_Head(self)+'24 16 -8';
    self.handrot=self.offhandrot='0 0 0';self.handvel=self.offhandvel='0 0 0';self.mainhand_hotspot=self.offhand_hotspot=0;
    self.advr_magic_sticks=2;before=self.mana;
    for(i=0;i<15;i=i+1)ADVR_MagicFrame();
    ADVR_Assert(self.advr_magic_ready && self.advr_magic_fx.skin==1,"frost charges blue orb");
    self.handvel='0 1 0';self.advr_magic_sticks=0;ADVR_MagicFrame();shot=newmis;
    ADVR_Assert(self.mana==before-1 && !shot,"frost flick emits cone for one mana without a projectile");
    ADVR_FrostLaunch(self.handpos,'0 1 0');shot=newmis; // legacy impact callback remains valid for existing projectiles
    v=spawn();v.classname="advr_frost_target";v.flags=FL_MONSTER;v.takedamage=DAMAGE_YES;v.health=1000;
    v.enemy=player;v.switchattacker=player;v.switchtimer=time+100;
    setmodel(v,"progs/player.mdl");setorigin(v,ADVR_Head(self)+'100 0 0');
    shot.advr_magic_damage=1;self=shot;other=v;ADVR_FrostTouch();self=player;
    ADVR_Assert(v.health==970 && v.advr_frost_until==time+8 && !v.advr_burn,"frost impact damages and chills without burning");
    v.advr_frost_until=time+1;ADVR_FrostHit(v);ADVR_FrostHit(v);
    ADVR_Assert(v.advr_frost_until==time+8,"repeat frost refreshes rather than stacks");
    r=ADVR_Record(IT_SHOTGUN);self.advr_main=r;self.handvel='0 0 0';self.advr_magic_sticks=2;
    for(i=0;i<65;i=i+1)ADVR_MagicFrame();
    ADVR_Assert(r.advr_enchant_type==3,"frost selection enchants held gun");r.advr_enchant_scale=1;
    advr_attack_actor=self;advr_attack_record=r;T_Damage(v,self,self,40,NOARMOR);
    ADVR_Assert(v.health==928 && v.advr_frost_until==time+8,"frost hits add five percent and chill");
    shot=spawn();shot.owner=self;ADVR_EnchantMissile(shot);advr_attack_actor=world;advr_attack_record=world;
    T_Damage(v,shot,self,40,NOARMOR);
    ADVR_Assert(v.health==886 && shot.advr_enchant_type==3,"frost projectile keeps enchant payload");remove(shot);
    v.advr_frost_until=0;v.flags=FL_CLIENT;ADVR_FrostHit(v);ADVR_Assert(!v.advr_frost_until,"frost ignores players");
    v.flags=FL_MONSTER | FL_GODMODE;ADVR_FrostHit(v);ADVR_Assert(!v.advr_frost_until,"frost respects invulnerability");remove(v);
    timer=spawn();timer.classname="advr_frost_clock";timer.flags=FL_MONSTER;timer.health=10;
    timer.advr_frost_until=time+4;timer.think=ADVR_TestFrostTick;timer.nextthink=time+0.1;
    self.advr_magic_sticks=0;ADVR_MagicFrame();frametime=oldframe;ADVR_Sync();
    bprint("ADVR FROST PASS: learning, persistence, casting, damage, refresh, enchantments and immunity\n");
};

void() ADVR_TestAcid = {
    local entity player,v,shot,e,r,splash;local float oldframe,start,i,hp,packed;
    player=self;oldframe=frametime;frametime=0.05;
    ADVR_TestMagicView();self.advr_off.advr_kind=ADVR_TOME;self.advr_known=1791;self.advr_known=1783;r=ADVR_Record(IT_AXE);r.advr_kind=ADVR_TOME;ADVR_TomePickup(self,r);
    ADVR_Assert(self.advr_known==1791 && self.advr_spell==3,"standard tome teaches acid");remove(r);
    self.advr_favorites[4]=4;ADVR_SaveParms();ADVR_Reset();ADVR_LoadParms();
    ADVR_Assert(self.advr_spell==3 && self.weaponframe2==3 && self.advr_favorites[4]==4,"acid selection and favorite persist");
    self.vrbits0=16384;self.handpos=ADVR_Head(self)+'24 0 -8';self.handvel=self.offhandvel='0 0 0';
    self.handrot=self.offhandrot='0 0 0';self.mainhand_hotspot=self.offhand_hotspot=0;
    self.advr_magic_sticks=2;
    for(i=0;i<15;i=i+1)ADVR_MagicFrame();
    ADVR_Assert(self.advr_magic_ready && self.advr_magic_fx.model=="progs/advr_acid_charge.mdl","acid charges green orb");
    hp=self.mana;self.handvel='0 1 0';self.advr_magic_sticks=0;ADVR_MagicFrame();shot=newmis;
    ADVR_Assert(shot.advr_acidbolt && !shot.advr_fireball && self.mana==hp-1,"acid flick costs one mana");
    v=spawn();v.classname="advr_acid_target";v.flags=FL_MONSTER;v.health=1000;v.takedamage=DAMAGE_YES;
    setmodel(v,"progs/player.mdl");setorigin(v,ADVR_Head(self)+'100 0 0');v.enemy=player;v.switchattacker=player;v.switchtimer=time+100;
    splash=spawn();splash.flags=FL_MONSTER;splash.health=1000;splash.takedamage=DAMAGE_YES;
    setorigin(splash,shot.origin+'0 0 20');splash.enemy=player;splash.switchattacker=player;splash.switchtimer=time+100;
    shot.advr_magic_damage=1;self=shot;other=v;ADVR_AcidTouch();self=player;
    ADVR_Assert(splash.health==970 && splash.advr_acid,"nearby acid splash has falloff and corrosion");
    remove(splash.advr_acid);remove(splash);
    ADVR_Assert(v.health==960 && v.advr_acid && !v.advr_burn,"acid impact deals forty and starts acid only");
    e=v.advr_acid;ADVR_AcidApply(v,self,1);ADVR_AcidApply(v,self,1);
    ADVR_Assert(v.advr_acid==e && e.advr_acid_end==time+4,"acid refresh uses one effect");
    start=time;self=e;
    for(i=1;i<=8;i=i+1){time=start+i*0.5;ADVR_AcidThink();}
    ADVR_Assert(v.health==928,"eight acid ticks total thirty two damage");
    time=start+4.1;ADVR_AcidThink();self=player;time=start;
    ADVR_Assert(!v.advr_acid,"acid expiry cleans up");
    v.classtype=CT_MONWIZARD;ADVR_AcidApply(v,self,1);e=v.advr_acid;hp=v.health;
    self=e;ADVR_AcidThink();self=player;
    ADVR_Assert(v.health==hp-2 && ADVR_AcidResistance(v)==0.5,"scrag takes half acid damage");
    v.health=0;self=e;ADVR_AcidThink();self=player;ADVR_Assert(!v.advr_acid,"death removes acid");v.health=1000;
    r=ADVR_Record(IT_SHOTGUN);r.advr_enchant_type=4;r.advr_enchant_until=time+30;r.advr_enchant_scale=1;
    packed=ADVR_EnchantPack(r);r.advr_enchant_type=0;ADVR_EnchantRestore(r,packed);
    ADVR_Assert(r.advr_enchant_type==4 && r.advr_enchant_until==time+30,"acid enchant survives packed map state");
    advr_attack_actor=self;advr_attack_record=r;T_Damage(v,self,self,40,NOARMOR);
    ADVR_Assert(v.health==959 && v.advr_acid,"scrag resists elemental bonus without reducing bullet damage");
    advr_attack_actor=world;advr_attack_record=world;
    e=v.advr_acid;v.health=0;self=e;ADVR_AcidThink();self=player;v.health=1000;v.classtype=CT_MONKNIGHT;v.classgroup=CG_STONE;
    shot=spawn();shot.advr_fireball=1;shot.owner=self;T_Damage(v,shot,self,20,NOARMOR);
    ADVR_Assert(v.health==990 && v.advr_burn,"stone resists fire impact");e=v.advr_burn;hp=v.health;
    self=e;self.advr_fire_tick=0;ADVR_FireThink();self=player;
    ADVR_Assert(v.health==hp-1,"stone resists burn damage");ADVR_FireOut(e);remove(shot);
    ADVR_EnchantRestore(r,242);ADVR_Assert(r.advr_enchant_type==2 && r.advr_enchant_until==time+30,"legacy enchant packing remains readable");
    remove(v);self.advr_main=r;self.advr_spell=3;self.handvel='0 0 0';self.advr_magic_sticks=2;
    for(i=0;i<65;i=i+1)ADVR_MagicFrame();
    ADVR_Assert(r.advr_enchant_type==4 && r.advr_enchant_until==time+30,"holding stick applies acid enchant");
    self.advr_magic_sticks=0;ADVR_MagicFrame();frametime=oldframe;self.advr_spell=3;self.handvel='0 0 0';ADVR_Sync();
    bprint("ADVR ACID PASS: learning, cast, DOT ticks, refresh, expiry, resistances and enchant persistence\n");
};

void() ADVR_TestHaste = {
    local entity r,v;local float i,oldframe,before;
    oldframe=frametime;frametime=0.05;ADVR_TestMagicView();self.advr_off.advr_kind=ADVR_TOME;self.advr_known=1791;
    self.advr_known=1759;r=ADVR_Record(IT_AXE);r.advr_kind=ADVR_TOME;ADVR_TomePickup(self,r);
    ADVR_Assert(self.advr_known==1791 && self.advr_spell==5,"tome teaches haste");remove(r);
    self.advr_favorites[4]=6;ADVR_SaveParms();ADVR_Reset();ADVR_LoadParms();
    ADVR_Assert(self.advr_spell==5 && self.advr_favorites[4]==6,"haste favorite and selection persist");
    self.vrbits0=16384;self.handpos=ADVR_Head(self)+'24 0 -8';self.handrot=self.offhandrot='0 0 0';
    self.handvel=self.offhandvel=self.handavel=self.offhandavel='0 0 0';
    self.mainhand_hotspot=self.offhand_hotspot=0;self.advr_magic_sticks=0;ADVR_MagicFrame();
    self.advr_magic_sticks=2;for(i=0;i<15;i=i+1)ADVR_MagicFrame();
    before=self.mana;newmis=world;self.advr_magic_sticks=0;ADVR_MagicFrame();
    ADVR_Assert(self.advr_haste_until==time+30 && self.mana==before-1 && !newmis && !self.advr_magic_fx,"release casts haste without flick or projectile");
    self.advr_spell=0;self.advr_magic_sticks=2;
    for(i=0;i<10;i=i+1)ADVR_MagicFrame();
    ADVR_Assert(self.advr_magic_charge<0.65,"haste still requires a deliberate charge");
    ADVR_MagicFrame();ADVR_Assert(self.advr_magic_charge>=0.65 && self.advr_magic_ready,"haste charges another spell 25 percent faster");
    ADVR_MagicClear();self.advr_magic_sticks=0;ADVR_MagicFrame();self.advr_haste_until=time-1;
    self.advr_magic_sticks=2;for(i=0;i<11;i=i+1)ADVR_MagicFrame();
    ADVR_Assert(self.advr_magic_charge<0.65 && !self.advr_magic_ready,"expired haste restores normal spell charge speed");
    ADVR_MagicClear();self.advr_magic_sticks=0;ADVR_MagicFrame();self.advr_spell=5;self.advr_haste_until=time+30;
    self.advr_magic_sticks=2;for(i=0;i<15;i=i+1)ADVR_MagicFrame();
    self.advr_magic_sticks=0;ADVR_MagicFrame();ADVR_Assert(self.advr_haste_until==time+30,"haste refreshes without stacking");
    r=ADVR_Record(IT_SHOTGUN);r.advr_enchant_type=6;r.advr_enchant_until=time+30;
    ADVR_EnchantRestore(r,ADVR_EnchantPack(r));ADVR_Assert(ADVR_HasteRate(r)==1.25,"haste enchant persists and accelerates cadence");
    v=spawn();v.flags=FL_MONSTER;v.health=100;advr_attack_actor=self;advr_attack_record=r;
    ADVR_Assert(ADVR_EnchantDamage(v,self,self,40)==40 && !advr_enchant_stagger,"haste adds no damage or lightning stagger");
    r.advr_enchant_until=time;ADVR_Assert(ADVR_HasteRate(r)==1,"expired haste restores ordinary cadence");
    advr_attack_actor=advr_attack_record=world;remove(v);
    self.advr_main=r;self.button0=1;self.advr_fg_rearm[1]=0;self.ammo_shells=50;r.wi_clip=8;
    self.muzzlepos=ADVR_Head(self)+'24 0 0';self.shotrot='0 0 0';r.advr_cooldown=0;r.advr_animtime=0;
    ADVR_Fire(1);before=r.advr_cooldown-time;ADVR_Assert(before>0,"ordinary shotgun schedules next shot");
    r.advr_enchant_until=time+30;r.advr_cooldown=0;r.advr_animtime=0;ADVR_Fire(1);
    ADVR_Assert(fabs((r.advr_cooldown-time)*1.25-before)<0.001,"haste accelerates actual shotgun cooldown");
    self.button0=0;self.advr_main=world;remove(r);frametime=oldframe;ADVR_Sync();
    bprint("ADVR HASTE PASS: learning, favorites, self cast, refresh, enchant persistence, cadence and damage isolation\n");
};


void() ADVR_TestProtection = {
    local entity r,v,q,shot;local float i,oldframe,hp,stamina,packed;local vector hand;
    oldframe=frametime;frametime=0.05;ADVR_TestMagicView();self.advr_off.advr_kind=ADVR_TOME;self.advr_known=1791;
    self.advr_known=1727;r=ADVR_Record(IT_AXE);r.advr_kind=ADVR_TOME;ADVR_TomePickup(self,r);
    ADVR_Assert(self.advr_known==1791 && self.advr_spell==6,"tome teaches protection");remove(r);
    self.advr_favorites[4]=7;ADVR_SaveParms();ADVR_Reset();ADVR_LoadParms();
    ADVR_Assert(self.advr_spell==6 && self.advr_favorites[4]==7,"protection selection and favorite persist");
    self.vrbits0=16384;self.handpos=ADVR_Head(self)+'24 0 -8';self.handrot=self.offhandrot='0 0 0';
    self.handvel=self.offhandvel=self.handavel=self.offhandavel='0 0 0';
    self.mainhand_hotspot=self.offhand_hotspot=0;self.advr_magic_sticks=0;ADVR_MagicFrame();
    self.advr_magic_sticks=2;for(i=0;i<15;i=i+1)ADVR_MagicFrame();
    hp=self.mana;newmis=world;self.advr_magic_sticks=0;ADVR_MagicFrame();
    ADVR_Assert(self.advr_protection_armor==50 && self.advr_protection_until==time+60 && self.mana==hp-1 && !newmis,"self cast gives fifty armor for sixty seconds without projectile");
    self.health=1000;self.armorvalue=100;self.armortype=0.3;self.moditems=0;self.invincible_finished=0;
    self.flags=self.flags-(self.flags & FL_GODMODE);self.takedamage=DAMAGE_AIM;
    v=spawn();v.flags=FL_MONSTER;setorigin(v,self.origin+'0 -80 11');
    T_Damage(self,v,v,30,DAMARMOR);
    ADVR_Assert(self.advr_protection_armor==26 && self.health==994 && self.armorvalue==100,"temporary red armor absorbs eighty percent and preserves regular armor");
    self.advr_protection_until=time;hp=self.health;T_Damage(self,v,v,30,DAMARMOR);
    ADVR_Assert(self.health==hp-21 && self.armorvalue==91,"expired protection uses ordinary armor");
    r=ADVR_Record(IT_SHOTGUN);r.advr_enchant_type=7;r.advr_enchant_until=time+60;r.advr_shield_hp=300;self.advr_main=r;
    self.handpos=self.origin+'-8 -10 9';stamina=self.vr_stamina_used;
    ADVR_Assert(ADVR_ShieldPose(1) && advr_shield_normal_y<0,"right shield is on weapon right side");
    ADVR_Assert(ADVR_ShieldDamage(self,v,v,100,DAMARMOR)==0 && r.advr_shield_hp==200 && self.vr_stamina_used==stamina,"shield blocks crossing attack without stamina");
    setorigin(v,self.origin+'0 80 11');
    ADVR_Assert(ADVR_ShieldDamage(self,v,v,100,DAMARMOR)==100 && r.advr_shield_hp==200,"shield does not block attacks from behind");
    setorigin(v,self.origin+'160 -80 11');ADVR_Assert(ADVR_ShieldDamage(self,v,v,100,DAMARMOR)==100,"attacks outside disc miss shield");
    setorigin(v,self.origin+'0 -80 11');
    shot=spawn();shot.velocity='0 500 0';setorigin(shot,self.origin+'0 -8 11');
    ADVR_Assert(ADVR_ShieldDamage(self,shot,v,40,DAMARMOR)==0 && r.advr_shield_hp==160,"projectile impact reconstructs incoming path across shield");remove(shot);
    hp=self.health;ADVR_MeleeDamage(self,v,v,20,DAMARMOR);
    ADVR_Assert(self.health==hp && r.advr_shield_hp==140 && self.vr_stamina_used==stamina,"shield intercepts melee before stamina parry");
    r.advr_shield_hp=200;
    ADVR_Assert(ADVR_ShieldDamage(self,v,v,350,DAMARMOR)==150 && r.advr_shield_hp==0 && r.advr_enchant_until<=time,"shield breaks at capacity with excess damage passing through");
    r.advr_shield_hp=173;r.advr_enchant_until=time+60;packed=ADVR_EnchantPack(r);q=ADVR_Record(IT_SHOTGUN);ADVR_EnchantRestore(q,packed);
    ADVR_Assert(q.advr_shield_hp==173 && q.advr_enchant_until==time+60 && q.advr_enchant_type==7,"shield capacity and sixty-second timer survive map encoding");remove(q);
    self.advr_main=world;self.advr_holster[0]=r;ADVR_Assert(!ADVR_ShieldPose(1),"holstered shield cannot block");
    self.advr_holster[0]=world;q=self.advr_off;self.advr_off=r;self.offhandpos=self.origin+'-8 10 9';
    ADVR_Assert(ADVR_ShieldPose(0) && advr_shield_normal_y>0,"left shield mirrors outward side");
    setorigin(v,self.origin+'0 80 11');ADVR_Assert(ADVR_ShieldDamage(self,v,v,50,DAMARMOR)==0 && r.advr_shield_hp==123,"left shield blocks from left");
    r.advr_enchant_until=time;ADVR_Assert(!ADVR_ShieldPose(0),"expired weapon shield cannot block");
    self.advr_off=q;self.advr_main=r;r.advr_shield_hp=300;r.advr_enchant_until=time+60;
    r.advr_enchant_type=0;r.advr_enchant_until=0;r.advr_shield_hp=0;
    self.advr_magic_sticks=0;ADVR_MagicFrame();self.advr_magic_sticks=2;
    for(i=0;i<65;i=i+1)ADVR_MagicFrame();self.advr_magic_sticks=0;ADVR_MagicFrame();
    ADVR_Assert(r.advr_enchant_type==7 && r.advr_enchant_until==time+60 && r.advr_shield_hp==300,"actual enchant grants full shield capacity and sixty seconds");
    ADVR_ProtectionFrame();ADVR_Assert(r.advr_shield_fx && r.advr_shield_fx.model=="progs/advr_shield.mdl","held shield creates visible surface");
    remove(v);self.health=100;frametime=oldframe;ADVR_Sync();
    bprint("ADVR PROTECTION PASS: learning, self cast, armor, directional shields, capacity, expiry, hands and persistence\n");
};


void() ADVR_TestEarthView = {
    ADVR_TestMagicView();configflag=configflag | SVR_RUNE_KEY1;self.advr_spell=8;self.mana=50;
    self.advr_earth_until=time+60;ADVR_MagicInit(self);ADVR_Sync();
};
void() ADVR_TestEarth = {
    local entity player,v,book;local float oldconfig,oldframe,i,hp;
    player=self;oldconfig=configflag;oldframe=frametime;frametime=0.05;
    configflag=configflag-(configflag & SVR_RUNE_KEY1);ADVR_TestMagicView();book=self.advr_off;book.advr_kind=ADVR_TOME;
    ADVR_Assert(!(ADVR_SpellMask(self,book) & 256),"standard tome requires Earth rune");
    book.advr_kind=ADVR_DEBUGTOME;
    ADVR_Assert(ADVR_SpellMask(self,book) & 256,"debug tome unlocks Earth without rune");
    book.advr_kind=ADVR_TOME;configflag=configflag | SVR_RUNE_KEY1;self.advr_spell=8;self.mana=29;self.vrbits0=16384;
    self.handpos=ADVR_Head(self)+'24 0 -8';self.handrot=self.offhandrot='0 0 0';
    self.handvel=self.offhandvel=self.handavel=self.offhandavel='0 0 0';
    self.mainhand_hotspot=self.offhand_hotspot=0;self.advr_magic_sticks=2;ADVR_MagicFrame();
    ADVR_Assert(!self.advr_magic_book,"Earth refuses charge below thirty essence");
    self.advr_magic_sticks=0;ADVR_MagicFrame();self.mana=50;self.advr_magic_sticks=2;
    for(i=0;i<30;i=i+1)ADVR_MagicFrame();
    ADVR_Assert(!self.advr_magic_ready && self.advr_magic_fx.model=="progs/advr_earth_rune.mdl","rune materializes during slow charge");
    for(i=0;i<32;i=i+1)ADVR_MagicFrame();
    ADVR_Assert(self.advr_magic_ready,"Earth charge ready at three seconds");
    self.advr_magic_sticks=0;ADVR_MagicFrame();
    ADVR_Assert(self.mana==20 && self.advr_earth_until==time+70,"Earth release costs thirty and grants sixty seconds");
    self.advr_favorites[4]=9;ADVR_SaveParms();ADVR_Reset();ADVR_LoadParms();
    ADVR_Assert(self.advr_spell==8 && self.advr_favorites[4]==9 && !self.advr_earth_until,"rune selection survives map transition; buff resets");
    self.advr_earth_until=time+70;self.health=1000;self.armorvalue=100;self.armortype=0.6;
    self.flags=self.flags-(self.flags & FL_GODMODE);self.invincible_finished=0;self.takedamage=DAMAGE_AIM;
    v=spawn();v.flags=FL_MONSTER;setorigin(v,self.origin+'80 0 0');
    for(i=0;i<3;i=i+1)T_Damage(self,v,v,100,DAMARMOR);
    ADVR_Assert(self.health==940 && self.armorvalue==100,"infinite red armor absorbs eighty percent without depleting normal armor");
    self.advr_earth_until=time;hp=self.health;T_Damage(self,v,v,100,DAMARMOR);
    ADVR_Assert(hp-self.health>=39 && hp-self.health<=40 && self.armorvalue>=39 && self.armorvalue<=40,"expiry restores normal armor behavior");remove(v);
    // Real physical empty-hand contact: fixed speed, no headshot rig.
    self.advr_main=world;self.advr_magic_book=world;self.handpos=ADVR_Head(self);self.handrot='0 0 0';self.handvel='3 0 0';
    self.mainhand_melee_attack_finished=0;self.advr_prevmain_time=0;self.super_damage_finished=0;
    v=spawn();v.classname="earth_punch_target";v.classtype=CT_TARGETDUMMY;v.flags=FL_MONSTER;
    v.movetype=MOVETYPE_STEP;v.solid=SOLID_BBOX;v.takedamage=DAMAGE_YES;v.health=1000;v.enemy=self;v.switchattacker=self;v.switchtimer=time+100;
    setsize(v,'-4 -4 -4','4 4 4');setorigin(v,self.handpos+'6 0 0');
    ADVR_Melee(1);hp=1000-v.health;
    v.health=1000;self.mainhand_melee_attack_finished=0;self.advr_prevmain_time=0;self.advr_earth_until=time+70;
    ADVR_Melee(1);
    ADVR_Assert(v.health<=1000-hp*3.5 && v.health>=1000-hp*4.5,"Earth punch has quad damage");
    ADVR_Assert(self.advr_earth_main_until>time && vlen(v.velocity)>0,"Earth punch emits quad feedback and knocks back");
    if(v.advr_shove)remove(v.advr_shove);remove(v);
    ADVR_Reset();self.velocity='0 0 0';configflag=oldconfig;frametime=oldframe;ADVR_TestMagicView();
    bprint("ADVR EARTH PASS: rune gate, charge, cost, duration, armor, fists, knockback, transition\n");
};

void() ADVR_TestSightMagic = {
    local float i,j,before,oldframe,packed;local entity r,v;local vector at;
    oldframe=frametime;frametime=0.05;ADVR_TestMagicView();self.advr_off.advr_kind=ADVR_TOME;self.advr_known=1791;
    self.vrbits0=16384;self.handpos=ADVR_Head(self)+'24 0 -8';self.handrot=self.offhandrot='0 0 0';
    self.handvel=self.offhandvel=self.handavel=self.offhandavel='0 0 0';
    self.mainhand_hotspot=self.offhand_hotspot=0;
    for(j=9;j<=10;j=j+1){
        self.advr_known=1791-pow(2,j);r=ADVR_Record(IT_AXE);r.advr_kind=ADVR_TOME;ADVR_TomePickup(self,r);
        ADVR_Assert(self.advr_known==1791 && self.advr_spell==j,"new spell is learnable");remove(r);
        self.advr_magic_sticks=0;ADVR_MagicFrame();self.advr_magic_sticks=2;
        for(i=0;i<15;i=i+1)ADVR_MagicFrame();
        before=self.mana;self.advr_magic_sticks=0;ADVR_MagicFrame();
        ADVR_Assert(self.mana==before-1 && !self.advr_magic_fx,"self cast costs one and clears charge");
        if(j==9)ADVR_Assert(self.invisible_finished>=time+30 && (self.items & IT_INVISIBILITY),"ring invisibility active");
        else ADVR_Assert(self.advr_darksight_until==time+30,"darksight timer active");
        r=ADVR_Record(IT_SHOTGUN);self.advr_main=r;self.advr_enchant_latched=0;
        self.advr_magic_sticks=2;for(i=0;i<65;i=i+1)ADVR_MagicFrame();
        ADVR_Assert(r.advr_enchant_type==j+1 && r.advr_enchant_until==time+30,"new enchant applies");
        packed=ADVR_EnchantPack(r);r.advr_enchant_type=0;ADVR_EnchantRestore(r,packed);
        ADVR_Assert(r.advr_enchant_type==j+1 && r.advr_enchant_until==time+30,"new enchant persists");
        self.advr_magic_sticks=0;ADVR_MagicFrame();self.advr_main=world;remove(r);
    }
    self.advr_spell=4;self.advr_magic_sticks=2;for(i=0;i<15;i=i+1)ADVR_MagicFrame();
    ADVR_Assert(self.advr_magic_fx.model==MODEL_PROJ_SHAL,"Void charge uses vorepod");
    ADVR_MagicClear();self.advr_magic_sticks=0;ADVR_MagicFrame();
    at=ADVR_Head(self);v=spawn();v.flags=FL_MONSTER;v.takedamage=DAMAGE_AIM;v.health=1000;v.th_pain=SUB_Null;
    setsize(v,'-4 -4 -4','4 4 4');setorigin(v,at+'50 0 0');
    ADVR_FrostCone(at,'1 0 0');ADVR_Assert(v.health<1000 && v.advr_frost_until>time,"cone damages and slows in front");
    before=v.health;setorigin(v,at+'0 50 0');ADVR_FrostCone(at,'1 0 0');ADVR_Assert(v.health==before,"cone excludes side targets");
    setorigin(v,at+'-50 0 0');ADVR_FrostCone(at,'1 0 0');ADVR_Assert(v.health==before,"cone excludes rear targets");
    setorigin(v,self.origin+'120 20 0');before=v.health;ADVR_FrostCone(at,'1 0 0');ADVR_Assert(v.health<before,"ground fan includes its widening interior");
    before=v.health;setorigin(v,self.origin+'240 40 0');ADVR_FrostCone(at,'1 0 0');ADVR_Assert(v.health<before,"expanded cone reaches beyond old twenty-foot limit");
    before=v.health;setorigin(v,self.origin+'120 40 0');ADVR_FrostCone(at,'1 0 0');ADVR_Assert(v.health==before,"ground fan excludes outside its width");
    setorigin(v,self.origin+'80 0 200');ADVR_FrostCone(at,'1 0 0');ADVR_Assert(v.health==before,"ground fan excludes above twenty feet");
    setorigin(v,at+'2000 0 0');ADVR_FrostCone(at,'1 0 0');ADVR_Assert(v.health==before,"cone excludes distant targets");remove(v);
    frametime=oldframe;ADVR_Sync();bprint("ADVR SIGHT MAGIC PASS\n");
};

void() ADVR_TestSightView = {
    ADVR_TestMagicView();self.invisible_finished=0;self.items=self.items-(self.items & IT_INVISIBILITY);self.advr_darksight_until=0;
    self.advr_main=ADVR_Record(IT_SHOTGUN);self.advr_main.advr_enchant_type=11;self.advr_main.advr_enchant_until=time+30;
    self.advr_spell=10;ADVR_Sync();
};
void() ADVR_TestInvisibleView = {ADVR_TestSightView();self.advr_main.advr_enchant_type=10;ADVR_Sync();};
void() ADVR_TestDarkView = {ADVR_TestSightView();self.advr_main.advr_enchant_type=0;self.advr_darksight_until=time+30;ADVR_Sync();};

void() ADVR_TestFrostSsg = {
    local entity e;local vector at;local float oldmode;
    oldmode=cvar("vr_reload_mode");ADVR_TestSsgInput();
    self.vrbits0=16384+4096;ADVR_ManualFrame();
    ADVR_Assert(!self.advr_main.advr_ssg_open,"flick cannot open closed SSG");
    self.vrbits0=16384+1048576;ADVR_ManualFrame();
    ADVR_Assert(self.advr_main.advr_ssg_open,"B opens closed SSG");
    self.advr_main.advr_reload_until=self.advr_main.advr_cooldown=0;
    self.vrbits0=16384;ADVR_ManualFrame();self.vrbits0=16384+1048576;ADVR_ManualFrame();
    ADVR_Assert(self.advr_main.advr_ssg_open,"B cannot close open SSG");
    self.vrbits0=16384+4096;ADVR_ManualFrame();ADVR_Assert(!self.advr_main.advr_ssg_open,"flick closes open SSG");
    at=ADVR_Head(self);ADVR_FrostLight(at,normalize('1 0 -1'),240);e=find(world,classname,"advr_frost_cone_light");
    ADVR_Assert(e && !find(e,classname,"advr_frost_cone_light"),"Frost uses one cone anchor rather than three balls");
    makevectors(e.angles);ADVR_Assert(v_forward*normalize('1 0 -1')>0.99,"cone illumination follows cast direction including pitch");
    ADVR_Assert(e.origin==at && e.advr_enchant_until==time+3,"cone origin and readable fade duration");
    remove(e);cvar_set("vr_reload_mode",ftos(oldmode));ADVR_TestMagicView();
    bprint("ADVR FROST SSG PASS: button-only open, flick-only close, single directional cone\n");
};



void() ADVR_TestFrostVolumeView = {
    local vector ang;local entity e;
    ADVR_TestMagicView();ang=self.v_viewangle;ang_x=ang_z=0;makevectors(ang);
    ADVR_FrostCone(self.origin,v_forward);
    e=find(world,classname,"advr_frost_cone_light");e.advr_enchant_until=time+15;
    bprint("ADVR FROST VOLUME VIEW\n");
};
