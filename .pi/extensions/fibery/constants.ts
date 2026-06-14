export const BUG_STATUS_VALUES = [
	"Rejected",
	"Unreproducible",
	"In Beta",
	"In Production",
	"Investigating",
	"In Progress",
	"Fixed",
	"Done",
] as const;

export const BUG_PRIORITY_VALUES = ["Critical", "High", "Normal", "Low"] as const;

export const FEATURE_STATUS_VALUES = ["Backlog", "In Progress", "Done", "In Beta", "In Production"] as const;

export const FEATURE_SIZE_VALUES = ["Minutes", "Hours", "Days", "Weeks", "Months"] as const;

export const FEATURE_IMPORTANCE_VALUES = ["Major", "Notable", "Minor", "Internal"] as const;

export type BugStatus = (typeof BUG_STATUS_VALUES)[number];
export type BugPriority = (typeof BUG_PRIORITY_VALUES)[number];
export type FeatureStatus = (typeof FEATURE_STATUS_VALUES)[number];
export type FeatureSize = (typeof FEATURE_SIZE_VALUES)[number];
export type FeatureImportance = (typeof FEATURE_IMPORTANCE_VALUES)[number];

export const DOMAIN_OPTIONS = [
	"Engine Core",
	"Engine Paper",
	"Module Plugin",
	"Basic Extension",
	"Entity Extension",
	"Marketplace",
	"Panel",
	"WorldGuard Extension",
	"Vault Extension",
	"RoadNetwork Extension",
	"Quest Extension",
	"Engine Loader",
	"Discord Bot",
	"Visibility Extension",
] as const;

export type DomainName = (typeof DOMAIN_OPTIONS)[number];

export const DOMAIN_ID_BY_NAME: Record<DomainName, string> = {
	"Engine Core": "5cedf4a0-e3e1-11ef-88e6-1388263f3f2c",
	"Engine Paper": "68431bf0-e3e1-11ef-88e6-1388263f3f2c",
	"Module Plugin": "6c4431d0-e3e1-11ef-88e6-1388263f3f2c",
	"Basic Extension": "72b0a260-e3e1-11ef-88e6-1388263f3f2c",
	"Entity Extension": "74a40df0-e3e1-11ef-88e6-1388263f3f2c",
	Marketplace: "7a23fba0-e3e1-11ef-88e6-1388263f3f2c",
	Panel: "7cd5ae20-e3e1-11ef-88e6-1388263f3f2c",
	"WorldGuard Extension": "841b67b0-e3e1-11ef-88e6-1388263f3f2c",
	"Vault Extension": "85bcbba0-e3e1-11ef-88e6-1388263f3f2c",
	"RoadNetwork Extension": "100c2f10-e3e3-11ef-88e6-1388263f3f2c",
	"Quest Extension": "12fd82a0-e3e3-11ef-88e6-1388263f3f2c",
	"Engine Loader": "39a87f00-e482-11ef-a5a4-f9c920bf52d9",
	"Discord Bot": "10012595-98f1-4ef9-842d-20a43b7421c0",
	"Visibility Extension": "f3f74f70-9e32-11f0-9626-9b858dc345a8",
};

export type ItemKind = "bug" | "feature";

export const WORKFLOW_TYPE_IDS = {
	bug: "Development/Bugs",
	feature: "Development/Features",
} as const;

export const WORKFLOW_FIELD_IDS = {
	bug: {
		nameField: "Development/Name",
		statusField: "workflow/state",
		priorityField: "Development/Priority",
		descriptionField: "Development/Description",
		milestoneField: "Development/Milestone",
		betaField: "Milestone/Beta",
		domainsField: "Development/Domains",
		discordsField: "Development/Discords",
		linksField: "Development/Features",
	},
	feature: {
		nameField: "Development/Name",
		statusField: "workflow/state",
		sizeField: "Development/Size",
		importanceField: "Development/Importance",
		descriptionField: "Development/Description",
		milestoneField: "Development/Milestone",
		betaField: "Milestone/Beta",
		domainsField: "Development/Domains",
		discordsField: "Development/Discords",
		linksField: "Development/Bugs",
	},
} as const;

export const RELATED_TYPE_IDS = {
	domain: "Development/Domain",
	discord: "Development/Discord",
	discordChannelIdField: "Development/Discord Channel Id",
	milestone: "Milestone/Milestone",
	beta: "Milestone/Beta",
	betaIdentifierField: "Milestone/Identifier",
	nameField: "Development/Name",
	milestoneNameField: "Milestone/Name",
} as const;

export const DEFAULT_STATUS_BY_KIND: { bug: BugStatus; feature: FeatureStatus } = {
	bug: "Investigating",
	feature: "Backlog",
};

export const BETA_PUBLICATION_FIELD = "Milestone/Publication" as const;

export const BUG_PRIORITY_SORT: Record<BugPriority, number> = {
	Critical: 0,
	High: 1,
	Normal: 2,
	Low: 3,
};

export const FEATURE_IMPORTANCE_SORT: Record<FeatureImportance, number> = {
	Major: 0,
	Notable: 1,
	Minor: 2,
	Internal: 3,
};

export const MILESTONE_IN_DEVELOPMENT_STATE = "In Development" as const;
