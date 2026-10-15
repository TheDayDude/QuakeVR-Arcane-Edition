// Tome magic: one free hand, physical grip charge, release with a deliberate throw.
float(entity r) ADVR_IsTome = {return r && (r.advr_kind==ADVR_TOME || r.advr_kind==ADVR_DEBUGTOME);};
void(entity player) ADVR_MagicInit = {
    if(!player.advr_magic_version) {
        // Existing saves already had both spells. Fresh players start with none.
        if(player.advr_mana_seen)player.advr_known=3;
        player.advr_magic_version=1;
    }
    player.advr_mana_max=max(50,player.advr_mana_max);
    player.mana=bound(0,player.mana,player.advr_mana_max);
};
float(entity player,entity book) ADVR_SpellMask = {
    if(!ADVR_IsTome(book))return 0;
    if(book.advr_kind==ADVR_DEBUGTOME)return pow(2,ADVR_SPELL_COUNT)-1;
    return player.advr_known;
};
void(entity player,entity book) ADVR_TomePickup = {
    local float spell,i;
    ADVR_MagicInit(player);
    if(!player.advr_mana_seen){player.advr_mana_seen=1;player.mana=min(player.advr_mana_max,player.mana+30);}
    if(book.advr_kind==ADVR_DEBUGTOME || book.advr_tome_read)return;
    book.advr_tome_read=1;
    spell=floor(random()*ADVR_SPELL_COUNT);
    for(i=0;i<ADVR_SPELL_COUNT;i=i+1) {
        if(!(player.advr_known & pow(2,spell))) {
            player.advr_known=player.advr_known | pow(2,spell);player.advr_spell=spell;
            if(spell==0)sprint(player,"Learned Fireball!\n");else if(spell==1)sprint(player,"Learned Lightning!\n");else sprint(player,"Learned Frostbolt!\n");
            return;
        }
        spell=mod(spell+1,ADVR_SPELL_COUNT);
    }
};
void() ADVR_PowerPickup = {
    if(QVR_AD_API!=1 || self.advr_mana_paid)return;
    self.advr_mana_paid=1;ADVR_MagicInit(other);
    other.advr_mana_max=other.advr_mana_max+10;
    sprint(other,"Arcane Essence capacity increased to ");sprint(other,ftos(other.advr_mana_max));sprint(other,".\n");
};
float() ADVR_MagicMultiplier = {
    local float bit,n;
    for(bit=1;bit<=8;bit=bit*2)if(query_configflag(bit))n=n+1;
    return 1+0.05*n;
};
void(entity victim,entity killer) ADVR_ManaReward = {
    local float amount,c;
    if(QVR_AD_API!=1 || victim.advr_mana_paid || !(victim.flags & FL_MONSTER))return;
    victim.advr_mana_paid=1;
    if(!(killer.flags & FL_CLIENT) || killer==victim)return;
    c=victim.classtype;amount=1;
    if(c==CT_MONWIZARD || c==CT_MONSKULLW || c==CT_MONSHAM || c==CT_MONSHAL || c==CT_MONMINOTAUR)amount=10;
    ADVR_MagicInit(killer);killer.mana=min(killer.advr_mana_max,killer.mana+amount);
};
void() ADVR_MagicClear = {
    if(self.advr_magic_fx){remove(self.advr_magic_fx);self.advr_magic_fx=world;}
    self.advr_magic_book=world;self.advr_magic_charge=0;self.advr_magic_peak='0 0 0';self.advr_magic_peak_time=0;
    self.advr_magic_release_until=0;
    self.advr_magic_ready=0;self.advr_magic_burst=0;self.advr_magic_tick=0;self.advr_magic_haptic=0;
};
// Book-hand trigger selects a spell; holding the trigger never cycles repeatedly.
// Selection is locked during a charge/burst, so the charged spell cannot change.
// Only physical left D-pad buttons are shortcuts. Preserve their saved slots 4..7.
float(float h,float key) ADVR_FavoriteSlot = {
    return key+2;
};
void() ADVR_MagicSelect = {
    local float buttons,h,mask,i,code,key;local entity book;
    buttons=0;if(self.button0)buttons=1;if(self.button3)buttons=buttons+2;
    h=-1;
    if(!self.advr_magic_book && !self.advr_enchant_record) {
        if(ADVR_IsTome(self.advr_main) && self.button0 && !(self.advr_magic_trigger & 1))h=1;
        else if(ADVR_IsTome(self.advr_off) && self.button3 && !(self.advr_magic_trigger & 2))h=0;
        if(h>=0){
            mask=ADVR_SpellMask(self,ADVR_Hand(h));
            for(i=0;i<ADVR_SPELL_COUNT;i=i+1) {
                self.advr_spell=mod(self.advr_spell+1,ADVR_SPELL_COUNT);
                if(mask & pow(2,self.advr_spell))break;
            }
            haptic(h,0,0.05,110,0.35);
        }
    }
    self.advr_magic_trigger=buttons;
    code=self.advr_magic_buttons;h=floor(code/8);key=mod(code,8)-1;
    book=self.advr_off;if(!ADVR_IsTome(book))book=self.advr_main;
    if(self.advr_magic_book || self.advr_enchant_record || !ADVR_IsTome(book) || h!=0 || key<2 || key>5)code=0;
    if(code && (code!=self.advr_fav_button || book!=self.advr_fav_book)) {
        self.advr_fav_button=code;self.advr_fav_book=book;
        self.advr_fav_time=0;self.advr_fav_done=0;self.advr_fav_spell=self.advr_spell;
    }
    if(code) {
        if(self.advr_fav_spell!=self.advr_spell){self.advr_fav_time=0;self.advr_fav_spell=self.advr_spell;}
        self.advr_fav_time=self.advr_fav_time+bound(0,frametime,0.1);
        key=ADVR_FavoriteSlot(h,key);
        if(!self.advr_fav_done && self.advr_fav_time>=2 && (ADVR_SpellMask(self,book) & pow(2,self.advr_spell))) {
            self.advr_favorites[key]=self.advr_spell+1;self.advr_fav_done=1;
            haptic(h,0,0.12,130,0.6);
        }
    } else if(self.advr_fav_button) {
        h=floor(self.advr_fav_button/8);key=mod(self.advr_fav_button,8)-1;
        key=ADVR_FavoriteSlot(h,key);
        i=self.advr_favorites[key]-1;
        if(!self.advr_magic_book && !self.advr_fav_done && self.advr_fav_time<2 &&
            book==self.advr_fav_book && i>=0 && (ADVR_SpellMask(self,book) & pow(2,i))) {
            self.advr_spell=i;haptic(h,0,0.04,110,0.3);
        }
        self.advr_fav_button=0;self.advr_fav_book=world;
    }
};
// A short Thunderbolt burst along the current hand aim, originating at the moving
// casting hand. Reuse AD lightning damage for resistance, reflection and kill credit.
void(vector at,float h) ADVR_MagicBeam = {
    local vector end;local float dt;
    dt=bound(0,frametime,0.05);
    makevectors(ADVR_Angles(h));self.advr_magic_direction=v_forward;
    setorigin(self.advr_magic_fx,at);
    traceline(at,at+self.advr_magic_direction*600,TRUE,self);end=trace_endpos;
    WriteByte(MSG_BROADCAST,SVC_TEMPENTITY);WriteByte(MSG_BROADCAST,TE_LIGHTNING2);
    // A dedicated emitter preserves the server's hand direction. Player-owned
    // gun beams are otherwise redirected to a muzzle and culled for empty hands.
    WriteEntity(MSG_BROADCAST,self.advr_magic_fx);WriteByte(MSG_BROADCAST,h);
    WriteCoord(MSG_BROADCAST,at_x);WriteCoord(MSG_BROADCAST,at_y);WriteCoord(MSG_BROADCAST,at_z);
    WriteCoord(MSG_BROADCAST,end_x);WriteCoord(MSG_BROADCAST,end_y);WriteCoord(MSG_BROADCAST,end_z);
    if(self.advr_magic_tick<=0) {
        PlayerLightningDamage(at,end+self.advr_magic_direction*4,self,20*ADVR_MagicMultiplier());
        self.advr_magic_tick=0.2;
        haptic(h,0,0.06,110,0.35);
    }
    self.advr_magic_tick=self.advr_magic_tick-dt;
    self.advr_magic_burst=self.advr_magic_burst-dt;
    if(self.advr_magic_burst<=0.001)ADVR_MagicClear();
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
// One timestamp per living monster: repeat frost hits refresh, never stack speed loss.
void(entity target) ADVR_FrostHit = {
    if(!(target.flags & FL_MONSTER) || target.health<=0 || !target.takedamage ||
       (target.flags & FL_GODMODE) || target.invincible_finished>time)return;
    target.advr_frost_until=time+4;
};
void() ADVR_FrostTouch = {
    if(other==self.owner)return;
    if(pointcontents(self.origin)==CONTENT_SKY){remove(self);return;}
    if(other.takedamage)T_Damage(other,self,self.owner,30*max(1,self.advr_magic_damage),DAMARMOR);
    particle2(self.origin,'0 0 30',3,16);
    sound(self,CHAN_WEAPON,"weapons/lhit.wav",0.5,ATTN_NORM);
    remove(self);
};
void(vector at,vector direction) ADVR_FrostLaunch = {
    newmis=spawn();newmis.classname="advr_frostbolt";newmis.owner=self;newmis.advr_frostbolt=1;
    newmis.solid=SOLID_BBOX;newmis.movetype=MOVETYPE_FLYMISSILE;
    newmis.velocity=normalize(direction)*750;newmis.angles=vectoangles(newmis.velocity);
    newmis.touch=ADVR_FrostTouch;newmis.think=SUB_Remove;newmis.nextthink=time+5;
    newmis.advr_magic_damage=ADVR_MagicMultiplier();
    setmodel(newmis,"progs/advr_frostbolt.mdl");setsize(newmis,'0 0 0','0 0 0');setorigin(newmis,at);
};

// Pending infusion belongs to a particular book, weapon and controller.
// Releasing, swapping either item or losing tracking cancels without spending.
void() ADVR_EnchantClear = {
    self.advr_enchant_record=world;self.advr_enchant_book=world;self.advr_enchant_charge=0;
    if(self.advr_enchant_fx){remove(self.advr_enchant_fx);self.advr_enchant_fx=world;}
};
void(entity book,float h,float down,float old) ADVR_EnchantFrame = {
    local entity r;
    r=ADVR_Hand(h);
    if(!down || !r || ADVR_IsTome(r) || ADVR_HandBusy(h) || self.mana<5) {ADVR_EnchantClear();return;}
    if(self.advr_enchant_record && (self.advr_enchant_record!=r || self.advr_enchant_book!=book || self.advr_enchant_hand!=h)) {
        ADVR_EnchantClear();return;
    }
    if(!self.advr_enchant_record) {
        if(old || self.advr_enchant_latched)return;
        self.advr_enchant_record=r;self.advr_enchant_book=book;self.advr_enchant_hand=h;
        self.advr_enchant_spell=self.advr_spell;self.advr_magic_haptic=0;
    }
    self.advr_enchant_charge=self.advr_enchant_charge+bound(0,frametime,0.05);
    if(time>=self.advr_magic_haptic){haptic(h,0,0.05,90,0.15+0.25*self.advr_enchant_charge/3);self.advr_magic_haptic=time+0.25;}
    if(self.advr_enchant_charge<3)return;
    r.advr_enchant_type=self.advr_enchant_spell+1;r.advr_enchant_until=time+60;
    r.advr_enchant_scale=ADVR_MagicMultiplier();self.mana=self.mana-5;
    self.advr_enchant_latched=1;
    haptic(h,0,0.12,150,0.7);haptic(h,0.2,0.12,150,0.7);
    sound(self,CHAN_AUTO,"skullwiz/attack.wav",0.45,ATTN_NORM);
    if(r.advr_enchant_type==1)sprint(self,"Fire enchantment: 60 seconds.\n");
    else if(r.advr_enchant_type==2)sprint(self,"Lightning enchantment: 60 seconds.\n");else sprint(self,"Frost enchantment: 60 seconds.\n");
    ADVR_EnchantClear();
};
// Projectile payload is copied at launch, never looked up from the shooter's
// current hand at impact. Burning ticks and unrelated spells have no payload.
void(entity missile) ADVR_EnchantMissile = {
    if(!advr_attack_record || missile.owner!=advr_attack_actor || time>=advr_attack_record.advr_enchant_until)return;
    missile.advr_enchant_type=advr_attack_record.advr_enchant_type;
    missile.advr_enchant_until=advr_attack_record.advr_enchant_until;
    missile.advr_enchant_scale=advr_attack_record.advr_enchant_scale;
};
// Rate-limit attempts as well as successes: pellets and beam ticks must not stunlock.
float(entity target,float roll) ADVR_EnchantStagger = {
    if(!target.th_pain || target.health<=0 || target.bossflag || target.vr_knockdown ||
       target.classgroup==CG_ZOMBIE || time<target.advr_stagger_next)return 0;
    target.advr_stagger_next=time+0.25;
    if(roll>=0.1)return 0;
    target.advr_stagger_next=time+2;
    return 1;
};
float(entity target,entity inflictor,entity attacker,float damage) ADVR_EnchantDamage = {
    local entity r;local float bonus;
    advr_enchant_stagger=0;
    if(QVR_AD_API!=1 || !(attacker.flags & FL_CLIENT) || !(target.flags & FL_MONSTER) || damage<=0)return damage;
    if(inflictor==attacker && attacker==advr_attack_actor)r=advr_attack_record;
    else if(inflictor.classname=="advr_dropped_weapon")r=inflictor.weaponinst;
    else if(inflictor!=attacker)r=inflictor;
    if(!r || !r.advr_enchant_type || time>=r.advr_enchant_until)return damage;
    bonus=damage*0.05*max(1,r.advr_enchant_scale);
    if(r.advr_enchant_type==1) {
        ADVR_Ignite(target,attacker);
        if(target.advr_burn)target.advr_burn.advr_magic_damage=max(1,r.advr_enchant_scale);
    } else if(r.advr_enchant_type==3) {
        ADVR_FrostHit(target);
    } else {
        bonus=Resist_Damage(target,IT_CELLS,bonus);
        if(bonus>0)advr_enchant_stagger=ADVR_EnchantStagger(target,random());
        if(bonus>0 && time>=target.advr_enchant_spark) {
            target.advr_enchant_spark=time+0.15;
            particle2(modelcentre(target),'0 0 30',3,8);
            sound(target,CHAN_AUTO,"weapons/lhit.wav",0.35,ATTN_NORM);
        }
    }
    return damage+max(0,bonus);
};
float(entity r) ADVR_EnchantPack = {
    if(!r || time>=r.advr_enchant_until)return 0;
    return r.advr_enchant_type+ceil(bound(0,r.advr_enchant_until-time,60))*4;
};
void(entity r,float packed) ADVR_EnchantRestore = {
    if(!r || packed<=0)return;
    r.advr_enchant_type=mod(packed,4);r.advr_enchant_until=time+floor(packed/4);
    r.advr_enchant_scale=ADVR_MagicMultiplier();
};

void() ADVR_MagicFrame = {
    local entity book,fx;local float h,grip,old,speed,stick,oldstick,previoussticks;local vector at,head,vel,w,f,turn,dir;
    previoussticks=self.advr_magic_oldsticks;self.advr_magic_oldsticks=self.advr_magic_sticks;
    if(self.health<=0 || intermission_running || cinematic_running || !ADVR_Tracked()) {ADVR_MagicClear();ADVR_EnchantClear();return;}
    ADVR_MagicInit(self);ADVR_MagicSelect();
    h=-1;
    if(ADVR_IsTome(self.advr_main) && !ADVR_IsTome(self.advr_off)){h=0;book=self.advr_main;}
    else if(ADVR_IsTome(self.advr_off) && !ADVR_IsTome(self.advr_main)){h=1;book=self.advr_off;}
    if(h<0){ADVR_MagicClear();ADVR_EnchantClear();return;}
    stick=(self.advr_magic_sticks & pow(2,h))!=0;oldstick=(previoussticks & pow(2,h))!=0;
    if(!stick)self.advr_enchant_latched=0;
    if(!(ADVR_SpellMask(self,book) & pow(2,self.advr_spell))) {
        ADVR_MagicClear();
        if(ADVR_SpellMask(self,book) & 1)self.advr_spell=0;
        else if(ADVR_SpellMask(self,book) & 2)self.advr_spell=1;
        else if(ADVR_SpellMask(self,book) & 4)self.advr_spell=2;
        else return;
    }
    if(ADVR_Hand(h)) {
        if(self.advr_magic_book || self.advr_magic_fx)ADVR_MagicClear();
        ADVR_EnchantFrame(book,h,stick,oldstick);return;
    }
    ADVR_EnchantClear();
    if(ADVR_MagicBlocked(h)){ADVR_MagicClear();return;}
    grip=ADVR_Grip(h);old=ADVR_OldGrip(h);
    if(!self.advr_magic_book)self.advr_magic_control=stick && !oldstick;
    if(self.advr_magic_control){grip=stick;old=oldstick;}
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
    if(self.advr_magic_burst>0){ADVR_MagicBeam(at,h);return;}
    if(h){vel=self.handvel;w=self.handavel;}else{vel=self.offhandvel;w=self.offhandavel;}
    makevectors(ADVR_Angles(h));f=v_forward;
    turn_x=w_y*f_z-w_z*f_y;turn_y=w_z*f_x-w_x*f_z;turn_z=w_x*f_y-w_y*f_x;
    vel=vel+turn*0.18;speed=vlen(vel);
    // Keep a brief peak so controller release latency does not eat a natural flick.
    if(speed>=0.45) {
        if(time-self.advr_magic_peak_time>0.18 || speed>=vlen(self.advr_magic_peak)) {
            self.advr_magic_peak=vel;self.advr_magic_peak_time=time;
        }
    }
    if(!grip) {
        // A charged spell waits briefly for a flick after the release edge.
        // Uncharged releases still cancel, and an open hand cannot extend the window.
        if(!self.advr_magic_release_until) {
            if(!old || self.advr_magic_charge<0.65){ADVR_MagicClear();return;}
            self.advr_magic_release_until=time+0.2;
        }
        if(time>self.advr_magic_release_until){ADVR_MagicClear();return;}
        if(self.advr_magic_fx)setorigin(self.advr_magic_fx,at);
        if(self.advr_magic_charge>=0.65 && self.mana>=1 && time-self.advr_magic_peak_time<=0.18 && vlen(self.advr_magic_peak)>=0.45) {
            dir=normalize(self.advr_magic_peak);traceline(at,at+dir*6,TRUE,self);
            if(trace_fraction==1 && pointcontents(trace_endpos)!=CONTENT_SOLID) {
                if(self.advr_spell==1) {
                    self.mana=self.mana-1;ADVR_MagicClear();
                    self.advr_magic_book=book;self.advr_magic_hand=h;
                    self.advr_magic_direction=dir;self.advr_magic_burst=0.6;
                    fx=spawn();fx.classname="advr_magic_beam";fx.owner=self;
                    self.advr_magic_fx=fx;setorigin(fx,at);
                    sound(self,CHAN_WEAPON,"weapons/lhit.wav",1,ATTN_NORM);
                    ADVR_MagicBeam(at,h);return;
                }
                at=trace_endpos;newmis=world;
                if(self.advr_spell==2)ADVR_FrostLaunch(at,dir);
                else Launch_Missile(at,dir,'0 0 0',CT_PROJ_FIRETOP,750);
                if(newmis) {
                    newmis.advr_fireball=self.advr_spell==0;newmis.advr_magic_damage=ADVR_MagicMultiplier();newmis.poisonous=0;
                    self.mana=self.mana-1;
                    sound(self,CHAN_WEAPON,"skullwiz/attack.wav",1,ATTN_NORM);
                    haptic(h,0,0.12,85,0.6);
                }
            }
            ADVR_MagicClear();return;
        }
        return;
    }
    self.advr_magic_release_until=0; // re-gripping resumes the held charge
    self.advr_magic_charge=min(1,self.advr_magic_charge+bound(0,frametime,0.05));
    if(!self.advr_magic_fx) {
        fx=spawn();fx.classname="advr_magic_charge";fx.owner=self;fx.solid=SOLID_NOT;fx.movetype=MOVETYPE_NONE;
        setmodel(fx,"progs/advr_magic_charge.mdl");fx.effects=EF_DIMLIGHT;fx.think=ADVR_MagicGlowThink;fx.nextthink=time+0.05;
        fx.skin=min(self.advr_spell,1);
        self.advr_magic_fx=fx;
    }
    setorigin(self.advr_magic_fx,at);self.advr_magic_fx.alpha=0.2+0.8*self.advr_magic_charge;
    if(!self.advr_magic_ready && self.advr_magic_charge>=0.65) {
        self.advr_magic_ready=1;
        haptic(h,0,0.09,150,0.7);haptic(h,0.16,0.09,150,0.7);
        self.advr_magic_haptic=time+0.75;
    }
    if(time>=self.advr_magic_haptic) {
        if(self.advr_magic_ready){self.advr_magic_haptic=time+0.75;haptic(h,0,0.04,110,0.25);}
        else {self.advr_magic_haptic=time+0.12;haptic(h,0,0.06,65,0.1+0.25*self.advr_magic_charge);}
    }
};
