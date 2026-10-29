// Permanent ammunition metadata. Each package retains its own count and infusion.
float(string s,float offset) ADVR_AmmoDigit = {
    local float i;local string c;c=substring(s,offset,1);
    for(i=0;i<16;i=i+1)if(c==substring("0123456789ABCDEF",i,1))return i;
    return 0;
};
float(string s) ADVR_AmmoCount = {return ADVR_AmmoDigit(s,0)*16+ADVR_AmmoDigit(s,1);};
string(float count,float element,float strength) ADVR_AmmoEntry = {
    return strcat(substring("0123456789ABCDEF",floor(count/16),1),substring("0123456789ABCDEF",mod(count,16),1),
        substring("0123456789ABCDEF",element,1),substring("0123456789ABCDEF",bound(0,rint((strength-1)*20),4),1));
};
// Always copy before releasing: substring/strcat results are temporary engine strings.
void(entity r,string value) ADVR_AmmoSet = {
    local string old;old=r.advr_ammo;if(strlen(value))r.advr_ammo=strzone(value);else r.advr_ammo="";if(strlen(old))strunzone(old);
};
void(float key,string value) ADVR_PouchSet = {
    local string old;old=self.advr_pouch[key];if(strlen(value))self.advr_pouch[key]=strzone(value);else self.advr_pouch[key]="";if(strlen(old))strunzone(old);
};
float(entity r) ADVR_AmmoKey = {
    local float w,k;w=r.advr_weapon;k=r.advr_kind;
    if(r.classname=="advr_reload_round"){w=r.advr_round_weapon;k=r.advr_round_kind;}
    if(k==ADVR_CROSSBOW)return 9;if(k==ADVR_WIDOWMAKER)return 8;if(k==ADVR_PLASMA)return 7;
    if(w==IT_SHOTGUN)return 0;if(w==IT_SUPER_SHOTGUN)return 1;if(w==IT_NAILGUN)return 2;
    if(w==IT_SUPER_NAILGUN)return 3;if(w==IT_GRENADE_LAUNCHER)return 4;if(w==IT_ROCKET_LAUNCHER)return 5;return 6;
};
float(string s) ADVR_AmmoTotal = {local float i,n;for(i=0;i<strlen(s);i=i+4)n=n+ADVR_AmmoCount(substring(s,i,4));return n;};
void(entity r,float n) ADVR_AmmoConsume = {
    local float count;local string s;s=r.advr_ammo;
    while(n>0 && strlen(s)>=4){
        count=ADVR_AmmoCount(s);
        if(n<count){s=strcat(ADVR_AmmoEntry(count-n,ADVR_AmmoDigit(s,2),1+.05*ADVR_AmmoDigit(s,3)),substring(s,4,1023));n=0;}
        else{n=n-count;s=substring(s,4,1023);}
    }
    ADVR_AmmoSet(r,s);
};
void(entity r) ADVR_AmmoNormalize = {
    local float n;n=ADVR_AmmoTotal(r.advr_ammo);
    if(n>r.wi_clip)ADVR_AmmoConsume(r,n-r.wi_clip);
    else if(n<r.wi_clip)ADVR_AmmoSet(r,strcat(r.advr_ammo,ADVR_AmmoEntry(r.wi_clip-n,0,1)));
};
void(entity r,entity p,float n) ADVR_AmmoInsert = {
    ADVR_AmmoNormalize(r);
    ADVR_AmmoSet(r,strcat(r.advr_ammo,ADVR_AmmoEntry(n,p.advr_enchant_type,p.advr_enchant_scale)));
};
float(entity p) ADVR_AmmoStore = {
    local float key;key=ADVR_AmmoKey(p);
    // A full metadata stack must never silently erase an infusion. Leave the prop physical.
    if(strlen(self.advr_pouch[key])>1016){sprint(self,"This weapon's ammo pouch is full.\n");return 0;}
    if(p.advr_round_count>0)ADVR_PouchSet(key,strcat(ADVR_AmmoEntry(p.advr_round_count,p.advr_enchant_type,p.advr_enchant_scale),self.advr_pouch[key]));
    return 1;
};
float(float key) ADVR_AmmoFamily = {if(key<2 || key==8)return 1;if(key<4)return 2;if(key<6)return 3;if(key<9)return 4;return 5;};
float(entity r) ADVR_AmmoReserved = {
    local float i,n;for(i=0;i<10;i=i+1)if(ADVR_AmmoFamily(i)==ADVR_AmmoFamily(ADVR_AmmoKey(r)))n=n+ADVR_AmmoTotal(self.advr_pouch[i]);return n;
};
void(entity r,entity p,float available) ADVR_AmmoTake = {
    local float key,i,reserved,n;local string s;key=ADVR_AmmoKey(r);s=self.advr_pouch[key];
    if(strlen(s)){
        n=min(p.advr_round_count,min(available,ADVR_AmmoCount(s)));p.advr_round_count=n;
        p.advr_enchant_type=ADVR_AmmoDigit(s,2);p.advr_enchant_scale=1+.05*ADVR_AmmoDigit(s,3);
        p.advr_enchant_until=0; // permanent ammo uses classname/payload, never a clock
        if(n==ADVR_AmmoCount(s))ADVR_PouchSet(key,substring(s,4,1023));
        else ADVR_PouchSet(key,strcat(ADVR_AmmoEntry(ADVR_AmmoCount(s)-n,p.advr_enchant_type,p.advr_enchant_scale),substring(s,4,1023)));
    }else{
        // Shared shell/nail/rocket/cell counters must not spend another weapon's stored package.
        for(i=0;i<10;i=i+1)if(ADVR_AmmoFamily(i)==ADVR_AmmoFamily(key))reserved=reserved+ADVR_AmmoTotal(self.advr_pouch[i]);
        p.advr_round_count=min(p.advr_round_count,max(0,available-reserved));
    }
};
// Button/automatic reload modes consume the same packages as physical loading.
float(entity r,float n) ADVR_AmmoReload = {
    local entity p;local float taken,available,clip;
    clip=r.wi_clip;p=spawn();
    if(r.advr_kind==ADVR_CROSSBOW)available=self.advr_bolts;else available=max(0,ADVR_Ammo(r.advr_weapon)-ADVR_Loaded(r.advr_weapon));
    while(taken<n){
        p.advr_round_count=n-taken;p.advr_enchant_type=0;p.advr_enchant_scale=1;
        // Limit extraction to the free chamber space, keeping the remainder on top.
        ADVR_AmmoTake(r,p,available);if(p.advr_round_count<=0)break;
        ADVR_AmmoInsert(r,p,p.advr_round_count);r.wi_clip=r.wi_clip+p.advr_round_count;
        taken=taken+p.advr_round_count;available=available-p.advr_round_count;
    }
    r.wi_clip=clip;remove(p);return taken;
};
void(entity r) ADVR_AmmoUnload = {
    local entity p;local float count;
    ADVR_AmmoNormalize(r);p=spawn();p.classname="advr_reload_round";p.advr_round_weapon=r.advr_weapon;p.advr_round_kind=r.advr_kind;
    while(strlen(r.advr_ammo)){
        count=ADVR_AmmoCount(r.advr_ammo);p.advr_round_count=count;
        p.advr_enchant_type=ADVR_AmmoDigit(r.advr_ammo,2);p.advr_enchant_scale=1+.05*ADVR_AmmoDigit(r.advr_ammo,3);
        if(!ADVR_AmmoStore(p))break;ADVR_AmmoConsume(r,count);r.wi_clip=r.wi_clip-count;
        if(r.advr_kind==ADVR_CROSSBOW)self.advr_bolts=self.advr_bolts+count;
    }
    remove(p);
};
// Only used while actually dispatching a ranged attack. Melee keeps the weapon's enchantment.
entity(entity r) ADVR_AmmoPayload = {
    local entity p;local string s;local float offset,count;
    if(!advr_ammo_shot || !r)return r;
    s=r.advr_ammo;offset=advr_ammo_round_offset;
    while(strlen(s)>=4 && offset>=ADVR_AmmoCount(s)){
        count=ADVR_AmmoCount(s);offset=offset-count;s=substring(s,4,1023);
    }
    if(!ADVR_AmmoDigit(s,2))return r;
    p=spawn();p.classname="advr_ammo_payload";
    p.advr_enchant_type=ADVR_AmmoDigit(s,2);p.advr_enchant_scale=1+.05*ADVR_AmmoDigit(s,3);
    p.advr_enchant_until=time+3600;p.think=SUB_Remove;p.nextthink=time+.01;
    return p;
};
void() ADVR_AmmoSave = {
    local float i;local entity r;
    for(i=0;i<10;i=i+1){if(advr_ammo_parm[i])strunzone(advr_ammo_parm[i]);advr_ammo_parm[i]=strzone(self.advr_pouch[i]);}
    for(i=0;i<8;i=i+1){
        if(i==0)r=self.advr_main;else if(i==1)r=self.advr_off;else r=self.advr_holster[i-2];
        if(r)ADVR_AmmoNormalize(r);
        if(advr_ammo_parm[i+10])strunzone(advr_ammo_parm[i+10]);advr_ammo_parm[i+10]=strzone(r.advr_ammo);
    }
};
void() ADVR_AmmoRestore = {
    local float i;local entity r;
    for(i=0;i<10;i=i+1)ADVR_PouchSet(i,advr_ammo_parm[i]);
    for(i=0;i<8;i=i+1){if(i==0)r=self.advr_main;else if(i==1)r=self.advr_off;else r=self.advr_holster[i-2];if(r)ADVR_AmmoSet(r,advr_ammo_parm[i+10]);}
};
void() ADVR_TestAmmoEnchant = {
    local entity r,p,shot,book;local float oldtime,i,h,oldframe;
    if(cvar("temp1")==1){
        self.items=self.items | IT_NAILGUN;self.ammo_nails=80;
        self.advr_initialized=1;self.advr_main=ADVR_Record(IT_NAILGUN);self.advr_main.wi_clip=7;
        ADVR_AmmoSet(self.advr_main,ADVR_AmmoEntry(7,1,1.15));
        ADVR_PouchSet(2,strcat(ADVR_AmmoEntry(3,3,1.1),ADVR_AmmoEntry(7,1,1.15)));
        ADVR_Sync();ADVR_SaveParms();dprint("ADVR AMMO PERSIST SETUP\n");return;
    }
    if(cvar("temp1")==2){
        ADVR_Assert(self.advr_pouch[2]==strcat(ADVR_AmmoEntry(3,3,1.1),ADVR_AmmoEntry(7,1,1.15)),"save/load and map transition retain pouch order and enchantments");
        if(world.take_weapons & IT_NAILGUN && !self.advr_main)
            ADVR_Assert(advr_ammo_parm[10]==ADVR_AmmoEntry(7,1,1.15),"transition carries loaded payload before destination map strips weapon");
        else ADVR_Assert(self.advr_main.advr_ammo==ADVR_AmmoEntry(7,1,1.15),"save/load and map transition retain loaded ammo");
        dprint("ADVR AMMO PERSIST PASS\n");return;
    }
    r=spawn();r.advr_weapon=IT_NAILGUN;r.wi_clip=0;
    p=spawn();p.classname="advr_reload_round";p.advr_round_weapon=IT_NAILGUN;p.advr_round_type=2;
    ADVR_PouchSet(2,"");ADVR_PouchSet(3,"");
    p.advr_round_count=7;p.advr_enchant_type=1;p.advr_enchant_scale=1.15;
    ADVR_Assert(ADVR_AmmoStore(p),"store enchanted partial magazine");
    p.advr_round_count=3;p.advr_enchant_type=3;ADVR_AmmoStore(p);
    p.advr_round_count=24;ADVR_AmmoTake(r,p,50);
    ADVR_Assert(p.advr_round_count==3 && p.advr_enchant_type==3,"LIFO preserves last magazine and count");
    ADVR_AmmoInsert(r,p,3);r.wi_clip=3;
    ADVR_AmmoConsume(r,1);r.wi_clip=2;
    ADVR_Assert(ADVR_AmmoCount(r.advr_ammo)==2 && ADVR_AmmoDigit(r.advr_ammo,2)==3,"firing consumes only one enchanted round");
    p.advr_round_count=24;ADVR_AmmoTake(r,p,47);
    ADVR_Assert(p.advr_round_count==7 && p.advr_enchant_type==1 && fabs(p.advr_enchant_scale-1.15)<.001,"older magazine retains element and rune strength");
    oldtime=time;time=time+10000;advr_ammo_shot=1;advr_attack_actor=self;advr_attack_record=r;
    shot=spawn();shot.owner=self;ADVR_EnchantMissile(shot);
    ADVR_Assert(shot.advr_enchant_type==3,"loaded enchantment does not expire");
    advr_ammo_shot=0;advr_attack_actor=advr_attack_record=world;time=oldtime;remove(shot);
    r.advr_weapon=IT_SHOTGUN;r.wi_clip=0;ADVR_AmmoSet(r,"");
    p.advr_enchant_type=1;ADVR_AmmoInsert(r,p,1);r.wi_clip=1;
    p.advr_enchant_type=3;ADVR_AmmoInsert(r,p,1);r.wi_clip=2;
    advr_ammo_shot=1;advr_ammo_round_offset=1;shot=ADVR_AmmoPayload(r);
    ADVR_Assert(shot.advr_enchant_type==3,"second shotgun barrel uses its own shell's infusion");
    remove(shot);advr_ammo_shot=advr_ammo_round_offset=0;
    ADVR_AmmoConsume(r,1);r.wi_clip=1;
    ADVR_Assert(ADVR_AmmoDigit(r.advr_ammo,2)==3,"mixed shells preserve loading order");
    ADVR_PouchSet(2,"");ADVR_PouchSet(3,ADVR_AmmoEntry(36,2,1));
    r.advr_weapon=IT_NAILGUN;p.advr_round_count=24;ADVR_AmmoTake(r,p,36);
    ADVR_Assert(p.advr_round_count==0 && ADVR_AmmoCount(self.advr_pouch[3])==36,"shared nails cannot steal stored super nailgun magazine");
    ADVR_PouchSet(3,"");ADVR_AmmoSet(r,"");remove(r);
    book=spawn();book.advr_kind=ADVR_TOME;self.advr_main=book;self.advr_off=world;self.advr_round[0]=p;
    self.mana=20;self.advr_spell=0;self.advr_enchant_latched=0;ADVR_EnchantClear();
    oldframe=frametime;frametime=.05;p.advr_round_count=24;p.advr_round_type=2;p.advr_enchant_type=0;
    for(i=0;i<20;i=i+1)ADVR_EnchantFrame(book,0,1,0);
    ADVR_EnchantFrame(book,0,0,0);ADVR_Assert(self.mana==20 && !p.advr_enchant_type,"cancelled ammo infusion is free");
    for(i=0;i<65;i=i+1)ADVR_EnchantFrame(book,0,1,0);
    ADVR_Assert(self.mana==17 && p.advr_enchant_type==1 && !p.advr_enchant_until,"magazine costs three mana and has no expiration");
    for(i=0;i<65;i=i+1)ADVR_EnchantFrame(book,0,1,0);
    ADVR_Assert(self.mana==17,"holding stick cannot repeatedly charge mana");
    self.advr_enchant_latched=0;p.advr_round_count=1;p.advr_round_type=1;p.advr_enchant_type=0;
    for(i=0;i<65;i=i+1)ADVR_EnchantFrame(book,0,1,0);
    ADVR_Assert(self.mana==16 && p.advr_enchant_type==1,"individual shell costs one mana");
    self.advr_enchant_latched=0;p.advr_round_count=2;
    for(i=0;i<65;i=i+1)ADVR_EnchantFrame(book,0,1,0);
    ADVR_Assert(self.mana==14,"two-shell bundle costs two mana");
    self.advr_enchant_latched=0;self.mana=0;p.advr_enchant_type=0;
    for(i=0;i<65;i=i+1)ADVR_EnchantFrame(book,0,1,0);
    ADVR_Assert(!p.advr_enchant_type && self.mana==0,"insufficient mana cannot enchant ammunition");
    for(h=0;h<2;h=h+1){
        self.advr_main=self.advr_off=self.advr_round[0]=self.advr_round[1]=world;
        if(h)self.advr_off=book;else self.advr_main=book;self.advr_round[h]=p;
        self.vrbits0=16384;self.advr_known=1791;self.advr_magic_version=1;self.advr_spell=2;self.mana=10;
        self.advr_enchant_latched=0;self.advr_magic_oldsticks=0;self.advr_magic_sticks=pow(2,h);
        p.advr_round_count=1;p.advr_enchant_type=0;
        for(i=0;i<65;i=i+1)ADVR_MagicFrame();
        ADVR_Assert(p.advr_enchant_type==3 && self.mana==9,"tome stick gesture enchants held ammunition in either hand");
        self.advr_magic_sticks=0;ADVR_MagicFrame();
    }
    frametime=oldframe;self.advr_main=self.advr_off=self.advr_round[0]=self.advr_round[1]=world;remove(p);remove(book);ADVR_EnchantClear();
    ADVR_TestPouchSelection();
    dprint("ADVR AMMO ENCHANT PASS\n");
};

