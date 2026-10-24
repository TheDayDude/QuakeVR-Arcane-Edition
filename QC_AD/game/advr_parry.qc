// Weapon guards and swept projectile batting adapted from QuakeVR combat.qc,
// vr_melee.qc and vr_juice.qc. AD keeps its native attack and projectile callbacks.
vector advr_guard_a,advr_guard_b,advr_guard_at;
float advr_parries,advr_deflections;
void() ADVR_BeginMelee = {self.advr_melee_begun=time;self.th_melee();};

float() ADVR_Meters = {return 26.246719*max(0.01,cvar("vr_world_scale"));};
vector(entity p) ADVR_Head = {if(p.headpos!='0 0 0')return p.headpos;return p.origin+p.view_ofs;};
float(float h) ADVR_TwoHands = {return (self.vrbits0 & 32)!=0 && !ADVR_Hand(1-h);};
float() ADVR_StaminaMax = {return max(1,cvar("vr_parry_stamina_max"));};

// self is the defending player. Use the engine's calibrated muzzle/tip position.
float(float h) ADVR_GuardLine = {
    local vector pos,tip;
    if(ADVR_RuneCrossed()){advr_guard_a=ADVR_Pos(0);advr_guard_b=ADVR_Pos(1);return 1;}
    if(!ADVR_CanParry(ADVR_Hand(h)))return 0;
    pos=ADVR_Pos(h);if(h)tip=self.muzzlepos;else tip=self.offmuzzlepos;
    if(vlen(tip-pos)<2 || vlen(tip-pos)>128) {
        makevectors(ADVR_Angles(h));
        tip=pos+v_forward*24;
        if(ADVR_Hand(h).advr_weapon==IT_AXE)tip=pos+v_forward*28;
        if(ADVR_Hand(h).advr_kind)tip=ADVR_WeaponTip(h);
    }
    advr_guard_a=pos-normalize(tip-pos)*5;
    advr_guard_b=tip;
    return 1;
};

float(vector a,vector b,vector toward) ADVR_GuardAcross = {
    local vector axis,flat,head,side,pt;
    local float len,mu,reach,i,aheadbody,aheadhead,lateral,dz;
    axis=b-a;len=vlen(axis);
    if(len<1 || fabs(axis_z)/len>sin(bound(5,cvar("vr_parry_angle"),89)*0.0174533))return 0;
    flat=axis;flat_z=0;
    if(fabs(normalize(flat)*toward)>0.866)return 0;
    mu=ADVR_Meters();reach=max(0.3,cvar("vr_parry_reach"))*mu;head=ADVR_Head(self);
    side_x=toward_y;side_y=-toward_x;side_z=0;
    if(fabs((a+axis*0.5-(self.origin+head)*0.5)*side)>0.5*mu)return 0;
    for(i=0;i<=4;i=i+1) {
        pt=a+axis*(i*0.25);aheadbody=(pt-self.origin)*toward;aheadhead=(pt-head)*toward;
        lateral=fabs((pt-(self.origin+head)*0.5)*side);dz=(pt_z-head_z)/mu;
        if(max(aheadbody,aheadhead)>0 && min(aheadbody,aheadhead)<reach && lateral<0.9*mu && dz>-1 && dz<0.45) {
            advr_guard_at=pt;return 1;
        }
    }
    return 0;
};
float(float h,vector from,vector toward) ADVR_Guards = {
    local vector aim,helper,pos;
    if(!ADVR_GuardLine(h))return 0;
    aim=from-(advr_guard_a+advr_guard_b)*0.5;aim_z=0;
    if(vlen(aim)>1)aim=normalize(aim);else aim=toward;
    if(normalize(advr_guard_b-advr_guard_a)*aim>cos(bound(0,cvar("vr_parry_muzzle_angle"),90)*0.0174533))return 0;
    if(ADVR_GuardAcross(advr_guard_a,advr_guard_b,toward))return 1;
    if(ADVR_TwoHands(h)) {
        pos=ADVR_Pos(h);helper=ADVR_Pos(1-h);
        return ADVR_GuardAcross(helper-(pos-helper)*0.5,pos+(pos-helper)*0.5,toward);
    }
    return 0;
};

