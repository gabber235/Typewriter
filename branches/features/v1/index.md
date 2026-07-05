---
title: Typewriter
description: Build interactive quests, NPC dialogues, and cinematic sequences on
  your Paper Minecraft server — no coding required, endlessly extensible for
  developers.
editUrl: false
head: []
tableOfContents: false
template: splash
lastUpdated: false
prev: false
next: false
sidebar:
  hidden: false
  attrs: {}
pagefind: true
draft: false
glossary: false
---

import { AudienceCard, AudienceSplit } from '@components/audiencesplit';
import { CommunityBand } from '@components/community';
import { CtaBand } from '@components/ctaband';
import { DemoShowcase, FeatureCard, FeatureGrid } from '@components/featuregrid';
import { Home } from '@components/home';
import { IntroAnimation } from '@components/intro';
import { VideoPlayer } from '@components/video';
import panelDemo from '@assets/home/panel-demo.png';
import { BASE_PATH } from '../../base-path';

<Home>

<IntroAnimation
	primaryCta={{ label: 'Get Started', href: './01-typewiter', icon: 'arrow' }}
	secondaryCta={{ label: 'Join Discord', href: 'https://discord.gg/HtbKyuDDBw', icon: 'discord' }}
/>

<FeatureGrid>
	<FeatureCard
		icon="comment-alt"
		title="Interactive Dialogues & Quests"
		description="Create dialogues, branching storylines, and dynamic quests that respond to player choices."
		media={{ src: `${BASE_PATH}media/chat-messages.gif`, alt: 'A Typewriter NPC dialogue with branching player choices' }}
	/>
	<FeatureCard
		icon="rocket"
		title="Cinematic Sequences"
		description="Build dynamic camera paths, animated NPC interactions, and immersive cutscenes that captivate your players."
	/>
	<FeatureCard
		icon="random"
		title="Intelligent NPCs & Entities"
		description="Custom activities, appearance changes, and player-specific entities that feel alive."
	/>
	<FeatureCard
		icon="forward-slash"
		title="Custom Commands"
		description="Create server commands that trigger your custom content — no coding required."
	/>
	<FeatureCard
		icon="laptop"
		title="Visual Configuration"
		description="Manage all your content using a visual web panel designed for ease of use."
		media={{ src: panelDemo.src, alt: 'The Typewriter web panel interface' }}
	/>
	<FeatureCard
		icon="puzzle"
		title="Extensions System"
		description="Extend Typewriter with modular components that integrate custom plugins and unique in-game experiences."
		href="https://github.com/Gabber235/typewriter"
	/>
</FeatureGrid>

<DemoShowcase
	title="Watch Typewriter in action"
	description="A complete walkthrough of the web panel and the interactive experiences you can build with it."
>
	<VideoPlayer
		src="@assets/videos/home/tw-demo.mp4"
		poster={panelDemo.src}
		preload="none"
	/>
</DemoShowcase>

<AudienceSplit>
	<AudienceCard
		eyebrow="For Admins"
		heading="No coding required"
		body="Configure complex interactions, NPCs, and quests through the visual web panel — even without prior coding knowledge. Need something specific? The extension system makes customization easy."
		accent="primary"
		cta={{ label: 'Read the docs', href: './01-typewiter' }}
	/>
	<AudienceCard
		eyebrow="For Developers"
		heading="Built to be extended"
		body="Typewriter is built to be highly extensible. The extensions system lets you build modular, reusable components that seamlessly integrate with the plugin."
		accent="secondary"
		cta={{ label: 'Explore the code', href: 'https://github.com/Gabber235/typewriter' }}
	/>
</AudienceSplit>

<CommunityBand />

<CtaBand
	heading="Ready to bring your server to life?"
	body="Join the beta and start building interactive experiences today."
	primaryCta={{ label: 'Get Started', href: './01-typewiter' }}
	secondaryCta={{ label: 'Join Discord', href: 'https://discord.gg/HtbKyuDDBw' }}
/>

</Home>