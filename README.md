# 🏎️ Flutter F1 Circuit Paths

> **All 24 Formula 1 circuits. GPS-accurate. Ready to race.**
> Drop two files into any Flutter project and get pixel-perfect circuit maps with animated cars — for every round on the 2024 calendar.

---

## What is this?

When I was building **APEX F1** — a Flutter race simulation app — I needed accurate circuit layouts to draw on screen. I couldn't find anything clean, ready-to-use, or Flutter-specific anywhere online.

So I built it myself.

This repo contains two Dart files that give you everything you need to render any F1 circuit in Flutter:

- **`circuit_paths.dart`** — GPS-derived coordinate paths for all 24 circuits, normalised to `0.0–1.0` so they scale to any canvas size
- **`multi_car_circuit_painter.dart`** — A ready-to-use animated `CustomPainter` widget that draws the circuit AND animates up to 20 cars racing around it in real time

No dependencies. No packages. Just drop them in and go.

---

## Preview

The `MultiCarCircuit` widget renders a live race visualization:

```
🏎️  Your car glows cyan with your name floating above it
🔵🔴🟠  Each rival in their real 2024 team livery color
🟡  Safety car mode turns all cars yellow and bunches them together
📍  Every corner in its GPS-accurate position
```

The circuit draws itself corner by corner with a glowing neon pulse on first load. Every corner is where it should be — the Grand Hotel Hairpin actually looks like a hairpin, Eau Rouge/Raidillon has the real uphill sweep, Suzuka's figure-8 overpass is faithfully reproduced.

---

## All 24 Circuits

| Round | Flag | Circuit | GPS Points |
|-------|------|---------|-----------|
| R1  | 🇧🇭 | Bahrain International Circuit      | 94  |
| R2  | 🇸🇦 | Jeddah Corniche Circuit            | 152 |
| R3  | 🇦🇺 | Albert Park Circuit                | 146 |
| R4  | 🇯🇵 | Suzuka International Racing Course | 172 |
| R5  | 🇨🇳 | Shanghai International Circuit     | 141 |
| R6  | 🇺🇸 | Miami International Autodrome      | 103 |
| R7  | 🇮🇹 | Autodromo Enzo e Dino Ferrari      | 84  |
| R8  | 🇲🇨 | Circuit de Monaco                  | 160 |
| R9  | 🇨🇦 | Circuit Gilles Villeneuve          | 102 |
| R10 | 🇪🇸 | Circuit de Barcelona-Catalunya     | 150 |
| R11 | 🇦🇹 | Red Bull Ring                      | 81  |
| R12 | 🇬🇧 | Silverstone Circuit                | 135 |
| R13 | 🇭🇺 | Hungaroring                        | 141 |
| R14 | 🇧🇪 | Circuit de Spa-Francorchamps       | 153 |
| R15 | 🇳🇱 | Circuit Zandvoort                  | 119 |
| R16 | 🇮🇹 | Autodromo Nazionale Monza          | 125 |
| R17 | 🇦🇿 | Baku City Circuit                  | 86  |
| R18 | 🇸🇬 | Marina Bay Street Circuit          | 116 |
| R19 | 🇺🇸 | Circuit of the Americas            | 171 |
| R20 | 🇲🇽 | Autódromo Hermanos Rodríguez       | 101 |
| R21 | 🇧🇷 | Autódromo José Carlos Pace         | 171 |
| R22 | 🇺🇸 | Las Vegas Street Circuit           | 100 |
| R23 | 🇶🇦 | Lusail International Circuit       | 107 |
| R24 | 🇦🇪 | Yas Marina Circuit                 | 133 |

**2,913 GPS coordinate points across 24 circuits.**

---

## Quick Start

### 1. Copy the files into your project

```
your_flutter_app/
└── lib/
    └── circuits/
        ├── circuit_paths.dart
        └── multi_car_circuit_painter.dart
```

### 2. Get a circuit path by round number

```dart
import 'circuits/circuit_paths.dart';

// Get the coordinate path for any round (1–24)
final List<Offset> monacoPath = CircuitPaths.forRound(8);

// Get the display name
final String name = CircuitPaths.nameForRound(8); // → "MONACO"

// Get the flag emoji
final String flag = CircuitPaths.flagForRound(8); // → "🇲🇨"
```

