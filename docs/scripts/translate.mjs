/**
 * Translates changed English documentation files to German using
 * the GitHub Models API (OpenAI-compatible endpoint).
 *
 * Auth: GITHUB_TOKEN — automatically available in GitHub Actions.
 * No additional API secrets required (uses the Copilot subscription).
 *
 * Usage:
 *   GITHUB_TOKEN=... CHANGED_FILES="docs/src/content/docs/foo.md" node docs/scripts/translate.mjs
 */

import { readFileSync, writeFileSync, mkdirSync } from 'fs';
import { dirname } from 'path';
import OpenAI from 'openai';

const client = new OpenAI({
  baseURL: 'https://models.inference.ai.azure.com',
  apiKey: process.env.GITHUB_TOKEN,
});

const SYSTEM_PROMPT = `You are a professional technical translator specializing in software and hardware documentation.
Translate the following Markdown document from English to German (Deutsch).

Rules:
- Preserve ALL Markdown formatting exactly (headings, bold, italic, tables, lists, code fences, etc.)
- Preserve ALL YAML frontmatter keys exactly; translate only the VALUES of "title" and "description" fields
- Do NOT translate: code blocks, inline code, UUIDs, hex values, file paths, shell commands, variable names, package names, URLs
- Do NOT translate brand/product names: ESP32, WS2812B, HC-SR04, FastLED, Valhalla, MapLibre, CoreBluetooth, Bluetooth, FreeRTOS, GitHub, iPhone, iOS, GATT, SPP, GPIO, JSON, MDX, Astro, Starlight
- Translate all human-readable prose, heading text, table cell content, and description text
- Maintain the exact same document structure and line count as much as possible`;

const changedFiles = (process.env.CHANGED_FILES ?? '')
  .split('\n')
  .map((f) => f.trim().replace(/\\+$/, ''))
  .filter((f) => f && !f.includes('/de/'));

if (changedFiles.length === 0) {
  console.log('No English doc files changed — skipping translation.');
  process.exit(0);
}

console.log(`Translating ${changedFiles.length} file(s)...`);

for (const file of changedFiles) {
  console.log(`\n→ ${file}`);

  const content = readFileSync(file, 'utf-8');

  const response = await client.chat.completions.create({
    model: 'gpt-4o-mini',
    temperature: 0.1,
    messages: [
      { role: 'system', content: SYSTEM_PROMPT },
      { role: 'user', content },
    ],
  });

  const translated = response.choices[0].message.content ?? '';

  const outPath = file.replace(
    'docs/src/content/docs/',
    'docs/src/content/docs/de/',
  );

  mkdirSync(dirname(outPath), { recursive: true });
  writeFileSync(outPath, translated, 'utf-8');
  console.log(`  ✓ written to ${outPath}`);
}

console.log('\nTranslation complete.');
