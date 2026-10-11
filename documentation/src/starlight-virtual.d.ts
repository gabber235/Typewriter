// Starlight ships plain JavaScript since 0.42 and no longer publishes type
// declarations for its virtual modules, yet its own components and our
// overrides still import them. Mirrors the declarations Starlight shipped up
// to 0.41.

declare module "virtual:starlight/user-config" {
	const Config: import("@astrojs/starlight/types").StarlightConfig;
	export default Config;
}

declare module "virtual:starlight/project-context" {
	const ProjectContext: {
		root: string;
		srcDir: string;
		trailingSlash: import("astro").AstroConfig["trailingSlash"];
		build: {
			format: import("astro").AstroConfig["build"]["format"];
		};
	};
	export default ProjectContext;
}

declare module "virtual:starlight/user-css" {}

declare module "virtual:starlight/optional-css" {}

declare module "virtual:starlight/user-images" {
	export const logos: {
		dark?: import("astro").ImageMetadata;
		light?: import("astro").ImageMetadata;
	};
}

declare module "virtual:starlight/pagefind-config" {
	export const pagefindUserConfig: Partial<
		Extract<
			import("@astrojs/starlight/types").StarlightConfig["pagefind"],
			object
		>
	>;
}

// Typed generically rather than as `typeof import(".../X.astro")` so tsc does
// not pull Starlight's shipped `.astro` sources into the check: the content
// mapper type-checks them, and skipLibCheck only covers `.d.ts` files.
declare module "virtual:starlight/components/*" {
	const Component: import("astro/runtime/server/index.js").AstroComponentFactory;
	export default Component;
}
