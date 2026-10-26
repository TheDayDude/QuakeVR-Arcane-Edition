// Selective port of QuakeVR immersive reloading (76e28be1), adapted to AD's
// total-including-clips accounting. A physical round is NEVER part of that total.
// Insert/refund adds its count back; extraction/ejection removes it immediately.
float(entity r) ADVR_ManualType = {
    if(!r || ADVR_IsTome(r) || r.advr_kind==ADVR_SAW)return 0;
    if(r.advr_kind==ADVR_CROSSBOW)return 5;
    return ADVR_AmmoType(r.advr_weapon);
};
float(entity r) ADVR_ManualSsg = {return r && r.advr_weapon==IT_SUPER_SHOTGUN && !r.advr_kind && cvar("vr_reload_mode")==3;};
float(entity r) ADVR_ManualMagazine = {return r.advr_kind==ADVR_WIDOWMAKER || ADVR_ManualType(r)==2 || ADVR_ManualType(r)==4;};
vector(float h) ADVR_ManualPort = {if(h)return self.loadportpos;return self.offloadportpos;};
void() ADVR_ManualPrecache = {
    precache_model("progs/advr_charge_handle.mdl");
    precache_model("progs/advr_base_mag_nail.mdl");precache_model("progs/advr_base_mag_nail2.mdl");precache_model("progs/advr_base_mag_light.mdl");
    precache_model("progs/advr_mag_shell.mdl");precache_model("progs/vr_shell.mdl");
    precache_sound("vr/reload_ssg_open.wav");precache_sound("vr/reload_ssg_close.wav");precache_sound("vr/reload_ssg_eject.wav");
    precache_model("progs/vr_shell_live.mdl");precache_model("progs/vr_shell_pair.mdl");
    precache_model("progs/vr_mag_nail.mdl");precache_model("progs/vr_mag_snail.mdl");
    precache_model("progs/vr_mag_light.mdl");precache_model("progs/vr_round_rocket.mdl");
    precache_model("progs/vrpouch_ammo.mdl");precache_model("progs/grenade.mdl");
    precache_model("progs/advr_reload_bolt.mdl");
    precache_model("progs/advr_handgrenade.mdl");
    precache_sound("vr/grenade_pin.wav");precache_sound("vr/grenade_fuse.wav");precache_sound("vr/grenade_tick.wav");precache_sound("vr/grenade_pouch.wav");
    precache_sound("vr/reload_shell_in.wav");precache_sound("vr/reload_pouch.wav");
    precache_sound("vr/reload_mag_out.wav");precache_sound("vr/reload_mag_in.wav");
    precache_sound("gunclick.wav");precache_sound("vr/reload_full.wav");precache_sound("vr/reload_empty.wav");
};
void(entity p) ADVR_ManualModel = {
    if(p.advr_round_kind==ADVR_WIDOWMAKER)setmodel(p,"progs/advr_mag_shell.mdl");
    else if(p.advr_round_type==1){
        if(p.advr_round_count>1)setmodel(p,"progs/vr_shell_pair.mdl");
        else setmodel(p,"progs/vr_shell_live.mdl");
    }else if(p.advr_round_type==2){
        if(p.advr_round_weapon==IT_SUPER_NAILGUN)setmodel(p,"progs/advr_base_mag_nail2.mdl");
        else setmodel(p,"progs/advr_base_mag_nail.mdl");
    }else if(p.advr_round_type==4){if(p.advr_round_kind==ADVR_PLASMA)setmodel(p,"progs/vr_mag_light.mdl");else setmodel(p,"progs/advr_base_mag_light.mdl");}
    else if(p.advr_round_type==5)setmodel(p,"progs/advr_reload_bolt.mdl");
    else if(p.advr_round_weapon==IT_ROCKET_LAUNCHER)setmodel(p,"progs/vr_round_rocket.mdl");
    else setmodel(p,"progs/advr_handgrenade.mdl");
    setsize(p,'-2 -2 -2','2 2 2');
};
void() ADVR_ManualThink = {
    if(self.advr_round_holder || self.advr_grenade)return;
    if(time>=self.advr_round_expire){remove(self);return;}
    self.nextthink=time+1;
};
entity(entity r,float n) ADVR_ManualProp = {
    local entity p,e,old;local float count;
    // Bound abandoned props without ever deleting something held or force-pulled.
    e=find(world,classname,"advr_reload_round");
    while(e){if(!e.advr_round_holder && !e.fg_state && !e.advr_grenade_fuse){count=count+1;if(!old || e.advr_round_expire<old.advr_round_expire)old=e;}e=find(e,classname,"advr_reload_round");}
    if(count>=48 && old)remove(old);
    p=spawn();p.classname="advr_reload_round";p.advr_round_count=n;
    p.advr_round_kind=r.advr_kind;
    p.advr_round_type=ADVR_ManualType(r);p.advr_round_weapon=r.advr_weapon;
    p.advr_round_expire=time+180;p.think=ADVR_ManualThink;p.nextthink=time+1;
    p.movetype=MOVETYPE_BOUNCE;p.solid=SOLID_BBOX;p.vr_rigid=1;p.gravity=1;
    ADVR_ManualModel(p);
    if(p.advr_round_type==3 && p.advr_round_weapon==IT_GRENADE_LAUNCHER)ADVR_GrenadeSetup(p,0);
    return p;
};
void(entity p,float h) ADVR_ManualCatch = {
    if(!p || !p.modelindex || p.state==STATE_DISABLED || p.classname!="advr_reload_round")return;
    if(self.health<=0 || self.advr_elder_until>time || (self.advr_magic_book && self.advr_magic_hand==h))return;
    if(ADVR_Hand(h) || ADVR_HandBusy(h) || p.advr_round_holder)return;
    self.advr_round[h]=p;self.advr_round_grip[h]=ADVR_Grip(h);p.advr_round_holder=self;p.owner=self;
    p.movetype=MOVETYPE_NONE;p.solid=SOLID_NOT;p.vr_rigid=0;
    p.velocity=p.avelocity=p.vr_spin='0 0 0';p.nextthink=0;
    setorigin(p,ADVR_Pos(h));p.angles=ADVR_Angles(h);p.angles_x=-p.angles_x;
    if(p.advr_grenade)ADVR_GrenadeCaught(p,h);
    haptic(h,0,0.05,70,0.35);
};
void(float h,float refund) ADVR_ManualRelease = {
    local entity p;local vector vel;
    p=self.advr_round[h];if(!p)return;
    self.advr_round[h]=world;self.advr_round_guard[h]=time+0.2;
    p.advr_round_holder=world;
    if(p.advr_grenade_fuse>0)refund=0;
    if(refund){
        if(p.advr_round_type==5)self.advr_bolts=self.advr_bolts+p.advr_round_count;
        else ADVR_SetAmmo(p.advr_round_weapon,ADVR_Ammo(p.advr_round_weapon)+p.advr_round_count);
        remove(p);return;
    }
    p.movetype=MOVETYPE_BOUNCE;p.solid=SOLID_BBOX;p.vr_rigid=1;
    p.advr_round_expire=time+180;p.advr_cooldown=time+0.3;
    if(h){vel=self.handthrowvel;p.vr_spin=self.handavel;}else{vel=self.offhandthrowvel;p.vr_spin=self.offhandavel;}
    p.velocity=vel*26.246719*max(0.01,cvar("vr_world_scale"));p.avelocity=p.vr_spin*57.29578;
    p.think=ADVR_ManualThink;p.nextthink=time+1;setorigin(p,p.origin);
    if(p.advr_grenade)ADVR_GrenadeReleased(p);
};
void() ADVR_ManualRefund = {ADVR_ManualRelease(0,1);ADVR_ManualRelease(1,1);};
void(float h) ADVR_ManualTake = {
    local entity r,p;local float n,available,t;
    r=ADVR_Hand(1-h);t=ADVR_ManualType(r);
    if(!t || ADVR_Hand(h) || ADVR_HandBusy(h))return;
    if(t==5)available=self.advr_bolts;
    else available=max(0,ADVR_Ammo(r.advr_weapon)-ADVR_Loaded(r.advr_weapon));
    n=1;if(t==1 && r.advr_weapon==IT_SUPER_SHOTGUN)n=2;
    if(ADVR_ManualMagazine(r))n=ADVR_RecordCapacity(r);
    n=min(n,available);
    if(n<=0){sound(self,CHAN_AUTO,"vr/reload_empty.wav",0.4,ATTN_NORM);return;}
    p=ADVR_ManualProp(r,n);
    if(t==5)self.advr_bolts=self.advr_bolts-n;
    else ADVR_SetAmmo(r.advr_weapon,ADVR_Ammo(r.advr_weapon)-n);
    ADVR_ManualCatch(p,h);sound(self,CHAN_AUTO,"vr/reload_pouch.wav",0.45,ATTN_NORM);
};
// Magazine presence is independent of its remaining ammunition.
void(float h) ADVR_ManualEject = {
    local entity r,p;local float n,chunk,index;
    r=ADVR_Hand(h);if(!ADVR_ManualType(r) || time<r.advr_reload_until)return;
    ADVR_ClampClip(r);n=r.wi_clip;
    if(ADVR_ManualMagazine(r)){if(r.advr_mag_absent)return;r.advr_mag_absent=1;
        if(n<=0){p=ADVR_ManualProp(r,0);setorigin(p,ADVR_ManualPort(h));p.velocity='0 0 -35';p.owner=self;p.advr_cooldown=time+0.15;}
    }else if(n<=0)return;
    r.wi_clip=0;r.advr_mag_absent=1;
    if(ADVR_ManualType(r)!=5)ADVR_SetAmmo(r.advr_weapon,max(0,ADVR_Ammo(r.advr_weapon)-n));
    while(n>0){
        chunk=n;if(!ADVR_ManualMagazine(r))chunk=min(n,1);
        p=ADVR_ManualProp(r,chunk);n=n-chunk;
        setorigin(p,ADVR_ManualPort(h));p.angles=ADVR_Angles(h);
        makevectors(p.angles);p.velocity='0 0 -35'+v_right*(index-1)*4;
        p.owner=self;p.advr_cooldown=time+0.15;index=index+1;
    }
    r.advr_reload_until=time+0.25;r.advr_cooldown=max(r.advr_cooldown,r.advr_reload_until);
    sound(self,CHAN_AUTO,"vr/reload_mag_out.wav",0.45,ATTN_NORM);haptic(h,0,0.05,70,0.4);
};
void(float h) ADVR_SsgToggle = {
    local entity r,p;local float i;
    r=ADVR_Hand(h);
    if(!ADVR_ManualSsg(r) || time<r.advr_reload_until || time<r.advr_cooldown || r.advr_animtime>0)return;
    if(r.advr_ssg_open){
        r.advr_ssg_open=0;sound(self,CHAN_AUTO,"vr/reload_ssg_close.wav",0.5,ATTN_NORM);
    }else{
        ADVR_ManualEject(h);
        for(i=0;i<r.advr_ssg_spent;i=i+1){
            p=spawn();p.classname="advr_spent_shell";setmodel(p,"progs/vr_shell.mdl");
            setsize(p,'-1 -1 -1','1 1 1');setorigin(p,ADVR_ManualPort(h));
            p.angles=ADVR_Angles(h);makevectors(p.angles);
            p.velocity=-v_forward*65+v_up*45+v_right*(i*2-1)*15;
            p.movetype=MOVETYPE_BOUNCE;p.solid=SOLID_NOT;p.avelocity='100 200 50';
            p.think=SUB_Remove;p.nextthink=time+15;
        }
        if(r.advr_ssg_spent)sound(self,CHAN_AUTO,"vr/reload_ssg_eject.wav",0.45,ATTN_NORM);
        r.advr_ssg_spent=0;r.advr_ssg_open=1;
        sound(self,CHAN_AUTO,"vr/reload_ssg_open.wav",0.5,ATTN_NORM);
    }
    r.advr_reload_until=time+0.35;self.advr_fg_rearm[h]=1;haptic(h,0,0.06,75,0.4);
};
float(float h) ADVR_ManualInsert = {
    local entity r,p;local float n,t;
    p=self.advr_round[h];r=ADVR_Hand(1-h);t=ADVR_ManualType(r);
    if(!p || p.advr_grenade_fuse>0 || !t || p.advr_round_type!=t || time<r.advr_reload_until)return 0;
    if(ADVR_ManualSsg(r) && !r.advr_ssg_open)return 0;
    if(t==1 && ((r.advr_kind==ADVR_WIDOWMAKER)!=(p.advr_round_kind==ADVR_WIDOWMAKER)))return 0;
    // Magazines and launcher rounds have different shapes and are not interchangeable.
    // Plasma and thunderbolt intentionally share energy cells, but their capacities differ.
    if((t==2 || t==3) && p.advr_round_weapon!=r.advr_weapon)return 0;
    if(ADVR_ManualMagazine(r) && !r.advr_mag_absent)return 0;
    n=min(p.advr_round_count,ADVR_RecordCapacity(r)-r.wi_clip);if(n<=0)return 0;
    r.wi_clip=r.wi_clip+n;r.advr_mag_absent=0;
    if(ADVR_ManualMagazine(r))r.advr_needs_charge=1;
    if(t!=5)ADVR_SetAmmo(r.advr_weapon,ADVR_Ammo(r.advr_weapon)+n);
    p.advr_round_count=p.advr_round_count-n;
    r.advr_reload_until=time+0.22;r.advr_cooldown=max(r.advr_cooldown,r.advr_reload_until);
    // Require release of a trigger held while loading before the gun can shoot.
    self.advr_fg_rearm[1-h]=1;
    if(ADVR_ManualMagazine(r))sound(self,CHAN_AUTO,"vr/reload_mag_in.wav",0.5,ATTN_NORM);
    else sound(self,CHAN_AUTO,"vr/reload_shell_in.wav",0.5,ATTN_NORM);
    haptic(h,0,0.06,90,0.45);haptic(1-h,0,0.06,90,0.35);
    if(p.advr_round_count<=0){self.advr_round[h]=world;self.advr_round_guard[h]=time+0.2;remove(p);}
    else ADVR_ManualModel(p);
    return n;
};
// The charging grip is independent of the supporting grip and of ammunition.
// Measure against the moving gun's rail: walking or moving both hands together
// cannot cock it. A full rearward pull followed by release closes the action.
void(float h,float grip,float old) ADVR_ChargeFrame = {
    local entity r;local vector home,back,axis,delta;local float length,along,lateral,release,started;
    r=ADVR_Hand(1-h);
    if(h){home=self.offchargehome;back=self.offchargeback;}
    else{home=self.chargehome;back=self.chargeback;}
    axis=back-home;length=vlen(axis);
    if(self.advr_charge_guard[h] && (self.advr_charge_guard[h]!=r || vlen(ADVR_Pos(h)-(home+back)*.5)>6*max(.5,cvar("vr_world_scale"))))self.advr_charge_guard[h]=world;
    if(cvar("vr_reload_mode")!=3 || !r || !ADVR_ManualMagazine(r) || ADVR_Hand(h) || self.health<=0 || self.advr_elder_until>time || length<1 || r.advr_mag_absent){
        if(self.advr_charge_record[h])self.advr_charge_record[h].advr_charge_pull=0;
        self.advr_charge_record[h]=world;return;
    }
    axis=axis/length;delta=ADVR_Pos(h)-home;along=delta*axis;
    if(self.advr_charge_record[h] && self.advr_charge_record[h]!=r){self.advr_charge_record[h].advr_charge_pull=0;self.advr_charge_record[h]=world;}
    if(!self.advr_charge_record[h]){
        if(!r.advr_needs_charge || !grip || old || ADVR_HandBusy(h) || self.advr_magic_book || ADVR_FGPulled(h) || ragdollheld(self,h)>0)return;
        if(vlen(delta)>3*max(.5,cvar("vr_world_scale")))return;
        self.advr_charge_record[h]=r;self.advr_charge_start[h]=along;self.advr_charge_full[h]=0;started=1;
        haptic(h,0,.035,70,.25);
    }
    lateral=vlen(delta-axis*along);
    r.advr_charge_pull=bound(0,(along-self.advr_charge_start[h])/length,1);
    if(r.advr_charge_pull>=.85 && lateral<3*max(.5,cvar("vr_world_scale")) && !self.advr_charge_full[h]){
        self.advr_charge_full[h]=1;haptic(h,0,.06,90,.45);
    }
    release=(!grip && old);
    // Charging handles always follow trigger hold/release, independent of sticky grip.
    // Do not interpret the initial sticky-grip press as the release.
    if(started)release=0;
    if(lateral>7*max(.5,cvar("vr_world_scale")))release=1;
    if(release){
        if(self.advr_charge_full[h] && lateral<7*max(.5,cvar("vr_world_scale"))){
            r.advr_needs_charge=0;self.advr_fg_rearm[1-h]=1;
            sound(self,CHAN_AUTO,"vr/reload_full.wav",.5,ATTN_NORM);haptic(1-h,0,.045,80,.3);
        }
        r.advr_charge_pull=0;self.advr_charge_record[h]=world;self.advr_charge_guard[h]=r;self.advr_round_guard[h]=time+.15;
    }
};

