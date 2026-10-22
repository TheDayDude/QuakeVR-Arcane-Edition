void() ADVR_TestSlipstep = {
    local entity r,v,block,job,actor;local float i,oldframe,hp,packed,found;local vector before,target,actorpos,angles;
    actor=self;oldframe=frametime;frametime=0.05;ADVR_TestMagicView();
    self.advr_known=1663;r=ADVR_Record(IT_AXE);r.advr_kind=ADVR_TOME;ADVR_TomePickup(self,r);
    ADVR_Assert(self.advr_known==1791 && self.advr_spell==7,"tome learns Slipstep");remove(r);
    self.advr_favorites[4]=8;ADVR_SaveParms();ADVR_Reset();ADVR_LoadParms();
    ADVR_Assert(self.advr_spell==7 && self.advr_favorites[4]==8,"eighth spell selection and favorite survive map state");
    self.headpos=self.origin+self.view_ofs;self.handpos=self.headpos-'0 0 8';self.vrbits0=16384;
    self.handvel=self.offhandvel=self.handavel=self.offhandavel='0 0 0';self.mainhand_hotspot=self.offhand_hotspot=0;
    self.handrot='50 0 0';
    for(i=0;i<8;i=i+1){self.handrot_y=i*45;ADVR_SlipPreview(1);if(self.advr_slip_valid){found=1;break;}}
    ADVR_Assert(found && self.advr_slip_marker,"arc finds supported landing and creates marker");target=self.advr_slip_target;
    ADVR_Assert(ADVR_SlipFit(self,target,1) && !ADVR_SlipFit(self,target+'0 0 512',1),"landing fit requires ground support");
    block=spawn();block.classname="slip_test_block";block.solid=SOLID_BBOX;setsize(block,self.mins,self.maxs);setorigin(block,target);
    ADVR_Assert(!ADVR_SlipFit(self,target,1),"occupied landing rejected");remove(block);
    block=spawn();block.classname="trigger_hurt";block.solid=SOLID_TRIGGER;setsize(block,'-32 -32 -32','32 32 32');setorigin(block,target);
    ADVR_Assert(!ADVR_SlipFit(self,target,1),"active hurt trigger rejected");remove(block);
    ADVR_MagicClear();self.advr_magic_sticks=0;ADVR_MagicFrame();self.advr_magic_sticks=2;
    for(i=0;i<15;i=i+1)ADVR_MagicFrame();
    ADVR_Assert(self.advr_slip_valid && self.advr_slip_marker,"charged hand updates destination");
    before=self.origin;hp=self.mana;newmis=world;self.advr_magic_sticks=0;ADVR_MagicFrame();
    ADVR_Assert(vlen(self.origin-before)>24 && vlen(self.origin-before)<=280 && self.mana==hp-1 && !newmis && !self.advr_slip_marker,"release teleports once, spends one mana and clears marker");
    setorigin(self,before);self.headpos=self.origin+self.view_ofs;self.handpos=self.headpos-'0 0 8';self.handrot='-90 0 0';
    self.advr_magic_sticks=2;for(i=0;i<15;i=i+1)ADVR_MagicFrame();hp=self.mana;before=self.origin;
    self.advr_magic_sticks=0;ADVR_MagicFrame();ADVR_Assert(self.origin==before && self.mana==hp,"invalid aim neither teleports nor spends mana");
    r=ADVR_Record(IT_SHOTGUN);r.advr_enchant_type=8;r.advr_enchant_until=time+30;
    packed=ADVR_EnchantPack(r);r.advr_enchant_type=0;ADVR_EnchantRestore(r,packed);
    ADVR_Assert(r.advr_enchant_type==8 && r.advr_enchant_until==time+30,"eighth enchant has independent persistent encoding");
    v=spawn();v.classname="slip_test_foe";v.flags=FL_MONSTER | FL_FLY;v.health=100;v.takedamage=DAMAGE_YES;v.classmove=MON_MOVEFLY;
    v.solid=SOLID_BBOX;setsize(v,'-4 -4 -4','4 4 4');setorigin(v,self.origin+'0 48 48');
    advr_attack_actor=self;advr_attack_record=r;
    ADVR_Assert(ADVR_EnchantDamage(v,self,self,40)==40 && v.advr_slip_pending,"weapon hit queues displacement without bonus damage");
    job=v.advr_slip_pending;ADVR_SlipHit(v,self);ADVR_Assert(v.advr_slip_pending==job,"pellets share one pending displacement");
    before=v.origin;self=job;ADVR_SlipEnemyThink();self=actor;
    ADVR_Assert(fabs(vlen(v.origin-before)-24)<0.01 && v.health==100,"enemy shifts twenty-four units without telefrag or damage");
    ADVR_SlipHit(v,self);ADVR_Assert(!v.advr_slip_pending,"enemy shifts are cooldown limited");
    v.advr_slip_next=0;block=spawn();block.solid=SOLID_BBOX;setsize(block,'-8 -8 -8','8 8 8');setorigin(block,v.origin+'0 24 0');
    ADVR_SlipHit(v,self);job=v.advr_slip_pending;before=v.origin;self=job;ADVR_SlipEnemyThink();self=actor;
    ADVR_Assert(v.origin==before,"enemy shift cannot pass into blocking geometry");remove(block);
    v.advr_slip_next=0;v.bossflag=1;ADVR_SlipHit(v,self);ADVR_Assert(!v.advr_slip_pending,"bosses retain scripted position");v.bossflag=0;
    actorpos=self.origin;v.flags=FL_MONSTER;v.classmove=1;setorigin(v,target-'0 0 20');found=0;
    for(i=0;i<8;i=i+1) {
        angles='0 0 0';angles_y=i*45;makevectors(angles);setorigin(self,v.origin-v_forward*64+'0 0 20');
        v.advr_slip_next=0;before=v.origin;ADVR_SlipHit(v,self);job=v.advr_slip_pending;self=job;ADVR_SlipEnemyThink();self=actor;
        if(vlen(v.origin-before)>20){found=1;break;}
    }
    ADVR_Assert(found && ADVR_SlipFit(v,v.origin,1),"grounded enemy shifts onto supported ground");setorigin(self,actorpos);
    v.advr_slip_next=0;before=v.origin;ADVR_SlipHit(v,self);job=v.advr_slip_pending;v.health=0;
    self=job;ADVR_SlipEnemyThink();self=actor;ADVR_Assert(v.origin==before,"lethal hit does not teleport a corpse");remove(v);
    advr_attack_actor=advr_attack_record=world;self.advr_main=r;ADVR_Sync();frametime=oldframe;
    bprint("ADVR SLIPSTEP PASS: learning, preview, safe teleport, invalid destinations, enchantment displacement and persistence\n");
};

void() ADVR_TestSlipView = {
    ADVR_TestMagicView();self.advr_spell=7;ADVR_Sync();
};
