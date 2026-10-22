// A temporary Hell Sword uses the calibrated hell-knight sword mesh and anchors.
// Its record remains distinct from permanent loot, including while holstered/dropped.
void() ADVR_NetherExpire = {
    local entity r,e,next,saved;local float i;
    r=self.enemy;
    if(!r || r.wi_uid!=self.count || r.classname!="advr_weapon_record"){remove(self);return;}
    if(time<r.advr_nether_until && self.owner.health>0){self.nextthink=time+0.1;return;}
    saved=self;e=nextent(world);
    while(e){next=nextent(e);
        if(e.flags & FL_CLIENT){
            self=e;
            if(e.advr_main==r)ADVR_SetHand(1,world);
            if(e.advr_off==r)ADVR_SetHand(0,world);
            for(i=0;i<6;i=i+1)if(e.advr_holster[i]==r)e.advr_holster[i]=world;
            ADVR_Sync();self=saved;
        }else if(e.classname=="advr_dropped_weapon" && e.weaponinst==r){particle(e.origin,'0 0 12',224,20);remove(e);}
        e=next;
    }
    remove(r);remove(saved);
};
void(float h) ADVR_NetherCast = {
    local entity r,c;
    if(ADVR_Hand(h))return;
    r=ADVR_Record(IT_AXE);r.advr_kind=ADVR_HELLSWORD;r.advr_nether_until=time+60;
    ADVR_SetHand(h,r);self.items=self.items | IT_AXE;
    c=spawn();c.classname="advr_nether_timer";c.owner=self;c.enemy=r;c.count=r.wi_uid;
    c.think=ADVR_NetherExpire;c.nextthink=time+0.1;
    sound(self,CHAN_WEAPON,"hknight/attack1.wav",0.8,ATTN_NORM);
    sprint(self,"Hell Sword: 60 seconds. Swing through air to slash with fire!\n");ADVR_Sync();
};
void() ADVR_NetherArcThink = {
    local vector from,to,a,b,at;local entity victim;local float i;
    if(time>=self.attack_finished || !self.owner || self.owner.health<=0){remove(self);return;}
    from=self.origin;to=from+self.velocity*0.025;
    // Five parallel sweeps cover the visible blade. Validate each start from the
    // previous centre so neither the width nor a thin wall can bypass occlusion.
    for(i=-2;i<=2;i=i+1){
        a=from+self.movedir*(i*10);b=to+self.movedir*(i*10);
        traceline(from,a,FALSE,self.owner);
        if(trace_fraction==1)traceline(a,b,FALSE,self.owner);
        if(trace_fraction<1){
            victim=trace_ent;at=trace_endpos;
            if(victim.takedamage){
                T_Damage(victim,self,self.owner,55*self.advr_magic_damage*ADVR_FireResistance(victim),DAMARMOR);
                if(victim.health>0)ADVR_Ignite(victim,self.owner);
            }
            particle(at,'0 0 20',224,30);sound(self,CHAN_AUTO,"hknight/hit.wav",0.6,ATTN_NORM);remove(self);return;
        }
    }
    setorigin(self,to);self.alpha=min(0.85,(self.attack_finished-time)*2);
    particle(self.origin,'0 0 4',224,3);self.nextthink=time+0.025;
};
entity(vector at,vector dir,vector swing) ADVR_NetherArc = {
    local entity p;local vector side,rot,basis;
    dir=normalize(dir);side=swing-dir*(swing*dir);
    if(vlen(side)<0.1){makevectors(vectoangles(dir));side=v_right;}
    side=normalize(side);rot=vectoangles(dir);rot_x=-rot_x;makevectors(rot);
    basis_x=side*v_right;basis_y=side*v_up;basis_z=0;basis=vectoangles(basis);rot_z=basis_y;
    p=spawn();p.classname="advr_nether_arc";p.owner=self;p.solid=SOLID_NOT;p.movetype=MOVETYPE_NONE;
    setmodel(p,"progs/advr_nether_arc.mdl");setsize(p,'0 0 0','0 0 0');setorigin(p,at);
    p.angles=rot;p.movedir=side;p.velocity=dir*480;p.advr_magic_damage=ADVR_MagicMultiplier();
    p.advr_enchant_type=1;p.advr_enchant_until=time+2;p.attack_finished=time+1.5;
    p.alpha=0.85;p.think=ADVR_NetherArcThink;p.nextthink=time+0.025;
    sound(self,CHAN_WEAPON,"hknight/attack1.wav",0.8,ATTN_NORM);return p;
};
// Aim with the headset, launch from a stable point ahead of the wrist, and
// converge on the sight line. Sword motion sets the slash plane, not its heading.
// A short accumulated sweep rejects isolated tracking spikes and wrist wiggles.
void(float h,vector tip,vector velocity,float speed,float dt,float hit) ADVR_NetherSwing = {
    local entity r;local vector dir,head,swing,at,target,plane;
    r=ADVR_Hand(h);if(!r || r.advr_nether_until<=time)return;
    swing=normalize(velocity);
    if(speed<1 || swing*r.advr_nether_swing < -0.3){r.advr_nether_ready=1;r.advr_nether_travel=0;r.advr_nether_swingtime=0;r.advr_nether_plane='0 0 0';}
    if(hit){r.advr_nether_ready=0;r.advr_nether_travel=0;r.advr_nether_swingtime=0;r.advr_nether_plane='0 0 0';r.advr_nether_swing=swing;return;}
    if(!r.advr_nether_ready || dt<=0 || dt>=0.1 || time<r.advr_nether_next)return;
    if(speed<2.2 || speed>20 || (h && vlen(self.handvel)<0.55) || (!h && vlen(self.offhandvel)<0.55)){
        r.advr_nether_travel=0;r.advr_nether_swingtime=0;r.advr_nether_plane='0 0 0';return;
    }
    r.advr_nether_swing=swing;r.advr_nether_swingtime=r.advr_nether_swingtime+dt;
    r.advr_nether_plane=r.advr_nether_plane+velocity*dt;
    r.advr_nether_travel=r.advr_nether_travel+speed*dt*26.246719*max(0.01,cvar("vr_world_scale"));
    if(speed<3 || r.advr_nether_swingtime<0.08 || r.advr_nether_travel<8*max(0.01,cvar("vr_world_scale")))return;
    head=ADVR_Head(self);if(vlen(ADVR_Pos(h)-head)>100)return;
    makevectors(self.v_viewangle);dir=v_forward;
    traceline(head,head+dir*2048,FALSE,self);target=trace_endpos;
    at=ADVR_Pos(h)+dir*12;
    traceline(head,at,TRUE,self);if(trace_fraction<1 || pointcontents(at)==CONTENT_SOLID)return;
    // Very close surfaces shouldn't turn the arc backwards into the caster.
    if(vlen(target-head)>64)dir=normalize(target-at);
    plane=normalize(r.advr_nether_plane);
    ADVR_NetherArc(at,dir,plane);
    r.advr_nether_ready=0;r.advr_nether_travel=0;r.advr_nether_swingtime=0;r.advr_nether_plane='0 0 0';r.advr_nether_swing=swing;r.advr_nether_next=time+0.7;
    haptic(h,0,0.08,85,0.45);
};
void() ADVR_TestNetherRune = {
    local entity player,book,r,timer,p,v;local float cfg,dt,i,hp;local vector savedhead;
    player=self;cfg=configflag;dt=frametime;savedhead=self.v_viewangle;self.v_viewangle='0 0 0';frametime=0.05;ADVR_TestMagicView();book=self.advr_off;
    configflag=configflag-(configflag & SVR_RUNE_KEY3);book.advr_kind=ADVR_TOME;
    ADVR_Assert(!(ADVR_SpellMask(self,book) & 4096),"Nether locked without Hell rune");
    book.advr_kind=ADVR_DEBUGTOME;
    ADVR_Assert(ADVR_SpellMask(self,book) & 4096,"debug tome unlocks Nether without rune");
    book.advr_kind=ADVR_TOME;configflag=configflag | SVR_RUNE_KEY3;self.advr_spell=12;self.mana=29;self.vrbits0=16384;
    self.handpos=ADVR_Head(self)+'24 0 -8';self.handrot=self.offhandrot='0 0 0';
    self.handvel=self.offhandvel=self.handavel=self.offhandavel='0 0 0';
    self.mainhand_hotspot=self.offhand_hotspot=0;self.advr_magic_sticks=2;ADVR_MagicFrame();
    ADVR_Assert(!self.advr_magic_book,"Nether requires thirty essence");
    self.advr_magic_sticks=0;ADVR_MagicFrame();self.mana=50;self.advr_magic_sticks=2;
    for(i=0;i<62;i=i+1)ADVR_MagicFrame();
    ADVR_Assert(self.advr_magic_ready && self.advr_magic_fx.model=="progs/advr_nether_rune.mdl","Hell rune materializes");
    self.advr_magic_sticks=0;ADVR_MagicFrame();r=self.advr_main;
    ADVR_Assert(self.mana==20 && r.advr_kind==ADVR_HELLSWORD && r.advr_nether_until==time+60,"release summons sixty-second sword for thirty mana");
    ADVR_Assert(!ADVR_PackRecord(r),"temporary sword cannot become permanent across maps");
    ADVR_NetherSwing(1,self.handpos,'0 3 0',3,0.02,1);
    ADVR_Assert(!find(world,classname,"advr_nether_arc"),"contact swing does not shoot arc");
    ADVR_NetherSwing(1,self.handpos,'0 0 0',0,0.02,0);
    self.handvel='0 1.2 0';for(i=0;i<6;i=i+1)ADVR_NetherSwing(1,self.handpos,'0 5 0',5,0.025,0);p=find(world,classname,"advr_nether_arc");
    ADVR_Assert(p && fabs(p.movedir_y)>0.9,"air swing emits arc aligned with swing");
    ADVR_NetherSwing(1,self.handpos,'0 3 0',3,0.02,0);
    ADVR_Assert(!find(p,classname,"advr_nether_arc"),"held motion cannot repeat arc");remove(p);
    v=spawn();v.classname="nether_target";v.flags=FL_MONSTER;v.health=1000;v.takedamage=DAMAGE_YES;v.th_pain=SUB_Null;
    v.solid=SOLID_BBOX;setsize(v,'-8 -8 -8','8 8 8');setorigin(v,player.origin+'80 110 64');
    p=ADVR_NetherArc(player.origin+'0 110 64','1 0 0','0 1 0');hp=v.health;
    for(i=0;i<8;i=i+1){if(p.modelindex){self=p;ADVR_NetherArcThink();self=player;}}
    ADVR_Assert(v.health<hp-50 && v.health>hp-70 && !p.modelindex,"fiery arc applies one strong impact and disappears");remove(v);
    timer=find(world,classname,"advr_nether_timer");self.advr_holster[0]=r;ADVR_SetHand(1,world);r.advr_nether_until=time;
    self=timer;ADVR_NetherExpire();self=player;
    ADVR_Assert(!self.advr_holster[0],"expiry removes holstered sword");
    ADVR_NetherCast(1);r=self.advr_main;ADVR_Drop(1);p=world;while((p=find(p,classname,"advr_dropped_weapon"))){if(p.weaponinst==r)break;}
    timer=find(world,classname,"advr_nether_timer");r.advr_nether_until=time;self=timer;ADVR_NetherExpire();self=player;
    ADVR_Assert(!p.modelindex,"expiry removes dropped sword");
    configflag=cfg;frametime=dt;self.v_viewangle=savedhead;ADVR_TestMagicView();
    bprint("ADVR NETHER RUNE PASS: rune gate, cost, charge, sword, swing plane, contact guard, cooldown, damage and expiry\n");
};

