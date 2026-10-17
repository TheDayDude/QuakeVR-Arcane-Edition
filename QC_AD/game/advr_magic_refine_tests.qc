void() ADVR_TestMagicRefine = {
    local entity actor,r,q,shot,controller,v,prop;local float packed,kind,i,count;
    actor=self;
    r=ADVR_Record(IT_AXE);r.advr_kind=ADVR_SWORD;r.advr_enchant_type=5;r.advr_enchant_until=time+30;
    ADVR_VoidWeapon(r);kind=r.advr_kind;
    ADVR_Assert(kind!=ADVR_SWORD && r.advr_void_original==ADVR_SWORD+1 && r.nextthink==time+30,"void changes melee form temporarily");
    packed=ADVR_EnchantPack(r);q=ADVR_Record(IT_AXE);q.advr_kind=kind;ADVR_EnchantRestore(q,packed);
    ADVR_Assert(q.advr_void_original==ADVR_SWORD+1 && q.nextthink==time+30,"map state preserves original melee form and timer");
    prop=spawn();prop.classname="advr_dropped_weapon";prop.weaponinst=q;setmodel(prop,ADVR_RecordModel(q));
    self=q;ADVR_VoidWeaponThink();self=actor;
    ADVR_Assert(q.advr_kind==ADVR_SWORD && !q.advr_void_original && prop.model=="progs/v_ksword.mdl","expiry restores dropped model and original kind");
    remove(prop);remove(q);ADVR_VoidRestore(r);remove(r);
    r=ADVR_Record(IT_SHOTGUN);r.advr_enchant_type=5;r.advr_enchant_until=time+30;
    shot=spawn();shot.owner=self;shot.classname="advr_test_homing";shot.solid=SOLID_BBOX;shot.movetype=MOVETYPE_FLYMISSILE;
    setmodel(shot,MODEL_PROJ_WIZ);setorigin(shot,ADVR_Head(self)+'24 0 0');setsize(shot,'0 0 0','0 0 0');
    shot.velocity='500 0 0';shot.think=SUB_Remove;shot.nextthink=time+5;
    advr_attack_actor=self;advr_attack_record=r;ADVR_EnchantMissile(shot);advr_attack_actor=world;advr_attack_record=world;
    controller=shot.advr_homing_controller;
    ADVR_Assert(controller && shot.think==SUB_Remove && shot.nextthink==time+5,"homing preserves missile think and fuse");
    v=spawn();v.flags=FL_MONSTER;v.health=1000;v.takedamage=DAMAGE_YES;v.solid=SOLID_BBOX;
    setsize(v,'-4 -4 -4','4 4 4');setorigin(v,shot.origin+'40 40 0');
    self=controller;ADVR_VoidHomingThink();self=actor;
    ADVR_Assert(shot.velocity_y>0 && fabs(vlen(shot.velocity)-500)<1,"void weapon projectile curves without changing speed");
    shot.advr_enchant_until=time-1;self=controller;ADVR_VoidHomingThink();self=actor;
    ADVR_Assert(!shot.advr_homing_controller,"homing ends with enchantment");remove(shot);remove(v);remove(r);
    // Each requested replacement has native AI and fits a generously empty location.
    for(i=0;i<8;i=i+1) {
        v=ADVR_HammerTestFoe();setorigin(v,actor.origin+'0 80 100');
        q=ADVR_VoidTransform(v,actor,i);
        ADVR_Assert(q && q.classname!="monster_army" && q.think==FoundTarget,"monstrous replacement has active native AI");remove(q);
    }
    prop=find(world,classname,"item_gib");while(prop){count=count+1;prop=find(prop,classname,"item_gib");}
    ADVR_Assert(count>=72,"transformations burst into physical gibs");
    // Leave a visible frosted target and five floating enchanted missiles for renderer inspection.
    v=ADVR_HammerTestFoe();v.advr_frost_until=time+8;setorigin(v,actor.origin+'100 0 24');
    for(i=1;i<=5;i=i+1) {
        shot=spawn();shot.classname="advr_enchant_probe";shot.movetype=MOVETYPE_NONE;
        setmodel(shot,MODEL_PROJ_SHAL);setorigin(shot,ADVR_Head(actor)+'90 0 0'+'0 16 0'*(i-3));
        shot.advr_enchant_type=i;shot.advr_enchant_until=time+30;
        shot.think=SUB_Remove;shot.nextthink=time+10;
    }
    bprint("ADVR MAGIC REFINE PASS: temporary melee forms, persistence, homing, expiry, monster pool and gibs\n");
};