void(float h,vector at,vector away,float quiet) ADVR_ParryFeedback = {
    haptic(h,0,0.3,90,1);handimpact(h,5,away);
    if(ADVR_TwoHands(h)){haptic(1-h,0,0.25,90,0.8);handimpact(1-h,3,away);}
    if(!quiet) {
        sound(self,CHAN_AUTO,"vr/parry.wav",bound(0,cvar("vr_bash_sound"),1),ATTN_NORM);
        particle2(at,away*80+'0 0 40',5,24);
    }
};

// The final successful parry spends the last stamina and knocks the weapon away,
// as in base QuakeVR. Picking it up while exhausted cannot bypass the limit.
void(float h) ADVR_ParrySpend = {
    local float cost,remaining,warn;
    if(ADVR_RuneActive()){self.vr_stamina_used=0;return;}
    if(!cvar("vr_parry_stamina")) {
        if(!ADVR_TwoHands(h) && random()<bound(0,cvar("vr_parry_drop_chance"),1)){ADVR_Drop(h);ADVR_Sync();}
        return;
    }
    cost=max(0,cvar("vr_parry_stamina_cost"));
    if(ADVR_TwoHands(h))cost=max(0,cvar("vr_parry_stamina_cost_2h"));
    self.vr_stamina_used=min(ADVR_StaminaMax(),self.vr_stamina_used+cost);
    self.vr_stamina_time=time;self.vr_stamina_said=0;
    remaining=max(0,ADVR_StaminaMax()-self.vr_stamina_used);warn=bound(0,cvar("vr_parry_stamina_warn"),1);
    if(cost>0 && remaining<=0) {
        if(warn>0){sound(self,CHAN_AUTO,"player/gasp1.wav",warn,ATTN_NORM);haptic(h,0,0.5,30,warn);}
        ADVR_Drop(h);ADVR_Sync();
    } else if(remaining<=max(0,cvar("vr_parry_stamina_cost")) && warn>0) {
        sound(self,CHAN_AUTO,"player/gasp2.wav",warn*0.8,ATTN_NORM);haptic(h,0.32,0.18,30,warn*0.8);
    }
};

// Called only at audited physical melee hit sites. Beams, poison, stomps,
// radius damage and triggers continue through T_Damage without a guard check.
void(entity targ,entity inflictor,entity attacker,float damage,float armor) ADVR_MeleeDamage = {
    local entity saved;
    local vector toward,oldf,oldr,oldu;
    local float h,quiet,cooldown,remaining;
    remaining=ADVR_ShieldDamage(targ,inflictor,attacker,damage,armor);
    if(remaining<damage){if(remaining>0){advr_shield_skip=targ;T_Damage(targ,inflictor,attacker,remaining,armor);}return;}
    saved=self;oldf=v_forward;oldr=v_right;oldu=v_up;self=targ;
    if(targ.classname=="player" && targ.health>0 && ADVR_Tracked() && cvar("vr_parry") &&
       inflictor==attacker && (attacker.flags & FL_MONSTER) && damage>0 &&
       (ADVR_RuneActive() || !cvar("vr_parry_stamina") || self.vr_stamina_used<ADVR_StaminaMax())) {
        toward=attacker.origin-targ.origin;toward_z=0;
        if(vlen(toward)<=150 && vlen(toward)>0) {
            toward=normalize(toward);h=-1;
            if(ADVR_Guards(1,attacker.origin,toward))h=1;
            else if(ADVR_Guards(0,attacker.origin,toward))h=0;
            if(h>=0) {
                cooldown=max(0,cvar("vr_parry_cooldown"));quiet=0;
                if(attacker.advr_parry_player==targ && attacker.advr_parry_last>0 && cooldown>0) {
                    if(time-attacker.advr_parry_last<cooldown)quiet=1;
                    if(cvar("vr_parry_cooldown_attack") && attacker.advr_melee_begun>0 &&
                       time-attacker.advr_melee_begun<2 && attacker.advr_parry_attack==attacker.advr_melee_begun)quiet=1;
                }
                attacker.advr_parry_player=targ;attacker.advr_parry_last=time;
                attacker.advr_parry_attack=attacker.advr_melee_begun;
                ADVR_ParryFeedback(h,advr_guard_at,-toward,quiet);
                if(!quiet){ADVR_ParrySpend(h);advr_parries=advr_parries+1;}
                if(attacker.movetype==MOVETYPE_STEP && !attacker.movetarget) {
                    attacker.velocity=attacker.velocity+toward*(320*max(0,cvar("vr_parry_push_enemy")));
                }
                targ.velocity=targ.velocity-toward*(180*max(0,cvar("vr_parry_push_player")));
                damage=damage*(1-bound(0,cvar("vr_parry_reduction"),1));
            }
        }
    }
    self=saved;v_forward=oldf;v_right=oldr;v_up=oldu;
    if(damage>0)T_Damage(targ,inflictor,attacker,damage,armor);
};

