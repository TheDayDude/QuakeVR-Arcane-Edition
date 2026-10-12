// AD weapons: trigger selects; a backward/upward flick launches. Grip only catches.
// Publish the original fg fields so the engine renders its beam and outline.
entity(float h) ADVR_FGTarget = {if(h)return self.mainhand_fgtarget;return self.offhand_fgtarget;};
entity(float h) ADVR_FGPulled = {if(h)return self.mainhand_fgpulled;return self.offhand_fgpulled;};
void(float h,entity e,float locked) ADVR_FGSet = {
    if(h){self.mainhand_fgtarget=e;self.mainhand_fglocked=locked;}
    else{self.offhand_fgtarget=e;self.offhand_fglocked=locked;}
};
float(entity e) ADVR_FGEligible = {
    if(e==world || e.fg_state || !e.model || e.solid==SOLID_NOT)return 0;
    if(e.classname=="advr_dropped_weapon")return e.weaponinst!=world;
    return !deathmatch && !coop && e.touch==item_touch && e.touch2==weapon_touch && (e.flags & FL_ITEM) && !(e.estate & ESTATE_BLOCK) && e.attack_finished<=time;
};
float(float h,entity e) ADVR_FGVisible = {
    local vector pos,at;pos=ADVR_Pos(h);at=modelcentre(e);
    if(vlen(at-pos)>max(32,cvar("vr_forcegrab_distance")))return 0;
    traceline(pos,at,TRUE,self);return trace_fraction==1 || trace_ent==e;
};
float(float h,entity e) ADVR_FGFlicked = {
    local vector back,pull,vel,w,f,tip;
    back=ADVR_Pos(h)-modelcentre(e);back_z=0;pull=normalize(normalize(back)+'0 0 1');
    if(h){vel=self.handvel;w=self.handavel;}else{vel=self.offhandvel;w=self.offhandavel;}
    if(vel*pull>=max(0.1,cvar("vr_forcegrab_flick_speed")))return 1;
    makevectors(ADVR_Angles(h));f=v_forward;
    tip_x=w_y*f_z-w_z*f_y;tip_y=w_z*f_x-w_x*f_z;tip_z=w_x*f_y-w_y*f_x;
    return tip*pull*57.29578>=max(1,cvar("vr_forcegrab_flick_turn"));
};
void(entity e) ADVR_FGRestore = {
    local entity player;player=e.fg_player;
    if(player!=world){
        if(e.fg_hand && player.mainhand_fgpulled==e)player.mainhand_fgpulled=world;
        if(!e.fg_hand && player.offhand_fgpulled==e)player.offhand_fgpulled=world;
    }
    e.movetype=e.advr_fg_movetype;e.solid=e.advr_fg_solid;e.think=e.advr_fg_think;
    e.nextthink=0;if(e.think)e.nextthink=max(time+0.02,e.advr_fg_nextthink);
    e.velocity='0 0 0';e.avelocity='0 0 0';e.fg_state=0;e.fg_player=world;
    setorigin(e,e.origin);
};
void() ADVR_FGFlight = {
    local entity e,player,oldother;local float h,remaining;local vector at,pos,flew,turned;
    e=self;player=e.fg_player;h=e.fg_hand;
    if(player==world || player.health<=0){ADVR_FGRestore(e);return;}
    self=player;
    if(ADVR_Hand(h) || !cvar("vr_forcegrab_mode")){ADVR_FGRestore(e);self=e;return;}
    pos=ADVR_Pos(h);at=forcegrabpoint(e);
    if(vlen(pos-at)<max(4,cvar("vr_forcegrab_catch_radius")) && ADVR_Grip(h)){
        flew=e.origin;turned=e.angles;
        ADVR_FGRestore(e);ADVR_FGSet(h,world,0);
        // The selection trigger must be released before the caught gun can fire.
        self.advr_fg_rearm[h]=1;
        if(e.classname=="advr_dropped_weapon")ADVR_Catch(e,h);
        else{
            self.advr_pickup_hand=h+1;oldother=other;self=e;other=player;e.touch();
            self=player;other=oldother;self.advr_pickup_hand=0;
        }
        ADVR_Sync();if(ADVR_Hand(h)){catchblend(h,e,flew,turned);haptic(h,0,0.07,90,0.8);}
        self=e;return;
    }
    remaining=e.advr_fg_arrive-time;
    if(remaining<=0.001){
        ADVR_FGRestore(e);ADVR_FGSet(h,world,0);self=e;return;
    }
    // Reject a newly obstructed path instead of pulling a weapon through a wall.
    traceline(at,pos,TRUE,e);
    if(trace_fraction<1 && trace_ent!=player){ADVR_FGRestore(e);ADVR_FGSet(h,world,0);self=e;return;}
    e.velocity=(pos-at)*(1/remaining);
    e.velocity_z=e.velocity_z+0.5*e.advr_fg_gravity*remaining;
    e.nextthink=time+0.001;self=e;
};
void(float h,entity e) ADVR_FGLaunch = {
    local float dist,flight,arc;local vector at,pos,mid;
    at=forcegrabpoint(e);pos=ADVR_Pos(h);dist=vlen(pos-at);
    flight=max(0.1,cvar("vr_forcegrab_time"))+dist/max(1,cvar("vr_forcegrab_speed"));
    arc=max(0,cvar("vr_forcegrab_arc"))*dist;mid=(at+pos)*0.5;
    traceline(mid,mid+'0 0 1'*(arc+8),TRUE,e);arc=max(0,(arc+8)*trace_fraction-8);
    e.advr_fg_movetype=e.movetype;e.advr_fg_solid=e.solid;e.advr_fg_think=e.think;e.advr_fg_nextthink=e.nextthink;
    e.fg_state=1;e.fg_player=self;e.fg_hand=h;e.advr_fg_arrive=time+flight;e.advr_fg_gravity=8*arc/(flight*flight);
    e.movetype=MOVETYPE_NOCLIP;e.solid=SOLID_NOT;e.flags=e.flags-(e.flags & FL_ONGROUND);
    e.vr_spin='0 0 0';e.avelocity='0 0 0';e.advr_throw_armed=0;e.throwhit=1;
    e.think=ADVR_FGFlight;e.nextthink=time+0.001;setorigin(e,e.origin);
    if(h)self.mainhand_fgpulled=e;else self.offhand_fgpulled=e;
    self.advr_fg_rearm[h]=1;ADVR_FGSet(h,world,0);haptic(h,0,0.12,50,0.6);
};
void(float h) ADVR_ForceGrab = {
    local entity e,best,old;local float trigger,score,dot;local vector pos,dir;
    if(ADVR_HandBusy(h)){ADVR_FGSet(h,world,0);return;}
    if(self.advr_magic_book && self.advr_magic_hand==h){ADVR_FGSet(h,world,0);return;}
    if(h)trigger=self.button0;else trigger=self.button3;
    if(!trigger)self.advr_fg_rearm[h]=0;
    e=ADVR_FGPulled(h);
    if(e && e.fg_state==1 && e.fg_player==self && e.fg_hand==h)return;
    if(h)self.mainhand_fgpulled=world;else self.offhand_fgpulled=world;
    old=ADVR_FGTarget(h);
    if(!cvar("vr_forcegrab_mode") || ADVR_Hand(h) || !trigger || self.advr_fg_rearm[h]){ADVR_FGSet(h,world,0);return;}
    // Use the previous aim target during the flick, even as the wrist turns off it.
    if(ADVR_FGEligible(old) && ADVR_FGVisible(h,old) && ADVR_FGFlicked(h,old)){
        ADVR_FGLaunch(h,old);return;
    }
    pos=ADVR_Pos(h);makevectors(ADVR_Angles(h));dir=v_forward;
    score=cos(bound(1,cvar("vr_forcegrab_cone"),60)*0.01745329);best=world;
    e=findradius(pos,max(32,cvar("vr_forcegrab_distance")));
    while(e){
        if(ADVR_FGEligible(e)){
            dot=normalize(modelcentre(e)-pos)*dir;
            if(dot>score && ADVR_FGVisible(h,e)){score=dot;best=e;}
        }
        e=e.chain;
    }
    ADVR_FGSet(h,best,0);
    if(best && best!=old && cvar("vr_forcegrab_eligible_haptics"))haptic(h,0,0.04,70,0.2);
};
