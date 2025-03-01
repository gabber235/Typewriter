import { handleLogto } from "@logto/sveltekit";
import { sequence } from "@sveltejs/kit/hooks";
import { env } from "$env/dynamic/private";

const logtoHandle = handleLogto(
    {
        endpoint: env.LOGTO_ENDPOINT ?? throwExpression("LOGTO_ENDPOINT is not set"),
        appId: env.LOGTO_APP_ID ?? throwExpression("LOGTO_APP_ID is not set"),
        appSecret: env.LOGTO_APP_SECRET ?? throwExpression("LOGTO_APP_SECRET is not set"),
    },
    { encryptionKey: env.LOGTO_COOKIE_ENCRYPTION_KEY ?? throwExpression("LOGTO_COOKIE_ENCRYPTION_KEY is not set"), }
);


export const handle = sequence(logtoHandle);

function throwExpression(errorMessage: string): never {
    throw new Error(errorMessage);
}
