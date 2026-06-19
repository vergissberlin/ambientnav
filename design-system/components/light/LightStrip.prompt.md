The signature AmbientNav element — an addressable-LED strip rendering the brand's light language.

```jsx
<LightStrip mode="guide" direction="right" />
<LightStrip mode="alert" intensity={0.8} />
<LightStrip mode="ambient" />
```

Modes: `ambient` (calm idle gradient), `guide` (cyan brightens toward `direction`), `alert` (magenta fills inward by `intensity` 0–1). Use as the hero motif, in the app's live-guide view, and anywhere the product's light behavior is shown. Cyan = direction, magenta = warning — never swap.
