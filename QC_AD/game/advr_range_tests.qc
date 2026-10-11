void() ADVR_TestRange = {
    local entity e;local float bows,hammers,left,right,tomes;
    ADVR_Assert(mapname=="ad_test11","range fixture uses firing range map");
    ADVR_RangeSetup();ADVR_RangeSetup();
    e=find(world,classname,"advr_dropped_weapon");
    while(e) {
        if(e.weaponinst.advr_kind==ADVR_CROSSBOW){
            bows=bows+1;ADVR_Assert(e.weaponinst.advr_bolt_pack==12,"range crossbow includes 12 bolts");
            ADVR_Assert(e.model=="progs/advr_crossbow.mdl","range crossbow has usable model");
        }
        if(e.weaponinst.advr_kind==ADVR_HAMMER){
            hammers=hammers+1;ADVR_Assert(e.model=="progs/advr_hammer.mdl","range hammer has usable model");
        }
        if(e.weaponinst.advr_kind==ADVR_TOME)tomes=tomes+1;
        if(e.weaponinst.advr_kind==ADVR_FURY1)left=left+1;
        if(e.weaponinst.advr_kind==ADVR_FURY2)right=right+1;
        e=find(e,classname,"advr_dropped_weapon");
    }
    ADVR_Assert(bows==1 && hammers==1 && left==1 && right==1 && tomes==1,"range has one of each weapon without duplicates after setup/load");
    bprint("ADVR RANGE PASS: tome, hammer, Fury pair, crossbow with 12 bolts, idempotent setup\n");
};
