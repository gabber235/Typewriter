# Topology

## What it is

Typewriter is made of separate parts that run in different places.

```
Typewriter Cloud (hosted by the Typewriter team)
  backend, web panel
        |
        v
Realm (server owner's hardware)        one per installation
  manages content
  synchronizes content and state between engines
  gateway between the panel and engines
        |
        v
Engines (Paper engine, panel engine, ...)
  execute published content using extensions

Host: a process that runs a realm, engines, or both
```

| Part | Runs where | Responsibility |
| --- | --- | --- |
| Typewriter Cloud | Typewriter team | Official backend and the hosted web panel |
| Realm | Server owner's hardware (hosting company or VPS) | Owns content, synchronizes content and state between engines, gateway between panel and engines |
| Engine | A Minecraft server or another runtime | Takes published content as configuration and enacts it, using extensions |
| Host | Server owner's hardware | Runs a realm, engines, or both. Host types differ in what they can run |

Example: the Paper host can run both a Paper engine and the realm.

### What lives where

```
Typewriter Cloud                  Realm (owner's hardware)
  accounts, organizations           content: books, entries
  members, roles                    protagonist data: stored values
  licenses (add ons)                publications, revisions
  marketplace
  hosted web panel
```

**Content and player data live only on the realm.** Someday the cloud may offer **backups and sync** for a monthly fee; not now.

**Cloud outage:** today, servers keep running and protagonists keep playing as long as NATS and the servers stay up, but engines cannot reconnect. Goal (end of closed beta or later): a **NATS leaf node** that owners can host, so engines and the realm keep talking to each other during an outage.

A realm runs in **development** or **production** mode (see [realm-modes.md](realm-modes.md)).

## Who it serves

Server owners run realms and hosts. Content creators reach engines through the panel and realm. Protagonists only see engines.

## Why

Separating content ownership (realm) from execution (engines) lets one set of content drive many engines and keeps state consistent between them.

## Horizon and maturity

| Item | Horizon | Maturity |
| --- | --- | --- |
| Cloud, realm, engine, host split | closed beta | shaped |
| Realm synchronizes state between engines | closed beta | shaped |
| Panel as desktop apps (see [panel.md](panel.md)) | later | wish |
| Panel as mobile apps (see [panel.md](panel.md)) | someday | wish |
| Renting a realm hosted by the Typewriter team (far future) | someday | wish |
| Content and player data only on the realm | closed beta | settled |
| Self hosted NATS leaf node for cloud outages (end of closed beta or later) | closed beta (not at the start)? | sketch |
| Paid cloud backups and sync | someday | wish |

## Open questions

- Which host types are planned besides the Paper host?
