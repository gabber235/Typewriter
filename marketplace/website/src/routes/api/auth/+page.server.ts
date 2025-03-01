import type { Actions } from './$types';
import { dev } from '$app/environment';

export const actions: Actions = {
    signIn: async ({ locals }) => {
        const callback = dev ? 'http://localhost:5173/callback' : 'https://marketplace.typewritermc.com/callback';
        await locals.logtoClient.signIn(callback);
    },
    signOut: async ({ locals }) => {
        const callback = dev ? "http://localhost:5173" : "https://marketplace.typewritermc.com";
        await locals.logtoClient.signOut(callback);
    }
};
