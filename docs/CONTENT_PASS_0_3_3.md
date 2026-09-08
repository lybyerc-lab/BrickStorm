# Content Pass 0.3.3

Foundation 0.3.3 turns the 0.3.2 build language into gameplay utility. Physical-phone feedback rated barn destruction 4/5, storm-probe building 5/5, and overall LEGO-game feel 4/5. The probe build rhythm is therefore preserved as a reference, while completed objects begin changing what the player can do.

## Usable buildables

`BuildableObject` now supports an optional post-build interaction state. A completed object can remain in the contextual ACTION system, advertise a new prompt, require a named actor-owned tool, apply a cooldown, and run object-specific utility behavior.

Current examples:

- Weather scanner: build it, then ACTION scans for the nearest uncollected sensor kit and reveals a short stud breadcrumb trail. After all kits are recovered it reports the active storm.
- Wind vane: build it, then ACTION reads the tracked storm bearing and distance.
- Storm probe: after the existing staged 5/5 build sequence, the finished probe remains interactable and produces a live storm readout.
- Cow ramp: remains a traversal-changing buildable through its physical ramp collider.

## First contextual tool loop

The farm now contains the first complete tool puzzle:

1. find the brick-built wrench;
2. carry it visibly on the chaser;
3. build the farm generator;
4. the generator advertises `NEEDS WRENCH` and refuses activation without it;
5. use ACTION with the wrench to repair the generator;
6. the generator emits a named utility state;
7. a powered equipment gate lifts permanently and reveals a stud cache.

No extra mobile tool button was added. Tools use the existing contextual ACTION path so the phone interface stays readable.

## Architecture

- `ToolbeltComponent` owns actor tools independently of world objects.
- `ToolPickup` grants a stable tool ID and display name.
- `BuildableObject` owns the generic post-build usability and tool-requirement contract.
- `GameEvents.utility_activated` lets built machines change unrelated world objects without hard scene references.
- `PoweredEquipmentGate` demonstrates a permanent route/reward change triggered through that signal.
- The HUD exposes the current tool summary without making core mission state tool-specific.

## North Star rule

Important rebuildables should increasingly answer: **what becomes possible after I build this?**

Good answers include opening a route, powering equipment, repairing a vehicle, revealing a secret, operating storm gear, creating traversal, enabling a character ability, or becoming a later-level dependency.
