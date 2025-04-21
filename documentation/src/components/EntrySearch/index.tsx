import React from "react";
import { Icon } from "@iconify/react";
import { blueprints } from "@site/src/libs/data";
import Admonition from "@theme/Admonition";
import { useColorMode } from "@docusaurus/theme-common";

interface EntryProps {
  entryName: string;
}

const EntrySearch: React.FC<EntryProps> = ({ entryName }) => {
  const { colorMode } = useColorMode();
  const isDarkTheme = colorMode === "dark";

  const colors = {
    primary: isDarkTheme ? "bg-[#448aff]" : "bg-[#448aff]",
    secondary: isDarkTheme ? "hover:bg-[#3d7ce5]" : "hover:bg-[#3d7ce5]",
    background: isDarkTheme ? "bg-[#171719]" : "bg-[#7f7b7f]",
    text: isDarkTheme ? "text-[#e6e0e9]" : "text-[#666366]",
    accent: isDarkTheme ? "bg-[#141218]" : "bg-[#fef7ff]",
    hover: isDarkTheme ? "hover:bg-[#121016]" : "hover:bg-[#e4dee5]",
    icon: isDarkTheme ? "text-[#141218]" : "text-[#f9f9f9]",
    buttonText: isDarkTheme ? "text-[#e6e0e9]" : "text-[#fff]",
    icons: isDarkTheme ? "text-[#e6e0e9]" : "text-[#222122]",
  };

  const parsedEntry = blueprints.get(entryName);

  if (!parsedEntry) {
    return (
      <Admonition type="danger" title="Invalid Entry">
        Invalid entry, please report this in the{" "}
        <a href="https://discord.gg/gs5QYhfv9x">Typewriter Discord</a>.{" "}
        {entryName}
      </Admonition>
    );
  }

  const { name, description, color, icon, tags } = parsedEntry;
  const finalName = name
    .replace(/_/g, " ")
    .replace(/\b\w/g, (c) => c.toUpperCase());

  const wikiBaseUrl =
    typeof window !== "undefined" ? window.location.origin : "";
  const wikiCategories = [
    "action",
    "dialogue",
    "event",
    "fact",
    "sound",
    "audience",
    "quest",
    "instance",
    "entity",
    "data",
    "activity",
    "group",
    "static",
    "cinematic",
  ];
  const category = tags.find((tag) => wikiCategories.includes(tag));
  const wikiUrl = category
    ? `${wikiBaseUrl}/beta/adapters/${parsedEntry.adapter}Adapter/entries/${category}/${name}`
    : `${wikiBaseUrl}/beta/adapters/${parsedEntry.adapter}Adapter`;

  const handleOpenWiki = () => {
    window.open(wikiUrl, "_blank");
  };

  return (
    <div className="w-full h-full flex justify-center items-center select-none pt-5 pb-10">
      <div
        className={`p-3 rounded-[12px] select-none shadow-md shadow-[#252525] ${colors.background}`}
      >
        <div className="flex items-center mb-4 space-x-2 w-auto max-w-[450px] p-1">
          <Icon
            icon="mdi:filter"
            className={`text-3xl ${colors.icons} rounded-full p-1 ${colors.accent}`}
          />
          <div className="flex space-x-2">
            <button
              className={`flex items-center rounded-full text-white px-3 py-1 text-sm cursor-pointer ${colors.primary} ${colors.secondary}`}
              disabled
            >
              <Icon icon="ic:outline-search" className="text-white text-lg" />
              <span className={`ml-1 ${colors.buttonText}`}>New Entries</span>
            </button>
            <button
              className={`flex items-center rounded-full text-white px-3 py-1 text-sm cursor-pointer ${colors.primary} ${colors.secondary}`}
              disabled
            >
              <Icon icon="ic:outline-search" className="text-white text-lg" />
              <span className={`ml-1 ${colors.buttonText}`}>Add Page</span>
            </button>
          </div>
        </div>
        <div
          className={`flex items-center rounded-lg px-3 py-2 mb-4 w-auto max-w-[450px] select-none ${colors.accent}`}
        >
          <Icon
            icon="ic:outline-search"
            className={`text-2xl ${colors.icons}`}
          />
          <input
            type="text"
            value={`Add ${finalName}`}
            className={`bg-transparent border-none outline-none flex-grow ml-2 text-lg pointer-events-auto cursor-text ${colors.text}`}
            readOnly
          />
          <Icon
            icon="mingcute:close-fill"
            className={`text-[30px] cursor-pointer rounded-full p-1 ${colors.text} ${colors.hover}`}
          />
        </div>
        <div
          className={`flex items-center rounded-lg cursor-pointer text-white w-auto max-w-[450px] mt-2 text-lg ${colors.accent} ${colors.hover}`}
          onClick={handleOpenWiki}
        >
          <div
            className="flex items-center justify-center mr-2 p-4 rounded"
            style={{ backgroundColor: color }}
          >
            <Icon icon={icon} className={`text-2xl ${colors.icon}`} />
          </div>
          <div className="flex-grow">
            <div
              className={`font-medium text-[16px] select-none ${colors.text}`}
            >
              Add {finalName}
            </div>
            <div className="text-[#a09fa6] text-sm select-none">
              {description}
            </div>
          </div>
          <span className={`text-2xl pr-5 select-none ${colors.text}`}>+</span>
        </div>
      </div>
    </div>
  );
};

export default EntrySearch;