void() ADVR_ManualFrame = {
    local float h,near,grip,old,release,secondary,flick,reach,trigger;local entity p;local vector pos;
    // Hand grenades remain available with either reload mode.
    if(cvar("vr_reload_mode")!=3){for(h=0;h<2;h=h+1)if(self.advr_round[h] && !self.advr_round[h].advr_grenade)ADVR_ManualRelease(h,1);}
    for(h=0;h<2;h=h+1){
        if(h)secondary=(self.vrbits0 & 1048576)!=0;else secondary=(self.vrbits0 & 524288)!=0;
        if(h)flick=(self.vrbits0 & 4096) && !(self.vrbits0 & 8192);
        else flick=(self.vrbits0 & 1024) && !(self.vrbits0 & 2048);
        if(cvar("vr_reload_mode")==3){
            if(ADVR_ManualSsg(ADVR_Hand(h))){
                if((ADVR_Hand(h).advr_ssg_open && flick) || (!ADVR_Hand(h).advr_ssg_open && secondary && !self.advr_round_secondary[h]))ADVR_SsgToggle(h);
            }else if(secondary && !self.advr_round_secondary[h])ADVR_ManualEject(h);
        }
        self.advr_round_secondary[h]=secondary;
        pos=ADVR_Pos(h);grip=ADVR_Grip(h);old=self.advr_round_grip[h];self.advr_round_grip[h]=grip;
        trigger=(h ? self.button0 : self.button3);
        ADVR_ChargeFrame(h,trigger,self.advr_charge_trigger[h]);
        self.advr_charge_trigger[h]=trigger;
        if(self.advr_charge_record[h])continue;
        near=(cvar("vr_reload_mode")==3 && vlen(pos-self.ammopouchpos)<max(2,cvar("vr_ad_reload_pouch_reach")));
        if((h && self.mainhand_hotspot==11) || (!h && self.offhand_hotspot==11))near=2;
        if(grip && !old){dprint("RELOAD GRIP h=");dprint(ftos(h));dprint(" distance=");dprint(ftos(vlen(pos-self.ammopouchpos)));dprint(" busy=");dprint(ftos(ADVR_HandBusy(h)));dprint(" gun=");dprint(ftos(ADVR_ManualType(ADVR_Hand(1-h))));dprint("\n");}
        p=self.advr_round[h];
        if(p){
            makevectors(ADVR_Angles(h));setorigin(p,pos);p.angles=ADVR_Angles(h);p.angles_x=-p.angles_x;
            if(p.advr_grenade)ADVR_GrenadeHeld(p,h);
            release=0;
            if(cvar("vr_weapon_grip_mode")==1){if(grip && !old)release=1;}
            else if(!grip && old)release=1;
            if(release && near && !p.advr_grenade_fuse){ADVR_ManualRelease(h,1);sound(self,CHAN_AUTO,"vr/reload_pouch.wav",0.4,ATTN_NORM);}
            else {
                traceline(pos,ADVR_ManualPort(1-h),TRUE,self);
                reach=max(2,cvar("vr_ad_reload_port_reach"));
                // A single shotgun shell must reach the receiver, not its broad magazine pickup radius.
                if(ADVR_Hand(1-h).advr_weapon==IT_SHOTGUN)reach=2;
                if(trace_fraction==1 && vlen(pos-ADVR_ManualPort(1-h))<reach)ADVR_ManualInsert(h);
                if(self.advr_round[h] && release)ADVR_ManualRelease(h,0);
            }
        }else if(near && !ADVR_Hand(h) && !ADVR_HandBusy(h) && !self.advr_magic_book && !ADVR_FGPulled(h) && ragdollheld(self,h)<=0){
            if(!self.advr_round_hover[h] && (near==2 || ADVR_ManualType(ADVR_Hand(1-h))))haptic(h,0,0.04,65,0.25);
            if(grip && !old){if(near==2)ADVR_GrenadeTake(h);else ADVR_ManualTake(h);}
        }
        self.advr_round_hover[h]=near;
    }
};

