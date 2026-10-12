void() ADVR_TestMagicView = {
    local entity p,foe;
    ADVR_Reset();self.advr_initialized=1;self.health=100;
    foe=spawn();setorigin(foe,self.origin+'0 0 16');
    p=ADVR_SpawnLoot(foe,IT_AXE+ADVR_TOME*65536);ADVR_Catch(p,0);remove(foe);ADVR_Sync();
};
void() ADVR_TestFlashlightView = {
    ADVR_Reset();self.advr_initialized=1;self.health=100;self.flags=self.flags | FL_GODMODE;
    self.items=self.items | IT_SHOTGUN;self.advr_main=ADVR_Record(IT_SHOTGUN);ADVR_Sync();
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
void() ADVR_TestMagic = {
    local entity book,p,foe,shot,player;local float oldframe,i,before;local vector head;
    player=self;oldframe=frametime;ADVR_TestMagicView();book=self.advr_off;
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
    ADVR_TomePickup(self);ADVR_Assert(self.mana==30,"second tome does not refill mana");
    foe=spawn();foe.flags=FL_MONSTER;foe.classtype=CT_MONARMY;
    ADVR_ManaReward(foe,self);ADVR_ManaReward(foe,self);ADVR_Assert(self.mana==31,"one reward per ordinary enemy");remove(foe);
    for(i=0;i<5;i=i+1) {
        foe=spawn();foe.flags=FL_MONSTER;
        if(i==0)foe.classtype=CT_MONWIZARD;else if(i==1)foe.classtype=CT_MONSKULLW;else if(i==2)foe.classtype=CT_MONSHAM;else if(i==3)foe.classtype=CT_MONSHAL;else foe.classtype=CT_MONMINOTAUR;
        before=self.mana;ADVR_ManaReward(foe,self);ADVR_Assert(self.mana==before+10,"magical monster yields ten");remove(foe);
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
    self.vrbits0=16384+16;ADVR_MagicFrame();
    ADVR_Assert(self.mana==before && !self.advr_magic_fx,"slow release cancels without spending");
    self.vrbits0=16384+8;ADVR_MagicFrame();self.vrbits0=16384+8+16;
    for(i=0;i<14;i=i+1)ADVR_MagicFrame();
    self.handvel='0 0.5 0.25';ADVR_MagicFrame();self.vrbits0=16384+16;ADVR_MagicFrame();shot=newmis;
    ADVR_Assert(self.mana==before-1 && shot.owner==self && shot.advr_fireball,"charged flick spends one and creates player fireball");
    ADVR_Assert(shot.velocity_y>600 && shot.velocity_z>300 && fabs(shot.velocity_x)<1,"fireball follows flick, not head aim");
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
    self.handvel='2 0 0';self.advr_magic_peak='0 0 0';ADVR_MagicFrame();before=self.mana;
    self.vrbits0=16384+16;ADVR_MagicFrame();
    ADVR_Assert(self.mana==before-1 && self.advr_magic_burst>0 && self.advr_magic_fx.classname=="advr_magic_beam","lightning launches dedicated beam for one mana");
    ADVR_Assert(foe.health<1000,"lightning beam damages target");before=foe.health;
    for(i=0;i<14;i=i+1)ADVR_MagicFrame();
    ADVR_Assert(foe.health<before && !self.advr_magic_book && !self.advr_magic_fx,"lightning sustains damage then stops");remove(foe);
    self.advr_spell=0;self.handvel='0 0 0';
    // Reverse the hands and cancel by occupying the casting hand.
    self.advr_off=world;self.advr_main=book;self.vrbits0=16384+2;ADVR_MagicFrame();
    ADVR_Assert(self.advr_magic_book==book && self.advr_magic_hand==0,"tome can be held in either hand");
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
