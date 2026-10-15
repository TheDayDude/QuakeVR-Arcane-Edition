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
    ADVR_Assert((first==1 || first==2 || first==4) && self.mana==30,"first standard tome teaches exactly one spell and grants thirty mana");
    ADVR_TomePickup(self,book);
    ADVR_Assert(self.advr_known==first && self.mana==30,"same physical tome cannot teach or refill twice");
    self.advr_off=book;self.button3=1;ADVR_MagicSelect();self.button3=0;ADVR_MagicSelect();
    ADVR_Assert(first & pow(2,self.advr_spell),"selection skips unknown spells");
    debug=ADVR_Record(IT_AXE);debug.advr_kind=ADVR_DEBUGTOME;ADVR_TomePickup(self,debug);
    ADVR_Assert(ADVR_SpellMask(self,debug)==7 && self.advr_known==first,"debug exposes all spells without learning them");
    second=ADVR_Record(IT_AXE);second.advr_kind=ADVR_TOME;ADVR_TomePickup(self,second);
    second=ADVR_Record(IT_AXE);second.advr_kind=ADVR_TOME;ADVR_TomePickup(self,second);
    ADVR_Assert(self.advr_known==7 && ADVR_SpellMask(self,book)==7,"three new tomes teach all spells, visible in first tome");
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
    ADVR_Assert(self.advr_known==7 && self.advr_mana_max==60 && self.advr_favorites[4]==1 && self.advr_favorites[7]==2,"knowledge capacity and favorites survive map parms");
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
    ADVR_TestMagicView();book=self.advr_off;self.vrbits0=16384;
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
    ADVR_Assert(r.advr_enchant_type==1 && r.advr_enchant_until==time+60 && self.mana==before-5,"three second hold enchants for one minute at five mana");
    for(i=0;i<70;i=i+1)ADVR_MagicFrame();
    ADVR_Assert(self.mana==before-5 && !self.advr_enchant_record,"held click cannot spend repeatedly");
    self.advr_magic_sticks=0;ADVR_MagicFrame();
    ADVR_Drop(1);p=find(world,classname,"advr_dropped_weapon");while(p && p.weaponinst!=r)p=find(p,classname,"advr_dropped_weapon");
    ADVR_Assert(p.weaponinst.advr_enchant_type==1,"drop retains enchantment on physical record");
    ADVR_Catch(p,1);ADVR_Assert(self.advr_main==r && r.advr_enchant_type==1,"catch keeps same enchantment");
    self.advr_holster[0]=r;self.advr_main=world;ADVR_SaveParms();ADVR_Reset();ADVR_LoadParms();
    r=self.advr_holster[0];book=self.advr_off;
    ADVR_Assert(r.advr_enchant_type==1 && r.advr_enchant_until==time+60,"holstered enchant survives map transition with remaining duration");
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
    self.advr_main.advr_enchant_type=1;self.advr_main.advr_enchant_until=time+60;
    self.advr_off.advr_enchant_type=2;self.advr_off.advr_enchant_until=time+60;
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
    ADVR_TestFrostView();book=self.advr_off;
    self.advr_known=3;r=ADVR_Record(IT_AXE);r.advr_kind=ADVR_TOME;ADVR_TomePickup(self,r);
    ADVR_Assert(self.advr_known==7 && self.advr_spell==2,"new standard tome teaches missing frost");remove(r);
    self.advr_favorites[4]=3;ADVR_SaveParms();ADVR_Reset();ADVR_LoadParms();book=self.advr_off;
    ADVR_Assert(self.advr_spell==2 && self.weaponframe2==2 && self.advr_favorites[4]==3,"frost selection and favorite survive map parms");
    self.vrbits0=16384;self.handpos=ADVR_Head(self)+'24 0 -8';self.offhandpos=ADVR_Head(self)+'24 16 -8';
    self.handrot=self.offhandrot='0 0 0';self.handvel=self.offhandvel='0 0 0';self.mainhand_hotspot=self.offhand_hotspot=0;
    self.advr_magic_sticks=2;before=self.mana;
    for(i=0;i<15;i=i+1)ADVR_MagicFrame();
    ADVR_Assert(self.advr_magic_ready && self.advr_magic_fx.skin==1,"frost charges blue orb");
    self.handvel='0 1 0';self.advr_magic_sticks=0;ADVR_MagicFrame();shot=newmis;
    ADVR_Assert(self.mana==before-1 && shot.advr_frostbolt && !shot.advr_fireball && shot.velocity_y>700,"frost flick launches blue bolt for one mana");
    v=spawn();v.classname="advr_frost_target";v.flags=FL_MONSTER;v.takedamage=DAMAGE_YES;v.health=1000;
    v.enemy=player;v.switchattacker=player;v.switchtimer=time+100;
    setmodel(v,"progs/player.mdl");setorigin(v,ADVR_Head(self)+'100 0 0');
    shot.advr_magic_damage=1;self=shot;other=v;ADVR_FrostTouch();self=player;
    ADVR_Assert(v.health==970 && v.advr_frost_until==time+4 && !v.advr_burn,"frost impact damages and chills without burning");
    v.advr_frost_until=time+1;ADVR_FrostHit(v);ADVR_FrostHit(v);
    ADVR_Assert(v.advr_frost_until==time+4,"repeat frost refreshes rather than stacks");
    r=ADVR_Record(IT_SHOTGUN);self.advr_main=r;self.handvel='0 0 0';self.advr_magic_sticks=2;
    for(i=0;i<65;i=i+1)ADVR_MagicFrame();
    ADVR_Assert(r.advr_enchant_type==3,"frost selection enchants held gun");r.advr_enchant_scale=1;
    advr_attack_actor=self;advr_attack_record=r;T_Damage(v,self,self,40,NOARMOR);
    ADVR_Assert(v.health==928 && v.advr_frost_until==time+4,"frost hits add five percent and chill");
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
