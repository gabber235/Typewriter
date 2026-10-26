---
title: Haunted House API Reference
description: Complete documentation for the GhostOS™ Smart Haunted House Management System.
editUrl: true
head: []
template: doc
sidebar:
  hidden: false
  attrs: {}
pagefind: true
draft: false
---

Welcome to the GhostOS™ API documentation. This system allows you to programmatically control all paranormal activities in your haunted property.

:::warning
This API controls actual supernatural entities. Use responsibly.
:::

---

## Authentication

All requests require a valid `X-Specter-Key` header.

```bash
curl -X GET https://api.ghostos.spooky/v1/ghosts \
  -H "X-Specter-Key: your_ethereal_key_here"
```

:::danger
Never expose your Specter Key. Unauthorized access may result in unwanted hauntings.
:::

---

## Endpoints

### Ghosts

#### `GET /api/v1/ghosts`

Retrieve all registered supernatural entities.

**Response:**

```json
{
  "ghosts": [
    {
      "id": "gh_001",
      "name": "The Grey Lady",
      "type": "apparition",
      "floor": 3,
      "spookLevel": 7,
      "schedule": "22:00-04:00",
      "chainRattling": true
    },
    {
      "id": "gh_002", 
      "name": "Headless Harold",
      "type": "poltergeist",
      "floor": "basement",
      "spookLevel": 9,
      "schedule": "midnight only",
      "chainRattling": false
    }
  ],
  "total": 2
}
```

#### `POST /api/v1/ghosts/{id}/activate`

Manually trigger a haunting event.

```typescript
interface HauntingRequest {
  ghostId: string;
  intensity: 1 | 2 | 3 | 4 | 5;
  effects: HauntingEffect[];
  duration: number; // minutes
}

type HauntingEffect = 
  | 'cold_spot'
  | 'flickering_lights'
  | 'mysterious_whispers'
  | 'floating_objects'
  | 'full_manifestation';
```

:::tip
Start with intensity 1-2 for new visitors. Jumping to 5 has resulted in lawsuits.
:::

---

### Atmospheric Controls

#### `PUT /api/v1/atmosphere`

Control environmental spookiness.

| Parameter | Type | Range | Description |
| --- | --- | :---: | --- |
| `fog_density` | float | 0-1 | Ground fog thickness |
| `temperature` | number | -10 to 25 | Celsius, lower is spookier |
| `creaking_frequency` | number | 0-100 | Floor creak events per hour |
| `cobweb_deployment` | boolean | — | Release fresh cobwebs |

```json
{
  "fog_density": 0.7,
  "temperature": 12,
  "creaking_frequency": 45,
  "cobweb_deployment": true,
  "thunder_probability": 0.3
}
```

:::note
Cobwebs are biodegradable spider silk. No actual spiders are employed (they unionized).
:::

---

### Audio System

#### `POST /api/v1/audio/play`

Trigger atmospheric sounds.

```python
import ghostos

client = ghostos.Client(api_key="your_key")

# Queue spooky sounds
client.audio.play([
    {"sound": "distant_scream", "volume": 0.6, "delay": 0},
    {"sound": "chains_dragging", "volume": 0.4, "delay": 5},
    {"sound": "evil_laughter", "volume": 0.8, "delay": 10}
])

# Emergency: calm everyone down
client.audio.play_calming_music()
```

**Available Sounds:**

| Sound ID | Description | Scare Rating |
| --- | --- | :---: |
| `distant_scream` | Muffled scream from unknown location | ⭐⭐⭐ |
| `chains_dragging` | Classic ghost chain sounds | ⭐⭐ |
| `evil_laughter` | Maniacal laughing, echoed | ⭐⭐⭐⭐ |
| `children_singing` | Creepy nursery rhyme | ⭐⭐⭐⭐⭐ |
| `your_name` | Whispers visitor's actual name | ⭐⭐⭐⭐⭐⭐ |

:::danger
`your_name` requires visitor consent forms. The legal team insists.
:::

---

### Event Scheduling

#### `POST /api/v1/schedule`

Create automated haunting schedules.

```yaml
haunting_schedule:
  weekdays:
    - time: "20:00"
      event: "lights_flicker"
      zones: ["entrance", "hallway"]
    
    - time: "22:00"
      event: "ghost_appearance"
      ghost_id: "gh_001"
      duration: 30
    
    - time: "00:00"
      event: "full_haunting"
      intensity: 4
      
  weekends:
    - time: "19:00"
      event: "family_friendly_spooks"
      intensity: 2
      # No actual terror, just ambiance
```

:::experimental
We're testing AI-driven adaptive hauntings that respond to visitor fear levels. Beta access available.
:::

---

## Error Handling

### Error Codes

| Code | Description | Resolution |
| --- | --- | --- |
| `401` | Invalid Specter Key | Check authentication |
| `404` | Ghost not found | May have crossed over |
| `429` | Too many hauntings | Ghosts need rest too |
| `500` | Server possessed | Contact support |
| `666` | Demonic interference | Call an exorcist |

```typescript
try {
  await ghostos.activateHaunting(request);
} catch (error) {
  if (error.code === 666) {
    console.error("Demonic entity detected. Initiating containment...");
    await ghostos.emergency.containment();
  }
}
```

:::bug[Known Issue]
Error 666 sometimes triggers on Friday the 13th even without demonic activity. We're investigating.
:::

---

## Rate Limits

| Plan | Hauntings/Hour | Ghosts | Price |
| :--- | :---: | :---: | ---: |
| Starter | 10 | 2 | Free |
| Professional | 100 | 10 | $49/mo |
| Enterprise | Unlimited | Unlimited | $299/mo |
| Cursed | ∞ | ∞ + Demons | Your soul |

:::success
Ready to haunt? Start with our free tier and upgrade as your paranormal needs grow!
:::