### 3. Draw it with a basic CustomPainter

```dart
class CircuitPainter extends CustomPainter {
  final List<Offset> path;
  CircuitPainter(this.path);

  @override
  void paint(Canvas canvas, Size size) {
    const PAD = 0.05;

    // Scale normalised 0..1 points to canvas pixels
    Offset s(Offset p) => Offset(
      PAD * size.width  + p.dx * size.width  * (1 - 2 * PAD),
      PAD * size.height + p.dy * size.height * (1 - 2 * PAD),
    );

    final pts = path.map(s).toList();
    final trackPath = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final pt in pts.skip(1)) trackPath.lineTo(pt.dx, pt.dy);

    canvas.drawPath(trackPath, Paint()
      ..color = const Color(0xFF00E5FF)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round);
  }

  @override
  bool shouldRepaint(CircuitPainter old) => false;
}

// In your widget tree
CustomPaint(
  size: const Size(300, 300),
  painter: CircuitPainter(CircuitPaths.forRound(8)), // Monaco
)
```

---

## The Full Animated Widget

For the full live race experience, use the `MultiCarCircuit` widget. It handles everything — drawing the track, animating the cars, safety car mode, glow effects, the whole thing.

### Widget parameters

```dart
MultiCarCircuit(
  round:      8,              // round number 1–24, auto-selects circuit
  drivers:    _state.drivers, // List<SimDriver> — your 20 drivers
  totalLaps:  78,             // total laps in the race
  currentLap: 24,             // current lap (drives race progress)
  safetyCar:  false,          // true → yellow mode, cars bunch up
  running:    true,           // false → cars freeze in place
)
```

### The SimDriver model

The widget expects a `List<SimDriver>`. Each driver needs these fields:

```dart
class SimDriver {
  final String id;       // 3-letter code: 'ver', 'nor', 'lec', etc.
  final String name;     // full name shown above the player's car
  int position;          // current race position 1–20
  bool isPlayer;         // true = glowing cyan car with name label
}
```

Driver IDs automatically map to their real 2024 team color:

| Drivers | Team | Color |
|---------|------|-------|
| `ver` `per` | Red Bull Racing | `#3671C6` |
| `lec` `sai` | Ferrari | `#E8002D` |
| `ham` `rus` | Mercedes | `#27F4D2` |
| `nor` `pia` | McLaren | `#FF8000` |
| `alo` `str` | Aston Martin | `#358C75` |
| `gas` `oco` | Alpine | `#0090FF` |
| `alb` `sar` | Williams | `#64C4FF` |
| `tsu` `ric` | RB | `#6692FF` |
| `hul` `mag` | Haas | `#B6BABD` |
| `bot` `zho` | Kick Sauber | `#52E252` |

Any unrecognised ID gets a neutral white dot.

### Minimal working example

```dart
import 'package:flutter/material.dart';
import 'circuits/circuit_paths.dart';
import 'circuits/multi_car_circuit_painter.dart';

class RaceMapDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    // 20 demo drivers — P1 through P20
    final driverIds = ['ver','nor','lec','ham','sai','rus','pia',
                       'per','alo','str','gas','hul','alb','tsu',
                       'bot','mag','oco','sar','zho','ric'];

    final drivers = List.generate(20, (i) => SimDriver(
      id:       driverIds[i],
      name:     driverIds[i].toUpperCase(),
      position: i + 1,
      isPlayer: i == 3, // HAM is the player
    ));

    return Scaffold(
      backgroundColor: const Color(0xFF030308),
      body: Center(
        child: SizedBox(
          width: 360, height: 360,
          child: MultiCarCircuit(
            round:      8,        // 🇲🇨 Monaco
            drivers:    drivers,
            totalLaps:  78,
            currentLap: 30,
            safetyCar:  false,
            running:    true,
          ),
        ),
      ),
    );
  }
}
```

---

## How the Coordinate System Works

All points are normalised to `0.0–1.0` relative to the circuit's GPS bounding box. This makes them resolution-independent — the same data works on a 200px widget or a 2000px canvas.

