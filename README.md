# Processing Image Data in Aestbeac

This repository contains a Processing sketch that generates a layered, noise-driven texture suitable for motion backgrounds, UI flourishes, or generative art studies. The sketch keeps its look and feel configurable by reading a parameter set from JSON so you can iterate without recompiling.

## Repository layout

| File | Description |
| ---- | ----------- |
| `dynamic_texture_template.pde` | Main Processing sketch that renders the animated texture. |
| `dynamic_texture_params.json` | Parameter file loaded at runtime to control colour palette, animation speed, geometry, and overlays. |
| `data/` (optional) | When you run the sketch inside Processing, place `dynamic_texture_params.json` in a `data` folder beside the PDE file so it can be reloaded at runtime. |

## Prerequisites

* [Processing 4.x](https://processing.org/download) with the **Java** mode enabled (this sketch uses Processing's Java API).
* A GPU that supports Processing's default OpenGL renderer (`P2D`) for best performance.

## Getting started

1. Clone or download this repository.
2. Create a new Processing sketch named `dynamic_texture_template` (or copy the `.pde` and `.json` files into an existing sketch).
3. Place `dynamic_texture_template.pde` inside the sketch folder.
4. Create a `data` directory beside the PDE file and copy `dynamic_texture_params.json` into it. Processing automatically searches this folder when calling `loadJSONObject`.
5. Open the sketch in the Processing IDE and press **Run**.

The sketch loads configuration values during `settings()` and resizes the canvas according to the JSON file. While the sketch is running you can press **R** to reload `dynamic_texture_params.json` without restarting, making rapid iteration possible.

## Customising the texture

Most visual aspects of the animation are exposed in `dynamic_texture_params.json`:

* `canvasWidth` / `canvasHeight` — overall canvas size in pixels.
* `palette` — list of hues, saturations, and brightness values (HSB) used for colour cycling.
* `cell*` keys — control the size, scaling jitter, rotation, and positional offset of each rectangular cell drawn to the canvas.
* `noise*` keys — adjust the frequency and animation speed of the underlying Perlin noise fields.
* `accent*` keys — toggle additional stroke layers that appear when noise crosses the `accentThreshold`.
* `overlay*` keys — define animated additive bands rendered above the cells for extra motion and atmosphere.
* `background*` keys — set the HSB background colour and transparency.

Change the values, save the JSON file, and press **R** in the running sketch to immediately see the effect of your adjustments.

## Tips

* Use Processing's **Sketch → Present** mode once you are happy with the look to generate a full-screen ambience.
* Because colours are handled in HSB, small adjustments to `paletteSpread`, `saturationJitter`, or `brightnessJitter` can dramatically change the mood without editing the palette entries.
* Increase `overlayBands`, `accentLayers`, or `noiseOctaves` gradually—these parameters can increase CPU usage on lower-powered machines.

## License

This project is licensed under the terms of the [Apache 2.0 License](LICENSE).