// Closest distance between two finite segments, including parallel/point cases.
float(vector a,vector b,vector c,vector d) ADVR_SegmentDistance = {
    local vector u,v,w;
    local float aa,bb,cc,dd,ee,den,s,t;
    u=b-a;v=d-c;w=a-c;aa=u*u;bb=u*v;cc=v*v;dd=u*w;ee=v*w;
    if(aa<0.001 && cc<0.001)return vlen(a-c);
    if(aa<0.001){s=0;t=bound(0,ee/cc,1);}
    else if(cc<0.001){t=0;s=bound(0,-dd/aa,1);}
    else {
        den=aa*cc-bb*bb;s=0;if(den>0.001)s=bound(0,(bb*ee-cc*dd)/den,1);
        t=(bb*s+ee)/cc;
        if(t<0){t=0;s=bound(0,-dd/aa,1);}else if(t>1){t=1;s=bound(0,(bb-dd)/aa,1);}
    }
    return vlen(w+u*s-v*t);
};

entity(entity e) ADVR_Thrower = {
    if(e.touch==Touch_HomingMissile)return e.oldenemy;
    return e.owner;
};
float(entity e) ADVR_CanDeflect = {
    if(e.advr_deflected || e.touchedvoid || e.solid==SOLID_NOT || e.solid==SOLID_TRIGGER ||
       e.takedamage || !(ADVR_Thrower(e).flags & FL_MONSTER) || e.classtype==CT_PROJ_MEGG)return 0;
    if(e.movetype!=MOVETYPE_FLYMISSILE && e.movetype!=MOVETYPE_FLY && e.movetype!=MOVETYPE_BOUNCE)return 0;
    return e.touch==Touch_Bullet || e.touch==Touch_Projectile || e.touch==Touch_PlasmaProjectile ||
           e.touch==Touch_Missile || e.touch==Touch_HomingMissile || e.touch==Touch_Grenade;
};

