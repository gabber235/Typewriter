---
name: fibery-tools
description: Guide Fibery bug and feature workflow operations with the hardcoded workflow tools.
---

# Fibery workflow behavior

Use this skill when an agent creates or updates Fibery bugs and features with the hardcoded workflow tools.

## Core behavior

- Infer likely domains from changed paths and module names before creating or updating an item.
- Validate inferred domains with the `question` tool whenever assumptions are uncertain.
- Ask for title first when creating an item.
- Use concise suggested titles based on changed code.
- Ask only for fields that are required or ambiguous for the operation.

## Clarification flow

1. Ask for title with one recommended option.
2. Propose domain choices with explicit names in one question.
   - Put the top recommendation first, with the actual domain name in the label.
   - Include two or three context variants as additional options.
   - Keep each option as one domain only.
   - Use multi select when more than one domain might apply.
3. Ask workflow fields as separate questions.
   - Ask status in one question.
   - Ask size in one question.
   - Ask importance in one question.
   - If the code already exists and is merged in this branch context, recommend `Done` as the status.
4. Ask whether to link Discord.
   - Include `No, do not link` as an option.
   - If linking is selected, collect `discord_thread_id` and pass it directly.
5. Ask for milestone or beta only if needed.
   - If milestone is needed, query `fibery-workflow_list_milestones` and show those options.
   - If beta is needed, query `fibery-workflow_list_recent_betas` and show the latest five options.

Batch the questions in one call to the `question` tool.

## Tool usage rules

- Use `fibery-workflow_find_items` when id is unknown.
- Use `fibery-workflow_create_bug` and `fibery-workflow_create_feature` for creation.
- Use `fibery-workflow_update_bug` and `fibery-workflow_update_feature` for updates.
- Use `fibery-workflow_link_bug_to_feature` only for explicit post create linking.
- Use `fibery-workflow_discover_domains` for domain recommendation and manual domain list prompts.
- Use `fibery-workflow_list_milestones` and `fibery-workflow_list_recent_betas` for guided selection prompts.
- Use markdown only descriptions through `description_markdown`.
- Use enum values only for status, priority, size, importance, and domains.

## Description preview behavior

- Draft a short markdown preview from the changed code.
- Ask whether to use the draft as is or add extra points.
- If extra points are requested, ask one follow up question to collect them.
- When you have gotten feedback, repeat the loop with the updated description.

## Domain inference hints

- `extensions/QuestExtension/` maps to `Quest Extension`.
- `extensions/EntityExtension/` maps to `Entity Extension`.
- `extensions/RoadNetworkExtension/` maps to `RoadNetwork Extension`.
- `module-plugin/` maps to `Module Plugin`.
- `discord_bot/` maps to `Discord Bot`.
- `engine/` maps to `Engine Core`.

When multiple domains are plausible, confirm with `question` before calling create or update tools.
