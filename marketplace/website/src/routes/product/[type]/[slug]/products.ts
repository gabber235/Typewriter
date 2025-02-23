export interface Product {
    id: string;
    name: string;
    shortDescription: string;
    bannerImage: string;
    rating: number;
    price: number;
    currency: string;
    highlight?: boolean;
    color?: string;
    type: 'extension' | 'resource' | 'kekbre';
    slug: string;
    description: string;
    downloads: number;
    likes: number;
    views: number;
    fileSize: string;
    publishDate: string;
    updateDate: string;
    tags: string[];
    compatibility: {
        gameEdition: string;
        versions: string[];
    };
    license: {
        type: string;
    };
    platforms: string[];
    creator: {
        name: string;
        avatarUrl: string;
    };
    content: (Entry | Texture)[]
}

export interface Entry {
    name: string;
    description: string;
    type: string;
    icon: string;
    color: string;
}

export interface Texture {
    name: string;
    description: string;
    texture: string;
}

export const products: Product[] = [
    {
        id: "1",
        name: "All The Mods 10",
        shortDescription: "The latest modpack in this amazing series takes your modding experience to the max!",
        bannerImage: "https://media.forgecdn.net/game-carousel-background-images/game_carousel_item_background_4d0b2f3b-1c05-46f7-8ce3-7cda6a121b13.webp",
        rating: 4.5,
        price: 9.99,
        currency: "USD",
        highlight: false,
        color: "#A854F8",
        type: "extension",
        slug: "all-the-mods-10",
        description: "<p>Experience the ultimate modding adventure with All The Mods 10!</p>",
        downloads: 45000,
        likes: 320,
        compatibility: {
            gameEdition: "Typewriter versions",
            versions: ["0.6.x", "0.7.x", "0.8-beta"]
        },
        platforms: ["Paper", "Purpur"],
        license: {
            type: "MIT"
        },
        creator: {
            name: "gabber235",
            avatarUrl: "https://github.com/gabber235.png"
        },
        views: 667,
        fileSize: "245MB",
        publishDate: "Jul 17, 2024",
        updateDate: "Jan 2, 2025",
        tags: ["modpack", "adventure", "tech"],
        content: [
            {
                "name": "Entry 1",
                "description": "The description for Entry 1.",
                "type": "manifest.AudienceEntry",
                "icon": "mdi:anvil",
                "color": "#FF5733"
            },
            {
                "name": "Entry 2",
                "description": "The description for Entry 2.",
                "type": "static.ArtifactEntry",
                "icon": "material-symbols:chart-data-outline-sharp",
                "color": "#33FF57"
            },
            {
                "name": "Entry 3",
                "description": "The description for Entry 3.",
                "type": "static.AssetEntry",
                "icon": "mdi:data-matrix-scan",
                "color": "#3357FF"
            },
            {
                "name": "Entry 4",
                "description": "The description for Entry 4.",
                "type": "static.SoundIdEntry",
                "icon": "mdi:package-variant-closed",
                "color": "#FF33A6"
            },
            {
                "name": "Entry 5",
                "description": "The description for Entry 5.",
                "type": "static.SoundSourceEntry",
                "icon": "mdi:file-document-outline",
                "color": "#33FFA6"
            },
            {
                "name": "Entry 6",
                "description": "The description for Entry 6.",
                "type": "static.SpeakerEntry",
                "icon": "mdi:anvil",
                "color": "#A633FF"
            },
            {
                "name": "Entry 7",
                "description": "The description for Entry 7.",
                "type": "static.VariableEntry",
                "icon": "mdi:data-matrix-scan",
                "color": "#FFA633"
            },
            {
                "name": "Entry 8",
                "description": "The description for Entry 8.",
                "type": "trigger.ActionEntry",
                "icon": "mdi:package-variant-closed",
                "color": "#33A6FF"
            },
            {
                "name": "Entry 9",
                "description": "The description for Entry 9.",
                "type": "trigger.DialogueEntry",
                "icon": "mdi:file-document-outline",
                "color": "#A6FF33"
            }
        ]
    },
    {
        id: "2",
        name: "Better Minecraft",
        shortDescription: "A carefully curated modpack",
        bannerImage: "https://external-content.duckduckgo.com/iu/?u=https%3A%2F%2Fstore-images.s-microsoft.com%2Fimage%2Fapps.60323.14294656681058683.4d17bdd8-7026-429a-846f-cf7836bc9e56.a69e6905-8926-4a48-b243-14a039b97aae%3Fmode%3Dscale%26q%3D90%26h%3D1080%26w%3D1920%26format%3Djpg&f=1&nofb=1&ipt=6a06fde46a21884092453224231210ab24ad48cd97088c2c48f5e51558e32929&ipo=images",
        rating: 4.8,
        price: 0,
        currency: "USD",
        highlight: false,
        color: "#1d4ed8",
        type: "kekbre",
        slug: "better-minecraft",
        description: "<p>Enhance your Minecraft experience with carefully selected modifications.</p>",
        downloads: 38500,
        likes: 285,
        compatibility: {
            gameEdition: "Typewriter versions",
            versions: ["0.6.x", "0.7.x", "0.8-beta"]
        },
        platforms: ["Paper"],
        license: {
            type: "Apache 2.0"
        },
        creator: {
            name: "Kerzinator_24",
            avatarUrl: "https://github.com/kerzinator24.png"
        },
        views: 523,
        fileSize: "180MB",
        publishDate: "Aug 1, 2024",
        updateDate: "Dec 15, 2024",
        tags: ["vanilla", "enhancement", "optimization"],
        content: [
            {
                name: "Better Minecraft",
                description: "A carefully curated modpack that enhances vanilla Minecraft without changing its core essence",
                texture: "https://external-content.duckduckgo.com/iu/?u=https%3A%2F%2Fstore-images.s-microsoft.com%2Fimage%2Fapps.60323.14294656681058683.4d17bdd8-7026-429a-846f-cf7836bc9e56.a69e6905-8926-4a48-b243-14a039b97aae%3Fmode%3Dscale%26q%3D90%26h%3D1080%26w%3D1920%26format%3Djpg&f=1&nofb=1&ipt=6a06fde46a21884092453224231210ab24ad48cd97088c2c48f5e51558e32929&ipo=images"
            },
            {
                name: "Better Minecraft",
                description: "A carefully curated modpack that enhances vanilla Minecraft without changing its core essence",
                texture: "https://external-content.duckduckgo.com/iu/?u=https%3A%2F%2Fstore-images.s-microsoft.com%2Fimage%2Fapps.60323.14294656681058683.4d17bdd8-7026-429a-846f-cf7836bc9e56.a69e6905-8926-4a48-b243-14a039b97aae%3Fmode%3Dscale%26q%3D90%26h%3D1080%26w%3D1920%26format%3Djpg&f=1&nofb=1&ipt=6a06fde46a21884092453224231210ab24ad48cd97088c2c48f5e51558e32929&ipo=images"
            },
        ]
    }
];