void() ADVR_TestCharging = {
    local entity r,p;local float h,i,w,k,before,mode,sticky;
    mode=cvar("vr_reload_mode");sticky=cvar("vr_weapon_grip_mode");
    cvar_set("vr_reload_mode","3");self.health=100;self.advr_main=self.advr_off=world;
    self.advr_magic_book=world;self.advr_elder_until=0;self.vrbits0=16384;
    for(h=0;h<2;h=h+1)for(i=0;i<5;i=i+1){
        cvar_set("vr_weapon_grip_mode","0");self.advr_round_guard[h]=0;
        w=IT_NAILGUN;k=0;if(i==1)w=IT_SUPER_NAILGUN;
        if(i==2 || i==3)w=IT_LIGHTNING;if(i==3)k=ADVR_PLASMA;
        if(i==4){w=IT_SUPER_SHOTGUN;k=ADVR_WIDOWMAKER;}
        r=ADVR_Record(w);r.advr_kind=k;r.wi_clip=0;r.advr_mag_absent=1;
        ADVR_SetHand(1-h,r);ADVR_SetAmmo(w,100);
        p=ADVR_ManualProp(r,ADVR_RecordCapacity(r));self.advr_round[h]=p;
        ADVR_Assert(ADVR_ManualInsert(h)>0 && r.advr_needs_charge,"new magazine requires cocking");
        r.advr_reload_until=r.advr_cooldown=0;self.advr_fg_rearm[1-h]=0;
        self.button0=self.button3=1;before=r.wi_clip;ADVR_Fire(1-h);
        ADVR_Assert(r.wi_clip==before && r.advr_dry_next>time,"uncocked gun clicks without firing");self.button0=self.button3=0;
        self.chargehome=self.offchargehome='100 100 100';self.chargeback=self.offchargeback='97 100 100';
        self.handpos=self.offhandpos='100 100 100';self.advr_round_guard[h]=0;
        ADVR_ChargeFrame(h,1,0);ADVR_Assert(self.advr_charge_record[h]==r,"free hand grips charging handle");
        self.handpos=self.offhandpos='99 100 100';ADVR_ChargeFrame(h,1,1);ADVR_ChargeFrame(h,0,1);
        ADVR_Assert(r.advr_needs_charge && !self.advr_charge_record[h],"short pull does not cock gun");
        self.advr_round_guard[h]=0;self.handpos=self.offhandpos='100 100 100';ADVR_ChargeFrame(h,1,0);
        // Move the gun and free hand together: no relative rail travel.
        self.chargehome=self.offchargehome='110 100 100';self.chargeback=self.offchargeback='107 100 100';self.handpos=self.offhandpos='110 100 100';
        ADVR_ChargeFrame(h,1,1);ADVR_Assert(!self.advr_charge_full[h],"body motion cannot cock weapon");
        self.handpos=self.offhandpos='107 100 100';ADVR_ChargeFrame(h,1,1);
        ADVR_Assert(self.advr_charge_full[h] && r.advr_needs_charge,"full pull waits for release");ADVR_ChargeFrame(h,0,1);
        ADVR_Assert(!r.advr_needs_charge && !self.advr_charge_record[h] && r.wi_clip==before,"release chambers without creating ammo");
        self.advr_charge_guard[h]=world;ADVR_Unload(1-h);
        ADVR_Assert(!r.advr_mag_absent && r.wi_clip==before,"red button cannot eject magazine");
        // Sticky grip must not change the trigger-based charging gesture.
        cvar_set("vr_weapon_grip_mode","1");r.advr_needs_charge=1;self.advr_round_guard[h]=0;self.handpos=self.offhandpos='110 100 100';
        ADVR_ChargeFrame(h,1,0);self.handpos=self.offhandpos='107 100 100';ADVR_ChargeFrame(h,1,1);ADVR_ChargeFrame(h,0,1);
        ADVR_Assert(!r.advr_needs_charge && !self.advr_charge_record[h],"trigger release chambers even with sticky grip");
        ADVR_SetHand(1-h,world);remove(r);
    }
    cvar_set("vr_reload_mode",ftos(mode));cvar_set("vr_weapon_grip_mode",ftos(sticky));
    self.advr_round_guard[0]=self.advr_round_guard[1]=0;ADVR_Sync();dprint("ADVR CHARGING PASS\n");
};