void() ADVR_TestMagicQoL = {
    local entity player,book,r,p,n,job;local float i,dt,cfg,next;local vector at;
    player=self;dt=frametime;cfg=configflag;frametime=0.05;ADVR_TestMagicView();book=self.advr_off;
    self.mana=0;ADVR_Assert(ADVR_Mana()>=30,"debug book can cast at zero real essence");ADVR_SpendMana(30);ADVR_Assert(self.mana==0,"debug cost leaves real essence unchanged");
    book.advr_kind=ADVR_TOME;self.mana=10;ADVR_SpendMana(5);ADVR_Assert(ADVR_Mana()==5,"ordinary tome pays normal enchant cost");book.advr_kind=ADVR_DEBUGTOME;
    ADVR_Assert(ADVR_NextSpell(7)==9 && ADVR_NextSpell(10)==8 && ADVR_NextSpell(8)==11 && ADVR_NextSpell(12)==13 && ADVR_NextSpell(13)==0,"selection follows grouped rune display order");
    self.mana=0;self.advr_spell=8;configflag=configflag-(configflag & SVR_RUNE_KEY1);self.vrbits0=16384;
    self.handpos=ADVR_Head(self)+'24 0 -8';self.handrot=self.offhandrot='0 0 0';self.handvel=self.offhandvel=self.handavel=self.offhandavel='0 0 0';
    self.mainhand_hotspot=self.offhand_hotspot=0;self.advr_magic_sticks=2;
    for(i=0;i<62;i=i+1)ADVR_MagicFrame();self.advr_magic_sticks=0;ADVR_MagicFrame();
    ADVR_Assert(self.advr_earth_until>time && self.mana==0,"debug rune casts for free with no rune and no mana");self.advr_earth_until=0;
    ADVR_NetherCast(1);r=self.advr_main;self.handvel='0 1.2 0';
    for(i=0;i<12;i=i+1)ADVR_NetherSwing(1,self.handpos,'0 2 0',2,0.025,0);
    ADVR_Assert(!find(world,classname,"advr_nether_arc"),"gentle sword motion emits no arc");
    ADVR_NetherSwing(1,self.handpos,'0 5 0',5,0.025,0);ADVR_Assert(!find(world,classname,"advr_nether_arc"),"single velocity spike emits no arc");
    for(i=0;i<4;i=i+1)ADVR_NetherSwing(1,self.handpos,'0 5 0',5,0.025,0);
    p=find(world,classname,"advr_nether_arc");makevectors(self.v_viewangle);
    ADVR_Assert(p && normalize(p.velocity)*v_forward>0.95,"sustained swing projects outward along view aim");remove(p);
    job=find(world,classname,"advr_nether_timer");r.advr_nether_until=time;self=job;ADVR_NetherExpire();self=player;
    n=ADVR_DarkCreate(world,player.origin+'0 110 64',"monster_demon1",player,0);ADVR_Assert(n!=world,"ally created");
    n.advr_dark_until=time-1;at=n.origin;next=n.nextthink;job=n.advr_dark_control;self=job;ADVR_DarkControl();self=player;
    ADVR_Assert(n.health>0 && n.modelindex && n.origin==at && n.nextthink==next,"ally survives old expiry without controller movement or animation resets");
    ADVR_DarkBurst(n);configflag=cfg;frametime=dt;ADVR_TestMagicView();
    bprint("ADVR MAGIC QOL PASS: infinite debug casting, normal costs, menu order, deliberate arcs, outward aim, permanent native allies\n");
};


