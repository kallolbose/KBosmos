# KBosmos — solar system simulation

A single-file web app (`kbosmos.html`) that shows the Sun, planets, Moon and Pluto at their real current positions and animates orbits and spins at true relative speeds.

## Stack
- Plain HTML/CSS/JS, no build step. Three.js r128 (UMD global `THREE`) from cdnjs, plus `OrbitControls` from jsDelivr (`three@0.128.0/examples/js/controls/OrbitControls.js`).
- Surface maps live in `textures/` (`<bodyId>.jpg`, plus `earth_clouds.jpg`, `earth_night.jpg`, `saturn_ring.png`). They're from Wikimedia Commons: Solar System Scope maps (CC BY 4.0, credited in the panel) and NASA's New Horizons Pluto mosaic (public domain). Earth and Moon are 3840 px; the rest are 2k. The page doesn't load the image files directly. It loads `textures/js/<name>.js` (each calls `orreryMap(name, dataURI)`), built from the images by `.claude/build-maps.ps1`. That way the maps also work when `kbosmos.html` is opened straight from disk (Chrome blocks WebGL from using `file://` images). Re-run the build script after changing an image. The procedural canvas textures are kept as the fallback until the maps load. Earth city lights are an emissive map faded on the lit side via `onBeforeCompile` (uses Lambert's `vLightFront`).

## Physics
- Planet positions: NASA JPL "Approximate Positions of the Planets", Table 1 Keplerian elements (valid 1800–2050). Sim time is clamped to that range.
- Moon: low-precision geocentric formula (ecliptic longitude/latitude/distance).
- Spin: IAU pole RA/Dec and prime-meridian W = W0 + Wd·days. Each `tilt` frame has +Y = pole and +X = the node at RA = pole RA + 90°, and `spin.rotation.y = W + mapLon0`, so the map centre (sphere local +X) lands where the IAU puts it. That's why the Moon's near side faces Earth and Earth's day side matches UTC. Negative Wd = spin opposite to the listed pole (Venus, Uranus). Pluto's IAU pole is its right-hand pole, so its Wd is positive, with `retro: true`. Pluto's map is centred on 180° (`mapLon0`).
- "Watch from above" (Moon box in the panel): top-down view of Earth and the Moon with a gold near-side marker (`nearMark`) to show tidal locking.
- Coordinates: ecliptic J2000 (x, y, z) maps to scene (x, z, −y), so scene +Y is ecliptic north.
- One shared sim clock drives everything, which keeps relative speeds exact.
- Galaxy view (Galaxy button): one click enters it via `setGalaxy`. That sets time to 1 month/s and follows the Sun, shows a compact card (drift-scale buttons, plus folded-away legend, schematic map and facts), and streams a dust field (`dust`, wrapped box shifted by the drift since entry). Exit restores the previous speed, pause and focus. It also has 3D "spiral path" trails. The Sun's galactocentric velocity is `GAL_V` (233 km/s circular + Schönrich 2010 solar motion), converted galactic → equatorial (`A_G` transpose) → ecliptic → scene. The trails are recomputed every frame from `heliocentric()` at past times minus the drift (`galK` scales the drift: 1 = true, 0.1, 0.01), so the Sun and planets themselves never move. The HUD distance readout also shows the galactic distance travelled since the page opened.
- Moons of other planets (`MOONS`, 20 major moons): JPL mean elements (ssd.jpl.nasa.gov/sats/elem, epoch J2000), each in its Laplace-plane frame (or the planet's equator), built like the body `tilt` frames. Uranus's moons use its right-hand pole, opposite the IAU north pole, so they orbit the way Uranus spins. The display distance in planet radii is `moonDist`: true below 3 radii (keeps Mimas outside the rings), compressed beyond that. Moon maps (`textures/<moon>.jpg`, from NASA/USGS/JPL/LPI maps on Wikimedia Commons) are made from the downloaded originals by `.claude/prep-moon-maps.ps1`, which crops poster margins, reprojects Ganymede from Mercator and fills unmapped areas. They load per system on first follow or close-up (`loadMoonMaps`). The Cassini maps are centred on 180° (`MAP_CENTER_180`), the rest on 0°. Uranus moon maps are flipped north-up. The moons are tidally locked, facing their planet, and the procedural textures remain as the fallback. Each moon is also a followable `byId` entry (`isMoon`, with a stand-in `root` at its world position). Following a planet frames its whole moon system.
- Eclipses: computed at load (not hard-coded) with Meeus, *Astronomical Algorithms* ch. 54, for every lunation 1800–2050 → `ECLIPSES` (sorted, UTC ms). Uses a coarse ΔT table. Matches NASA catalogue times to ~1 min. The "Eclipses" button opens prev/next solar & lunar bookmarks plus a nearby list; jumping pauses and follows Earth. No shadows are rendered, so `tintMoon()` reddens the Moon while it's in the umbra.
- Moon orbit ring is tilted 5.145° and turned to the ascending node `moonNode(d)` (= L − F of `moonGeo`, so ring and Moon agree). Solid half = north of ecliptic.
- "Why not every month?" (in the Eclipses panel): live readouts plus a geometry overlay (`geoGrp`: ecliptic disc, node line, Sun/shadow line). In that view `sceneRadius` shrinks Earth and Moon to true size relative to the Moon's orbit (60.27 Earth radii), because neither display mode keeps that ratio (true mode is only ~5 Earth radii) and the exaggerated sizes make the Moon look aligned every month. The camera turns with the Sun line to stay side-on.

## Display scaling
- `compressed` mode: distance = 12·√r(AU); body sizes exaggerated (∝ R^0.42).
- `true` mode: 1 AU = 40 units; planets ×400, Sun ×20; Moon distance exaggerated.

## Gotchas
- Each body object has 3D groups `root` / `tilt` / `spin`. Don't add data fields with those names (the axial-tilt number is `obliq` because `tilt` clashed once and crashed the app).

## Running locally
- Opening `kbosmos.html` from disk works in Chrome. The browser pane, though, renders `file://` pages as a snapshot without relative files, so test over HTTP. `.claude/launch.json` starts `.claude/serve.ps1`, a PowerShell static server on http://localhost:8765. Python and Node aren't installed on this machine.

## Published copy
- Artifact: https://claude.ai/artifact/VwvJqCV1FGmFAhae6u1aLx. Republish after changes by publishing `kbosmos.html` with that URL. Publish `textures/js/*.js` via `files` when they change. The raw images aren't published. Files left out are kept on later publishes.
