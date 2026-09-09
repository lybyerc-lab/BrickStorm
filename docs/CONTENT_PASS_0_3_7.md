# Content Pass 0.3.7

## Character

The playable character now reads more as a clean molded brick toy at phone distance. Visual complexity was spent on silhouette and articulation rather than additional texture detail. The motor is unchanged; the presentation now distributes motion across pelvis, torso, limbs, and head so the body does not swing as one rigid mass.

## Post-probe county-road chase

Storm Run no longer stops immediately after the probe payoff. A new county-road chase continues north of the farm with:

- extended continuous road and prairie dressing;
- road-guidance studs;
- smashable roadside props;
- wind-thrown debris crossings;
- a roadside storm-chaser NPC;
- a new buildable road beacon;
- wrench-based post-build repair;
- an `InteractionGraph`-controlled county barrier;
- a hero utility-pole destruction beat;
- first-intercept reward and a Wakita-forward objective hook.

The encounter deliberately alternates **drive -> react -> stop/build/tool -> consequence -> drive -> destruction** rather than becoming a long empty vehicle corridor.

## Mobile discipline

The extension keeps static dressing light and preserves independent identity only for gameplay-active pieces. Debris gusts are bounded bursts, the barrier and beacon are compact hero objects, and the road collision is a simple overlapping slab rather than detailed render collision.