// Save swept weapon segments at 40 Hz for the original short batting window.
void(float h) ADVR_TrackBat = {
    local entity r;
    local vector vel;
    local float dt,i,speed,need;
    r=ADVR_Hand(h);if(!r || !ADVR_GuardLine(h))return;
    if(r.advr_guard_player!=self || r.advr_guard_hand!=h) {
        r.advr_guard_time=0;r.advr_bat_slot_time=0;
        for(i=0;i<8;i=i+1)r.advr_bat_time[i]=0;
    }
    r.advr_guard_player=self;r.advr_guard_hand=h;
    dt=time-r.advr_guard_time;
    if(h)vel=self.handvel;else vel=self.offhandvel;
    speed=vlen(vel);vel=vel*ADVR_Meters();
    if(dt>0 && dt<0.1 && vlen(advr_guard_b-r.advr_guard_far)<64 && r.advr_guard_time>0) {
        if(speed>0.3 && vlen((advr_guard_b-r.advr_guard_far)/dt)>vlen(vel))vel=(advr_guard_b-r.advr_guard_far)/dt;
        need=max(0.1,cvar("vr_melee_speed")*max(0,cvar("vr_deflect_speed")));
        if(speed>0.3 && vlen(vel)/ADVR_Meters()>=need && speed<20) {
            i=r.advr_bat_index;
            if(time-r.advr_bat_slot_time>=0.025){i=i+1;if(i>=8)i=0;r.advr_bat_slot_time=time;}
            r.advr_bat_index=i;r.advr_bat_time[i]=time;
            r.advr_bat_near[i]=r.advr_guard_near;r.advr_bat_far[i]=r.advr_guard_far;r.advr_bat_vel[i]=vel;
        }
    } else {
        for(i=0;i<8;i=i+1)r.advr_bat_time[i]=0;
    }
    r.advr_guard_near=advr_guard_a;r.advr_guard_far=advr_guard_b;r.advr_guard_time=time;
};

float(entity e,float h) ADVR_BatProjectile = {
    local entity r,thrower;
    local vector from,to,vel,normal,rel,aim;
    local float i,j,radius,window,hit,step,speed;
    r=ADVR_Hand(h);
    if((!ADVR_CanParry(r) && !ADVR_RuneCrossed()) || !ADVR_CanDeflect(e) || !cvar("vr_deflect") ||
       (!ADVR_RuneActive() && cvar("vr_parry_stamina") && self.vr_stamina_used>=ADVR_StaminaMax()))return 0;
    from=e.origin-e.velocity*min(0.025,frametime);to=e.origin+e.velocity*min(0.05,frametime);
    radius=max(0,cvar("vr_deflect_radius"))+min(16,vlen(e.maxs-e.mins)*0.5);
    window=bound(0,cvar("vr_deflect_window"),0.2);hit=0;
    for(i=0;i<8;i=i+1) {
        if(r.advr_bat_time[i]<=0 || time-r.advr_bat_time[i]>window)continue;
        // Sweep between recorded and current lines as well as along each line.
        for(j=0;j<=4;j=j+1) {
            step=j*0.25;
            if(ADVR_SegmentDistance(from,to,r.advr_bat_near[i]*(1-step)+r.advr_guard_near*step,
               r.advr_bat_far[i]*(1-step)+r.advr_guard_far*step)<=radius) {
                vel=r.advr_bat_vel[i];hit=1;break;
            }
        }
        if(hit)break;
    }
    if(ADVR_RuneCrossed() && ADVR_SegmentDistance(from,to,ADVR_Pos(0),ADVR_Pos(1))<=radius+5){hit=1;vel='0 0 0';}
    if(!hit)return 0;
    // A nearby projectile on the other side of a wall cannot be batted.
    traceline(ADVR_Pos(h),e.origin,TRUE,self);
    if(trace_fraction<1 && trace_ent!=e)return 0;
    thrower=ADVR_Thrower(e);rel=e.velocity-vel;normal=normalize(-rel);
    vel=e.velocity-normal*((1+bound(0,cvar("vr_deflect_bounce"),1))*(rel*normal));
    speed=bound(200,vlen(vel),1600);aim=normalize(thrower.origin+thrower.view_ofs-e.origin);
    if(normalize(vel)*aim>0.8)vel=normalize(vel)*(1-bound(0,cvar("vr_deflect_aim_assist"),1))+aim*bound(0,cvar("vr_deflect_aim_assist"),1);
    e.velocity=normalize(vel)*speed;e.angles=vectoangles(e.velocity);
    e.advr_projectile_payload=thrower.pos2;e.advr_thrower_class=thrower.classtype;
    e.owner=self;e.enemy=thrower;e.advr_deflected=1;e.flags=e.flags-(e.flags & FL_ONGROUND);
    if(e.touch==Touch_HomingMissile)e.oldenemy=self;
    e.attack_speed=speed;e.attack_track=normalize(e.velocity);e.attack_origin=thrower.origin;
    e.finalangle=normalize(e.velocity);e.mangle=e.velocity;
    ADVR_ParryFeedback(h,e.origin,-normalize(e.velocity),0);
    // One paid effort per batting motion, even for a volley of projectiles.
    if(r && (time-r.advr_bat_paid>0.3 || r.advr_bat_paid==0)){r.advr_bat_paid=time;ADVR_ParrySpend(h);}
    advr_deflections=advr_deflections+1;
    return 1;
};

