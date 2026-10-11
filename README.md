# Quantum Alarm

A joke alarm for Garmin watches. It looks like a loud alarm, and the only hint of "quantum" is
electrons orbiting the warning sign, a Schrödinger's cat that is alive and dead at once, and a
pause where every message is on screen at the same time. The idea is that you see the word
"quantum", understand it is complicated, and run.

> אפליקציית בדיחה לשעוני Garmin: אזעקה רועשת עם רמז קוונטי. נא להתרחק מהמיקרופון עם ידיים על הפה.

It does not set a real alarm. It is a Connect IQ **watch app** (not a widget) that only plays an
animation, a siren-like beep and a vibration while it is open.

## What it shows

One cycle is about 17 seconds:

1. `QUANTUM ALARM` / `COMPLEX. RUN.`
2. Round 1: `STEP AWAY FROM THE MIC, HANDS ON YOUR` and the last word, `MOUTH`, said normally.
3. Round 2: the same lines, but the last word is drawn out slowly: `MOUUUUUUUTH`.
4. A pause where all the texts are drawn on top of each other, half transparent.

All the time: a red/black siren flash, a glitchy cyan/pink text split, orbiting electrons with
trails and three ghost copies each, and a small cat that flips between alive (open eyes), both
(both eye sets overlaid) and dead (X eyes), two seconds at a time.

The text is in English by default and in Hebrew when the watch language is Hebrew
(`resources-heb/`).

## Supported devices

The manifest lists **169 devices**: every device in Connect IQ SDK 9.2.0 that accepts a watch app,
from the 2014 Forerunner 920XT up to current Fenix, Venu, Forerunner, Instinct and Edge models.

- Minimum API level: **1.2.0** (the first-generation `epix` is the lowest device).
- The code only uses calls that exist since API 1.0.0, so it also fits the old 64 KB watches
  (fenix 3, Forerunner 230/235/630/920XT, vívoactive, D2 Bravo).
- Real transparency (`Graphics.createColor`, API 4.0.0+) is used when the device has it.
  Older devices get colors pre-mixed with the background instead.
- Not supported (the compiler rejects watch apps there): `fr45`, `garminswim2`, `edge130`,
  `edge130plus`.

### What has actually been tested

| Level | Devices |
| --- | --- |
| Builds without errors | all 169 |
| Seen running in the simulator | Forerunner 235, Venu 2, vívoactive 4S |
| Not seen on a screen | everything else, including the bike computers and handhelds |

A successful build does not mean the layout looks good: fonts are fixed system fonts and
positions are fractions of the screen, so very small or very large screens may need tuning.
Issues and pull requests with screenshots are welcome.

## Build and run

You need the [Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/) and a developer key.

With VS Code and the Garmin **Monkey C** extension:

1. Run `Monkey C: Generate a Developer Key` once, or point `monkeyC.developerKeyPath` at your key.
2. Press **F5**. It asks which watch to run, then opens the simulator.

From the command line:

```
monkeyc -f monkey.jungle -d fr235_sim -o bin/quantumalarm.prg -y path/to/developer_key.der -w
monkeydo bin/quantumalarm.prg fr235
```

Build a package for every device in the manifest:

```
monkeyc -e -f monkey.jungle -o bin/quantumalarm.iq -y path/to/developer_key.der -w
```

Never commit your developer key. `.gitignore` already excludes `*.der` and similar files.

## Project layout

```
manifest.xml            app type, minimum API level, device list, languages
monkey.jungle           build config
source/                 QuantumAlarmApp, QuantumAlarmView (all drawing), QuantumAlarmDelegate
resources/              launcher icon and English strings
resources-heb/          Hebrew strings
```

All drawing and timing is in `source/QuantumAlarmView.mc`. The timeline is in `onUpdate`
(0.1 second ticks), and the colors are the constants at the top of the file.

## Known limits

- No speech: Connect IQ watch apps cannot play audio or speak, only beeps and vibration.
- No true transparency on devices older than API 4.0.0 (see above).
- The app must be open. There is no background alarm.

## License

[MIT](LICENSE)
