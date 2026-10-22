// Debug casting bypasses costs without changing the real essence pool.
float() ADVR_Mana = {
    if(self.advr_main.advr_kind==ADVR_DEBUGTOME || self.advr_off.advr_kind==ADVR_DEBUGTOME)return 100000;
    return self.mana;
};
void(float amount) ADVR_SpendMana = {
    if(self.advr_main.advr_kind!=ADVR_DEBUGTOME && self.advr_off.advr_kind!=ADVR_DEBUGTOME)self.mana=max(0,self.mana-amount);
};
float(float spell) ADVR_NextSpell = {
    if(spell==7)return 9;if(spell==10)return 8;if(spell==8)return 11;
    return mod(spell+1,ADVR_SPELL_COUNT);
};
float(entity r) ADVR_HasteRate = {
    if(r && r.advr_enchant_type==6 && r.advr_enchant_until>time)return 1.25;
    return 1;
};
// Tome magic: one free hand, physical grip charge, release with a deliberate throw.
float(entity r) ADVR_IsTome = {return r && (r.advr_kind==ADVR_TOME || r.advr_kind==ADVR_DEBUGTOME);};
void(entity player) ADVR_MagicInit = {
    if(!player.advr_magic_version) {
        // Existing saves already had both spells. Fresh players start with none.
        if(player.advr_mana_seen)player.advr_known=3;
        player.advr_magic_version=1;
    }
    player.advr_available=(player.advr_known & 1791);
    if(query_configflag(SVR_RUNE_KEY1))player.advr_available=player.advr_available | 256;
    if(query_configflag(SVR_RUNE_KEY2))player.advr_available=player.advr_available | 2048;
    if(query_configflag(SVR_RUNE_KEY3))player.advr_available=player.advr_available | 4096;
    if(query_configflag(SVR_RUNE_KEY4))player.advr_available=player.advr_available | 8192;
    player.advr_mana_max=max(50,player.advr_mana_max);
    player.mana=bound(0,player.mana,player.advr_mana_max);
};
float(entity player,entity book) ADVR_SpellMask = {
    if(!ADVR_IsTome(book))return 0;
    if(book.advr_kind==ADVR_DEBUGTOME)return pow(2,ADVR_SPELL_COUNT)-1;
    return (player.advr_known & 1791) + 256*query_configflag(SVR_RUNE_KEY1)+2048*(query_configflag(SVR_RUNE_KEY2)!=0)+4096*(query_configflag(SVR_RUNE_KEY3)!=0)+8192*(query_configflag(SVR_RUNE_KEY4)!=0);
};
void(entity player,entity book) ADVR_TomePickup = {
    local float spell,i;
    ADVR_MagicInit(player);
    if(!player.advr_mana_seen){player.advr_mana_seen=1;player.mana=min(player.advr_mana_max,player.mana+30);}
    if(book.advr_kind==ADVR_DEBUGTOME || book.advr_tome_read)return;
    book.advr_tome_read=1;
    spell=floor(random()*10);if(spell>=8)spell=spell+1;
    for(i=0;i<10;i=i+1) {
        if(!(player.advr_known & pow(2,spell))) {
            player.advr_known=player.advr_known | pow(2,spell);player.advr_spell=spell;
            if(spell==0)sprint(player,"Learned Fire!\n");else if(spell==1)sprint(player,"Learned Lightning!\n");else if(spell==2)sprint(player,"Learned Frost!\n");else if(spell==3)sprint(player,"Learned Acid!\n");else if(spell==4)sprint(player,"Learned Void!\n");else if(spell==5)sprint(player,"Learned Haste!\n");else if(spell==6)sprint(player,"Learned Protection!\n");else if(spell==7)sprint(player,"Learned Slipstep!\n");else if(spell==9)sprint(player,"Learned Invisibility!\n");else sprint(player,"Learned Darksight!\n");
            return;
        }
        spell=mod(spell+1,11);if(spell==8)spell=9;
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
    if(self.advr_slip_marker){remove(self.advr_slip_marker);self.advr_slip_marker=world;}
    self.advr_slip_valid=0;
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
                self.advr_spell=ADVR_NextSpell(self.advr_spell);
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
        self.advr_lightning_cast=1;PlayerLightningDamage(at,end+self.advr_magic_direction*4,self,20*ADVR_MagicMultiplier());self.advr_lightning_cast=0;
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
    if(ADVR_HandBusy(h))return 1;
    if(ragdollheld(self,h)>0 || ADVR_Hand(h) || ADVR_Holster(h)>=0 || weaponanygrip(self,h)>0 || ADVR_FGPulled(h))return 1;
    if(h){if(self.vrbits0 & 262144)return 1;if(self.mainhand_hotspot==7)return 1;}
    else {if(self.vrbits0 & 131072)return 1;if(self.offhand_hotspot==7)return 1;}
    return 0;
};
// One timestamp per living monster: repeat frost hits refresh, never stack speed loss.
// Elemental resistance applies only to the elemental portion of a weapon hit.
float(entity target) ADVR_FireResistance = {
    if((target.flags & FL_MONSTER) && (target.classgroup==CG_STONE || target.gibtype==GIBTYPE_STONE))return 0.5;
    return 1;
};
float(entity target) ADVR_LightningResistance = {if(target.classtype==CT_MONMINOTAUR)return 0.5/max(0.5,1-target.resist_cells);return 1;};
float(entity target) ADVR_AcidResistance = {
    if(target.classtype==CT_MONWIZARD)return 0.5;
    return 1;
};
void() ADVR_AcidThink = {
    local entity v;
    v=self.enemy;
    if(!v || v.advr_acid!=self || v.health<=0 || !v.takedamage || v.modelindex!=self.advr_acid_model || time>self.advr_acid_end+0.001) {
        if(v && v.advr_acid==self)v.advr_acid=world;
        remove(self);return;
    }
    self.nextthink=time+0.5;
    setorigin(self,modelcentre(v));
    particle2(self.origin,'0 0 15',17,3);
    particle(self.origin,'0 0 -40',63,8);
    if(time>=self.advr_acid_sound){sound(self,CHAN_AUTO,GIB_SOUND_ACID,0.4,ATTN_NORM);self.advr_acid_sound=time+1;}
    T_Damage(v,self,self.owner,4*max(1,self.advr_magic_damage)*ADVR_AcidResistance(v),NOARMOR);
};
void(entity target,entity attacker,float multiplier) ADVR_AcidApply = {
    local entity effect;
    if(!(target.flags & FL_MONSTER) || target.health<=0 || !target.takedamage ||
       (target.flags & FL_GODMODE) || target.invincible_finished>time)return;
    effect=target.advr_acid;
    if(!effect || effect.classname!="advr_acid_dot" || effect.enemy!=target) {
        effect=spawn();effect.classname="advr_acid_dot";effect.enemy=target;
        effect.advr_acid_model=target.modelindex;target.advr_acid=effect;
        effect.think=ADVR_AcidThink;effect.nextthink=time+0.5;
    }
    effect.owner=attacker;effect.advr_magic_damage=multiplier;effect.advr_acid_end=time+4;
};
void() ADVR_AcidTouch = {
    local entity e,hit;local float damage;
    if(other==self.owner)return;
    if(pointcontents(self.origin)==CONTENT_SKY){remove(self);return;}
    hit=other;
    // One hit per victim, native fire-sized falloff, no splash through walls.
    e=world;
    while((e=nextent(e))) {
        if(!e.takedamage)continue;
        damage=40-0.5*vlen(modelcentre(e)-self.origin);
        if(e==hit)damage=40;
        if(damage<=0)continue;
        if(e!=hit && !CanDamage(e,self))continue;
        if(e==self.owner)damage=damage*0.5;
        T_Damage(e,self,self.owner,damage*max(1,self.advr_magic_damage)*ADVR_AcidResistance(e),DAMARMOR);
    }
    particle(self.origin,'0 0 30',63,80);
    sound(self,CHAN_WEAPON,"weapons/lhit.wav",0.7,ATTN_NORM);remove(self);
};
// Independent controller leaves native fire impact, trail and expiry callbacks intact.
.entity advr_guidance;
.float advr_guidance_hand;
void() ADVR_GuidedBoltThink = {
    local entity missile,caster;local vector aim;local float speed;
    missile=self.enemy;caster=self.owner;
    if(!missile || missile.advr_guidance!=self || missile.owner!=caster ||
       missile.solid==SOLID_NOT || time>=self.attack_finished ||
       !caster || caster.health<=0 || !(caster.flags & FL_CLIENT)) {
        if(missile && missile.advr_guidance==self)missile.advr_guidance=world;
        remove(self);return;
    }
    if(self.advr_guidance_hand)aim=caster.handrot;else aim=caster.offhandrot;
    makevectors(aim);speed=vlen(missile.velocity);
    if(speed>1 && !(missile.advr_voidorb && missile.enemy && missile.enemy.health>0)) {
        missile.velocity=normalize(normalize(missile.velocity)*0.88+v_forward*0.12)*speed;
        missile.angles=vectoangles(missile.velocity);
    }
    self.nextthink=time+0.05;
};
void(entity missile,float hand) ADVR_GuideBolt = {
    local entity guide;
    guide=spawn();guide.classname="advr_guided_bolt";guide.owner=self;guide.enemy=missile;
    guide.advr_guidance_hand=hand;guide.attack_finished=time+8;
    missile.advr_guidance=guide;guide.think=ADVR_GuidedBoltThink;guide.nextthink=time+0.05;
};
void(vector at,vector direction) ADVR_AcidLaunch = {
    newmis=spawn();newmis.classname="advr_acidbolt";newmis.owner=self;newmis.advr_acidbolt=1;
    newmis.solid=SOLID_BBOX;newmis.movetype=MOVETYPE_FLYMISSILE;
    newmis.velocity=normalize(direction)*550;newmis.angles=vectoangles(newmis.velocity);
    newmis.touch=ADVR_AcidTouch;newmis.think=SUB_Remove;newmis.nextthink=time+5;
    newmis.advr_magic_damage=ADVR_MagicMultiplier();
    setmodel(newmis,MODEL_PROJ_WIZ);setsize(newmis,'-4 -4 -4','4 4 4');setorigin(newmis,at);
};
void(entity target) ADVR_FrostHit = {
    if(!(target.flags & FL_MONSTER) || target.health<=0 || !target.takedamage ||
       (target.flags & FL_GODMODE) || target.invincible_finished>time)return;
    target.advr_frost_until=time+8*ADVR_FireResistance(target);
};
void() ADVR_FrostTouch = {
    if(other==self.owner)return;
    if(pointcontents(self.origin)==CONTENT_SKY){remove(self);return;}
    if(other.takedamage)T_Damage(other,self,self.owner,30*max(1,self.advr_magic_damage)*ADVR_FireResistance(other),DAMARMOR);
    particle2(self.origin,'0 0 30',3,16);
    sound(self,CHAN_WEAPON,"weapons/lhit.wav",0.5,ATTN_NORM);
    remove(self);
};
void(vector at,vector direction) ADVR_FrostLaunch = {
    newmis=spawn();newmis.classname="advr_frostbolt";newmis.owner=self;newmis.advr_frostbolt=1;
    newmis.solid=SOLID_BBOX;newmis.movetype=MOVETYPE_FLYMISSILE;
    newmis.velocity=normalize(direction)*550;newmis.angles=vectoangles(newmis.velocity);
    newmis.touch=ADVR_FrostTouch;newmis.think=SUB_Remove;newmis.nextthink=time+5;
    newmis.advr_magic_damage=ADVR_MagicMultiplier();
    setmodel(newmis,"progs/advr_frostbolt.mdl");setsize(newmis,'-4 -4 -4','4 4 4');setorigin(newmis,at);
};

// Brief light emitters placed only along the unobstructed cast volume.
void() ADVR_FrostLightThink = {
    if(time>=self.advr_enchant_until){remove(self);return;}
    self.alpha=max(0.01,(self.advr_enchant_until-time)/1.25);self.nextthink=time+0.05;
};
void(vector at,vector aim,float reach) ADVR_FrostLight = {
    local entity glow;
    glow=spawn();glow.classname="advr_frost_cone_light";glow.owner=self;
    glow.movetype=MOVETYPE_NONE;glow.solid=SOLID_NOT;
    // An invisible network anchor for one shadowed, per-pixel cone light.
    setmodel(glow,"progs/advr_frostbolt.mdl");glow.alpha=1;
    setorigin(glow,at);glow.angles=vectoangles(aim);glow.angles_x=-glow.angles_x;
    glow.advr_enchant_until=time+1.25;glow.think=ADVR_FrostLightThink;glow.nextthink=time+0.05;
};
// 30-degree total cone, thirty physical feet at the configured world scale.
void(vector at,vector direction) ADVR_FrostCone = {
    local entity e,fx;local vector delta,aim,tip;local float reach,d,i;
    aim=normalize(direction);reach=240*max(0.1,cvar("vr_world_scale"));
    ADVR_FrostLight(at,aim,reach);
    fx=spawn();fx.owner=self;fx.advr_frostbolt=1;setorigin(fx,at);
    e=world;
    while((e=nextent(e))){
        if(e==self || !(e.flags & FL_MONSTER) || e.health<=0 || !e.takedamage)continue;
        delta=modelcentre(e)-at;d=vlen(delta);
        if(d>reach || (d>0 && normalize(delta)*aim<0.9659258))continue;
        traceline(at,modelcentre(e),TRUE,self);if(trace_fraction<1)continue;
        ADVR_FrostHit(e);
        T_Damage(e,fx,self,16*ADVR_MagicMultiplier()*ADVR_FireResistance(e),DAMARMOR);
    }
    sound(self,CHAN_WEAPON,"weapons/lhit.wav",0.6,ATTN_NORM);remove(fx);
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
    if(!down || !r || ADVR_IsTome(r) || ADVR_HandBusy(h) || ADVR_Mana()<5) {ADVR_EnchantClear();return;}
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
    ADVR_VoidRestore(r);
    r.advr_enchant_type=self.advr_enchant_spell+1;r.advr_enchant_until=time+30;
    if(r.advr_enchant_type==5)ADVR_VoidWeapon(r);
    if(r.advr_enchant_type==7){r.advr_enchant_until=time+60;r.advr_shield_hp=300;}
    r.advr_enchant_scale=ADVR_MagicMultiplier();ADVR_SpendMana(5);
    self.advr_enchant_latched=1;
    haptic(h,0,0.12,150,0.7);haptic(h,0.2,0.12,150,0.7);
    sound(self,CHAN_AUTO,"skullwiz/attack.wav",0.45,ATTN_NORM);
    if(r.advr_enchant_type==1)sprint(self,"Fire enchantment: 30 seconds.\n");
    else if(r.advr_enchant_type==2)sprint(self,"Lightning enchantment: 30 seconds.\n");else if(r.advr_enchant_type==3)sprint(self,"Frost enchantment: 30 seconds.\n");else if(r.advr_enchant_type==4)sprint(self,"Acid enchantment: 30 seconds.\n");else if(r.advr_enchant_type==5)sprint(self,"Void enchantment: 30 seconds.\n");else if(r.advr_enchant_type==6)sprint(self,"Haste enchantment: 30 seconds.\n");else if(r.advr_enchant_type==7)sprint(self,"Protection shield: 300 damage, 60 seconds.\n");else if(r.advr_enchant_type==10)sprint(self,"Invisible weapon: 30 seconds.\n");else if(r.advr_enchant_type==11)sprint(self,"Darksight lantern: 30 seconds.\n");else sprint(self,"Slipstep enchantment: 30 seconds.\n");
    ADVR_EnchantClear();
};
// Projectile payload is copied at launch, never looked up from the shooter's
// current hand at impact. Burning ticks and unrelated spells have no payload.
void(entity missile) ADVR_EnchantMissile = {
    if(!advr_attack_record || missile.owner!=advr_attack_actor || time>=advr_attack_record.advr_enchant_until)return;
    if(advr_attack_record.advr_enchant_type>=10)return; // utility enchantments affect the weapon, not its ammunition
    missile.advr_enchant_type=advr_attack_record.advr_enchant_type;
    missile.advr_enchant_until=advr_attack_record.advr_enchant_until;
    missile.advr_enchant_scale=advr_attack_record.advr_enchant_scale;
    ADVR_VoidHoming(missile);
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
    if(r.advr_enchant_type==8)ADVR_SlipHit(target,attacker);
    if(r.advr_enchant_type>=6)return damage; // Haste changes cadence, never elemental damage.
    bonus=damage*0.05*max(1,r.advr_enchant_scale);
    if(r.advr_enchant_type==5) {
        bonus=0;
        if(r.advr_weapon==IT_AXE && !ADVR_IsTome(r))bonus=damage*0.075*max(1,r.advr_enchant_scale);
        ADVR_VoidRoll(target,attacker,random());
    } else if(r.advr_enchant_type==1) {
        bonus=bonus*ADVR_FireResistance(target);
        ADVR_Ignite(target,attacker);
        if(target.advr_burn)target.advr_burn.advr_magic_damage=max(1,r.advr_enchant_scale);
    } else if(r.advr_enchant_type==4) {
        bonus=bonus*ADVR_AcidResistance(target);ADVR_AcidApply(target,attacker,max(1,r.advr_enchant_scale));
    } else if(r.advr_enchant_type==3) {
        bonus=bonus*ADVR_FireResistance(target);
        ADVR_FrostHit(target);
    } else {
        bonus=Resist_Damage(target,IT_CELLS,bonus)*ADVR_LightningResistance(target);
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
    if(!r)return 0;
    if(time>=r.advr_enchant_until){ADVR_VoidRestore(r);return 0;}
    if(r.advr_enchant_type>=10)return 4194304+r.advr_enchant_type*64+ceil(bound(0,r.advr_enchant_until-time,30));
    if(r.advr_enchant_type==8)return 2097152+ceil(bound(0,r.advr_enchant_until-time,30));
    if(r.advr_enchant_type==7)return 1048576+floor(bound(0,r.advr_shield_hp,300))*512+ceil(bound(0,r.advr_enchant_until-time,60))*8+7;
    return r.advr_void_original*8192+4096+r.advr_enchant_type+ceil(bound(0,r.advr_enchant_until-time,30))*8;
};
void(entity r,float packed) ADVR_EnchantRestore = {
    if(!r || packed<=0)return;
    if(packed>=4194304){packed=packed-4194304;r.advr_enchant_type=floor(packed/64);r.advr_enchant_until=time+bound(0,mod(packed,64),30);return;}
    if(packed>=2097152){r.advr_enchant_type=8;r.advr_enchant_until=time+bound(0,packed-2097152,30);return;}
    if(packed>=1048576){
        packed=packed-1048576;r.advr_enchant_type=7;r.advr_shield_hp=floor(packed/512);
        r.advr_enchant_until=time+min(60,floor(mod(packed,512)/8));return;
    }
    r.advr_void_original=floor(packed/8192);packed=mod(packed,8192);
    if(packed>=4096){packed=packed-4096;r.advr_enchant_type=mod(packed,8);r.advr_enchant_until=time+floor(packed/8);}
    else {r.advr_enchant_type=mod(packed,4);r.advr_enchant_until=time+floor(packed/4);}
    r.advr_enchant_until=min(r.advr_enchant_until,time+30);
    if(r.advr_void_original){r.think=ADVR_VoidWeaponThink;r.nextthink=r.advr_enchant_until;}
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
        else if(ADVR_SpellMask(self,book) & 8)self.advr_spell=3;
        else if(ADVR_SpellMask(self,book) & 16)self.advr_spell=4;
        else if(ADVR_SpellMask(self,book) & 32)self.advr_spell=5;
        else if(ADVR_SpellMask(self,book) & 64)self.advr_spell=6;
        else if(ADVR_SpellMask(self,book) & 128)self.advr_spell=7;
        else if(ADVR_SpellMask(self,book) & 256)self.advr_spell=8;
        else if(ADVR_SpellMask(self,book) & 512)self.advr_spell=9;
        else if(ADVR_SpellMask(self,book) & 1024)self.advr_spell=10;
        else if(ADVR_SpellMask(self,book) & 2048)self.advr_spell=11;
        else if(ADVR_SpellMask(self,book) & 4096)self.advr_spell=12;
        else if(ADVR_SpellMask(self,book) & 8192)self.advr_spell=13;
        else return;
    }
    if(ADVR_Hand(h)) {
        if(self.advr_magic_book || self.advr_magic_fx)ADVR_MagicClear();
        if(self.advr_spell==8 || self.advr_spell==11 || self.advr_spell==12 || self.advr_spell==13){ADVR_EnchantClear();return;}
        ADVR_EnchantFrame(book,h,stick,oldstick);return;
    }
    ADVR_EnchantClear();
    if(ADVR_MagicBlocked(h)){ADVR_MagicClear();return;}
    grip=ADVR_Grip(h);old=ADVR_OldGrip(h);
    if(!self.advr_magic_book)self.advr_magic_control=stick && !oldstick;
    if(self.advr_magic_control){grip=stick;old=oldstick;}
    if(self.advr_magic_book && (self.advr_magic_book!=book || self.advr_magic_hand!=h)){ADVR_MagicClear();return;}
    if(!self.advr_magic_book) {
        if(!grip || old || ADVR_Mana()<((self.advr_spell==8 || self.advr_spell==11 || self.advr_spell==12 || self.advr_spell==13) ? 30 : 1))return;
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
    if(self.advr_spell==13 && !grip){
        if(old && self.advr_magic_charge>=0.65 && ADVR_Mana()>=30 && (book.advr_kind==ADVR_DEBUGTOME || query_configflag(SVR_RUNE_KEY4))){
            // Pay before putting away a Debug Tome (which bypasses the cost).
            ADVR_SpendMana(30);ADVR_ElderCast(1-h);haptic(h,0,0.25,60,0.9);
        }ADVR_MagicClear();return;
    }
    if(self.advr_spell==12 && !grip){
        if(old && self.advr_magic_charge>=0.65 && ADVR_Mana()>=30 && (book.advr_kind==ADVR_DEBUGTOME || query_configflag(SVR_RUNE_KEY3))){
            ADVR_SpendMana(30);ADVR_NetherCast(h);haptic(h,0,0.25,85,0.9);
        }ADVR_MagicClear();return;
    }
    if(self.advr_spell==11 && !grip){
        if(old && self.advr_magic_charge>=0.65 && ADVR_Mana()>=30 && (book.advr_kind==ADVR_DEBUGTOME || query_configflag(SVR_RUNE_KEY2))){
            ADVR_SpendMana(30);ADVR_DarkCast();haptic(h,0,0.25,65,0.9);
        }ADVR_MagicClear();return;
    }
    if(self.advr_spell==8 && !grip) {
        if(old && self.advr_magic_charge>=0.65 && ADVR_Mana()>=30 && (book.advr_kind==ADVR_DEBUGTOME || query_configflag(SVR_RUNE_KEY1))) {
            ADVR_SpendMana(30);self.advr_earth_until=time+60;
            sound(self,CHAN_AUTO,"misc/r_tele1.wav",1,ATTN_NORM);
            haptic(h,0,0.25,80,0.9);particle(self.origin+'0 0 24','0 0 60',8,100);
            sprint(self,"Earth Rune: stone form for 60 seconds!\n");
        }
        ADVR_MagicClear();return;
    }
    if(self.advr_spell==7 && !grip) {
        if(old && self.advr_magic_charge>=0.65 && ADVR_Mana()>=1)ADVR_SlipCast(h);
        ADVR_MagicClear();return;
    }
    if(!grip && old && self.advr_spell>=5 && self.advr_magic_charge>=0.65 && ADVR_Mana()>=1) {
        ADVR_SpendMana(1);
        if(self.advr_spell==5)self.advr_haste_until=time+30;
        else if(self.advr_spell==9){self.items=self.items | IT_INVISIBILITY;self.invisible_time=1;self.invisible_finished=max(self.invisible_finished,time+30);self.invisible_sound=time+1;}
        else if(self.advr_spell==10)self.advr_darksight_until=time+30;
        else {self.advr_protection_until=time+60;self.advr_protection_armor=50;}
        sound(self,CHAN_AUTO,"misc/r_tele1.wav",0.6,ATTN_NORM);haptic(h,0,0.12,110,0.6);
        if(self.advr_spell==5)sprint(self,"Haste: 25% faster movement for 30 seconds.\n");
        else if(self.advr_spell==9)sprint(self,"Invisibility: 30 seconds.\n");
        else if(self.advr_spell==10)sprint(self,"Darksight: 30 seconds.\n");
        else sprint(self,"Protection: 50 temporary red armor for 60 seconds.\n");
        ADVR_MagicClear();return;
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
        if(self.advr_magic_charge>=0.65 && ADVR_Mana()>=1 && time-self.advr_magic_peak_time<=0.18 && vlen(self.advr_magic_peak)>=0.45) {
            dir=normalize(self.advr_magic_peak);traceline(at,at+dir*6,TRUE,self);
            if(trace_fraction==1 && pointcontents(trace_endpos)!=CONTENT_SOLID) {
                if(self.advr_spell==1) {
                    ADVR_SpendMana(1);ADVR_MagicClear();
                    self.advr_magic_book=book;self.advr_magic_hand=h;
                    self.advr_magic_direction=dir;self.advr_magic_burst=0.6;
                    fx=spawn();fx.classname="advr_magic_beam";fx.owner=self;
                    if((self.advr_spell>=5 && self.advr_spell<8) || (self.advr_spell>=9 && self.advr_spell<=10)){fx.advr_enchant_type=self.advr_spell+1;fx.advr_enchant_until=time+3600;}
        self.advr_magic_fx=fx;setorigin(fx,at);
                    sound(self,CHAN_WEAPON,"weapons/lhit.wav",1,ATTN_NORM);
                    ADVR_MagicBeam(at,h);return;
                }
                at=trace_endpos;newmis=world;
                if(self.advr_spell==4){makevectors(ADVR_Angles(h));ADVR_VoidLaunch(at,dir,v_forward);}
                else if(self.advr_spell==3)ADVR_AcidLaunch(at,dir);
                else if(self.advr_spell==2){ADVR_FrostCone(at,dir);ADVR_SpendMana(1);haptic(h,0,0.12,85,0.6);ADVR_MagicClear();return;}
                else Launch_Missile(at,dir,'0 0 0',CT_PROJ_FIRETOP,550);
                if(newmis) {
                    setsize(newmis,'-4 -4 -4','4 4 4');
                    ADVR_GuideBolt(newmis,h);
                    newmis.advr_fireball=self.advr_spell==0;newmis.advr_magic_damage=ADVR_MagicMultiplier();newmis.poisonous=0;
                    ADVR_SpendMana(1);
                    sound(self,CHAN_WEAPON,"skullwiz/attack.wav",1,ATTN_NORM);
                    haptic(h,0,0.12,85,0.6);
                }
            }
            ADVR_MagicClear();return;
        }
        return;
    }
    self.advr_magic_release_until=0; // re-gripping resumes the held charge
    self.advr_magic_charge=min(1,self.advr_magic_charge+bound(0,frametime,0.05)*((self.advr_spell==8 || self.advr_spell==11 || self.advr_spell==12 || self.advr_spell==13) ? 0.2166667 : 1)*(1+0.25*(self.advr_haste_until>time)));
    if(self.advr_spell==7 && self.advr_magic_charge>=0.65)ADVR_SlipPreview(h);
    if(!self.advr_magic_fx) {
        fx=spawn();fx.classname="advr_magic_charge";fx.owner=self;fx.solid=SOLID_NOT;fx.movetype=MOVETYPE_NONE;
        if(self.advr_spell==13)setmodel(fx,"progs/advr_elder_rune.mdl");else if(self.advr_spell==12)setmodel(fx,"progs/advr_nether_rune.mdl");else if(self.advr_spell==11)setmodel(fx,"progs/advr_dark_rune.mdl");else if(self.advr_spell==8)setmodel(fx,"progs/advr_earth_rune.mdl");else if(self.advr_spell==4)setmodel(fx,MODEL_PROJ_SHAL);else if(self.advr_spell==3)setmodel(fx,"progs/advr_acid_charge.mdl");else setmodel(fx,"progs/advr_magic_charge.mdl");fx.effects=EF_DIMLIGHT;fx.think=ADVR_MagicGlowThink;fx.nextthink=time+0.05;
        fx.skin=min(self.advr_spell,1);if(self.advr_spell>=3)fx.skin=0;
        if((self.advr_spell>=5 && self.advr_spell<8) || (self.advr_spell>=9 && self.advr_spell<=10)){fx.advr_enchant_type=self.advr_spell+1;fx.advr_enchant_until=time+3600;}
        self.advr_magic_fx=fx;
    }
    setorigin(self.advr_magic_fx,at);self.advr_magic_fx.alpha=0.2+0.8*self.advr_magic_charge;
    if(self.advr_spell==8 || self.advr_spell==11 || self.advr_spell==12 || self.advr_spell==13) {
        self.advr_magic_fx.alpha=bound(0.02,self.advr_magic_charge/0.65,1);
        self.advr_magic_fx.model_scale='1 1 1'*(0.25+0.75*min(1,self.advr_magic_charge/0.65));
    }
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