float(entity missile,entity target) ADVR_DeflectTouch = {
    local entity saved,oldent;
    local float caught,oldfrac,oldall,oldstart,olddist,oldopen,oldwater;
    local vector oldf,oldr,oldu,oldend,oldnormal;
    if(target.classname!="player" || target.health<=0 || !(target.vrbits0 & 16384))return 0;
    saved=self;oldf=v_forward;oldr=v_right;oldu=v_up;self=target;
    oldent=trace_ent;oldfrac=trace_fraction;oldall=trace_allsolid;oldstart=trace_startsolid;
    olddist=trace_plane_dist;oldopen=trace_inopen;oldwater=trace_inwater;oldend=trace_endpos;oldnormal=trace_plane_normal;
    caught=ADVR_BatProjectile(missile,1);if(!caught)caught=ADVR_BatProjectile(missile,0);
    self=saved;v_forward=oldf;v_right=oldr;v_up=oldu;
    trace_ent=oldent;trace_fraction=oldfrac;trace_allsolid=oldall;trace_startsolid=oldstart;
    trace_plane_dist=olddist;trace_inopen=oldopen;trace_inwater=oldwater;trace_endpos=oldend;trace_plane_normal=oldnormal;
    return caught;
};

void() ADVR_ParryFrame = {
    local entity e,next;
    local float left,hud;
    if(!cvar("vr_parry_stamina") && !(cvar("vr_climb") && cvar("vr_climb_stamina")))self.vr_stamina_used=0;
    else if(time-self.vr_stamina_time>=max(0,cvar("vr_parry_stamina_delay")))
        self.vr_stamina_used=max(0,self.vr_stamina_used-max(0,cvar("vr_parry_stamina_regen"))*frametime);
    if(ADVR_RuneActive())self.vr_stamina_used=0;
    ADVR_TrackBat(1);ADVR_TrackBat(0);
    if(cvar("vr_deflect") && (ADVR_RuneCrossed() || ADVR_CanParry(self.advr_main) || ADVR_CanParry(self.advr_off))) {
        e=findradius(ADVR_Head(self),192);
        while(e){next=e.chain;if(!ADVR_BatProjectile(e,1))ADVR_BatProjectile(e,0);e=next;}
    }
    hud=0;
    if(cvar("vr_parry_stamina") || (cvar("vr_climb") && cvar("vr_climb_stamina"))) {
        left=max(0,ADVR_StaminaMax()-self.vr_stamina_used);hud=128+min(100,ceil(100*left/ADVR_StaminaMax()));
        if(left>0 && left<=max(0,cvar("vr_parry_stamina_cost")))hud=hud+256;
        if(self.vr_stamina_used>0 && time-self.vr_stamina_time>=max(0,cvar("vr_parry_stamina_delay")))hud=hud+512;
        if(self.vr_climb_drain)hud=hud+65536;
    }
    self.vr_melee_hud=hud;
};