void() ADVR_TestManualReload = {
    local entity r,p;local float mode,before;
    mode=cvar("vr_reload_mode");cvar_set("vr_reload_mode","3");
    ADVR_Reset();self.advr_initialized=1;self.health=100;self.vrbits0=16384;self.moditems=0;
    self.advr_round_guard[0]=self.advr_round_guard[1]=0;
    self.ammo_shells=20;r=ADVR_Record(IT_SHOTGUN);self.advr_main=r;r.wi_clip=0;r.advr_mag_absent=1;
    ADVR_ManualTake(0);p=self.advr_round[0];
    ADVR_Assert(p.advr_round_count==1 && self.ammo_shells==19,"manual shell extraction conserves total");
    ADVR_Assert(ADVR_ManualInsert(0)==1 && r.wi_clip==1 && self.ammo_shells==20 && !self.advr_round[0],"manual shell insertion transfers only owned round");
    r.advr_reload_until=0;ADVR_Reload(1);ADVR_Assert(r.wi_clip==1,"manual disables automatic reload");
    self.advr_round_guard[0]=0;ADVR_ManualTake(0);ADVR_ManualRelease(0,0);p=find(world,classname,"advr_reload_round");
    ADVR_Assert(p.advr_round_count==1 && !p.advr_round_holder && self.ammo_shells==19,"dropped shell remains outside inventory");
    self.advr_round_guard[0]=0;ADVR_ManualCatch(p,0);ADVR_ManualRefund();
    ADVR_Assert(self.ammo_shells==20 && !self.advr_round[0],"caught shell refunds exactly once");
    ADVR_ManualRefund();ADVR_Assert(self.ammo_shells==20,"repeated refund cannot duplicate ammo");
    self.advr_main=world;self.ammo_nails=60;r=ADVR_Record(IT_NAILGUN);self.advr_main=r;r.wi_clip=7;
    r.advr_reload_until=0;ADVR_ManualEject(1);p=find(world,classname,"advr_reload_round");
    ADVR_Assert(p.advr_round_count==7 && r.wi_clip==0 && self.ammo_nails==53,"partial magazine eject preserves seven rounds");
    self.advr_round_guard[0]=0;ADVR_ManualCatch(p,0);r.advr_reload_until=0;ADVR_ManualInsert(0);
    ADVR_Assert(r.wi_clip==7 && self.ammo_nails==60,"partial magazine reinsertion conserves ammo");
    self.advr_round_guard[0]=0;ADVR_ManualTake(0);p=self.advr_round[0];r.advr_reload_until=0;
    ADVR_Assert(!ADVR_ManualInsert(0) && p.advr_round_count==24,"loaded magazine rejects replacement until ejected");
    ADVR_ManualRefund();self.advr_main=world;self.ammo_shells=30;r=ADVR_Record(IT_SUPER_SHOTGUN);self.advr_main=r;r.wi_clip=1;r.advr_ssg_open=1;
    self.advr_round_guard[0]=0;ADVR_ManualTake(0);ADVR_ManualInsert(0);p=self.advr_round[0];
    ADVR_Assert(r.wi_clip==2 && p.advr_round_count==1 && self.ammo_shells==29,"shell pair leaves unused shell in hand");
    ADVR_ManualRefund();ADVR_Assert(self.ammo_shells==30,"partial pair refund preserves total");
    self.advr_round_guard[0]=0;ADVR_ManualTake(0);r.advr_reload_until=0;before=self.ammo_shells;
    ADVR_Assert(!ADVR_ManualInsert(0) && r.wi_clip==2 && self.ammo_shells==before,"full shotgun leaves held shells untouched");
    ADVR_Assert(ADVR_HandBusy(0) && ADVR_MagicBlocked(0),"reload hand cannot also cast or manipulate another item");
    ADVR_ManualRefund();self.advr_main=world;self.ammo_rockets=20;
    r=ADVR_Record(IT_GRENADE_LAUNCHER);r.wi_clip=0;r.advr_mag_absent=1;self.advr_main=r;
    self.advr_round_guard[0]=0;ADVR_ManualTake(0);p=self.advr_round[0];
    ADVR_Assert(p.advr_round_count==1 && self.ammo_rockets==19,"launcher pouch yields one unarmed grenade");
    r.advr_weapon=IT_ROCKET_LAUNCHER;ADVR_Assert(!ADVR_ManualInsert(0),"rocket tube rejects a grenade");
    r.advr_weapon=IT_GRENADE_LAUNCHER;ADVR_ManualInsert(0);
    ADVR_Assert(r.wi_clip==1 && self.ammo_rockets==20,"grenade muzzle loading conserves ammo");
    r.advr_weapon=IT_ROCKET_LAUNCHER;r.wi_clip=0;r.advr_mag_absent=1;r.advr_reload_until=0;
    self.advr_round_guard[0]=0;ADVR_ManualTake(0);ADVR_ManualInsert(0);
    ADVR_Assert(r.wi_clip==1 && self.ammo_rockets==20,"rocket muzzle loading conserves ammo");
    self.advr_main=world;r=ADVR_Record(IT_AXE);r.advr_kind=ADVR_CROSSBOW;r.wi_clip=0;r.advr_mag_absent=1;self.advr_main=r;self.advr_bolts=12;
    self.advr_round_guard[0]=0;ADVR_ManualTake(0);ADVR_ManualInsert(0);
    ADVR_Assert(r.wi_clip==1 && self.advr_bolts==11,"crossbow manually loads one bolt from hidden reserve");
    r.advr_reload_until=0;ADVR_ManualEject(1);p=find(world,classname,"advr_reload_round");
    self.advr_round_guard[0]=0;ADVR_ManualCatch(p,0);ADVR_ManualRefund();
    ADVR_Assert(self.advr_bolts==12 && r.wi_clip==0,"crossbow unload returns bolt without normal ammo mutation");
    self.advr_main=world;self.ammo_cells=80;r=ADVR_Record(IT_LIGHTNING);r.advr_kind=ADVR_PLASMA;r.wi_clip=0;r.advr_mag_absent=1;self.advr_main=r;
    self.advr_round_guard[0]=0;ADVR_ManualTake(0);ADVR_Assert(self.advr_round[0].advr_round_count==24,"plasma uses its own capacity");
    cvar_set("vr_reload_mode","2");ADVR_ManualFrame();ADVR_Assert(self.ammo_cells==80 && !self.advr_round[0],"mode switch refunds held ammo");
    cvar_set("vr_reload_mode","3");r.advr_kind=0;r.wi_clip=0;r.advr_mag_absent=1;self.advr_round_guard[0]=0;ADVR_ManualTake(0);
    ADVR_Assert(self.advr_round[0].advr_round_count==36,"thunderbolt keeps 36-cell capacity");
    r.advr_kind=ADVR_PLASMA;ADVR_ManualInsert(0);
    ADVR_Assert(r.wi_clip==24 && self.advr_round[0].advr_round_count==12 && self.ammo_cells==68,"smaller plasma cell port keeps excess in the hand");
    SetChangeParms();ADVR_Assert(self.ammo_cells==80 && parm7==80 && !self.advr_round[0],"held ammo refunded before AD snapshots map-transition totals");
    self.advr_main=world;self.ammo_shells=40;r=ADVR_Record(IT_SUPER_SHOTGUN);r.advr_kind=ADVR_WIDOWMAKER;r.wi_clip=0;r.advr_mag_absent=1;self.advr_main=r;
    self.advr_round_guard[0]=0;ADVR_ManualTake(0);p=self.advr_round[0];
    ADVR_Assert(p.advr_round_count==24 && p.advr_round_kind==ADVR_WIDOWMAKER,"Widowmaker pouch gives 24-shell magazine");
    r.advr_kind=0;r.advr_ssg_open=1;
    ADVR_Assert(!ADVR_ManualInsert(0),"SSG rejects Widowmaker magazine");
    r.advr_kind=ADVR_WIDOWMAKER;ADVR_ManualInsert(0);
    ADVR_Assert(r.wi_clip==24 && self.ammo_shells==40,"Widowmaker magazine conserves all 24 shells");
    r.wi_clip=9;self.ammo_shells=25;r.advr_reload_until=0;ADVR_ManualEject(1);
    p=find(world,classname,"advr_reload_round");self.advr_round_guard[0]=0;ADVR_ManualCatch(p,0);
    ADVR_Assert(p.advr_round_count==9 && p.advr_round_kind==ADVR_WIDOWMAKER,"partly used shell magazine retains nine rounds");
    ADVR_ManualRefund();ADVR_Assert(self.ammo_shells==25,"shell magazine refund conserves ammo");
    r.advr_kind=0;r.wi_clip=0;r.advr_mag_absent=1;r.advr_ssg_open=0;r.advr_ssg_spent=2;r.advr_reload_until=0;r.advr_cooldown=0;
    self.advr_round_guard[0]=0;ADVR_ManualTake(0);
    ADVR_Assert(!ADVR_ManualInsert(0),"closed SSG rejects loading");
    ADVR_SsgToggle(1);ADVR_Assert(r.advr_ssg_open && !r.advr_ssg_spent,"breaking open ejects spent shells without creating ammo");
    r.advr_reload_until=0;ADVR_ManualInsert(0);
    ADVR_Assert(r.wi_clip==2 && r.advr_ssg_open,"SSG stays open after loading both barrels");
    r.advr_reload_until=r.advr_cooldown=0;ADVR_SsgToggle(1);ADVR_Assert(!r.advr_ssg_open && r.wi_clip==2,"closing keeps two live shells");
    ADVR_ManualRefund();r=self.advr_main=ADVR_Record(IT_NAILGUN);self.advr_off=world;r.wi_clip=0;r.advr_mag_absent=0;r.advr_reload_until=0;
    self.ammo_nails=60;self.advr_round_guard[0]=0;ADVR_ManualTake(0);
    ADVR_Assert(!ADVR_ManualInsert(0),"empty installed magazine blocks replacement");
    ADVR_ManualEject(1);ADVR_Assert(r.advr_mag_absent && r.wi_clip==0,"manual eject removes empty magazine");
    r.advr_reload_until=0;ADVR_Assert(ADVR_ManualInsert(0)>0 && !r.advr_mag_absent,"fresh magazine seats after eject");
    r.wi_clip=0;r.advr_cooldown=r.advr_reload_until=r.advr_dry_next=0;self.button0=1;self.advr_fg_rearm[1]=0;
    ADVR_Fire(1);ADVR_Assert(r.advr_dry_next>time && !r.advr_mag_absent,"dry fire clicks without ejecting");self.button0=0;
    ADVR_Reset();cvar_set("vr_reload_mode",ftos(mode));bprint("ADVR MANUAL RELOAD PASS\n");
};

