// Only surviving whole-body corpses are handed to Box3D. AD owns dying,
// overkill, drops, boss events, corpse chopping, fading and temporary knockdowns.
void() ADVR_CorpseReady = {
    if(self.gibbed || self.health>0 || !(self.flags & FL_MONSTER))return;
    if(!canragdoll(self))return;
    self.vr_ragdoll_noblood=0;
    if(self.classgroup==CG_ROBOT || self.gibtype!=GIBTYPE_BLOOD || self.poisonous ||
       (self.bleedcolour && self.bleedcolour!=MON_BCOLOR_RED))self.vr_ragdoll_noblood=1;
    if(self.vr_corpse!=2)self.advr_corpse_since=time;
    self.vr_corpse=2;
    self.solid=5; // nonsolid to actors, touchable by the engine's physical shapes
    self.movetype=MOVETYPE_TOSS;
    self.advr_corpse_push=1;
};

// Engine callback when the active-body budget is full. Match base QuakeVR's
// oldest-corpse replacement, without killing live creatures or replaying deaths.
float(entity incoming) VR_Knockdown_MakeRoom = {
    local entity e,oldest;
    local float count,most,guard;
    most=floor(cvar("vr_ragdoll_max"));if(most<1)return 0;
    guard=0;
    while(guard<64) {
        count=0;oldest=world;e=nextent(world);
        while(e) {
            if(e!=incoming && isragdoll(e)) {
                count=count+1;
                if(e.health<=0 && e.vr_corpse==2) {
                    if(!oldest || e.advr_corpse_since<oldest.advr_corpse_since)oldest=e;
                }
            }
            e=nextent(e);
        }
        if(count<most)return 1;
        if(!oldest)return 0;
        oldest.bodyonflr="";remove(oldest);guard=guard+1;
    }
    return 0;
};

void() ADVR_CorpseUpdate = {
    // Also enables existing saved AD corpses when the user turns ragdolls on.
    if(!self.gibbed && self.health<=0 && self.vr_corpse!=2)ADVR_CorpseReady();
    if(self.advr_corpse_push && isragdoll(self)) {
        self.advr_corpse_push=0;
        if(vlen(self.advr_death_velocity)>1)
            physicspush(self,self.origin,normalize(self.advr_death_velocity)*min(180,vlen(self.advr_death_velocity)));
    }
};
