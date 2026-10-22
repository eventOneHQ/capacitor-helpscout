export interface HelpScoutPlugin {
  echo(options: { value: string }): Promise<{ value: string }>;
}