void() ADVR_TestManualView = {
    ADVR_Reset();self.advr_initialized=1;self.health=100;self.flags=self.flags | FL_GODMODE;
    cvar_set("vr_reload_mode","3");self.items=IT_NAILGUN;self.moditems=0;self.ammo_nails=100;
    self.advr_main=ADVR_Record(IT_NAILGUN);self.advr_main.wi_clip=0;
    ADVR_ManualTake(0);ADVR_Sync();
};
void() ADVR_TestManualInput = {
    ADVR_TestManualView();ADVR_ManualRefund();
    self.advr_round_guard[0]=0;ADVR_Sync();
};
void() ADVR_TestManualCheck = {
    dprint("MANUAL INPUT clip=");dprint(ftos(self.advr_main.wi_clip));dprint(" ammo=");dprint(ftos(self.ammo_nails));
    dprint(" hand=");dprint(ftos(self.advr_round[0].advr_round_count));dprint(" port=");dprint(vtos(self.loadportpos));dprint("\n");
    ADVR_Assert(self.advr_main.wi_clip==24 && self.ammo_nails==100 && !self.advr_round[0],"controller pouch-to-port reload");
    bprint("ADVR MANUAL INPUT PASS\n");
};
void() ADVR_TestManualEjectCheck = {
    local entity p;local float n;
    p=find(world,classname,"advr_reload_round");
    while(p){if(p.advr_round_type==2)n=n+p.advr_round_count;p=find(p,classname,"advr_reload_round");}
    ADVR_Assert(self.advr_main.wi_clip==0 && self.ammo_nails==76 && n==24,"secondary button ejects physical magazine");
    bprint("ADVR MANUAL EJECT INPUT PASS\n");
};

