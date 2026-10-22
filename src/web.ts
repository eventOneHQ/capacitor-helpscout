import { WebPlugin } from '@capacitor/core';

import type { HelpScoutPlugin } from './definitions';

export class HelpScoutWeb extends WebPlugin implements HelpScoutPlugin {
  async echo(options: { value: string }): Promise<{ value: string }> {
    console.log('ECHO', options);
    return options;
  }
}
