// A transformation owns no equipment: records stay in the existing inventory.
// Its saved health is restored on expiry/map exit, but never revives a dead player.
void() ADVR_ElderEnd = {
    if(!self.advr_elder_until)return;
    if(self.health>0)self.health=max(1,self.advr_elder_health);
    self.max_health=self.advr_elder_maxhealth;
    self.advr_elder_until=0;self.advr_elder_idle=0;
    self.advr_prevmain_time=self.advr_prevoff_time=0;
};
vector(float i) ADVR_ElderHolsterPos = {
    if(i==0)return self.advr_holsterpos0;if(i==1)return self.advr_holsterpos1;
    if(i==2)return self.advr_holsterpos2;if(i==3)return self.advr_holsterpos3;
    if(i==4)return self.advr_holsterpos4;return self.advr_holsterpos5;
};
void(float h) ADVR_ElderCast = {
    local float i,best,d,nearest;local entity book;
    book=ADVR_Hand(h);if(!ADVR_IsTome(book) || self.advr_elder_until>time)return;
    best=-1;nearest=999999;
    for(i=0;i<6;i=i+1)if(!self.advr_holster[i]){
        d=vlen(ADVR_ElderHolsterPos(i)-ADVR_Pos(h));
        if(d<nearest){nearest=d;best=i;}
    }
    ADVR_ManualRefund();ADVR_EnchantClear();ADVR_FuryClear();
    ADVR_FGSet(0,world,0);ADVR_FGSet(1,world,0);
    if(best>=0){self.advr_holster[best]=book;ADVR_SetHand(h,world);}
    else ADVR_Displace(h);
    // Normally the casting hand is empty; defend against an input/pickup race.
    if(ADVR_Hand(1-h))ADVR_Displace(1-h);
    self.advr_elder_health=self.health;self.advr_elder_maxhealth=self.max_health;
    self.health=500;self.max_health=500;self.advr_elder_until=time+60;
    self.advr_elder_idle=time+4;self.vr_flashlight_state=0;
    self.advr_prevmain_time=self.advr_prevoff_time=0;
    sound(self,CHAN_VOICE,"demon/sight2.wav",1,ATTN_NORM);
    sprint(self,"Elder Rune: Fiend form for 60 seconds!\n");ADVR_Sync();
};
float() ADVR_ElderFrame = {
    if(!self.advr_elder_until)return 0;
    if(time>=self.advr_elder_until || self.health<=0 || intermission_running){ADVR_ElderEnd();return 0;}
    self.impulse=0;self.vr_flashlight_state=0;
    // Prevent an automatic map pickup from equipping anything while transformed.
    if(self.advr_main)ADVR_Displace(1);if(self.advr_off)ADVR_Displace(0);
    if(time>=self.advr_elder_idle){sound(self,CHAN_VOICE,"demon/idle1.wav",0.65,ATTN_IDLE);self.advr_elder_idle=time+4+random()*4;}
    if(cinematic_running || !ADVR_Tracked()){ADVR_Sync();return 1;}
    advr_attack_actor=self;advr_attack_record=world;
    ADVR_Melee(1);ADVR_Melee(0);advr_attack_actor=world;
    ADVR_Sync();return 1;
};

