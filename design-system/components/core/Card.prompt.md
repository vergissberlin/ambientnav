A dark surface container — the default panel for grouping content.

```jsx
<Card glow="cyan"><h3>Live guide</h3>…</Card>
<Card glow="magenta" frame><h3>Proximity alert</h3>…</Card>
```

Flat `--amb-surface-2` fill, hairline border, 16px radius, ambient drop shadow. `glow` adds a hue bloom on hover. Never add a colored left-border stripe or grey inner shadow — state/hue is signaled via corner brackets, not a side stripe, see the Cybernetic Frame section in `design-system/readme.md`. The optional `frame` prop (default `false`) renders those corner brackets, colored to match `glow` (cyan/violet/magenta), at rest opacity `.35` and active opacity `.9` on hover.
