---
title: Dragon Training 101
description: A beginner's guide to befriending and training your first dragon.
editUrl: true
head: []
template: doc
sidebar:
  hidden: false
  attrs: {}
pagefind: true
draft: false
---

So you've decided to train a dragon. Excellent choice! This guide will walk you through everything from selecting your scaly companion to teaching them not to burn down your village.

:::warning
Dragons are not pets. They are majestic, fire-breathing partners who will tolerate your existence if you're lucky.
:::

---

## Choosing Your Dragon

### Popular Breeds

| Breed | Size | Temperament | Fire Color |
| :--- | :---: | :---: | ---: |
| Norwegian Ridgeback | Large | Aggressive | Orange |
| Welsh Green | Medium | Docile | Green-tinted |
| Swedish Short-Snout | Medium | Shy | Blue |
| Common Garden Drake | Small | Friendly | Yellow |

:::tip[First Timer?]
Start with a Common Garden Drake. They're the golden retrievers of the dragon world.
:::

### What to Look For

When selecting a dragon hatchling, check for:

1. Bright, alert eyes
2. Shiny scales (no dullness)
3. Strong wing membranes
4. A willingness to not immediately eat you

```typescript
interface Dragon {
  name: string;
  breed: string;
  age: number;
  fireBreathEnabled: boolean;
  trustLevel: number; // 0-100
}

function assessDragon(dragon: Dragon): string {
  if (dragon.trustLevel < 20) {
    return "Keep your distance!";
  }
  return "Safe to approach";
}
```

---

## Basic Training Commands

### The Essential Five

:::info
All commands should be given in a firm but respectful tone. Dragons can smell fear AND condescension.
:::

1. **"Dracarys"** — Breathe fire (use sparingly)
2. **"Sōvēs"** — Fly
3. **"Kelītīs"** — Stop/Halt
4. **"Mazvērdagon"** — Eat (your enemy, not you)
5. **"Lykirī"** — Calm down

### Training Schedule

```yaml
weekly_schedule:
  monday:
    - morning: "Trust exercises"
    - afternoon: "Short flights"
  tuesday:
    - morning: "Fire control practice"
    - afternoon: "Rest (dragons need 18 hours sleep)"
  wednesday:
    - morning: "Obstacle course"
    - afternoon: "Treat rewards"
  thursday:
    - morning: "Advanced maneuvers"
    - afternoon: "Bonding time"
  friday:
    - all_day: "Free flight day"
```

:::danger
Never train a dragon when hungry. Neither you nor the dragon. Someone will get eaten.
:::

---

## Feeding Your Dragon

### Dietary Requirements

Dragons are obligate carnivores with specific needs:

- **Protein**: 80% of diet (sheep, cattle, the occasional knight)
- **Minerals**: Charcoal and volcanic rock for digestion
- **Hydration**: A small lake per week

:::note
Contrary to popular belief, dragons do NOT eat princesses. That's just bad PR from medieval times.
:::

### Foods to Avoid

| Food | Reason |
| --- | --- |
| Chocolate | Toxic to dragons |
| Processed meats | Digestive issues |
| Anything frozen | Offends their fire nature |
| Salads | They'll lose respect for you |

---

## Common Problems

:::bug[Known Issue]
Some dragons develop a habit of hoarding gold. This is normal behavior and should be accommodated, not corrected.
:::

### My Dragon Won't Listen

Check the following:

- [ ] Have you established trust?
- [ ] Is the dragon well-fed?
- [ ] Are you speaking clearly?
- [ ] Did you accidentally insult their mother?

### Unexpected Fire Breathing

```bash
# Emergency protocol
./dragon-control --command=kelītīs --urgency=high

# If that fails
./evacuate-village --radius=5km
```

:::success
Congratulations on starting your dragon training journey! May your eyebrows remain intact.
:::