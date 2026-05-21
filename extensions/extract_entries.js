#!/usr/bin/env node
const fs = require('fs');
const path = require('path');

// Extension configuration
const EXTENSIONS = {
    "VaultExtension": "vault",
    "EntityExtension": "entity",
    "BasicExtension": "basic",
    "CitizensExtension": "citizens",
    "QuestExtension": "quest",
    "WorldGuardExtension": "worldguard",
    "SuperiorSkyblockExtension": "superiorskyblock",
    "RoadNetworkExtension": "roadnetwork",
    "RPGRegionsExtension": "rpgregions",
    "MythicMobsExtension": "mythicmobs",
    "_DocsExtension": "docs"
};

function findKotlinFilesWithEntry(extensionDir) {
    const files = [];
    function walk(dir) {
        try {
            const items = fs.readdirSync(dir);
            for (const item of items) {
                const fullPath = path.join(dir, item);
                const stat = fs.statSync(fullPath);
                if (stat.isDirectory()) {
                    walk(fullPath);
                } else if (item.endsWith('.kt')) {
                    try {
                        const content = fs.readFileSync(fullPath, 'utf-8');
                        if (content.includes('@Entry')) {
                            files.push(fullPath);
                        }
                    } catch (e) {
                        console.error(`Error reading ${fullPath}:`, e.message);
                    }
                }
            }
        } catch (e) {
            // Directory doesn't exist
        }
    }
    walk(extensionDir);
    return files;
}

function extractEntryAnnotation(content) {
    const pattern = /@Entry\s*\(\s*"([^"]+)"\s*,\s*"([^"]+)"\s*,\s*Colors\.(\w+)\s*,\s*"([^"]+)"\s*\)/;
    const match = content.match(pattern);
    if (match) {
        return {
            id: match[1],
            displayName: match[2],
            color: match[3],
            icon: match[4]
        };
    }
    return null;
}

function extractJavadoc(content) {
    const pattern = /\/\*\*([\s\S]*?)\*\//;
    const match = content.match(pattern);
    if (match) {
        let javadoc = match[1].trim();
        // Remove leading * and whitespace from each line
        const lines = javadoc.split('\n').map(line => {
            line = line.trim();
            if (line.startsWith('*')) {
                line = line.substring(1).trim();
            }
            return line;
        }).filter(line => line);
        
        // Get first paragraph (before empty line or ##)
        const firstPara = [];
        for (const line of lines) {
            if (line.startsWith('#') || !line) {
                break;
            }
            firstPara.push(line);
        }
        return firstPara.join(' ').trim();
    }
    return '';
}

function extractFieldsWithHelp(content) {
    const fields = {};
    const pattern = /@Help\s*\(\s*"([^"]+)"\s*\)\s*(?:\n\s*)*(?:val|var)\s+(\w+)\s*:/g;
    let match;
    while ((match = pattern.exec(content)) !== null) {
        const helpText = match[1];
        const fieldName = match[2];
        fields[fieldName] = helpText;
    }
    return fields;
}

function humanizeFieldName(name) {
    // Convert camelCase to Title Case
    const result = name.replace(/([a-z])([A-Z])/g, '$1 $2').capitalize();
    return result.charAt(0).toUpperCase() + result.slice(1);
}

String.prototype.capitalize = function() {
    return this.charAt(0).toUpperCase() + this.slice(1);
};

