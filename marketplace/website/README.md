# Typewriter Marketplace

A SvelteKit-based marketplace for Typewriter modules and extensions.

## Prerequisites

- Node.js 18+
- npm or pnpm

## Getting Started

### 1. Install Dependencies

```bash
npm install
```

### 2. Configure Environment Variables

Copy the example environment file, which holds the non secret configuration:

```bash
cp .env.example .env
```

| Variable | Source | Description |
|----------|--------|-------------|
| `AUTH_AUTHENTIK_ID` | `.env` | OAuth2 client ID (default: `typewriter-marketplace`) |
| `AUTH_AUTHENTIK_ISSUER` | `.env` | Authentik issuer URL |
| `AUTH_SECRET` | secretspec | Auth.js secret for session encryption. Generate with: `openssl rand -base64 32` |
| `AUTH_AUTHENTIK_SECRET` | secretspec | OAuth2 client secret from Authentik |

The secrets belong to the `marketplace` profile of the repository's [`secretspec.toml`](../../secretspec.toml), which reads them from the Typewriter 1Password vault, or from the repository root's `.env` without vault access ([CONTRIBUTING.md](../../CONTRIBUTING.md#secrets)).

#### Getting the Client Secret

The client secret is managed via Terraform in the infrastructure repository. Store it in the vault:

```bash
cd infrastructure/5_authentik/configuration/companies/typewriter
terraform output -raw marketplace_client_secret | secretspec set AUTH_AUTHENTIK_SECRET --profile marketplace --from-file -
```

### 3. Start Development Server

```bash
secretspec run --profile marketplace -- npm run dev

# or start the server and open the app in a new browser tab
secretspec run --profile marketplace -- npm run dev -- --open
```

## Authentication

This application uses [Auth.js](https://authjs.dev/) with [Authentik](https://goauthentik.io/) as the OAuth2/OIDC provider.

### Authentication Flow

1. User clicks "Login" or "Sign up"
2. User is redirected to Authentik (Discord OAuth)
3. After authentication, user is redirected back to `/auth/callback/authentik`
4. Session is established and user data is available via `$page.data.session`

### Available Scopes

- `openid` - OpenID Connect core
- `profile` - User profile (name, username)
- `email` - User email address

### Accessing Session Data

In server-side code (`+page.server.ts`, `+layout.server.ts`):

```typescript
export const load: PageServerLoad = async (event) => {
  const session = await event.locals.auth();
  return { session };
};
```

In Svelte components:

```svelte
<script>
  let { data } = $props();
  // data.session?.user contains user information
</script>
```

## Building

To create a production version:

```bash
npm run build
```

Preview the production build:

```bash
npm run preview
```

## Development Tools

### Storybook

Run Storybook for component development:

```bash
npm run storybook
```

Build Storybook:

```bash
npm run build-storybook
```

### Linting & Formatting

```bash
npm run lint
npm run format
```

### Type Checking

```bash
npm run check
```

## Deployment

You may need to install an [adapter](https://svelte.dev/docs/kit/adapters) for your target environment.

## Related Documentation

- [Authentik Configuration](../../../infrastructure/5_authentik/configuration/companies/typewriter/subsystems/marketplace/README.md)
- [Auth.js Documentation](https://authjs.dev/)
- [SvelteKit Documentation](https://svelte.dev/docs/kit)