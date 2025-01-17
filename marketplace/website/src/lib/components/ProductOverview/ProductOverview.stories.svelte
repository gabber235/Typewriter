<script module>
    import { defineMeta } from "@storybook/addon-svelte-csf";
    import ProductOverview from "$components/ProductOverview/ProductOverview.svelte";

    const sampleProducts = [
        {
            id: "1",
            name: "All The Mods 10",
            shortDescription:
                "The latest modpack in this amazing series takes your modding experience to the max!",
            bannerImage:
                "https://media.forgecdn.net/game-carousel-background-images/game_carousel_item_background_4d0b2f3b-1c05-46f7-8ce3-7cda6a121b13.webp",
            rating: 4.5,
            price: 9.99,
            currency: "USD",
            highlight: false,
            highlightColor: "blue"
        },
        {
            id: "2",
            name: "Better Minecraft",
            shortDescription:
                "A carefully curated modpack that enhances vanilla Minecraft without changing its core essence",
            bannerImage:
                "https://external-content.duckduckgo.com/iu/?u=https%3A%2F%2Fstore-images.s-microsoft.com%2Fimage%2Fapps.60323.14294656681058683.4d17bdd8-7026-429a-846f-cf7836bc9e56.a69e6905-8926-4a48-b243-14a039b97aae%3Fmode%3Dscale%26q%3D90%26h%3D1080%26w%3D1920%26format%3Djpg&f=1&nofb=1&ipt=6a06fde46a21884092453224231210ab24ad48cd97088c2c48f5e51558e32929&ipo=images",
            rating: 4.8,
            price: 14.99,
            currency: "USD",
            highlight: false,
            highlightColor: "red"
        },
        {
            id: "3",
            name: "Create Above & Beyond",
            shortDescription: "An expert modpack centered around the Create mod with unique progression",
            bannerImage:
                "https://external-content.duckduckgo.com/iu/?u=https%3A%2F%2Fi.ytimg.com%2Fvi%2FMazIia7oM58%2Fmaxresdefault.jpg&f=1&nofb=1&ipt=b8343cf91f18c67f2224b91c4212bf522c3ed95210b36aba1e2f18218c920985&ipo=images",
            rating: 4.7,
            price: 19.99,
            currency: "USD",
            highlight: false,
            highlightColor: "green"
        },
        {
            id: "4",
            name: "RLCraft",
            shortDescription:
                "The challenging modpack that turns Minecraft into a realistic survival experience",
            bannerImage:
                "https://external-content.duckduckgo.com/iu/?u=https%3A%2F%2Fbisecthosting.com%2Fimages%2FCF%2FRLCraft%2FBH_RL_Header.webp&f=1&nofb=1&ipt=ed5464b1e4a764c10a45a40988e137490d6da9f8f16532fbf2303e6e954ff377&ipo=images",
            rating: 4.6,
            price: 12.99,
            currency: "USD",
            highlight: false,
            highlightColor: "yellow"
        },
        {
            id: "5",
            name: "StoneBlock 2",
            shortDescription:
                "A modpack focused on mining and crafting underground with a plethora of new features",
            bannerImage: "https://i.ytimg.com/vi/mv7KNlMRzBY/maxresdefault.jpg",
            rating: 4.4,
            price: 13.99,
            currency: "USD",
            highlight: false,
            highlightColor: "orange"
        },
        {
            id: "6",
            name: "Farming Valley",
            shortDescription:
                "A relaxing modpack that takes you to a peaceful valley full of lush fields and forests",
            bannerImage:
                "https://i.ytimg.com/vi/feWRjBNPeTQ/maxresdefault.jpg",
            rating: 4.9,
            price: 16.99,
            currency: "USD",
            highlight: false,
            highlightColor: "purple"
        },
        {
            id: "7",
            name: "Life in the Village 3",
            shortDescription:
                "This pack is based around town-building mod - Minecolonies and it can be casual or challenging as you want it to be.",
            bannerImage:
                "https://i.imgur.com/7k5BBMI.png",
            rating: 4.5,
            price: 11.99,
            currency: "USD",
            highlight: false,
            highlightColor: "pink"
        },
        {
            id: "8",
            name: "The Aether II",
            shortDescription:
                "The Aether II is the sequel to the highly popular dimension mod \"The Aether\", set in a hostile paradise miles up in the clouds.",
            bannerImage:
                "https://i.imgur.com/d9dL8ge.png",
            rating: 4.4,
            price: 10.99,
            currency: "USD",
            highlight: false,
            highlightColor: "brown"
        }
    ];

    const {Story} = defineMeta({
        component: ProductOverview,
        tags: ["autodocs"],
        args: {
            products: sampleProducts
        },
        parameters: {
            layout: "fullscreen"
        }
    });
</script>

<Story name="Default" parameters={{ viewport: { defaultViewport: "pc" } }}/>
<Story name="Mobile - Galaxy S5" parameters={{ viewport: { defaultViewport: "galaxys5" } }}/>
<Story name="Mobile - iPhone 14 Pro Max" parameters={{ viewport: { defaultViewport: "iphone14promax" } }}/>
<Story name="Tablet - iPad" parameters={{ viewport: { defaultViewport: "ipad" } }}/>
