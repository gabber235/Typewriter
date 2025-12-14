import { SvelteKitAuth } from "@auth/sveltekit";
import Authentik from "@auth/sveltekit/providers/authentik";
import { env } from "$env/dynamic/private";

declare module "@auth/sveltekit" {
	interface Session {
		user: {
			id: string;
			name?: string | null;
			email?: string | null;
			image?: string | null;
			username?: string | null;
		};
	}
}

export const { handle, signIn, signOut } = SvelteKitAuth({
	trustHost: true,
	providers: [
		Authentik({
			clientId: env.AUTH_AUTHENTIK_ID,
			clientSecret: env.AUTH_AUTHENTIK_SECRET,
			issuer: env.AUTH_AUTHENTIK_ISSUER,
			authorization: {
				params: {
					scope: "openid profile email",
				},
			},
		}),
	],
	callbacks: {
		session({ session, token }) {
			if (token.sub) {
				session.user.id = token.sub;
			}
			if (token.preferred_username) {
				session.user.username = token.preferred_username as string;
			}
			return session;
		},
		jwt({ token, profile }) {
			if (profile) {
				token.preferred_username = profile.preferred_username;
			}
			return token;
		},
	},
});