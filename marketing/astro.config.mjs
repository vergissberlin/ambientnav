import { defineConfig } from 'astro/config';

export default defineConfig({
  // Netlify serves this from its own domain root, unlike docs/ which is
  // path-based under vergissberlin.github.io/ambientnav on GitHub Pages.
  outDir: './dist',
});