function translateToRussian(text) {
    const translations = {
        "Withdraw Balance": "Снять баланс",
        "The amount of money to withdraw.": "Размер денежной суммы для снятия.",
        "The `Withdraw Balance Action` is used to withdraw money from a user's balance.": "Действие `Снять баланс` используется для снятия денег с баланса игрока.",
        "Amount": "Сумма",
        "Groups grouped by permission": "Группы, сгруппированные по разрешениям",
        "The `Permission Group` is a group for which a player has a certain permission. To determine if a player is part of this group, the permissions of the player are checked. If the player has all the permissions, they are part of the group.": "Группа `Разрешение` - это группа, в которой игрок имеет определённое разрешение. Чтобы определить, является ли игрок частью этой группы, проверяются его разрешения. Если игрок имеет все разрешения, он является частью группы.",
        "Groups": "Группы",
        "Deposit Balance": "Пополнить баланс",
        "The `Deposit Balance Action` is used to deposit money into a user's balance.": "Действие `Пополнить баланс` используется для внесения денег на счёт игрока.",
        "This action could be used to reward the player for completing a task/quest.": "Это действие может быть использовано для вознаграждения игрока за выполнение задачи/квеста.",
        "Set Prefix": "Установить префикс",
        "The `Set Prefix Action` action sets the prefix of a player's message": "Действие `Установить префикс` устанавливает префикс сообщения игрока",
        "This could be used for a badge system. When a player completes a certain task, like killing a boss, they could be given a prefix that shows up in chat, like `[Deamon Slayer]`": "Это можно использовать для системы значков. Когда игрок выполняет определённую задачу, например убивает босса, ему можно дать префикс, который появляется в чате, например `[Deamon Slayer]`",
        "The prefix to set.": "Префикс для установки.",
        "Prefix": "Префикс",
        "Triggers when the player's balance changes": "Срабатывает при изменении баланса игрока",
        "The `Balance Change Event` entry is an event triggered when the player's balance changes.": "Запись `Событие изменения баланса` - это событие, которое срабатывает при изменении баланса игрока.",
        "This could be used to give the player a custom role when they reach a certain balance. For example, they could be given the role of \"Gold Member\" when they reach 100$.": "Это может быть использовано для предоставления игроку пользовательской роли при достижении определённого баланса. Например, они могут получить роль \"Золотого члена\" при достижении 100$.",
        "The balance of a player's account": "Баланс счёта игрока",
        "A [fact](/docs/creating-stories/facts) that represents a player's balance.": "Факт, который представляет баланс игрока.",
        "This fact could be used to track a player's balance in a game. For example, if the player is rich, allow them to access to a VIP area. If the player is poor, they can't afford to enter.": "Этот факт может быть использован для отслеживания баланса игрока в игре. Например, если игрок богат, позвольте ему получить доступ в VIP область. Если игрок беден, он не может себе позволить войти.",
        "If the player has a permission": "Если у игрока есть разрешение",
        "A [fact](/docs/creating-stories/facts) that checks if the player has a certain permission.": "Факт, который проверяет, имеет ли игрок определённое разрешение.",
        "This fact could be used to check if the player has a certain permission, for example to check if the player is an admin.": "Этот факт может быть использован для проверки, имеет ли игрок определённое разрешение, например для проверки, является ли игрок администратором.",
        "The permission to check for": "Разрешение для проверки",
        "Permission": "Разрешение",
        "Filters an audience based on if they have a specific permission": "Фильтрует аудиторию на основе наличия у них определённого разрешения",
        "The `PermissionAudienceEntry` filters an audience based on if they have a specific permission.": "Запись `PermissionAudienceEntry` фильтрует аудиторию на основе наличия у них определённого разрешения.",
        "This can be used to show certain content only to players with specific permissions. For example, only showing admin commands to players with the `admin` permission.": "Это может использоваться для отображения определённого содержимого только игрокам с определёнными разрешениями. Например, отображение команд администратора только игрокам с разрешением `admin`.",
        "The permission to check for.": "Разрешение для проверки.",
        "Audiences grouped by balance": "Аудитории, сгруппированные по балансу",
        "The `Balance Audience` is an group for which a player's balance meets a certain condition. To determine if a player is part of this group, the balance of the player is checked for each condition. The first condition that is met determines the group the player is part of.": "Группа `Баланс аудитории` - это группа, для которой баланс игрока соответствует определённому условию. Чтобы определить, является ли игрок частью этой группы, баланс игрока проверяется для каждого условия. Первое выполненное условие определяет группу, к которой относится игрок.",
        "This could be used to have facts that are specific to a player's balance, like a VIPs where all share some balance threshold.": "Это может быть использовано для фактов, которые относятся к балансу игрока, например для VIP, где все имеют определённый порог баланса.",
        "Group": "Группа",
    };
    
    // If exact match found, return translation
    if (translations[text]) {
        return translations[text];
    }
    
    // Otherwise return the original text (placeholder for now)
    return text;
}