void() ADVR_TestElderView = {
    ADVR_TestMagicView();self.advr_spell=13;self.health=87;self.max_health=100;
    ADVR_ElderCast(0);
};
void() ADVR_TestElder = {
    local entity book,p,v;local float cfg,dt,i,hp;
    cfg=configflag;dt=frametime;frametime=0.05;ADVR_TestMagicView();book=self.advr_off;
    configflag=configflag-(configflag & SVR_RUNE_KEY4);book.advr_kind=ADVR_TOME;
    ADVR_Assert(!(ADVR_SpellMask(self,book)&8192),"Elder requires Elder Magic rune");
    book.advr_kind=ADVR_DEBUGTOME;
    ADVR_Assert(ADVR_SpellMask(self,book)&8192,"debug unlocks Elder without rune");
    book.advr_kind=ADVR_TOME;configflag=configflag | SVR_RUNE_KEY4;
    self.advr_spell=13;self.mana=29;self.vrbits0=16384;
    self.handpos=ADVR_Head(self)+'24 0 -8';self.handrot=self.offhandrot='0 0 0';
    self.handvel=self.offhandvel=self.handavel=self.offhandavel='0 0 0';
    self.mainhand_hotspot=self.offhand_hotspot=0;self.advr_magic_sticks=2;ADVR_MagicFrame();
    ADVR_Assert(!self.advr_magic_book,"Elder rejects less than thirty mana");
    self.advr_magic_sticks=0;ADVR_MagicFrame();self.mana=50;self.advr_magic_sticks=2;
    self.advr_holsterpos0=self.advr_holsterpos1=self.advr_holsterpos2=self.advr_holsterpos3=self.advr_holsterpos4=self.offhandpos+'50 0 0';
    self.advr_holsterpos5=self.offhandpos;self.health=87;self.max_health=100;
    for(i=0;i<62;i=i+1)ADVR_MagicFrame();
    ADVR_Assert(self.advr_magic_ready && self.advr_magic_fx.model=="progs/advr_elder_rune.mdl","Elder rune materializes during charge");
    self.advr_magic_sticks=0;ADVR_MagicFrame();
    ADVR_Assert(self.mana==20 && self.advr_elder_until==time+60 && self.health==500,"Elder paid cost, duration and health");
    ADVR_Assert(self.advr_holster[5]==book && !self.advr_main && !self.advr_off,"book goes to nearest available holster");
    ADVR_Select(IT_AXE);ADVR_Assert(!self.advr_main,"selection cannot access hidden equipment");
    self.velocity='0 0 0';self.waterlevel=0;self.onladder=0;self.jump_flag=0;
    self.flags=self.flags | FL_ONGROUND | FL_JUMPRELEASED;PlayerJump();
    ADVR_Assert(self.velocity_z>=map_jumpheight*1.6,"Fiend jumps higher without forced horizontal leap");
    self.velocity='0 0 0';
    self.health=300;self.advr_elder_until=time;ADVR_ElderFrame();
    ADVR_Assert(!self.advr_elder_until && self.health==87 && self.max_health==100 && self.advr_holster[5]==book,"expiry restores original health and preserves tome");
    // A full inventory drops the book, preserving every stored record.
    self.advr_holster[5]=world;ADVR_SetHand(0,book);book.advr_kind=ADVR_DEBUGTOME;self.mana=0;
    for(i=0;i<6;i=i+1)self.advr_holster[i]=ADVR_Record(IT_SHOTGUN);
    ADVR_SpendMana(30);ADVR_ElderCast(0);p=find(world,classname,"advr_dropped_weapon");
    while(p && p.weaponinst!=book)p=find(p,classname,"advr_dropped_weapon");
    ADVR_Assert(p!=world && self.mana==0 && self.health==500,"full slots drop debug book without mana cost");
    for(i=0;i<6;i=i+1)ADVR_Assert(self.advr_holster[i].advr_weapon==IT_SHOTGUN,"stored weapon preserved");
    ADVR_Catch(p,1);ADVR_Assert(!self.advr_main && p.weaponinst==book,"Fiend cannot pick up dropped book");
    // Actual open-hand collision, ordinary versus airborne claw damage.
    self.advr_magic_book=world;self.handpos=ADVR_Head(self);self.handrot='0 0 0';self.handvel='3 0 0';
    self.mainhand_melee_attack_finished=0;self.advr_prevmain_time=0;self.super_damage_finished=0;
    v=spawn();v.classname="elder_claw_target";v.classtype=CT_TARGETDUMMY;v.flags=FL_MONSTER;
    v.movetype=MOVETYPE_STEP;v.solid=SOLID_BBOX;v.takedamage=DAMAGE_YES;v.health=1000;v.enemy=self;v.switchattacker=self;v.switchtimer=time+100;
    setsize(v,'-4 -4 -4','4 4 4');setorigin(v,self.handpos+'12 0 0');
    self.flags=self.flags | FL_ONGROUND;ADVR_Melee(1);hp=1000-v.health;
    ADVR_Assert(hp>=39 && hp<=41,"open-hand Fiend claw damage");
    v.health=1000;self.flags=self.flags-(self.flags & FL_ONGROUND);self.mainhand_melee_attack_finished=0;self.advr_prevmain_time=0;
    ADVR_Melee(1);ADVR_Assert(1000-v.health>=hp*1.45 && 1000-v.health<=hp*1.55,"airborne claws deal fifty percent more damage");
    if(v.advr_shove)remove(v.advr_shove);remove(v);
    self.health=-1;ADVR_ElderEnd();ADVR_Assert(self.health==-1 && !self.advr_elder_until && self.max_health==100,"death never revives player");
    ADVR_TestMagicView();self.health=73;self.max_health=100;ADVR_ElderCast(0);SetChangeParms();
    ADVR_Assert(self.health==73 && !self.advr_elder_until && parm2==73,"map transition saves normal health");
    configflag=cfg;frametime=dt;ADVR_TestMagicView();
    bprint("ADVR ELDER PASS: rune gate, charge, cost, debug, closest holster, full slots, lockout, claws, airborne bonus, expiry, death, transition\n");
};

void() ADVR_TestElderState = {
    local float i,n;
    ADVR_Assert(self.advr_elder_until>time && self.health==500 && self.advr_elder_health==87 && self.advr_elder_maxhealth==100,"saved transformation retains normal and temporary health");
    for(i=0;i<6;i=i+1)if(ADVR_IsTome(self.advr_holster[i]))n=n+1;
    ADVR_Assert(n==1 && !self.advr_main && !self.advr_off,"saved transformation retains one stored book and empty claws");
    bprint("ADVR ELDER SAVE PASS\n");
};
void() ADVR_TestElderExpire = {
    self.advr_elder_until=time;ADVR_ElderFrame();
    ADVR_Assert(self.health==87 && self.max_health==100 && !self.advr_elder_until,"loaded transformation restores normal health");
    bprint("ADVR ELDER RESTORE PASS\n");
};
