// Shared player-side Rune benefits. Allies keep their independent lifetime.
float() ADVR_RuneActive = {return self.health>0 && (self.advr_rune_until>time || self.advr_earth_until>time || self.advr_dark_until>time || self.advr_elder_until>time);};
void(float h) ADVR_RuneStow = {
    local float i,best,d,nearest;local entity book;
    book=ADVR_Hand(h);if(!ADVR_IsTome(book))return;
    best=-1;nearest=999999;
    for(i=0;i<6;i=i+1)if(!self.advr_holster[i]){
        d=vlen(ADVR_ElderHolsterPos(i)-ADVR_Pos(h));if(d<nearest){nearest=d;best=i;}
    }
    if(best>=0){self.advr_holster[best]=book;ADVR_SetHand(h,world);}else ADVR_Displace(h);
    ADVR_Sync();
};
float() ADVR_RuneCrossed = {
    local vector head,right,mid,ang;local float mu;
    if(!ADVR_RuneActive() || self.advr_main || self.advr_off || self.advr_reload_hands || !ADVR_Tracked())return 0;
    head=ADVR_Head(self);mu=ADVR_Meters();ang=self.v_viewangle;ang_x=ang_z=0;makevectors(ang);right=v_right;
    mid=(self.handpos+self.offhandpos)*0.5-head;
    return (self.handpos-head)*right < -0.06*mu && (self.offhandpos-head)*right > 0.06*mu &&
        vlen(self.handpos-self.offhandpos)<1.1*mu && mid_z>-1.0*mu && mid_z<0.15*mu &&
        mid*v_forward>0.08*mu && mid*v_forward<1.1*mu;
};
float(entity e) ADVR_Raiseable = {
    return (e.flags & FL_MONSTER) && e.health<=0 && e.modelindex && !e.gibbed && !e.bossflag && !e.advr_dark_used && !e.advr_dark_owner;
};
entity(entity e) ADVR_RaiseCorpse = {
    local string name;
    if(!ADVR_Raiseable(e))return world;name=e.classname;
    if(ADVR_DarkHumanoid(e)){if(random()<0.5)name="monster_zombie";else name="monster_zombiek";}
    return ADVR_DarkCreate(e,e.origin+'0 0 8',name,self,ADVR_DarkHumanoid(e));
};
void() ADVR_RuneRockTouch = {
    if(other==self.owner)return;
    if(other.takedamage){T_Damage(other,self,self.owner,20*self.advr_magic_damage,DAMARMOR);if(other.health>0)ADVR_Ignite(other,self.owner);}
    sound(self,CHAN_WEAPON,SOUND_IMP_ROCK1,0.7,ATTN_NORM);
    particle(self.origin,'0 0 20',8,12);remove(self);
};
void(vector at,vector aim,float h) ADVR_RuneRock = {
    local entity p;
    p=spawn();p.classname="advr_rune_rock";p.owner=self;p.solid=SOLID_BBOX;p.movetype=MOVETYPE_FLYMISSILE;
    if(random()<0.5)setmodel(p,MODEL_PROJ_GROCK1);else setmodel(p,MODEL_PROJ_GROCK2);p.frame=floor(random()*10);p.scale=0.5;setsize(p,'-2 -2 -2','2 2 2');setorigin(p,at);
    p.velocity=aim*650;p.advr_fireball=1;sound(self,CHAN_WEAPON,"golem/rockstorm.wav",0.6,ATTN_NORM);p.avelocity='170 240 110';p.advr_magic_damage=ADVR_MagicMultiplier();
    p.touch=ADVR_RuneRockTouch;p.think=SUB_Remove;p.nextthink=time+3;
    haptic(h,0,0.05,90,0.25);
};
void() ADVR_NecroticFxThink = {
    if(!self.owner || self.owner.health<=0 || self.owner.advr_dark_until<=time || time>self.attack_finished){remove(self);return;}
    self.nextthink=time+0.05;
};
void(float h,vector at,vector aim) ADVR_NecroticRay = {
    local entity e,target,fx;local vector end,delta,point;local float reach,d,along;
    tracebox(at,'-2 -2 -2','2 2 2',at+aim*600,FALSE,self);end=trace_endpos;target=trace_ent;reach=vlen(end-at);
    // Ragdolls often have no solid hull. Pick the nearest visible corpse along the ray.
    e=nextent(world);
    while(e){if(ADVR_Raiseable(e)){
        point=modelcentre(e);delta=point-at;along=delta*aim;
        if(along>0 && along<=reach+12 && (hitmodel_any(e,at,at+aim*reach,0)>=0 || vlen(delta-aim*along)<24)){
            traceline(at,point,TRUE,self);if(trace_fraction==1){target=e;end=point;reach=along;}
        }
    }e=nextent(e);}
    fx=self.advr_necrotic_fx[h];
    if(!fx || fx.classname!="advr_necrotic_ray" || fx.owner!=self){
        fx=spawn();fx.classname="advr_necrotic_ray";fx.owner=self;fx.solid=SOLID_NOT;fx.movetype=MOVETYPE_NONE;
        // Model-less emitter: visual segments come from the lightning temp event.
        self.advr_necrotic_fx[h]=fx;
        fx.alpha=0.35;fx.think=ADVR_NecroticFxThink;
    }
    setorigin(fx,at);delta=end-at;fx.angles=vectoangles(delta); // Alias models use positive pitch upward.
    fx.model_scale_x=vlen(delta)/600-1;fx.model_scale_y=fx.model_scale_z=0;
    fx.attack_finished=time+0.1;fx.nextthink=time+0.05;
    WriteByte(MSG_BROADCAST,SVC_TEMPENTITY);WriteByte(MSG_BROADCAST,14); // TE_ADVR_NECROTIC
    WriteEntity(MSG_BROADCAST,fx);WriteByte(MSG_BROADCAST,h);
    WriteCoord(MSG_BROADCAST,at_x);WriteCoord(MSG_BROADCAST,at_y);WriteCoord(MSG_BROADCAST,at_z);
    WriteCoord(MSG_BROADCAST,end_x);WriteCoord(MSG_BROADCAST,end_y);WriteCoord(MSG_BROADCAST,end_z);
    if(time>=fx.pain_finished){sound(fx,CHAN_WEAPON,"weapons/lhit.wav",0.65,ATTN_NORM);fx.pain_finished=time+0.6;}
    if(ADVR_Raiseable(target)){
        if(self.advr_raise_target[h]!=target){self.advr_raise_target[h]=target;self.advr_raise_time[h]=0;}
        self.advr_raise_seen[h]=time;self.advr_raise_time[h]=self.advr_raise_time[h]+min(0.05,frametime);
        if(self.advr_raise_time[h]>=2.5){ADVR_RaiseCorpse(target);self.advr_raise_target[h]=world;self.advr_raise_time[h]=0;haptic(h,0,0.2,60,0.6);}
    }else{
        if(time-self.advr_raise_seen[h]>0.15){self.advr_raise_target[h]=world;self.advr_raise_time[h]=0;}
        if(time>=self.advr_rune_tick[h]){
            if(target.takedamage && target.health>0 && !target.advr_dark_owner && target!=self)
                T_Damage(target,self,self,2*ADVR_MagicMultiplier(),DAMARMOR);
            self.advr_rune_tick[h]=time+0.25;haptic(h,0,0.03,60,0.12);
        }
    }
};
void() ADVR_RuneClear = {
    local float h;
    self.advr_rune_until=self.advr_dark_until=self.advr_hell_until=0;
    for(h=0;h<2;h=h+1){
        if(self.advr_necrotic_fx[h] && self.advr_necrotic_fx[h].classname=="advr_necrotic_ray")remove(self.advr_necrotic_fx[h]);
        self.advr_necrotic_fx[h]=self.advr_raise_target[h]=world;self.advr_raise_time[h]=self.advr_rune_tick[h]=self.advr_rock_charge[h]=self.advr_raise_seen[h]=0;
    }
};
void() ADVR_RuneFrame = {
    local float h,button;local vector at,aim;
    if(!ADVR_RuneActive() || intermission_running){ADVR_RuneClear();return;}
    self.vr_stamina_used=0;
    if(self.advr_dark_until>time && time>=self.advr_rune_smoke){particle2(self.handpos,'0 0 5',4,1);particle2(self.offhandpos,'0 0 5',4,1);self.advr_rune_smoke=time+0.15;}
    for(h=0;h<2;h=h+1){
        if(h)button=self.button0;else button=self.button3;
        if(!ADVR_Tracked() || cinematic_running || ADVR_Hand(h) || ADVR_Grip(h) || !button || self.advr_magic_book){
            self.advr_raise_target[h]=world;self.advr_raise_time[h]=0;self.advr_rock_charge[h]=0;continue;
        }
        at=ADVR_Pos(h);if(vlen(at-ADVR_Head(self))>100){self.advr_raise_target[h]=world;self.advr_raise_time[h]=0;self.advr_rock_charge[h]=0;continue;}
        traceline(ADVR_Head(self),at,TRUE,self);if(trace_fraction<1){self.advr_raise_target[h]=world;self.advr_raise_time[h]=0;self.advr_rock_charge[h]=0;continue;}
        makevectors(ADVR_Angles(h));aim=v_forward;
        if(self.advr_dark_until>time)ADVR_NecroticRay(h,at,aim);
        else if(self.advr_earth_until>time && time>=self.advr_rune_tick[h]){
            self.advr_rock_charge[h]=self.advr_rock_charge[h]+min(0.05,frametime);
            haptic(h,0,0.025,70,0.12);
            if(self.advr_rock_charge[h]>=0.4){ADVR_RuneRock(at+aim*5,aim,h);self.advr_rune_tick[h]=time+0.35;self.advr_rock_charge[h]=0;}
        }
    }
};

