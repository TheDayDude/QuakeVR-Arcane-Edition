// Selective hand-grenade port from QuakeVR 699ce475: pin, fuse, pouch and returns.
// AD keeps its native grenade explosion/damage rules and physical reload accounting.
void(entity g) ADVR_GrenadeBoom = {
    local entity saved,p,c;local float h;
    if(!g.advr_grenade)return;
    saved=self;p=g.advr_round_holder;c=g.advr_grenade_control;
    g.advr_grenade=0;g.takedamage=DAMAGE_NO;g.advr_grenade_control=world;
    if(p){for(h=0;h<2;h=h+1)if(p.advr_round[h]==g){p.advr_round[h]=world;p.advr_round_guard[h]=time+0.2;}}
    g.advr_round_holder=world;
    if(g.fg_state)ADVR_FGRestore(g);
    if(c)remove(c);
    g.owner=g.advr_grenade_attacker;g.effects=0;g.activate=world;
    self=g;Explode_Grenade();self=saved;
};
void(entity g,entity attacker) ADVR_GrenadeDamage = {
    if(!g.advr_grenade || g.advr_round_holder || !g.takedamage)return;
    g.advr_grenade_attacker=attacker;g.takedamage=DAMAGE_NO;
    // A short deferred chain prevents recursive radius damage through nearby traps.
    if(!g.advr_grenade_fuse || g.advr_grenade_fuse>time+0.05)g.advr_grenade_fuse=time+0.05;
};
void() ADVR_GrenadeTouch = {
    local entity g,p,saved;local float h;
    g=self;p=other;
    if(g.advr_round_holder || g.fg_state)return;
    if(!g.advr_grenade_fuse){
        if(vlen(g.velocity)>40)sound(g,CHAN_WEAPON,"weapons/bounce.wav",0.4,ATTN_NORM);
        return;
    }
    if((p.flags & FL_CLIENT) && p.advr_initialized && time>=g.advr_cooldown && cvar("vr_grenade_catch")){
        self=p;
        for(h=0;h<2;h=h+1)if(!ADVR_Hand(h) && !ADVR_HandBusy(h) && ADVR_Grip(h) && vlen(ADVR_Pos(h)-g.origin)<10){
            ADVR_ManualCatch(g,h);self=g;return;
        }
        self=g;
    }
    // AD's normal impact rules, including parries, bounce and poisonous variants.
    Touch_Grenade();
};
void() ADVR_GrenadeControl = {
    local entity c,g,p,next,saved;local float h,left;
    c=self;g=c.enemy;
    if(!g.advr_grenade || g.advr_grenade_control!=c || !g.modelindex || g.state==STATE_DISABLED){
        // Native impact explosions also need to invalidate the hand/fuse metadata.
        if(g.advr_grenade_control==c){g.advr_grenade=0;g.advr_grenade_control=world;}
        remove(c);return;
    }
    if(g.advr_grenade_fuse && time>=g.advr_grenade_fuse){ADVR_GrenadeBoom(g);return;}
    if(g.advr_grenade_fuse && time>=g.advr_grenade_tick){
        left=g.advr_grenade_fuse-time;
        sound(g,CHAN_AUTO,"vr/grenade_tick.wav",0.65,ATTN_NORM);
        particle(g.origin,'0 0 25',224,3);
        g.advr_grenade_tick=time+bound(0.08,left*0.2,0.5);
        p=g.advr_round_holder;
        if(p){self=p;h=(p.advr_round[1]==g);haptic(h,0,0.025,100,0.25);self=c;}
    }
    if(!g.advr_round_holder && !g.fg_state && time>=g.advr_cooldown){
        // Detached unarmed traps must be hittable by their owner's own bullets.
        if(!g.advr_grenade_fuse)g.owner=world;
        if(cvar("vr_grenade_catch")){
            p=find(world,classname,"player");
            while(p){
                next=find(p,classname,"player");self=p;
                if(p.health>0 && p.advr_initialized)for(h=0;h<2;h=h+1){
                    if(!ADVR_Hand(h) && !ADVR_HandBusy(h) && ADVR_Grip(h) && vlen(ADVR_Pos(h)-g.origin)<6){
                        traceline(ADVR_Pos(h),g.origin,TRUE,p);
                        if(trace_fraction==1){ADVR_ManualCatch(g,h);self=c;c.nextthink=time+0.025;return;}
                    }
                }
                p=next;
            }
            self=c;
        }
    }
    c.nextthink=time+0.025;
};
void(entity g,float live) ADVR_GrenadeSetup = {
    local entity c;
    if(g.advr_grenade)return;
    g.advr_grenade=1;g.advr_grenade_attacker=g.owner;
    g.advr_round_type=3;g.advr_round_weapon=IT_GRENADE_LAUNCHER;g.advr_round_count=1;
    g.classname="advr_reload_round";g.classgroup=CG_PROJGRENADES;
    if(!live){g.classtype=CT_PROJ_GL;g.height=EXPLODE_SMALL;g.noise="weapons/bounce.wav";g.skin=1;}
    else {g.advr_grenade_fuse=g.nextthink;g.skin=0;}
    // Keep poison grenades green; normal grenades share the centered, smaller mesh.
    if(!g.poisonous)setmodel(g,"progs/advr_handgrenade.mdl");
    else g.model_scale='0.78 0.78 0.78';
    setsize(g,'-3 -2 -2','3 2 2');
    g.health=1;g.takedamage=DAMAGE_YES;g.touch=ADVR_GrenadeTouch;
    g.advr_cooldown=time+0.2;g.think=SUB_Null;g.nextthink=0;
    c=spawn();c.classname="advr_grenade_control";c.enemy=g;
    c.think=ADVR_GrenadeControl;c.nextthink=time+0.025;g.advr_grenade_control=c;
};
void(entity g,float h) ADVR_GrenadeCaught = {
    g.takedamage=DAMAGE_NO;
    self.advr_grenade_trigger[h]=(h ? self.button0 : self.button3);
    // Give the first catch time to return it; re-catching cannot prolong the fuse.
    if(g.advr_grenade_fuse && !g.advr_grenade_caught)
        g.advr_grenade_fuse=max(g.advr_grenade_fuse,time+bound(1,cvar("vr_grenade_held_fuse"),5));
    g.advr_grenade_caught=1;
};
void(entity g,float h) ADVR_GrenadeHeld = {
    local float trigger;
    trigger=(h ? self.button0 : self.button3);
    if(trigger && !self.advr_grenade_trigger[h] && !g.advr_grenade_fuse){
        g.advr_grenade_fuse=time+bound(1,cvar("vr_handgrenade_fuse"),5);
        g.advr_grenade_attacker=self;g.skin=0;g.advr_grenade_tick=time+0.15;
        sound(g,CHAN_AUTO,"vr/grenade_pin.wav",0.8,ATTN_NORM);
        sound(g,CHAN_WEAPON,"vr/grenade_fuse.wav",0.65,ATTN_NORM);
        haptic(h,0,0.08,100,0.6);
    }
    self.advr_grenade_trigger[h]=trigger;
};
void(entity g) ADVR_GrenadeReleased = {
    g.advr_grenade_attacker=self;g.takedamage=DAMAGE_YES;g.health=1;
    g.think=SUB_Null;g.nextthink=0;
    if(g.advr_grenade_fuse){g.classtype=CT_PROJ_GL;g.dmg=DAMAGE_PLAYGRENADE;}
};
void(float h) ADVR_GrenadeTake = {
    local entity r,g;
    if(!cvar("vr_handgrenade") || ADVR_Hand(h) || ADVR_HandBusy(h))return;
    if(self.ammo_rockets-ADVR_Loaded(IT_GRENADE_LAUNCHER)<=0)return;
    r=spawn();r.advr_weapon=IT_GRENADE_LAUNCHER;g=ADVR_ManualProp(r,1);ADVR_AmmoTake(r,g,self.ammo_rockets-ADVR_Loaded(IT_GRENADE_LAUNCHER));remove(r);
    if(g.advr_round_count<=0){if(g.advr_grenade_control)remove(g.advr_grenade_control);remove(g);return;}
    self.ammo_rockets=self.ammo_rockets-1;g.advr_grenade_attacker=self;
    ADVR_ManualCatch(g,h);sound(self,CHAN_AUTO,"vr/grenade_pouch.wav",0.5,ATTN_NORM);
};

