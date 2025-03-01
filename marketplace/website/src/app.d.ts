import type { LogtoClient, UserInfoResponse } from '@logto/sveltekit';

declare global {
    namespace App {
        // interface Error {}
        // interface PageData {}
        // interface PageState {}
        // interface Platform {}
        interface Locals {
            logtoClient: LogtoClient;
            user?: UserInfoResponse;
        }
    }
}

export { };