function processExtension(extName, namespace, extensionsDir) {
    const extensionDir = path.join(extensionsDir, extName);
    if (!fs.existsSync(extensionDir)) {
        console.log(`Extension directory not found: ${extensionDir}`);
        return {};
    }
    
    const kotlinFiles = findKotlinFilesWithEntry(extensionDir);
    const entries = {};
    
    for (const filepath of kotlinFiles) {
        try {
            const content = fs.readFileSync(filepath, 'utf-8');
            const entryInfo = extractEntryAnnotation(content);
            
            if (!entryInfo) {
                continue;
            }
            
            const entryId = entryInfo.id;
            const displayName = entryInfo.displayName;
            const javadoc = extractJavadoc(content);
            const fields = extractFieldsWithHelp(content);
            
            entries[entryId] = {
                displayName,
                javadoc,
                fields,
                color: entryInfo.color,
                icon: entryInfo.icon
            };
            
            console.log(`Extracted ${namespace}.${entryId} from ${path.basename(filepath)}`);
        } catch (e) {
            console.error(`Error processing ${filepath}:`, e.message);
        }
    }
    
    return entries;
}

function generateJsonFiles(extName, namespace, entries, extensionsDir) {
    const transDir = path.join(extensionsDir, extName, 'src', 'main', 'resources', 'translations');
    fs.mkdirSync(transDir, { recursive: true });
    
    const enJson = {};
    const ruJson = {};
    
    for (const entryId of Object.keys(entries)) {
        const entry = entries[entryId];
        
        // Title
        enJson[`${namespace}.${entryId}.title`] = entry.displayName;
        ruJson[`${namespace}.${entryId}.title`] = translateToRussian(entry.displayName);
        
        // Description
        enJson[`${namespace}.${entryId}.description`] = entry.javadoc;
        ruJson[`${namespace}.${entryId}.description`] = translateToRussian(entry.javadoc);
        
        // Fields
        for (const fieldName of Object.keys(entry.fields)) {
            const helpText = entry.fields[fieldName];
            const label = humanizeFieldName(fieldName);
            
            enJson[`${namespace}.${entryId}.fields.${fieldName}.label`] = label;
            enJson[`${namespace}.${entryId}.fields.${fieldName}.help`] = helpText;
            
            ruJson[`${namespace}.${entryId}.fields.${fieldName}.label`] = translateToRussian(label);
            ruJson[`${namespace}.${entryId}.fields.${fieldName}.help`] = translateToRussian(helpText);
        }
    }
    
    // Write English file
    const enFile = path.join(transDir, `${namespace}_l10n_en.json`);
    fs.writeFileSync(enFile, JSON.stringify(enJson, null, 2));
    console.log(`Created ${enFile}`);
    
    // Write Russian file
    const ruFile = path.join(transDir, `${namespace}_l10n_ru.json`);
    fs.writeFileSync(ruFile, JSON.stringify(ruJson, null, 2));
    console.log(`Created ${ruFile}`);
}

async function main() {
    const extensionsDir = path.win32.normalize('c:/Users/Ося/Documents/Dev/Minecraft/plugins/Typewriter/extensions');
    
    for (const [extName, namespace] of Object.entries(EXTENSIONS)) {
        console.log(`\n${'='.repeat(60)}`);
        console.log(`Processing ${extName} (namespace: ${namespace})`);
        console.log(`${'='.repeat(60)}`);
        
        const entries = processExtension(extName, namespace, extensionsDir);
        
        if (Object.keys(entries).length > 0) {
            generateJsonFiles(extName, namespace, entries, extensionsDir);
            console.log(`Generated ${Object.keys(entries).length} localization entries for ${extName}`);
        } else {
            console.log(`No @Entry annotations found in ${extName}`);
        }
    }
}

main().catch(console.error);