### GPS → Flutter conversion

```python
PAD = 0.05  # 5% padding so the circuit doesn't touch the edges

x = PAD + (longitude - min_lon) / lon_range * (1 - 2 * PAD)
y = PAD + (max_lat  - latitude) / lat_range * (1 - 2 * PAD)
#           ↑ Y is flipped because GPS latitude increases upward
#             but screen Y increases downward
```

### Normalised → canvas pixels

```dart
const PAD = 0.05;

Offset toCanvas(Offset p, Size size) => Offset(
  PAD * size.width  + p.dx * size.width  * (1 - 2 * PAD),
  PAD * size.height + p.dy * size.height * (1 - 2 * PAD),
);
```

### Placing an object at any point around the circuit

```dart
/// Returns the canvas position at [progress] (0.0–1.0) around the circuit.
/// Drive progress with an AnimationController to animate a car lapping.
Offset pointOnCircuit(List<Offset> pts, double progress, Size size) {
  final n = pts.length - 1;
  final f = ((progress % 1.0) + 1.0) % 1.0 * n;
  final i = f.floor().clamp(0, n - 1);
  final t = f - i.toDouble();
  final a = pts[i];
  final b = pts[(i + 1) % pts.length];

  const PAD = 0.05;
  return Offset(
    PAD * size.width  + (a.dx + (b.dx - a.dx) * t) * size.width  * (1 - 2 * PAD),
    PAD * size.height + (a.dy + (b.dy - a.dy) * t) * size.height * (1 - 2 * PAD),
  );
}
```

Animate a car continuously around the circuit:

```dart
// In your State class
late AnimationController _lapCtrl;

@override
void initState() {
  super.initState();
  _lapCtrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4), // one lap = 4 seconds
  )..repeat();
}

// In your CustomPainter
final carPos = pointOnCircuit(
  CircuitPaths.forRound(8),
  _lapCtrl.value, // 0.0 → 1.0, repeating
  size,
);
canvas.drawCircle(carPos, 6, Paint()..color = Colors.cyan);
```

---

## Requirements

| Tool | Version |
|------|---------|
| Flutter | ≥ 3.0.0 |
| Dart | ≥ 3.0.0 |

Zero pub.dev dependencies. Pure Flutter SDK only.

---

## File Overview

```
flutter-f1-circuits/
├── circuit_paths.dart
│   ├── CircuitPaths.forRound(int round)     → List<Offset>
│   ├── CircuitPaths.nameForRound(int round) → String
│   ├── CircuitPaths.flagForRound(int round) → String
│   └── 24 × static const List<Offset>
│       bahrain, saudi_arabia, australia, japan, china,
│       miami, emilia, monaco, canada, spain, austria,
│       british, hungary, belgium, netherlands, italy,
│       azerbaijan, singapore, usa, mexico, brazil,
│       las_vegas, qatar, abu_dhabi
│
└── multi_car_circuit_painter.dart
    ├── MultiCarCircuit (StatefulWidget)
    │   └── props: round, drivers, totalLaps,
    │              currentLap, safetyCar, running
    └── _MultiCarPainter (CustomPainter)
        ├── _drawTrack()     — layered tarmac + neon edge
        ├── _drawAllCars()   — 20 animated dots
        ├── _drawCar()       — individual car with glow + label
        ├── _drawLegend()    — YOU / RIVALS legend + SC badge
        └── _pointAt()       — interpolate position on path
```

---

## Built With This

**APEX F1** is the app this came from — a neon-themed F1 race simulation built entirely in Flutter. It features a lap-by-lap race engine with 20 drivers, safety cars, weather changes, tyre degradation, pit strategy, qualifying sessions, standings, teams, and a personal championship tracker.

The circuit data in this repo is the component that makes the live map work. Every race in the app shows the real circuit with all 20 cars racing on it in real time.

---

## License

MIT — use it in anything, personal or commercial. Credit is appreciated but not required.

If this saved you time, a ⭐ on the repo means a lot.
If you build something with it, open an issue and show me — genuinely curious to see what people make. 🏁

---

*Made by a Software Engineering student who spent way too long looking for this data online before deciding to just build it. — 2024*
