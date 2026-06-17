import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';
import { readFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { join, dirname } from 'path';
import { remarkMermaid } from './src/plugins/remark-mermaid.mjs';

const __dirname = dirname(fileURLToPath(import.meta.url));
const { version } = JSON.parse(readFileSync(join(__dirname, '../package.json'), 'utf-8'));

export default defineConfig({
  site: 'https://vergissberlin.github.io',
  base: '/ambientnav',
  markdown: {
    remarkPlugins: [remarkMermaid],
  },
  integrations: [
    starlight({
      title: `AmbientNav v${version}`,
      description: 'Ambient LED navigation and parking assistance for vehicles',
      social: {
        github: 'https://github.com/vergissberlin/ambientnav',
      },
      components: {
        Head: './src/components/Head.astro',
      },
      defaultLocale: 'root',
      locales: {
        root: { label: 'English', lang: 'en' },
        de: { label: 'Deutsch', lang: 'de' },
      },
      sidebar: [
        {
          label: 'Getting Started',
          translations: { de: 'Erste Schritte' },
          link: '/getting-started/',
        },
        {
          label: 'Reference',
          translations: { de: 'Referenz' },
          items: [
            {
              label: 'Architecture',
              translations: { de: 'Architektur' },
              link: '/architecture/',
            },
            {
              label: 'Agents',
              translations: { de: 'Agenten' },
              link: '/agents/',
            },
            {
              label: 'Protocols',
              translations: { de: 'Protokolle' },
              link: '/protocols/',
            },
            {
              label: 'LED Effects',
              translations: { de: 'LED-Effekte' },
              link: '/led-effects/',
            },
          ],
        },
      ],
    }),
  ],
});
