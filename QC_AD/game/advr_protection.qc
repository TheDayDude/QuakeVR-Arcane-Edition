// Protection keeps temporary armor separate from ordinary pickups and armor type.
// Shields are oriented discs. Only a held weapon and an outside-to-inside hit count.
float(float h) ADVR_ShieldPose = {
    local entity r;local vector head;
    r=ADVR_Hand(h);
    if(!r || ADVR_IsTome(r) || r.advr_enchant_type!=7 || r.advr_enchant_until<=time || r.advr_shield_hp<=0)return 0;
    makevectors(ADVR_Angles(h));advr_shield_normal=v_right;if(!h)advr_shield_normal=-v_right;
    advr_shield_center=ADVR_Pos(h)+v_forward*8+advr_shield_normal*6+v_up*2;
    head=ADVR_Head(self);if(vlen(advr_shield_center-head)>100)return 0;
    traceline(head,advr_shield_center,TRUE,self);return trace_fraction==1;
};
float(vector from,vector to) ADVR_ShieldCross = {
    local float a,b,t;local vector delta;
    a=(from-advr_shield_center)*advr_shield_normal;b=(to-advr_shield_center)*advr_shield_normal;
    if(a<=0 || b>0 || a-b<0.001)return 0;
    t=a/(a-b);advr_shield_point=from+(to-from)*t;delta=advr_shield_point-advr_shield_center;
    return vlen(delta)<=20;
};
void() ADVR_ShieldThink = {
    local entity fx,player,r;local float h,valid;local vector ang;
    fx=self;player=fx.owner;r=fx.weaponinst;h=fx.advr_shield_hand;
    valid=0;
    if(player && player.health>0 && r) {
        self=player;
        if(ADVR_Hand(h)==r && ADVR_ShieldPose(h)) {
            valid=1;setorigin(fx,advr_shield_center);ang=ADVR_Angles(h);ang_x=-ang_x;fx.angles=ang;
            fx.alpha=0.18+0.12*bound(0,r.advr_shield_hp/300,1);
        }
    }
    self=fx;
    if(!valid){if(r && r.advr_shield_fx==fx)r.advr_shield_fx=world;remove(fx);return;}
    self.nextthink=time+0.02;
};
void() ADVR_ProtectionFrame = {
    local float h;local entity r,fx,saved;
    if(self.advr_protection_until<=time)self.advr_protection_armor=0;
    for(h=0;h<2;h=h+1) {
        r=ADVR_Hand(h);
        if(ADVR_ShieldPose(h) && !r.advr_shield_fx) {
            fx=spawn();fx.classname="advr_protection_shield";fx.owner=self;fx.weaponinst=r;fx.advr_shield_hand=h;
            fx.solid=SOLID_NOT;fx.movetype=MOVETYPE_NONE;setmodel(fx,"progs/advr_shield.mdl");
            r.advr_shield_fx=fx;fx.think=ADVR_ShieldThink;saved=self;self=fx;ADVR_ShieldThink();self=saved;
        }
    }
};
float(entity target,entity inflictor,entity attacker,float damage,float kind) ADVR_ShieldDamage = {
    local entity saved,r;local float h,absorbed;local vector from,to,oldf,oldr,oldu;
    if(QVR_AD_API!=1 || !(target.flags & FL_CLIENT) || target.health<=0 || damage<=0 ||
       !(attacker.flags & (FL_MONSTER | FL_CLIENT)) || attacker==target ||
       (kind!=DAMARMOR && kind!=DAMSPLASH))return damage;
    saved=self;oldf=v_forward;oldr=v_right;oldu=v_up;self=target;
    from=modelcentre(attacker);to=target.origin+target.view_ofs*0.5;
    if(inflictor!=attacker && inflictor!=world) {
        from=inflictor.origin;
        if(kind==DAMARMOR && vlen(inflictor.velocity)>1) {
            to=inflictor.origin+normalize(inflictor.velocity)*4;
            from=inflictor.origin-normalize(inflictor.velocity)*128;
        }
    }
    for(h=0;h<2 && damage>0;h=h+1) {
        if(ADVR_ShieldPose(h) && ADVR_ShieldCross(from,to)) {
            r=ADVR_Hand(h);absorbed=min(damage,r.advr_shield_hp);r.advr_shield_hp=r.advr_shield_hp-absorbed;damage=damage-absorbed;
            haptic(h,0,0.08,120,0.4);particle(advr_shield_point,advr_shield_normal*30,111,8);
            sound(self,CHAN_AUTO,"vr/parry.wav",0.35,ATTN_NORM);
            if(r.advr_shield_hp<=0){r.advr_enchant_until=0;sound(self,CHAN_AUTO,"misc/r_tele1.wav",0.5,ATTN_NORM);}
        }
    }
    self=saved;v_forward=oldf;v_right=oldr;v_up=oldu;return damage;
};
