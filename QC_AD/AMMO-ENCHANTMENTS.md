# Permanent ammunition enchantments

Hold a physical round or magazine in one hand and a tome in the other. Select
Fire, Lightning, Frost, Acid, Void, or Slipstep, then hold the ammo hand's
thumbstick click for three seconds, as with weapon infusion. Releasing early
cancels without spending mana. Release the stick before starting another infusion.

Enchanted physical rounds and magazines use the same elemental visual effect as
enchanted weapons, including while held or dropped. The effect also builds during
infusion and has no expiry once the ammo is enchanted.

With a tome in either hand, click **that hand's thumbstick** to cycle the ammo
pouch selection. A message names the selected package. Use the free hand to draw
from the ammo pouch as usual (immersive reload mode); no gun is required. Each
click advances once through shotgun shells, super shotgun pairs, nailgun and
super nailgun magazines, grenades, rockets, thunderbolt and plasma cells,
Widowmaker magazines, and crossbow bolts. Selection starts at shotgun shells.
The separate grenade pouch keeps its normal behavior. Holding a gun instead of
a tome continues to select its ammo automatically. The ammo hand's thumbstick
still performs infusion; the tome hand's click only changes the pouch selection.

The ammo pouch previews up to three upcoming draws using the selected weapon's
actual round or magazine model. Each item shows its own enchantment. The rightmost
item (from the wearer's viewpoint) is drawn first; crossbow bolts are stacked with
the next bolt on top. The preview updates after drawing, returning, or switching
ammo. Partial magazines stay separate, and ammo reserved for another weapon is
not shown as available. More stored packages appear as space becomes available.

- Magazines cost **3 mana**, including partially used magazines and Widowmaker magazines.
- Individual shotgun shells, grenades, rockets, and crossbow bolts cost **1 mana each**.
  A two-shell bundle costs 2 mana.
- Ammo has no enchantment timer. Its element and rune strength remain with it
  through storage, loading, ejection, drops, save/load, and level transitions.
- Each weapon has its own pouch stack. The last package returned is the next
  drawn for that weapon, including its remaining round count. Standard reserve
  ammunition is drawn after that stack is empty. Shared ammo counters cannot
  spend packages reserved for another weapon.
- Loaded rounds fire in loading order. An enchanted round supplies the shot's
  infusion; an ordinary round still benefits from a temporary weapon infusion.
  Infusing ammo again replaces its previous element.

Utility enchantments (such as Protection, invisibility, and Darksight) remain
weapon enchantments. Empty magazines and armed grenades cannot be infused.
Existing map rules that remove weapons or ammunition still apply. Physical
ammo dropped into the world follows the existing cleanup rules.

Costs can be adjusted with `vr_ad_ammo_enchant_mag_cost` (default 3) and
`vr_ad_ammo_enchant_round_cost` (default 1). Negative values act as zero.

Existing saves treat previously untracked ammunition as ordinary ammo. New saves
contain the pouch and loaded-round metadata. Each weapon's pouch supports 255
separate returned packages, beyond standard carried ammo limits; if full, a
returned object stays physical instead of losing its enchantment.
