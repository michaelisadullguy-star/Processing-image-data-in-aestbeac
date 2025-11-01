// Dynamic Texture Template for Processing
//
// This sketch demonstrates how to create a multi-layered, colour-rich texture
// using animated Perlin noise. Parameters are loaded from a JSON file via the
// loadParamsJSON() helper so that designers can iterate without recompiling.
// Press 'R' to reload the JSON file at runtime.

SketchParams params = new SketchParams();
String PARAM_FILE = "data/dynamic_texture_params.json";
boolean sketchReady = false;
ArrayList<CellData> cellGrid = new ArrayList<CellData>();
ArrayList<OverlayBandData> overlayBandData = new ArrayList<OverlayBandData>();

void settings() {
  loadParamsJSON();
  size(params.canvasWidth, params.canvasHeight, P2D);
}

void setup() {
  colorMode(HSB, 360, 100, 100, 100);
  surface.setResizable(true);
  applyRuntimeParams();
  sketchReady = true;
}

void draw() {
  background(
    params.backgroundHue,
    params.backgroundSaturation,
    params.backgroundBrightness,
    params.backgroundAlpha
  );

  float timeSeconds = millis() * 0.001;
  float paletteTime = timeSeconds * params.colorCycleSpeed;
  float noiseTime = timeSeconds * params.noiseSpeed;

  noStroke();
  rectMode(CENTER);

  if (cellGrid.size() == 0) {
    buildCellGrid();
  }

  if (overlayBandData.size() == 0 && params.overlayBands > 0) {
    buildOverlayBands();
  }

  for (CellData cell : cellGrid) {
    float noiseValue = noise(cell.noiseX, cell.noiseY, noiseTime);
    float paletteSample = fract(noiseValue + cell.paletteSeed * params.palettePhaseJitter + sin(paletteTime + cell.paletteSeed * TWO_PI) * 0.1);
    color texColour = samplePalette(paletteSample, paletteTime + cell.paletteSeed * params.palettePhaseJitter * TWO_PI);

    float alphaOsc = 0.75 + 0.25 * sin(paletteTime * 1.1 + cell.paletteSeed * TWO_PI);
    float alpha = params.fillAlpha * alphaOsc;
    fill(hue(texColour), saturation(texColour), brightness(texColour), alpha);

    float offsetAngle = paletteTime * 0.8 + cell.offsetSeed * TWO_PI;
    float offsetRadius = params.cellOffsetJitter * params.cellSize * sin(paletteTime + cell.offsetSeed * TWO_PI);
    float px = cell.centerX + cos(offsetAngle) * offsetRadius;
    float py = cell.centerY + sin(offsetAngle) * offsetRadius;

    pushMatrix();
    translate(px, py);
    float baseAngle = (noiseValue - 0.5) * PI * params.textureDepth;
    float angle = baseAngle + cell.rotationSeed * params.cellRotationJitter;
    rotate(angle);

    float widthScale = 0.7 + noiseValue * params.textureDepth + cell.widthJitter * params.cellScaleJitter;
    float heightScale = 0.7 + cos(paletteTime + noiseValue * PI) * 0.3 + cell.heightJitter * params.cellScaleJitter;
    float rectWidth = params.cellSize * max(0.25, widthScale);
    float rectHeight = params.cellSize * max(0.25, heightScale);
    float corner = max(0, params.cornerRadius + cell.widthJitter * params.cornerRadiusJitter);
    rect(0, 0, rectWidth, rectHeight, corner);

    if (noiseValue > params.accentThreshold) {
      drawAccentLayer(noiseValue, paletteTime, cell);
    }
    popMatrix();
  }

  drawNoiseOverlay(timeSeconds);
}

