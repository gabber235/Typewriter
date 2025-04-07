# Installation Guide

:::danger
Typewriter only works on **Paper** Spigot servers. It will not work on Spigot or Bukkit servers.
:::

:::caution
Typewriter is currently in beta. This means that the plugin is still in development and may contain bugs. If you find
any bugs, please report them [here](https://discord.gg/HtbKyuDDBw)
:::

## Installing the Plugin

To install the Typewriter plugin on your paper spigot Minecraft server, follow these steps:

1. Download the plugin from [here](https://github.com/gabber235/TypeWriter/releases).
2. Place the downloaded .jar file in your server's `plugins` folder.
3. Download and install all the required plugins from the **[dependencies](dependencies)**. Also check if you have installed any incompatible plugins.
4. Restart your server to complete the installation.

### Basic Adapter

The basic adapter contains the base entries for any server.

To install the basic adapter (or any for that matter), follow these steps:

1. Download the `BasicAdapter.jar` file from [here](https://github.com/gabber235/TypeWriter/releases).
2. Place it in the `server/plugins/Typewriter/adapters` folder.
3. Restart your server to complete the installation.

#### Pre-Made Adapters

In addition to the basic adapter, Typewriter also offers several pre-made adapters that can be easily installed and
configured. For a list of available adapters and instructions on how to install them, see [here](./06-adapters.md#pre-made-adapters).

:::danger[Out of Sync]
When updating the plugin, it's crucial to **always** install the corresponding adapters for that update. Failure to match the versions of the adapter and plugin can result in the plugin not functioning correctly!
:::

## Configuring the Web Panel
:::caution
Typewriter's web panel does **not** support external server providers such as Minehut, Aternos, or Apex. You can still use everthing else in Typewriter. It is possible to use the panel still by setting up a local server with Typewriter installed. For more information, please visit the [Discord](https://discord.gg/HtbKyuDDBw).
:::

The web panel to configure your server's interactions. The web panel is preinstalled inside the plugin, though it is
disabled by default for security and performance reasons.

:::caution
The web should only be used on a development server and **NOT** on a production server.
As it uses precious resources to both host a website and web sockets.
:::

The web panel needs two ports to be open. These can be changed, but it does need at least two new ports to be open. The
default ports are `8080` and `9092`. If you are not able to open these ports, the easiest way is to use typewriter
locally and copying the files in `server/plugins/Typewriter/pages` to your production server.

To enable the web panel, follow these steps:

1. Open the `server/plugins/Typewriter/config.yml` file.
2. Change the settings to the following:

```yaml title="server/plugins/Typewriter/config.yml"
# Whether the web panel and web sockets are enabled.
enabled: true
# The hostname of the server. CHANGE THIS to your servers ip.
hostname: "127.0.0.1"
# The panel uses web sockets to sync changes to the server and it allows you to work with multiple people at the same time.
websocket:
    # The port of the websocket server. Make sure this port is open.
    port: 9092
    # The authentication that is used. Leave unchanged if you don't know what you are doing.
    auth: "session"
panel:
    # The panel can be disabled while the sockets are still open. Only disable this if you know what you are doing.
    # If the web sockets are disabled then the panel wil always be disabled.
    enabled: true
    # The port of the web panel. Make sure this port is open.
    port: 8080
```

3. Restart your server to complete the installation.
4. To connect to the web panel. Run `/typewriter connect` in game. This will give you a link to the web panel.

:::info[Note]
If the web panel is not working, make sure that the ports are open and that the `hostname` is set to your servers IP.
Check the [Troubleshooting Guide](troubleshooting) for more information.
If it still doesn't work, ask for help in the [Discord](https://discord.gg/HtbKyuDDBw).
:::

Once opened, you can use the web panel to create and configure quests, NPC dialogues, and more. The panel also allows
you to view and edit your server's existing player interactions.

## Troubleshooting

Got any problems? Check out the [Troubleshooting](troubleshooting) page for solutions to common problems.
If you still have problems, feel free to ask them in the [Discord](https://discord.gg/HtbKyuDDBw).

## What's Next?

Try to create your first interaction by following the [First Interaction](03-first-interaction.mdx) guide. If you have any
questions, feel free to ask them in the [Discord](https://discord.gg/HtbKyuDDBw).
