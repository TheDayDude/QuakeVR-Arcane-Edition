// Slipstep destinations are authoritative: no telefrag, wall or hazardous landing.
float(entity e,vector at,float floorcheck) ADVR_SlipFit = {
    local vector foot,corner;local entity hurt;local float i;
    tracebox(at,e.mins,e.maxs,at,FALSE,e);
    if(trace_startsolid || trace_allsolid)return 0;
    foot=at;foot_z=foot_z+e.mins_z+2;
    if(pointcontents(foot)!=CONTENT_EMPTY || pointcontents(at)!=CONTENT_EMPTY)return 0;
    hurt=find(world,classname,"trigger_hurt");
    while(hurt) {
        if(hurt.solid==SOLID_TRIGGER && at_x+e.maxs_x>hurt.absmin_x && at_x+e.mins_x<hurt.absmax_x &&
           at_y+e.maxs_y>hurt.absmin_y && at_y+e.mins_y<hurt.absmax_y &&
           at_z+e.maxs_z>hurt.absmin_z && at_z+e.mins_z<hurt.absmax_z)return 0;
        hurt=find(hurt,classname,"trigger_hurt");
    }
    if(!floorcheck)return 1;
    for(i=0;i<4;i=i+1) {
        corner=foot;if(i & 1)corner_x=corner_x+e.maxs_x-1;else corner_x=corner_x+e.mins_x+1;
        if(i & 2)corner_y=corner_y+e.maxs_y-1;else corner_y=corner_y+e.mins_y+1;
        traceline(corner,corner-'0 0 18',FALSE,e);
        if(trace_fraction==1 || trace_plane_normal_z<0.7 || (trace_ent && trace_ent.solid!=SOLID_BSP))return 0;
    }
    return 1;
};
float(entity e,vector floorpoint) ADVR_SlipLand = {
    local vector at;
    at=floorpoint;at_z=at_z-e.mins_z+1;
    if(!ADVR_SlipFit(e,at,1))return 0;
    advr_slip_landing=at;return 1;
};
void() ADVR_SlipMarkerThink = {
    if(!self.owner || self.owner.health<=0 || self.owner.advr_slip_marker!=self || !self.owner.advr_magic_book) {
        if(self.owner && self.owner.advr_slip_marker==self)self.owner.advr_slip_marker=world;
        remove(self);return;
    }
    self.nextthink=time+0.05;
};
void(float h) ADVR_SlipPreview = {
    local vector at,next,vel,hit;local float i,found,valid;local entity marker;
    self.advr_slip_valid=0;makevectors(ADVR_Angles(h));at=ADVR_Pos(h);vel=v_forward*350+'0 0 120';
    for(i=0;i<32;i=i+1) {
        next=at+vel*0.04;vel_z=vel_z-24;
        if(vlen(next-self.origin)>256)break;
        traceline(at,next,FALSE,self);
        if(trace_fraction<1) {
            hit=trace_endpos;found=1;
            if(!trace_startsolid && trace_plane_normal_z>=0.7 && (!trace_ent || trace_ent.solid==SOLID_BSP) &&
               vlen(hit-self.origin)>24 && ADVR_SlipLand(self,hit)) {
                valid=1;self.advr_slip_valid=1;self.advr_slip_target=advr_slip_landing;
            }
            break;
        }
        at=next;
    }
    if(!found){if(self.advr_slip_marker){remove(self.advr_slip_marker);self.advr_slip_marker=world;}return;}
    marker=self.advr_slip_marker;
    if(!marker){marker=spawn();marker.classname="advr_slip_marker";marker.owner=self;marker.solid=SOLID_NOT;setmodel(marker,"progs/advr_slip_marker.mdl");self.advr_slip_marker=marker;marker.think=ADVR_SlipMarkerThink;marker.nextthink=time+0.05;}
    setorigin(marker,hit+'0 0 1');marker.alpha=0.65;marker.advr_enchant_type=1;if(valid)marker.advr_enchant_type=8;
    marker.advr_enchant_until=time+1;
};
float(float h) ADVR_SlipCast = {
    local vector at,delta;
    ADVR_SlipPreview(h); // Recheck on release: a monster or moving door may have arrived.
    if(!self.advr_slip_valid || ADVR_Mana()<1){haptic(h,0,0.08,40,0.2);return 0;}
    at=self.advr_slip_target;delta=at-self.origin;
    sound(self,CHAN_AUTO,"misc/r_tele1.wav",0.65,ATTN_NORM);particle(self.origin,'0 0 30',224,24);
    ADVR_SpendMana(1);self.velocity='0 0 0';self.oldorigin=at;self.teleport_time=time+0.3;self.carry_teleported=time+0.3;
    self.headpos=self.headpos+delta;self.handpos=self.handpos+delta;self.offhandpos=self.offhandpos+delta;
    self.muzzlepos=self.muzzlepos+delta;self.offmuzzlepos=self.offmuzzlepos+delta;
    setorigin(self,at);particle(at,'0 0 30',224,24);haptic(h,0,0.12,110,0.5);return 1;
};
void() ADVR_SlipEnemyThink = {
    local entity v;local vector away,at,floorpoint;local float valid;
    v=self.enemy;
    if(v && v.advr_slip_pending==self) {
        v.advr_slip_pending=world;
        if(ADVR_VoidEligible(v) && self.owner) {
            away=v.origin-self.owner.origin;away_z=0;
            if(vlen(away)>0.01) {
                at=v.origin+normalize(away)*24;
                tracebox(v.origin,v.mins,v.maxs,at,FALSE,v);
                if(!trace_startsolid && !trace_allsolid && trace_fraction==1) {
                    if(v.flags & FL_FLY)valid=ADVR_SlipFit(v,at,0);
                    else {
                        traceline(at+'0 0 16',at-'0 0 64',FALSE,v);floorpoint=trace_endpos;
                        if(trace_fraction<1 && trace_plane_normal_z>=0.7 && (!trace_ent || trace_ent.solid==SOLID_BSP) && ADVR_SlipLand(v,floorpoint)) {
                            at=advr_slip_landing;if(fabs(at_z-v.origin_z)<=18)valid=1;
                        }
                    }
                    if(valid){sound(v,CHAN_AUTO,"misc/r_tele1.wav",0.6,ATTN_NORM);particle(v.origin,'0 0 30',224,16);setorigin(v,at);v.oldorigin=at;particle(at,'0 0 30',224,16);}
                }
            }
        }
    }
    remove(self);
};
void(entity target,entity attacker) ADVR_SlipHit = {
    local entity job;
    if(!ADVR_VoidEligible(target) || target.advr_slip_pending || target.advr_slip_next>time)return;
    target.advr_slip_next=time+0.5;
    job=spawn();job.classname="advr_slip_enemy";job.owner=attacker;job.enemy=target;
    target.advr_slip_pending=job;job.think=ADVR_SlipEnemyThink;job.nextthink=time+0.01;
};