// Mock-controller fixtures: the tests act through the real pouch/port/button path.
void() ADVR_TestSsgInput = {
    ADVR_Reset();self.advr_initialized=1;self.health=100;self.flags=self.flags | FL_GODMODE;
    cvar_set("vr_reload_mode","3");self.items=IT_SUPER_SHOTGUN;self.moditems=0;self.ammo_shells=30;
    self.advr_main=ADVR_Record(IT_SUPER_SHOTGUN);self.advr_main.wi_clip=0;
    self.advr_main.advr_ssg_spent=2;self.advr_round_guard[0]=0;ADVR_Sync();
};
void() ADVR_TestSsgOpenCheck = {
    ADVR_Assert(self.advr_main.advr_ssg_open && !self.advr_main.advr_ssg_spent,"button opens breech and ejects spent shells");
    bprint("ADVR SSG OPEN INPUT PASS\n");
};
void() ADVR_TestSsgLoadedCheck = {
    local entity r;local float n;
    r=self.advr_main;n=self.ammo_shells;
    ADVR_Assert(r.advr_ssg_open && r.wi_clip==2 && n==30,"open breech accepts pair at rendered load point");
    self.advr_fg_rearm[1]=0;self.button0=1;r.advr_cooldown=r.advr_reload_until=0;ADVR_Fire(1);self.button0=0;
    ADVR_Assert(r.wi_clip==2 && self.ammo_shells==n,"open loaded SSG cannot fire");
    bprint("ADVR SSG LOAD INPUT PASS\n");
};
void() ADVR_TestSsgClosedCheck = {
    ADVR_Assert(!self.advr_main.advr_ssg_open && self.advr_main.wi_clip==2,"flick closes loaded breech");
    bprint("ADVR SSG CLOSE INPUT PASS\n");
};
void() ADVR_TestWidowInput = {
    ADVR_TestSsgInput();self.advr_main.advr_kind=ADVR_WIDOWMAKER;self.advr_main.advr_ssg_spent=0;
    self.ammo_shells=60;ADVR_Sync();
};
void() ADVR_TestWidowLoadCheck = {
    ADVR_Assert(self.advr_main.wi_clip==24 && self.ammo_shells==60 && !self.advr_round[0],"Widowmaker pouch-to-port magazine reload");
    bprint("ADVR WIDOW MAG INPUT PASS\n");
};

