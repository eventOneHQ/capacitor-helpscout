import { HelpScout } from 'capacitor-helpscout';

const $ = (id) => document.getElementById(id);
const log = (label, value) => {
  const line = `${label}: ${value === undefined ? 'ok' : JSON.stringify(value)}`;
  $('log').textContent = `${line}\n${$('log').textContent}`;
};

const identity = () => ({ signature: $('signature').value || undefined });

const actions = {
  initialize: () => HelpScout.initialize({ beaconId: $('beaconId').value, logsEnabled: true }),
  configure: () =>
    HelpScout.configure({
      color: '#617DEC',
      focusMode: 'neutral',
      enablePreviousMessages: true,
      contactForm: { showName: true, showSubject: true, allowAttachments: true, customFieldsEnabled: true },
    }),
  getStatus: () => HelpScout.getStatus(),
  open: () => HelpScout.open(identity()),
  close: () => new Promise((resolve) => setTimeout(() => resolve(HelpScout.close()), 3000)),
  search: () => HelpScout.search({ query: $('query').value, ...identity() }),
  openArticle: () => HelpScout.openArticle({ articleId: $('query').value, ...identity() }),
  askQuestion: () => HelpScout.askQuestion({ question: $('query').value, ...identity() }),
  identify: () =>
    HelpScout.identify({
      email: $('email').value,
      name: $('name').value || undefined,
      ...identity(),
    }),
  logout: () => HelpScout.logout({ endActiveChat: true }),
  reset: () => HelpScout.reset(),
  clear: () => HelpScout.clear(),
  addAttribute: () => HelpScout.addAttribute({ key: 'plan', value: 'pro' }),
  removeAttribute: () => HelpScout.removeAttribute({ key: 'plan' }),
  clearAttributes: () => HelpScout.clearAttributes(),
  setSessionAttributes: () => HelpScout.setSessionAttributes({ attributes: { 'App version': '1.0.0' } }),
  getSessionAttributes: () => HelpScout.getSessionAttributes(),
  setPrefilledForm: () =>
    HelpScout.setPrefilledForm({
      name: $('name').value || undefined,
      email: $('email').value || undefined,
      subject: 'Need help with my invoice',
      message: 'Hello, I need some help with my invoice...',
      customFields: { 5678: 'Question' },
      attachments: [{ filename: 'hello.txt', data: btoa('Hello from Beacon') }],
    }),
  clearPrefilledForm: () => HelpScout.clearPrefilledForm(),
  setSuggestions: () =>
    HelpScout.setSuggestions({
      suggestions: [{ type: 'link', url: 'https://www.helpscout.com', text: 'Help Scout' }],
    }),
  resetSuggestions: () => HelpScout.resetSuggestions(),
  initializePushNotifications: () => HelpScout.initializePushNotifications(),
};

document.querySelectorAll('button[data-action]').forEach((button) => {
  button.addEventListener('click', async () => {
    const [name, screen] = button.dataset.action.split(':');
    try {
      const result = name === 'navigate' ? await HelpScout.navigate({ screen, ...identity() }) : await actions[name]();
      log(button.dataset.action, result);
    } catch (error) {
      log(`${button.dataset.action} failed`, String(error.message ?? error));
    }
  });
});

HelpScout.addListener('beaconOpened', (event) => log('beaconOpened', event));
HelpScout.addListener('beaconClosed', (event) => log('beaconClosed', event));
