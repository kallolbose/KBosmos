# KBosmos

A 3D solar system that shows the Sun, planets, Moon, Pluto and 20 major moons where they really are right now, and runs their orbits and spins at their true relative speeds.

It's a single HTML page built with [Three.js](https://threejs.org/). There's no build step and nothing to install.

## Features

- **Real positions, live.** Planets use NASA JPL's Keplerian orbital elements (accurate from 1800 to 2050). The Moon uses the main terms of Meeus's lunar theory (accurate to about 10 arcseconds).
- **Real spin.** Each body's axis and rotation follow the IAU rotation models. Earth's day side matches the actual time, and the Moon keeps its near side toward Earth.
- **One shared clock.** Speed time up, slow it down, run it backwards, pause, or jump back to now. Everything stays in step.
- **Moons.** 20 major moons of Mars, Jupiter, Saturn, Uranus, Neptune and Pluto, each tidally locked and mapped with spacecraft imagery.
- **Eclipses.** Every solar and lunar eclipse from 1800 to 2050 is computed at load with Meeus's method (within about a minute of NASA's catalogue). You can jump to the previous or next one. A live, to-scale view shows how the Sun, Moon and Earth line up and explains each kind of eclipse: total, annular, hybrid, partial, and the three lunar kinds. **Watch it from Earth** shows the sky from the spot where the eclipse is central: the ring of an annular eclipse, the corona at totality, or the Moon reddening in Earth's shadow. A geometry view explains why there isn't an eclipse every month.
- **Galaxy view.** Watch the solar system travel around the Milky Way at about 246 km/s, with the planets tracing spirals.
- **Two scales.** *Compressed* fits everything on screen. *True distance* keeps real spacing (with enlarged bodies).
- **What if… (fiction mode).** Switch from the formulas to a real gravity simulation of all 32 bodies, starting from where they really are. Then change anything: drag a planet, change any body's mass, distance or speed, reverse or remove it, or pick a scenario (Jupiter becomes a star, no Jupiter, a passing star, the Sun losing half its mass…). Press Play to watch the effect spread. A report lists what happened to every body (new orbits, escapes, collisions, lost or captured moons, and Earth's sunlight), with trails for the new paths and hollow dots showing where the planets really are.
- **Orbit picker.** Show or hide any orbit, including each planet's moon orbits, or use the All / Inner / Outer / None shortcuts.
- Click any body to follow it and see its details.

## Running it

Open `kbosmos.html` in Chrome. That's all: the surface maps are bundled as scripts in `textures/js/`, so they load even from a local file.

It works on phones and tablets too. On a phone the controls fit in one row, with the rest under **More**, and panels open one at a time above the bar. You drag to rotate, pinch to zoom and tap a body to follow it; in What if…, long-press a planet to move it. Touch devices load lighter 1024 px surface maps (`textures/js/sm/`, about 4 MB in all) instead of the full-size ones. On a desktop with a mouse nothing changes.

To serve it over HTTP instead (on Windows, PowerShell only):

```powershell
powershell -File .claude/serve.ps1
```

Then open http://localhost:8765.

## Project layout

| Path | What it is |
| --- | --- |
| `kbosmos.html` | The whole app: markup, styles and code |
| `textures/*.jpg`, `*.png` | Source surface maps |
| `textures/js/*.js` | The maps as data-URI scripts that the page actually loads |
| `.claude/build-maps.ps1` | Rebuilds `textures/js/` (and the smaller `textures/js/sm/` copies for touch devices) from the images. Run it after changing a map. |
| `.claude/prep-moon-maps.ps1` | Crops, reprojects and fills the downloaded moon maps |
| `.claude/serve.ps1` | Small static server for local testing |

## Credits

- Orbital elements: NASA JPL, [Approximate Positions of the Planets](https://ssd.jpl.nasa.gov/planets/approx_pos.html) and [planetary satellite mean elements](https://ssd.jpl.nasa.gov/sats/elem/)
- Rotation models: IAU Working Group on Cartographic Coordinates and Rotational Elements
- Eclipses: Jean Meeus, *Astronomical Algorithms*, chapter 54
- Galactic motion: Schönrich, Binney & Dehnen (2010)
- Planet maps: [Solar System Scope](https://www.solarsystemscope.com/textures/) (CC BY 4.0, based on NASA data)
- Pluto and Charon: NASA/JHUAPL/SwRI, New Horizons
- Moon maps: NASA/JPL/USGS (Galileo, Voyager); NASA/JPL-Caltech/SSI/LPI (Cassini); Phil Stooke/PDS (Phobos); Deimos: Askaniy Anpilogov & John van Vliet (CC BY-SA 3.0)

Parts of Triton, Charon and the moons of Uranus have never been photographed, so they're filled with an average colour.

---

Made by Kallol Bose.
