<script lang="ts">
    export let text: string;
    export let variant: string;
</script>

<style>
    .primary { background-color: var(--ifm-color-primary); }
    .secondary { background-color: var(--ifm-color-secondary); }
    .accent { background-color: var(--ifm-color-accent); }
    .danger { background-color: var(--ifm-color-danger); }
    button { transition: filter 0.2s; }
    button:hover { filter: brightness(0.9); }
</style>

<div class="flex items-center justify-center p-4 rounded-lg shadow text-lg font-semibold text-gray-700">
    <button class="text-white px-4 py-2 rounded-lg {variant}">{text}</button>
</div>