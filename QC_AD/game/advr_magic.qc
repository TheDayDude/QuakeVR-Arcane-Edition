// Tome magic: one free hand, physical grip charge, release with a deliberate throw.
float(entity r) ADVR_IsTome = {return r && r.advr_kind==ADVR_TOME;};
void(entity player) ADVR_TomePickup = {
    if(player.advr_mana_seen)return;
    player.advr_mana_seen=1;player.mana=min(9999,player.mana+30);
};
void(entity victim,entity killer) ADVR_ManaReward = {
    local float amount,c;
    if(QVR_AD_API!=1 || victim.advr_mana_paid || !(victim.flags & FL_MONSTER))return;
    victim.advr_mana_paid=1;
    if(!(killer.flags & FL_CLIENT) || killer==victim)return;
    c=victim.classtype;amount=1;
    if(c==CT_MONWIZARD || c==CT_MONSKULLW || c==CT_MONSHAM || c==CT_MONSHAL || c==CT_MONMINOTAUR)amount=10;
    killer.mana=min(9999,max(0,killer.mana)+amount);
};
void() ADVR_MagicClear = {
    if(self.advr_magic_fx){remove(self.advr_magic_fx);self.advr_magic_fx=world;}
    self.advr_magic_book=world;self.advr_magic_charge=0;self.advr_magic_peak='0 0 0';self.advr_magic_peak_time=0;
};
void() ADVR_MagicGlowThink = {
    if(!self.owner || self.owner.health<=0 || self.owner.advr_magic_fx!=self) {
        if(self.owner && self.owner.advr_magic_fx==self)self.owner.advr_magic_fx=world;
        remove(self);return;
    }
    self.angles_y=self.angles_y+15;
    self.nextthink=time+0.05;
};
float(float h) ADVR_MagicBlocked = {
    if(ragdollheld(self,h)>0 || ADVR_Hand(h) || ADVR_Holster(h)>=0 || weaponanygrip(self,h)>0 || ADVR_FGPulled(h))return 1;
    if(h){if(self.vrbits0 & 262144)return 1;if(self.mainhand_hotspot==7)return 1;}
    else {if(self.vrbits0 & 131072)return 1;if(self.offhand_hotspot==7)return 1;}
    return 0;
};
void() ADVR_MagicFrame = {
    local entity book,fx;local float h,grip,old,speed;local vector at,head,vel,w,f,turn,dir;
    if(self.health<=0 || intermission_running || cinematic_running || !ADVR_Tracked()) {ADVR_MagicClear();return;}
    h=-1;
    if(ADVR_IsTome(self.advr_main) && !self.advr_off){h=0;book=self.advr_main;}
    else if(ADVR_IsTome(self.advr_off) && !self.advr_main){h=1;book=self.advr_off;}
    if(h<0){ADVR_MagicClear();return;}
    if(ADVR_MagicBlocked(h)){ADVR_MagicClear();return;}
    grip=ADVR_Grip(h);old=ADVR_OldGrip(h);
    if(self.advr_magic_book && (self.advr_magic_book!=book || self.advr_magic_hand!=h)){ADVR_MagicClear();return;}
    if(!self.advr_magic_book) {
        if(!grip || old || self.mana<1)return;
        self.advr_magic_book=book;self.advr_magic_hand=h;
        ADVR_FGSet(h,world,0);
    }
    at=ADVR_Pos(h);head=ADVR_Head(self);
    // Never create or cast a flame through a wall or far outside the tracked reach.
    if(vlen(at-head)>100){ADVR_MagicClear();return;}
    traceline(head,at,TRUE,self);if(trace_fraction<1 || pointcontents(at)==CONTENT_SOLID){ADVR_MagicClear();return;}
    if(h){vel=self.handvel;w=self.handavel;}else{vel=self.offhandvel;w=self.offhandavel;}
    makevectors(ADVR_Angles(h));f=v_forward;
    turn_x=w_y*f_z-w_z*f_y;turn_y=w_z*f_x-w_x*f_z;turn_z=w_x*f_y-w_y*f_x;
    vel=vel+turn*0.18;speed=vlen(vel);
    // Keep a brief peak so controller release latency does not eat a natural flick.
    if(speed>=0.8) {
        if(time-self.advr_magic_peak_time>0.12 || speed>=vlen(self.advr_magic_peak)) {
            self.advr_magic_peak=vel;self.advr_magic_peak_time=time;
        }
    }
    if(!grip) {
        if(old && self.advr_magic_charge>=0.65 && self.mana>=1 && time-self.advr_magic_peak_time<=0.12 && vlen(self.advr_magic_peak)>=0.8) {
            dir=normalize(self.advr_magic_peak);traceline(at,at+dir*6,TRUE,self);
            if(trace_fraction==1 && pointcontents(trace_endpos)!=CONTENT_SOLID) {
                at=trace_endpos;newmis=world;
                Launch_Missile(at,dir,'0 0 0',CT_PROJ_FIRETOP,750);
                if(newmis) {
                    newmis.advr_fireball=1;newmis.poisonous=0;
                    self.mana=self.mana-1;
                    sound(self,CHAN_WEAPON,"skullwiz/attack.wav",1,ATTN_NORM);
                    haptic(h,0,0.12,85,0.6);
                }
            }
        }
        ADVR_MagicClear();return;
    }
    self.advr_magic_charge=min(1,self.advr_magic_charge+bound(0,frametime,0.05));
    if(!self.advr_magic_fx) {
        fx=spawn();fx.classname="advr_magic_charge";fx.owner=self;fx.solid=SOLID_NOT;fx.movetype=MOVETYPE_NONE;
        setmodel(fx,"progs/advr_magic_charge.mdl");fx.effects=EF_DIMLIGHT;fx.think=ADVR_MagicGlowThink;fx.nextthink=time+0.05;
        self.advr_magic_fx=fx;
    }
    setorigin(self.advr_magic_fx,at+'0 0 3');self.advr_magic_fx.alpha=0.2+0.8*self.advr_magic_charge;
    if(time>=self.advr_magic_haptic) {
        self.advr_magic_haptic=time+0.12;haptic(h,0,0.06,65,0.1+0.25*self.advr_magic_charge);
    }
};