void drawNoiseOverlay(float timeSeconds) {
  if (overlayBandData.size() == 0) {
    return;
  }

  pushStyle();
  blendMode(ADD);
  noFill();
  for (OverlayBandData band : overlayBandData) {
    float timePhase = timeSeconds * params.overlaySpeed + band.noiseShift;
    float noiseOffset = noise(timePhase, band.offsetSeed * 11.0);
    float paletteSample = fract(band.position + noiseOffset + band.offsetSeed);
    color bandColour = samplePalette(paletteSample, timeSeconds + band.offsetSeed * params.overlayAlphaJitter * TWO_PI);

    float alphaOsc = 0.65 + 0.35 * sin(timeSeconds * 0.7 + band.offsetSeed * TWO_PI);
    float strokeAlpha = params.overlayAlpha * alphaOsc;
    stroke(hue(bandColour), saturation(bandColour), brightness(bandColour), strokeAlpha);
    strokeWeight(1.0 + band.strokeSeed * params.overlayStrokeScale);

    float yBase = height * (band.position + 0.05f * sin(TWO_PI * (band.position + timePhase + band.offsetSeed)));
    beginShape();
    for (int x = 0; x < width; x += params.overlayStep) {
      float distort = noise(x * params.overlayNoiseScale, band.position * params.overlayNoiseScale, timePhase + band.noiseShift);
      float y = yBase + map(distort, 0, 1, -params.overlayAmplitude, params.overlayAmplitude);
      curveVertex(x, y);
    }
    endShape();
  }
  popStyle();
}

void drawAccentLayer(float noiseValue, float paletteTime, CellData cell) {
  pushStyle();
  noFill();
  strokeWeight(params.accentStrokeWeight);

  for (int layer = 0; layer < params.accentLayers; layer++) {
    float blend = (float) layer / max(1, params.accentLayers - 1);
    float samplePoint = fract(noiseValue + blend * params.accentJitter + cell.accentSeed);
    color c = samplePalette(samplePoint, paletteTime + blend + cell.accentSeed * params.accentPhaseJitter * TWO_PI);
    float phase = paletteTime * 0.9 + blend * TWO_PI + cell.accentSeed * params.accentPhaseJitter * TWO_PI;
    float alpha = params.accentAlpha * (0.55 + 0.45 * sin(phase));
    stroke(hue(c), saturation(c), brightness(c), alpha);

    float radiusBase = params.cellSize * (1.0 + blend * params.accentScale);
    float radius = radiusBase * (0.9 + 0.2 * sin(phase + cell.rotationSeed));
    float offset = (noiseValue - 0.5) * params.accentDrift * params.cellSize + cell.rotationSeed * params.accentRadiusJitter * params.cellSize * 0.5;
    float skew = 0.7 + 0.3 * cos(phase + cell.offsetSeed * TWO_PI);
    ellipse(offset, offset * skew, radius, radius * skew);
  }
  popStyle();
}

color samplePalette(float mix, float timePhase) {
  if (params.palette.size() == 0) {
    return color(0, 0, 100, 100);
  }

  float wrappedMix = (mix % 1.0 + 1.0) % 1.0;
  int paletteSize = params.palette.size();
  float scaled = wrappedMix * paletteSize;
  int indexA = floor(scaled) % paletteSize;
  int indexB = (indexA + 1) % paletteSize;
  float localBlend = scaled - floor(scaled);

  float[] colourA = params.palette.get(indexA);
  float[] colourB = params.palette.get(indexB);

  float hueValue = lerpAngle(colourA[0], colourB[0], localBlend);
  hueValue = (hueValue + params.paletteSpread * sin(timePhase + wrappedMix * TWO_PI)) % 360;
  if (hueValue < 0) {
    hueValue += 360;
  }

  float saturationValue = lerp(colourA[1], colourB[1], localBlend);
  float brightnessValue = lerp(colourA[2], colourB[2], localBlend);

  saturationValue = constrain(
    saturationValue + params.saturationJitter * sin(TWO_PI * wrappedMix + timePhase),
    0,
    100
  );
  brightnessValue = constrain(
    brightnessValue + params.brightnessJitter * cos(TWO_PI * wrappedMix + timePhase),
    0,
    100
  );

  return color(hueValue, saturationValue, brightnessValue, 100);
}