void() ADVR_TestRuneExpansion = {
    local entity book,p,v,e;local float dt,i,before,remaining;local vector head,spot;
    dt=frametime;frametime=0.05;ADVR_TestMagicView();book=self.advr_off;
    self.advr_holsterpos5=self.offhandpos;ADVR_RuneStow(0);
    ADVR_Assert(!self.advr_off,"rune stows book and frees hand");
    self.advr_rune_until=time+70;self.vr_stamina_used=ADVR_StaminaMax();ADVR_ParrySpend(1);
    ADVR_Assert(self.vr_stamina_used==0,"rune parry spends no stamina");
    head=ADVR_Head(self);self.v_viewangle='0 0 0';self.vrbits0=16384;
    self.handpos=head+'12 6 -12';self.offhandpos=head+'12 -6 -12';
    ADVR_Assert(ADVR_RuneCrossed(),"crossed empty hands form guard");
    self.handpos=head+'12 -6 -12';self.offhandpos=head+'12 6 -12';
    ADVR_Assert(!ADVR_RuneCrossed(),"uncrossed hands do not guard");
    self.advr_earth_until=time+70;self.handrot='0 0 0';self.button0=1;self.button3=0;
    ADVR_RuneFrame();ADVR_Assert(!find(world,classname,"advr_rune_rock"),"Earth needs a brief charge");
    for(i=0;i<8;i=i+1)ADVR_RuneFrame();p=find(world,classname,"advr_rune_rock");
    ADVR_Assert(p && p.owner==self && vlen(p.velocity)>600,"earth trigger shoots physical rock");remove(p);self.button0=0;
    self.advr_dark_until=time+70;self.advr_earth_until=0;
    v=spawn();v.classname="rune_ray_target";v.health=100;v.takedamage=DAMAGE_YES;v.solid=SOLID_BBOX;v.th_pain=SUB_Null;
    setsize(v,'-8 -8 -8','8 8 8');setorigin(v,head+'80 0 0');self.advr_rune_tick[1]=0;
    ADVR_NecroticRay(1,head,'1 0 0');
    ADVR_Assert(v.health<100 && v.health>=96,"necrotic tick is much weaker than lightning");
    ADVR_Assert(self.advr_necrotic_fx[1].alpha==0.35,"necrotic ray is translucent");
    // Exercise the actual hand-driven frame, not only a direct beam call.
    self.handpos=head;self.handrot='-26.565 0 0';self.button0=1;self.advr_magic_book=world;
    setorigin(v,head+'64 0 32');self.advr_rune_tick[1]=0;before=v.health;ADVR_RuneFrame();
    ADVR_Assert(v.health<before,"pitched hand ray damages the aimed target");
    ADVR_Assert(self.advr_necrotic_fx[1].angles_x>20 && self.advr_necrotic_fx[1].angles_x<30,"visible ray pitches upward with actual damage trace");
    self.button0=0;remove(v);
    p=spawn();p.classtype=CT_PROJ_FIRETOP;self.advr_hell_until=time+70;self.health=1000;before=self.health;
    T_Damage(self,p,p,30,DAMARMOR);ADVR_Assert(self.health==before,"Nether blocks fire projectile damage");
    p.classtype=CT_PROJ_NG;T_Damage(self,p,p,30,DAMARMOR);ADVR_Assert(self.health<before,"Nether does not block ordinary projectiles");
    self.waterlevel=1;self.watertype=CONTENT_LAVA;self.dmgtime=0;before=self.health;WaterMove();
    ADVR_Assert(self.health==before,"Nether blocks lava immersion damage");
    self.advr_hell_until=0;self.dmgtime=0;WaterMove();ADVR_Assert(self.health<before,"lava protection ends with Nether");
    self.waterlevel=0;self.watertype=CONTENT_EMPTY;remove(p);
    v=spawn();v.classname="monster_zombie";v.flags=FL_MONSTER;v.health=0;v.classgroup=CG_ZOMBIE;
    setmodel(v,"progs/zombie.mdl");setsize(v,'-8 -8 -8','8 8 8');setorigin(v,head+'80 0 0');
    for(i=0;i<49;i=i+1)ADVR_NecroticRay(1,head,'1 0 0');
    ADVR_Assert(v.modelindex && self.advr_raise_time[1]>2.3,"corpse needs continuous two-and-half-second channel");
    self.button0=0;ADVR_RuneFrame();ADVR_Assert(!self.advr_raise_target[1] && self.advr_raise_time[1]==0,"release resets corpse channel");
    for(i=0;i<51;i=i+1)ADVR_NecroticRay(1,head,'1 0 0');
    ADVR_Assert(!v.modelindex,"full necrotic channel consumes corpse and reanimates it");
    self.advr_rune_until=self.advr_dark_until=time;ADVR_RuneFrame();
    ADVR_Assert(!ADVR_RuneActive() && !self.advr_necrotic_fx[1],"expiry removes ray and rune benefits");
    // A cast may consume no more than twenty of twenty-one eligible corpses.
    for(i=0;i<21;i=i+1){
        e=spawn();e.classname="monster_zombie";e.flags=FL_MONSTER;e.health=0;e.classgroup=CG_ZOMBIE;e.advr_rune_smoke=12345;
        setmodel(e,"progs/zombie.mdl");setsize(e,'-8 -8 -8','8 8 8');
        spot=self.origin+'40 -100 120';spot_x=spot_x+floor(i/5)*45;spot_y=spot_y+(i-floor(i/5)*5)*45;setorigin(e,spot);
    }
    ADVR_DarkCast();e=world;remaining=0;
    while((e=nextent(e)))if(e.advr_rune_smoke==12345 && e.modelindex)remaining=remaining+1;
    ADVR_Assert(remaining>=1 && remaining<21,"Dark cast raises some corpses but caps at twenty");
    frametime=dt;ADVR_TestMagicView();bprint("ADVR RUNE EXPANSION PASS: stow, stamina, crossed arms, rocks, ray damage, channel interruption, expiry\n");
};

void() ADVR_TestRuneAbilityView = {
    local entity p;local vector aim;
    ADVR_TestMagicView();ADVR_RuneStow(0);self.advr_dark_until=self.advr_rune_until=time+70;
    makevectors(self.v_viewangle);aim=v_forward;ADVR_NecroticRay(1,ADVR_Head(self)+v_forward*12+v_right*8-v_up*4,aim);
    p=self.advr_necrotic_fx[1];p.attack_finished=time+20;
    makevectors(self.v_viewangle);ADVR_RuneRock(ADVR_Head(self)+v_forward*30-v_right*8-v_up*4,aim,0);p=find(world,classname,"advr_rune_rock");p.velocity='0 0 0';p.movetype=MOVETYPE_NONE;p.nextthink=time+20;
    bprint("ADVR RUNE ABILITY VIEW: dark aura, translucent ray and rock\n");
};