float(entity e) ADVR_CanDeflect;
void() ADVR_TestGrenades = {
    local entity g,c,r,player,foe;local float mode,gripmode,ammo,fuse;local vector pos;
    mode=cvar("vr_reload_mode");gripmode=cvar("vr_weapon_grip_mode");
    cvar_set("vr_reload_mode","3");cvar_set("vr_weapon_grip_mode","0");
    ADVR_Reset();self.advr_initialized=1;self.health=500;self.ammo_rockets=20;
    self.vrbits0=16384+16;self.button0=self.button3=0;
    self.handpos=self.origin+'24 0 40';self.offhandpos=self.origin+'24 20 40';self.ammopouchpos=self.origin+'0 0 -80';
    player=self;ADVR_GrenadeTake(1);g=self.advr_round[1];
    ADVR_Assert(g.advr_grenade && !g.advr_grenade_fuse && self.ammo_rockets==19,"pouch gives one unarmed grenade and debits one rocket");
    self.button0=1;ADVR_GrenadeHeld(g,1);fuse=g.advr_grenade_fuse;
    ADVR_Assert(fuse>time && self.advr_round[1]==g && g.velocity=='0 0 0',"trigger arms without launching");
    self.advr_main=ADVR_Record(IT_GRENADE_LAUNCHER);r=self.advr_main;self.advr_main=world;self.advr_off=r;r.wi_clip=0;
    ADVR_Assert(!ADVR_ManualInsert(1),"armed grenade cannot be loaded");
    self.handthrowvel='2 1 0';ADVR_ManualRelease(1,1);
    ADVR_Assert(!self.advr_round[1] && g.advr_grenade_fuse==fuse && g.velocity_x>50 && self.ammo_rockets==19,"armed grenade throws instead of refunding with fuse intact");
    c=g.advr_grenade_control;g.advr_grenade=0;remove(g);remove(c);
    self.advr_round_guard[1]=0;self.advr_off=world;remove(r);self.button0=0;
    ADVR_GrenadeTake(1);g=self.advr_round[1];self.handthrowvel='0 0 0';ADVR_ManualRelease(1,0);
    ADVR_Assert(!g.advr_grenade_fuse && g.takedamage && g.velocity=='0 0 0',"unarmed grenade stays as a shootable trap");
    self.vrbits0=16384;g.advr_cooldown=0;c=g.advr_grenade_control;self=c;ADVR_GrenadeControl();self=player;
    ADVR_Assert(!g.owner,"trap permits owner's shots");
    setorigin(g,self.origin+'200 0 40');T_Damage(g,player,player,1,DAMARMOR);
    ADVR_Assert(g.advr_grenade_fuse>time && !g.takedamage,"damage schedules trap detonation once");
    g.advr_grenade_fuse=time;self=c;ADVR_GrenadeControl();self=player;
    ADVR_Assert(!g.advr_grenade,"damaged trap detonates");
    // Real monster launch path, not a mock round, must be eligible in flight.
    foe=spawn();foe.flags=FL_MONSTER;self=foe;
    Launch_Grenade(player.origin+'180 0 60','-250 0 100','0 100 0',CT_PROJ_GLMON);g=newmis;self=player;
    ADVR_Assert(g.advr_grenade && g.advr_grenade_fuse>time,"ogre launch registers independent fuse");
    ADVR_Assert(ADVR_CanDeflect(g),"shootable ogre grenades still allow melee parries");
    g.advr_cooldown=0;ADVR_Assert(ADVR_FGEligible(g),"flying ogre grenade is force grabbable");
    ADVR_FGLaunch(1,g);c=g.advr_grenade_control;
    ADVR_Assert(g.fg_state && c.think==ADVR_GrenadeControl,"force pull cannot replace fuse timer");
    self.advr_round_guard[1]=0;self.vrbits0=16384+8;setorigin(g,self.handpos);
    self=g;ADVR_FGFlight();self=player;fuse=g.advr_grenade_fuse;
    ADVR_Assert(self.advr_round[1]==g && fuse>=time+1,"ogre grenade catches with time to return");
    self.handthrowvel='3 0 1';ADVR_ManualRelease(1,0);
    ADVR_Assert(g.owner==player && g.advr_grenade_attacker==player && g.classtype==CT_PROJ_GL && g.advr_grenade_fuse==fuse,"returned grenade uses player damage and unchanged fuse");
    self.advr_round_guard[1]=0;ADVR_ManualCatch(g,1);ADVR_Assert(g.advr_grenade_fuse==fuse,"re-catching does not reset fuse");
    g.advr_grenade_fuse=time;self=c;ADVR_GrenadeControl();self=player;
    ADVR_Assert(!self.advr_round[1] && !g.advr_grenade,"held grenade expires and releases hand");
    remove(foe);
    // Exercise real frame input, both hands, toggle grip and legacy reload mode.
    self.flags=self.flags | FL_GODMODE;self.health=500;self.button0=self.button3=0;
    self.advr_round_guard[0]=self.advr_round_guard[1]=0;self.vrbits0=16384;
    self.mainhand_hotspot=0;self.offhand_hotspot=11;self.advr_round_grip[0]=0;
    cvar_set("vr_reload_mode","2");cvar_set("vr_weapon_grip_mode","1");
    self.vrbits0=16384+2;ADVR_ManualFrame();g=self.advr_round[0];
    ADVR_Assert(g.advr_grenade,"rear pouch works in non-manual reload mode with off hand");
    self.vrbits0=16384;ADVR_ManualFrame();self.button3=1;ADVR_ManualFrame();
    ADVR_Assert(self.advr_round[0]==g && g.advr_grenade_fuse>time,"toggle grip retains armed off-hand grenade");
    self.vrbits0=16384+2;ADVR_ManualFrame();
    ADVR_Assert(!self.advr_round[0] && g.advr_grenade_fuse>time,"second grip releases armed grenade even at pouch");
    // An expired grenade must explode during a force pull, not wait for arrival.
    self.offhand_hotspot=0;self.button3=0;self.vrbits0=16384;self.advr_round_guard[0]=0;
    setorigin(g,self.origin+'180 40 40');ADVR_FGLaunch(0,g);g.advr_grenade_fuse=time;
    c=g.advr_grenade_control;self=c;ADVR_GrenadeControl();self=player;
    ADVR_Assert(!g.advr_grenade && !self.offhand_fgpulled,"fuse expires during force flight and clears pull state");
    r=ADVR_Record(IT_NAILGUN);self.advr_main=r;r.wi_clip=3;
    self.vrbits0=16384+1048576;self.advr_round_secondary[1]=0;ADVR_ManualFrame();
    ADVR_Assert(r.wi_clip==3,"grenade support leaves non-manual magazine controls unchanged");
    self.flags=self.flags-(self.flags & FL_GODMODE);
    cvar_set("vr_reload_mode",ftos(mode));cvar_set("vr_weapon_grip_mode",ftos(gripmode));
    ADVR_Reset();self.health=100;
    bprint("ADVR GRENADES PASS: pouch, arming, throwing, traps, damage, ogre force grab, return and fuse lifecycle\n");
};