void() ADVR_TestManualRelease = {
    local float mode,gripmode,h,k,w,before;local entity r,p;
    mode=cvar("vr_reload_mode");gripmode=cvar("vr_weapon_grip_mode");cvar_set("vr_reload_mode","3");
    for(h=0;h<2;h=h+1)for(k=0;k<2;k=k+1)for(w=0;w<2;w=w+1){
        ADVR_Reset();self.advr_initialized=1;self.health=100;self.ammo_shells=self.ammo_nails=80;
        self.vrbits0=16384;cvar_set("vr_weapon_grip_mode",ftos(k));
        r=ADVR_Record(IT_SHOTGUN);if(w)r.advr_weapon=IT_NAILGUN;r.wi_clip=0;r.advr_mag_absent=1;
        if(h)self.advr_off=r;else self.advr_main=r;
        self.handpos='40 20 50';self.offhandpos='-40 20 50';self.ammopouchpos='0 0 0';
        self.loadportpos=self.offloadportpos='0 100 50';self.advr_round_guard[h]=0;
        if(h)self.vrbits0=self.vrbits0|8;else self.vrbits0=self.vrbits0|2;
        ADVR_ManualTake(h);p=self.advr_round[h];ADVR_Assert(p!=world,"take release fixture ammo");
        self.vrbits0=16384;ADVR_ManualFrame();
        if(k){
            ADVR_Assert(self.advr_round[h]==p,"sticky initial release keeps ammo");
            // PREV can already be set by a prior server move; local edges still release.
            if(h)self.vrbits0=16384|8|16;else self.vrbits0=16384|2|4;
            ADVR_ManualFrame();
        }
        dprint(sprintf("RELEASE h=%g mode=%g mag=%g held=%g holder=%g movetype=%g oldgrip=%g\n",h,k,w,self.advr_round[h]!=world,p.advr_round_holder!=world,p.movetype,self.advr_round_grip[h]));
        ADVR_Assert(!self.advr_round[h] && !p.advr_round_holder && p.movetype==MOVETYPE_BOUNCE,"both grip modes drop held shells and magazines");
        ADVR_GripFrame(h);ADVR_Assert(!self.advr_round[h],"release cannot immediately recatch ammunition");
        self.advr_round_guard[h]=0;self.vrbits0=16384;
        if(!k){if(h)self.vrbits0=self.vrbits0|8;else self.vrbits0=self.vrbits0|2;}
        ADVR_ManualCatch(p,h);self.ammopouchpos=ADVR_Pos(h);
        if(k){if(h)self.vrbits0=self.vrbits0|8;else self.vrbits0=self.vrbits0|2;}else self.vrbits0=16384;
        ADVR_ManualFrame();ADVR_Assert(!self.advr_round[h] && ADVR_Ammo(r.advr_weapon)==80,"regrab and release at pouch refunds exactly once");
    }
    ADVR_Reset();cvar_set("vr_reload_mode",ftos(mode));cvar_set("vr_weapon_grip_mode",ftos(gripmode));
    bprint("ADVR AMMO RELEASE PASS\n");
};

