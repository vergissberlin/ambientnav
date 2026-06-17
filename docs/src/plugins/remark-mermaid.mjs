import { visit } from 'unist-util-visit';

// HTML-escape so the raw source is valid inside a <pre> element.
// The browser decodes entities back to the original characters when
// mermaid reads element.textContent, so the diagram syntax is unaffected.
const esc = (s) =>
  s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');

export function remarkMermaid() {
  return (tree) => {
    visit(tree, 'code', (node, index, parent) => {
      if (node.lang !== 'mermaid') return;

      // Replace the fenced code block with a raw HTML node.
      // The `not-content` class opts the element out of Starlight's
      // prose styling. Mermaid targets `.mermaid` to render SVGs.
      parent.children[index] = {
        type: 'html',
        value: `<pre class="mermaid not-content">${esc(node.value)}</pre>`,
      };
    });
  };
}
