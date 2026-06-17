import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';
import { readFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { join, dirname } from 'path';
import { remarkMermaid } from './src/plugins/remark-mermaid.mjs';
import starlightVersions from 'starlight-versions';
import { unified } from '@astrojs/markdown-remark';

const __dirname = dirname(fileURLToPath(import.meta.url));
const { version } = JSON.parse(readFileSync(join(__dirname, '../package.json'), 'utf-8'));

export default defineConfig({
  site: 'https://vergissberlin.github.io',
  base: '/ambientnav',
  markdown: {
    processor: unified({ remarkPlugins: [remarkMermaid] }),
  },
  integrations: [
    starlight({
      title: 'AmbientNav',
      description: 'Ambient LED navigation and parking assistance for vehicles',
      plugins: [
        starlightVersions({
          versions: [{ slug: '0.1', label: 'v0.1.0' }],
          current: { label: `v${version}` },
        }),
      ],
      social: [
        { icon: 'github', label: 'GitHub', href: 'https://github.com/vergissberlin/ambientnav' },
      ],
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
          label: 'Hardware',
          translations: { de: 'Hardware' },
          items: [
            {
              label: 'Wiring',
              translations: { de: 'Verkabelung' },
              link: '/wiring/',
            },
          ],
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