void() ADVR_TestNetherAim = {
    local entity p,r,player,job;local float i;local vector oldview,oldaim;
    oldview=self.v_viewangle;oldaim=self.v_angle;ADVR_TestMagicView();ADVR_NetherCast(1);r=self.advr_main;
    self.v_viewangle='0 0 0';self.v_angle='0 180 0';self.handpos=ADVR_Head(self)+'24 8 -8';self.handvel='0 0.7 0';
    ADVR_NetherSwing(1,self.handpos,'0 0 0',0,.025,0);
    for(i=0;i<4;i=i+1)ADVR_NetherSwing(1,self.handpos,'0 3.2 0',3.2,.025,0);
    p=find(world,classname,"advr_nether_arc");
    ADVR_Assert(p!=world,"moderate deliberate sweep fires arc");
    ADVR_Assert(normalize(p.velocity)*'1 0 0'>.95,"arc follows headset rather than legacy weapon aim");
    ADVR_Assert(vlen(p.origin-(self.handpos+'12 0 0'))<.1,"stable wrist launch rather than moving sword tip");
    ADVR_Assert(fabs(p.movedir*normalize(p.velocity))<.01,"slash plane remains perpendicular to flight");remove(p);
    for(i=0;i<8;i=i+1)ADVR_NetherSwing(1,self.handpos,'0 4 0',4,.025,0);
    ADVR_Assert(!find(world,classname,"advr_nether_arc"),"one arc per swing and cooldown");
    player=self;job=find(world,classname,"advr_nether_timer");r.advr_nether_until=time;self=job;ADVR_NetherExpire();self=player;
    self.v_viewangle=oldview;self.v_angle=oldaim;ADVR_TestMagicView();
    bprint("ADVR NETHER AIM PASS: headset aim, stable launch, moderate sweep, plane, cooldown\n");
};
