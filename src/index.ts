import { registerPlugin } from '@capacitor/core';

import type { HelpScoutPlugin } from './definitions';

const HelpScout = registerPlugin<HelpScoutPlugin>('HelpScout', {
  web: () => import('./web').then((m) => new m.HelpScoutWeb()),
});

export * from './definitions';
export { HelpScout };