// Preview the next three draws without changing counts or the per-weapon LIFO stack.
// Each item packs count in the low byte and element above it; zero means no item.
void() ADVR_PouchPreview = {
    local entity r;local float key,w,capacity,available,reserved,i,n,element,packed,family;
    local string stack;
    self.advr_pouch_preview_key=self.advr_pouch_preview0=self.advr_pouch_preview1=self.advr_pouch_preview2=0;
    r=self.advr_main;if(!ADVR_ManualType(r))r=self.advr_off;
    if(ADVR_ManualType(r))key=ADVR_AmmoKey(r);
    else if(ADVR_IsTome(self.advr_main) || ADVR_IsTome(self.advr_off))key=bound(0,self.advr_pouch_selection,9);
    else return;
    self.advr_pouch_preview_key=key+1;family=ADVR_AmmoFamily(key);
    w=IT_SHOTGUN;if(family==2)w=IT_NAILGUN;if(family==3)w=IT_ROCKET_LAUNCHER;if(family==4)w=IT_LIGHTNING;
    available=max(0,ADVR_Ammo(w)-ADVR_Loaded(w));if(key==9)available=self.advr_bolts;
    capacity=1;if(key==1)capacity=2;if(key==2 || key==7 || key==8)capacity=24;if(key==3 || key==6)capacity=36;
    for(i=0;i<10;i=i+1)if(ADVR_AmmoFamily(i)==family)reserved=reserved+ADVR_AmmoTotal(self.advr_pouch[i]);
    stack=self.advr_pouch[key];
    for(i=0;i<3;i=i+1){
        element=0;
        if(strlen(stack)>=4){
            n=min(capacity,min(available,ADVR_AmmoCount(stack)));element=ADVR_AmmoDigit(stack,2);
            if(n==ADVR_AmmoCount(stack))stack=substring(stack,4,1023);
            else stack=strcat(ADVR_AmmoEntry(ADVR_AmmoCount(stack)-n,element,1),substring(stack,4,1023));
            reserved=reserved-n;
        }else n=min(capacity,max(0,available-reserved));
        if(n<=0)break;
        packed=n+256*element;available=available-n;
        if(i==0)self.advr_pouch_preview0=packed;
        if(i==1)self.advr_pouch_preview1=packed;
        if(i==2)self.advr_pouch_preview2=packed;
    }
};
