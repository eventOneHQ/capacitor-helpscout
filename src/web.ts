import { WebPlugin } from '@capacitor/core';

import type { BeaconStatus, HelpScoutPlugin } from './definitions';

const UNAVAILABLE = 'The Help Scout Beacon mobile SDK is only available on iOS and Android.';

/**
 * The Beacon mobile SDKs only exist on iOS and Android. For the web use the Beacon JavaScript API.
 */
export class HelpScoutWeb extends WebPlugin implements HelpScoutPlugin {
  async initialize(): Promise<void> {
    throw this.unimplemented(UNAVAILABLE);
  }

  async configure(): Promise<void> {
    throw this.unimplemented(UNAVAILABLE);
  }

  async open(): Promise<void> {
    throw this.unimplemented(UNAVAILABLE);
  }

  async close(): Promise<void> {
    throw this.unimplemented(UNAVAILABLE);
  }

  async navigate(): Promise<void> {
    throw this.unimplemented(UNAVAILABLE);
  }

  async search(): Promise<void> {
    throw this.unimplemented(UNAVAILABLE);
  }

  async openArticle(): Promise<void> {
    throw this.unimplemented(UNAVAILABLE);
  }

  async askQuestion(): Promise<void> {
    throw this.unimplemented(UNAVAILABLE);
  }

  async identify(): Promise<void> {
    throw this.unimplemented(UNAVAILABLE);
  }

  async logout(): Promise<void> {
    throw this.unimplemented(UNAVAILABLE);
  }

  async reset(): Promise<void> {
    throw this.unimplemented(UNAVAILABLE);
  }

  async clear(): Promise<void> {
    throw this.unimplemented(UNAVAILABLE);
  }

  async addAttribute(): Promise<{ added: boolean }> {
    throw this.unimplemented(UNAVAILABLE);
  }

  async removeAttribute(): Promise<void> {
    throw this.unimplemented(UNAVAILABLE);
  }

  async clearAttributes(): Promise<void> {
    throw this.unimplemented(UNAVAILABLE);
  }

  async setSessionAttributes(): Promise<{ success: boolean }> {
    throw this.unimplemented(UNAVAILABLE);
  }

  async getSessionAttributes(): Promise<{ attributes: Record<string, string> }> {
    throw this.unimplemented(UNAVAILABLE);
  }

  async setPrefilledForm(): Promise<void> {
    throw this.unimplemented(UNAVAILABLE);
  }

  async clearPrefilledForm(): Promise<void> {
    throw this.unimplemented(UNAVAILABLE);
  }

  async setSuggestions(): Promise<void> {
    throw this.unimplemented(UNAVAILABLE);
  }

  async resetSuggestions(): Promise<void> {
    throw this.unimplemented(UNAVAILABLE);
  }

  async initializePushNotifications(): Promise<void> {
    throw this.unimplemented(UNAVAILABLE);
  }

  async setPushToken(): Promise<void> {
    throw this.unimplemented(UNAVAILABLE);
  }

  async failedToRegisterForPushNotifications(): Promise<void> {
    throw this.unimplemented(UNAVAILABLE);
  }

  async isBeaconPushNotification(): Promise<{ value: boolean }> {
    throw this.unimplemented(UNAVAILABLE);
  }

  async handlePushNotification(): Promise<{ handled: boolean }> {
    throw this.unimplemented(UNAVAILABLE);
  }

  async getStatus(): Promise<BeaconStatus> {
    return { initialized: false };
  }
}