float lerpAngle(float start, float end, float amt) {
  float delta = ((end - start + 540) % 360) - 180;
  return (start + delta * amt + 360) % 360;
}

void keyPressed() {
  if (key == 'r' || key == 'R') {
    println("Reloading parameters from " + PARAM_FILE);
    loadParamsJSON();
  }
}

int readInt(JSONObject json, String key, int fallback) {
  return json.hasKey(key) ? json.getInt(key) : fallback;
}

float readFloat(JSONObject json, String key, float fallback) {
  return json.hasKey(key) ? json.getFloat(key) : fallback;
}

void loadParamsJSON() {
  loadParamsJSON(PARAM_FILE, sketchReady);
}

void loadParamsJSON(String path) {
  loadParamsJSON(path, sketchReady);
}

void loadParamsJSON(String path, boolean applyRuntime) {
  SketchParams newParams = new SketchParams();
  JSONObject json = null;
  try {
    json = loadJSONObject(path);
    println("Parameters loaded from " + path);
  } catch (Exception e) {
    println("Could not load parameters from " + path + ". Using defaults.");
  }

  if (json != null) {
    newParams.loadFrom(json);
  }

  params = newParams;

  if (applyRuntime) {
    applyRuntimeParams();
  }
}

void applyRuntimeParams() {
  if (surface != null) {
    surface.setSize(params.canvasWidth, params.canvasHeight);
  }
  smooth(params.smoothingSamples);
  frameRate(params.targetFrameRate);
  noiseDetail(params.noiseOctaves, params.noiseFalloff);
  preparePrecomputedAssets();
}

void preparePrecomputedAssets() {
  buildCellGrid();
  buildOverlayBands();
}

void buildCellGrid() {
  cellGrid = new ArrayList<CellData>();

  int gridWidth = width > 0 ? width : params.canvasWidth;
  int gridHeight = height > 0 ? height : params.canvasHeight;
  int maxWidth = max(gridWidth, params.cellSize);
  int maxHeight = max(gridHeight, params.cellSize);

  for (int y = 0; y < maxHeight; y += params.cellSize) {
    for (int x = 0; x < maxWidth; x += params.cellSize) {
      if (x >= gridWidth || y >= gridHeight) {
        continue;
      }

      CellData cell = new CellData();
      cell.centerX = x + params.cellSize * 0.5;
      cell.centerY = y + params.cellSize * 0.5;
      cell.noiseX = x * params.noiseScale;
      cell.noiseY = y * params.noiseScale;

      cell.widthJitter = signedRandom(pseudoRandom(x, y, 11.0));
      cell.heightJitter = signedRandom(pseudoRandom(x, y, 19.0));
      cell.rotationSeed = signedRandom(pseudoRandom(x, y, 23.0));
      cell.offsetSeed = pseudoRandom(x, y, 31.0);
      cell.paletteSeed = pseudoRandom(x, y, 47.0);
      cell.accentSeed = pseudoRandom(x, y, 59.0);

      cellGrid.add(cell);
    }
  }

  if (cellGrid.size() == 0) {
    CellData cell = new CellData();
    int fallbackWidth = width > 0 ? width : params.canvasWidth;
    int fallbackHeight = height > 0 ? height : params.canvasHeight;
    cell.centerX = fallbackWidth * 0.5;
    cell.centerY = fallbackHeight * 0.5;
    cell.noiseX = cell.centerX * params.noiseScale;
    cell.noiseY = cell.centerY * params.noiseScale;
    cell.widthJitter = 0;
    cell.heightJitter = 0;
    cell.rotationSeed = 0;
    cell.offsetSeed = 0.5;
    cell.paletteSeed = 0.3;
    cell.accentSeed = 0.8;
    cellGrid.add(cell);
  }
}

