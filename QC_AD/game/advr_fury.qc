// Two physical Fury blades form an X; charge once, then uncross to rearm.
float(entity r) ADVR_IsFury = {return r && (r.advr_kind==ADVR_FURY1 || r.advr_kind==ADVR_FURY2);};
vector advr_fury_cross;
float(vector a,vector b,vector c,vector d) ADVR_FuryCross = {
    local vector u,v,w,p,q;local float aa,bb,cc,dd,ee,den,s,t;
    u=b-a;v=d-c;w=a-c;aa=u*u;bb=u*v;cc=v*v;dd=u*w;ee=v*w;
    if(aa<100 || cc<100 || aa>16384 || cc>16384)return 0;
    if(fabs(normalize(u)*normalize(v))>0.8)return 0;
    den=aa*cc-bb*bb;if(den<1)return 0;
    s=(bb*ee-cc*dd)/den;t=(aa*ee-bb*dd)/den;
    // Cross the blades, not the grips or tips; allow a little tracking tolerance.
    if(s<0.25 || s>0.9 || t<0.25 || t>0.9)return 0;
    p=a+u*s;q=c+v*t;if(vlen(p-q)>5)return 0;
    advr_fury_cross=(p+q)*0.5;return 1;
};
void() ADVR_FuryClear = {
    if(self.advr_fury_glow){remove(self.advr_fury_glow);self.advr_fury_glow=world;}
    self.advr_fury_charge=0;
};
void() ADVR_FuryGlowThink = {
    if(!self.owner || self.owner.health<=0 || self.owner.advr_fury_glow!=self ||
        !ADVR_IsFury(self.owner.advr_main) || !ADVR_IsFury(self.owner.advr_off)) {
        if(self.owner && self.owner.advr_fury_glow==self)self.owner.advr_fury_glow=world;
        remove(self);return;
    }
    self.nextthink=time+0.1;
};
void() ADVR_FuryFrame = {
    local vector a,b,c,d,head,dir,at,side;local entity fx;local float crossed,i;
    if(self.health<=0 || intermission_running || cinematic_running ||
        !ADVR_IsFury(self.advr_main) || !ADVR_IsFury(self.advr_off)) {
        ADVR_FuryClear();self.advr_fury_latched=0;return;
    }
    // Swapping either sword cannot inherit a partially completed charge.
    if(self.advr_fury_main!=self.advr_main || self.advr_fury_off!=self.advr_off) {
        ADVR_FuryClear();self.advr_fury_main=self.advr_main;self.advr_fury_off=self.advr_off;
    }
    a=self.handpos;b=self.muzzlepos;c=self.offhandpos;d=self.offmuzzlepos;
    crossed=ADVR_FuryCross(a,b,c,d);head=ADVR_Head(self);
    makevectors(self.v_angle);dir=v_forward;
    if(crossed) {
        if(vlen(advr_fury_cross-head)>64 || (advr_fury_cross-head)*dir<6)crossed=0;
        traceline(head,advr_fury_cross,TRUE,self);if(trace_fraction<1)crossed=0;
    }
    if(!crossed){ADVR_FuryClear();self.advr_fury_latched=0;return;}
    if(self.advr_fury_latched || time<self.advr_fury_cooldown){ADVR_FuryClear();return;}
    self.advr_fury_charge=self.advr_fury_charge+bound(0,frametime,0.05);
    if(!self.advr_fury_glow) {
        fx=spawn();fx.classname="advr_fury_charge";fx.owner=self;
        fx.solid=SOLID_NOT;fx.movetype=MOVETYPE_NONE;
        setmodel(fx,"progs/advr_fury_charge.mdl");fx.alpha=0.05;fx.effects=EF_DIMLIGHT;
        fx.think=ADVR_FuryGlowThink;fx.nextthink=time+0.1;
        self.advr_fury_glow=fx;
    }
    self.advr_fury_glow.alpha=0.05+0.9*bound(0,self.advr_fury_charge,1);
    setorigin(self.advr_fury_glow,advr_fury_cross);
    if(time>=self.advr_fury_fxnext) {
        self.advr_fury_fxnext=time+0.07;
        haptic(0,0,0.05,65,0.1+self.advr_fury_charge*0.3);
        haptic(1,0,0.05,65,0.1+self.advr_fury_charge*0.3);
    }
    if(self.advr_fury_charge<1)return;
    at=advr_fury_cross+dir*8;traceline(head,at,TRUE,self);
    if(trace_fraction<1){ADVR_FuryClear();return;}
    // Native AD projectile keeps explosion, resistance, damage credit and parry handling.
    // A deterministic fan like the knight's: center and +/-8 degrees. Save the
    // basis because Launch_Missile may change the global direction vectors.
    makevectors(self.v_angle);side=v_right*0.14054;
    for(i=-1;i<=1;i=i+1)
        Launch_Missile(at,normalize(dir+side*i),'100 150 50',CT_PROJ_FURY1,750);
    sound(self,CHAN_WEAPON,"hknight/attack1.wav",1,ATTN_NORM);
    self.advr_fury_latched=1;self.advr_fury_cooldown=time+5;
    ADVR_FuryClear();
};
