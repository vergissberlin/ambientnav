import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';
import { readFileSync, existsSync, writeFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { join, dirname } from 'path';
import { execSync } from 'child_process';
import { remarkMermaid } from './src/plugins/remark-mermaid.mjs';
import starlightVersions from 'starlight-versions';
import { unified } from '@astrojs/markdown-remark';

const __dirname = dirname(fileURLToPath(import.meta.url));
const { version } = JSON.parse(readFileSync(join(__dirname, '../package.json'), 'utf-8'));

// Build the default sidebar for a given version, including a GitHub release notes link.
function buildVersionSidebar(tag) {
  return {
    sidebar: [
      {
        label: 'Release Notes',
        translations: { de: 'Versionshinweise' },
        link: `https://github.com/vergissberlin/ambientnav/releases/tag/${tag}`,
        attrs: { target: '_blank', rel: 'noopener noreferrer' },
      },
      { label: 'Getting Started', translations: { de: 'Erste Schritte' }, link: '/getting-started/' },
      { label: 'Flash Firmware', translations: { de: 'Firmware flashen' }, link: '/flash/' },
      { label: 'Hardware', translations: { de: 'Hardware' }, items: [
        { label: 'Wiring', translations: { de: 'Verkabelung' }, link: '/wiring/' },
      ]},
      { label: 'Reference', translations: { de: 'Referenz' }, items: [
        { label: 'Architecture', translations: { de: 'Architektur' }, link: '/architecture/' },
        { label: 'Agents', translations: { de: 'Agenten' }, link: '/agents/' },
        { label: 'Protocols', translations: { de: 'Protokolle' }, link: '/protocols/' },
        { label: 'LED Effects', translations: { de: 'LED-Effekte' }, link: '/led-effects/' },
      ]},
    ],
  };
}

// Read all git tags, filter to ambientnav releases, sort descending.
const previousVersions = execSync('git tag --sort=-version:refname', { encoding: 'utf-8' })
  .trim()
  .split('\n')
  .filter(tag => /^ambientnav-v\d+\.\d+\.\d+$/.test(tag))
  .reduce((acc, tag) => {
    const [, major, minor, patch] = tag.match(/ambientnav-v(\d+)\.(\d+)\.(\d+)/);
    const label = `v${major}.${minor}.${patch}`;
    if (label === `v${version}`) return acc; // skip current version
    const slug = `${major}.${minor}`;
    const jsonPath = join(__dirname, `src/content/versions/${slug}.json`);
    if (!existsSync(jsonPath)) {
      writeFileSync(jsonPath, JSON.stringify(buildVersionSidebar(tag), null, 2) + '\n');
    }
    acc.push({ slug, label });
    return acc;
  }, []);

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
      customCss: ['./src/styles/theme.css'],
      logo: {
        dark: './src/assets/logo-dark.svg',
        light: './src/assets/logo-light.svg',
        alt: 'AmbientNav',
        replacesTitle: false,
      },
      plugins: [
        ...(previousVersions.length > 0
          ? [starlightVersions({ versions: previousVersions, current: { label: `v${version}` } })]
          : []),
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
          label: 'Release Notes',
          translations: { de: 'Versionshinweise' },
          link: `https://github.com/vergissberlin/ambientnav/releases/tag/ambientnav-v${version}`,
          attrs: { target: '_blank', rel: 'noopener noreferrer' },
        },
        {
          label: 'Getting Started',
          translations: { de: 'Erste Schritte' },
          link: '/getting-started/',
        },
        {
          label: 'Flash Firmware',
          translations: { de: 'Firmware flashen' },
          link: '/flash/',
        },
        {
          label: 'Flash Firmware (Manual)',
          translations: { de: 'Firmware flashen (manuell)' },
          link: '/flash-firmware/',
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
        {
          label: 'Community',
          translations: { de: 'Community' },
          items: [
            {
              label: 'Ideas & Feature Requests',
              translations: { de: 'Ideen & Feature-Wünsche' },
              link: '/ideas/',
            },
          ],
        },
      ],
    }),
  ],
});