void buildOverlayBands() {
  overlayBandData = new ArrayList<OverlayBandData>();
  if (params.overlayBands <= 0) {
    return;
  }

  for (int i = 0; i < params.overlayBands; i++) {
    OverlayBandData band = new OverlayBandData();
    band.position = params.overlayBands == 1 ? 0.5 : (float) i / (float) (params.overlayBands - 1);
    band.offsetSeed = pseudoRandom(i, params.overlayBands, 71.0);
    band.strokeSeed = 0.5 + 0.5 * signedRandom(pseudoRandom(i, params.overlayBands, 83.0));
    band.noiseShift = pseudoRandom(i, params.overlayBands, 97.0) * 8.0;
    overlayBandData.add(band);
  }
}

float fract(float value) {
  return value - floor(value);
}

float signedRandom(float r) {
  return r * 2.0 - 1.0;
}

float pseudoRandom(float x, float y, double salt) {
  float v = sin((float) ((x + salt) * 12.9898 + (y - salt) * 78.233));
  return fract(v * 43758.5453f);
}

class CellData {
  float centerX;
  float centerY;
  float noiseX;
  float noiseY;
  float widthJitter;
  float heightJitter;
  float rotationSeed;
  float offsetSeed;
  float paletteSeed;
  float accentSeed;
}

class OverlayBandData {
  float position;
  float offsetSeed;
  float strokeSeed;
  float noiseShift;
}

class SketchParams {
  int canvasWidth = 1080;
  int canvasHeight = 640;
  int cellSize = 24;
  float cellScaleJitter = 0.35;
  float cellRotationJitter = 0.5;
  float cellOffsetJitter = 0.28;
  float cornerRadiusJitter = 2.5;
  float palettePhaseJitter = 0.25;

  float noiseScale = 0.006;
  float noiseSpeed = 0.2;
  int noiseOctaves = 4;
  float noiseFalloff = 0.5;

  float colorCycleSpeed = 0.4;
  float paletteSpread = 80;
  float saturationJitter = 20;
  float brightnessJitter = 25;

  float textureDepth = 0.7;
  float fillAlpha = 60;
  float cornerRadius = 4.0;

  float accentThreshold = 0.72;
  int accentLayers = 3;
  float accentScale = 2.2;
  float accentStrokeWeight = 1.6;
  float accentAlpha = 45;
  float accentJitter = 0.35;
  float accentDrift = 0.45;
  float accentPhaseJitter = 0.35;
  float accentRadiusJitter = 0.35;

  int overlayBands = 5;
  float overlayNoiseScale = 0.004;
  float overlayAmplitude = 40;
  float overlayAlpha = 28;
  float overlaySpeed = 0.35;
  int overlayStep = 16;
  float overlayStrokeScale = 3.0;
  float overlayAlphaJitter = 0.35;

  float backgroundHue = 210;
  float backgroundSaturation = 18;
  float backgroundBrightness = 8;
  float backgroundAlpha = 100;

  int targetFrameRate = 60;
  int smoothingSamples = 4;

  ArrayList<float[]> palette = new ArrayList<float[]>();

  SketchParams() {
    palette.add(new float[] {210, 65, 95});
    palette.add(new float[] {320, 70, 95});
    palette.add(new float[] {35, 85, 95});
    palette.add(new float[] {160, 55, 90});
  }