void() ADVR_TestReloadBolt = {
    ADVR_TestSsgInput();self.advr_main.advr_weapon=IT_AXE;self.advr_main.advr_kind=ADVR_CROSSBOW;
    self.advr_bolts=12;ADVR_ManualTake(0);ADVR_Sync();
    ADVR_Assert(self.advr_round[0].model=="progs/advr_reload_bolt.mdl" && !self.advr_round[0].effects && !self.advr_round[0].vr_rigid,"plain held bolt has no projectile glow or physics");
    bprint("ADVR RELOAD BOLT PASS\n");
};
void() ADVR_TestReloadShells = {
    ADVR_TestSsgInput();ADVR_ManualTake(0);ADVR_Sync();
    ADVR_Assert(self.advr_round[0].advr_round_count==2 && self.advr_round[0].solid==SOLID_NOT && !self.advr_round[0].vr_rigid,"held pair is not a solid physics body");
    bprint("ADVR RELOAD SHELLS PASS\n");
};
void() ADVR_TestReloadSnail = {
    ADVR_TestManualInput();self.advr_main.advr_weapon=IT_SUPER_NAILGUN;self.advr_main.wi_clip=36;ADVR_Sync();
};

void() ADVR_TestClassicView = {
    local float i,w;local entity p;local vector org,forward,right,up;
    makevectors(self.v_viewangle);forward=v_forward;right=v_right;up=v_up;org=self.headpos;
    for(i=0;i<6;i=i+1){
        w=IT_SHOTGUN;if(i==1)w=IT_NAILGUN;if(i==2)w=IT_SUPER_NAILGUN;if(i==3)w=IT_GRENADE_LAUNCHER;if(i==4)w=IT_ROCKET_LAUNCHER;if(i==5)w=IT_LIGHTNING;
        p=spawn();p.classname="advr_model_preview";setmodel(p,ADVR_Model(w,0));
        setorigin(p,org+forward*100+right*((i-3*floor(i/3)-1)*44)+up*(12-floor(i/3)*24));
        p.angles='0 0 0';p.angles_y=self.v_viewangle_y+90;p.solid=SOLID_NOT;
    }
    dprint("ADVR CLASSIC VIEW READY\n");
};

void() ADVR_TestChargeInput = {
    ADVR_TestManualInput();self.advr_main.wi_clip=24;self.advr_main.advr_mag_absent=0;self.advr_main.advr_needs_charge=1;
    self.advr_round_guard[0]=0;ADVR_Sync();
};
// Developer-only grip preview: temp1 is the weapon item bit (1..64).
void() ADVR_TestGripView = {
    local float w;
    w=cvar("temp1");
    if(w!=1 && w!=2 && w!=4 && w!=8 && w!=16 && w!=32 && w!=64)return;
    ADVR_TestManualInput();self.advr_main.advr_weapon=w;
    self.advr_main.wi_clip=24;self.advr_main.advr_mag_absent=0;
    self.advr_main.advr_needs_charge=0;ADVR_Sync();
};
void() ADVR_TestChargeInputCheck = {
    dprint("CHARGE DETAIL main=");dprint(ftos(self.advr_main.advr_weapon));dprint(" clip=");dprint(ftos(self.advr_main.wi_clip));dprint(" held=");dprint(ftos(self.advr_charge_record[0]!=world));dprint("\n");
    dprint("CHARGE INPUT pending=");dprint(ftos(self.advr_main.advr_needs_charge));dprint(" rail=");dprint(vtos(self.chargehome));dprint(" to ");dprint(vtos(self.chargeback));dprint("\n");
    ADVR_Assert(!self.advr_main.advr_needs_charge && self.advr_main.wi_clip==24 && !self.advr_charge_record[0],"rendered rail and controller input cock actual gun");
    dprint("ADVR CHARGE INPUT PASS\n");
};

// Real controller fixture for the restored shotgun's generated receiver port.
void() ADVR_TestShotInput = {
    ADVR_TestSsgInput();self.items=IT_SHOTGUN;
    self.advr_main.advr_weapon=IT_SHOTGUN;self.advr_main.advr_ssg_spent=0;
    ADVR_Sync();
};
void() ADVR_TestShotCheck = {
    dprint(sprintf("SHOT INPUT clip=%g ammo=%g held=%g port=%v hand=%v\n",self.advr_main.wi_clip,self.ammo_shells,self.advr_round[0]!=world,self.loadportpos,self.offhandpos));
    ADVR_Assert(self.advr_main.wi_clip==1 && self.ammo_shells==30 && !self.advr_round[0],"shotgun pouch-to-rendered-receiver shell insertion");
    bprint("ADVR SHOT INPUT PASS\n");
};