  void loadFrom(JSONObject json) {
    canvasWidth = readInt(json, "canvasWidth", canvasWidth);
    canvasHeight = readInt(json, "canvasHeight", canvasHeight);
    cellSize = readInt(json, "cellSize", cellSize);
    cellScaleJitter = readFloat(json, "cellScaleJitter", cellScaleJitter);
    cellRotationJitter = readFloat(json, "cellRotationJitter", cellRotationJitter);
    cellOffsetJitter = readFloat(json, "cellOffsetJitter", cellOffsetJitter);
    cornerRadiusJitter = readFloat(json, "cornerRadiusJitter", cornerRadiusJitter);
    palettePhaseJitter = readFloat(json, "palettePhaseJitter", palettePhaseJitter);

    noiseScale = readFloat(json, "noiseScale", noiseScale);
    noiseSpeed = readFloat(json, "noiseSpeed", noiseSpeed);
    noiseOctaves = readInt(json, "noiseOctaves", noiseOctaves);
    noiseFalloff = readFloat(json, "noiseFalloff", noiseFalloff);

    colorCycleSpeed = readFloat(json, "colorCycleSpeed", colorCycleSpeed);
    paletteSpread = readFloat(json, "paletteSpread", paletteSpread);
    saturationJitter = readFloat(json, "saturationJitter", saturationJitter);
    brightnessJitter = readFloat(json, "brightnessJitter", brightnessJitter);

    textureDepth = readFloat(json, "textureDepth", textureDepth);
    fillAlpha = readFloat(json, "fillAlpha", fillAlpha);
    cornerRadius = readFloat(json, "cornerRadius", cornerRadius);

    accentThreshold = readFloat(json, "accentThreshold", accentThreshold);
    accentLayers = readInt(json, "accentLayers", accentLayers);
    accentScale = readFloat(json, "accentScale", accentScale);
    accentStrokeWeight = readFloat(json, "accentStrokeWeight", accentStrokeWeight);
    accentAlpha = readFloat(json, "accentAlpha", accentAlpha);
    accentJitter = readFloat(json, "accentJitter", accentJitter);
    accentDrift = readFloat(json, "accentDrift", accentDrift);
    accentPhaseJitter = readFloat(json, "accentPhaseJitter", accentPhaseJitter);
    accentRadiusJitter = readFloat(json, "accentRadiusJitter", accentRadiusJitter);

    overlayBands = readInt(json, "overlayBands", overlayBands);
    overlayNoiseScale = readFloat(json, "overlayNoiseScale", overlayNoiseScale);
    overlayAmplitude = readFloat(json, "overlayAmplitude", overlayAmplitude);
    overlayAlpha = readFloat(json, "overlayAlpha", overlayAlpha);
    overlaySpeed = readFloat(json, "overlaySpeed", overlaySpeed);
    overlayStep = readInt(json, "overlayStep", overlayStep);
    overlayStrokeScale = readFloat(json, "overlayStrokeScale", overlayStrokeScale);
    overlayAlphaJitter = readFloat(json, "overlayAlphaJitter", overlayAlphaJitter);

    backgroundHue = readFloat(json, "backgroundHue", backgroundHue);
    backgroundSaturation = readFloat(json, "backgroundSaturation", backgroundSaturation);
    backgroundBrightness = readFloat(json, "backgroundBrightness", backgroundBrightness);
    backgroundAlpha = readFloat(json, "backgroundAlpha", backgroundAlpha);

    targetFrameRate = readInt(json, "targetFrameRate", targetFrameRate);
    smoothingSamples = readInt(json, "smoothingSamples", smoothingSamples);

    if (json.hasKey("palette")) {
      JSONArray arr = json.getJSONArray("palette");
      if (arr != null && arr.size() > 0) {
        palette = new ArrayList<float[]>();
        for (int i = 0; i < arr.size(); i++) {
          JSONObject entry = arr.getJSONObject(i);
          if (entry == null) {
            continue;
          }
          float h = entry.hasKey("h") ? entry.getFloat("h") : Float.NaN;
          float s = entry.hasKey("s") ? entry.getFloat("s") : Float.NaN;
          float b = entry.hasKey("b") ? entry.getFloat("b") : Float.NaN;
          if (!Float.isNaN(h) && !Float.isNaN(s) && !Float.isNaN(b)) {
            palette.add(new float[] {h, s, b});
          }
        }
        if (palette.size() == 1) {
          float[] colour = palette.get(0);
          palette.add(new float[] {(colour[0] + 120) % 360, colour[1], colour[2]});
        }
      }
    }
  }
}
