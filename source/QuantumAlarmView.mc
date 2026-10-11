using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Timer as Timer;
using Toybox.Math as Math;
using Toybox.Attention as Attention;

// Colors taken from the original web page (CSS --cyan, --pink, --yellow, --ink),
// and the flash color is what its red overlay (screen blend, 55%) gives on --ink.
const C_CYAN = 0x19E3FF;
const C_PINK = 0xFF2BD6;
const C_YELLOW = 0xFFD400;
const C_INK = 0x07070D;
const C_INK_RED = 0x7F1025;
const C_DIM = 0xB4B4B8;       // white at 70%
const C_GHOST = 0x5A5A60;     // white at 33%

// Port of web/index.html. Always on, no button.
//
// Timeline (100 ms ticks, 152 per cycle), same order as the web page:
//   0-29     title, twice
//   30-90    block: warning lines (25), last word stretched (32), pause (4)
//   91-151   the same block again
class QuantumAlarmView extends Ui.View {

    hidden var _timer;
    hidden var _t = 0;
    hidden var _titleA;
    hidden var _titleB;
    hidden var _title;
    hidden var _on = false;
    hidden var _sub1;
    hidden var _sub2;
    hidden var _w1;
    hidden var _w2;
    hidden var _w3;
    hidden var _mouth;
    hidden var _word;

    function initialize() {
        View.initialize();
        _titleA = Ui.loadResource(Rez.Strings.TitleA);
        _titleB = Ui.loadResource(Rez.Strings.TitleB);
        _sub1 = Ui.loadResource(Rez.Strings.Sub1);
        _w1 = Ui.loadResource(Rez.Strings.Warn1);
        _w2 = Ui.loadResource(Rez.Strings.Warn2);
        _w3 = Ui.loadResource(Rez.Strings.Warn3);
        _mouth = Ui.loadResource(Rez.Strings.MouthLong);
        _word = Ui.loadResource(Rez.Strings.Mouth);
        _sub2 = _w1 + " " + _w2;
        _title = _titleA + " " + _titleB;
    }

    function onShow() {
        _timer = new Timer.Timer();
        _timer.start(method(:tick), 100, true);
    }

    function onHide() {
        if (_timer != null) { _timer.stop(); }
    }

    function tick() as Void {
        _t += 1;
        // siren: alternate high/low tone, buzz on every red flash
        if (_t % 6 == 0) {
            if (Attention has :playTone) {
                Attention.playTone((_t / 6) % 2 == 0 ? Attention.TONE_ALERT_HI : Attention.TONE_ALERT_LO);
            }
            if (Attention has :vibrate) {
                Attention.vibrate([new Attention.VibeProfile(100, 250)]);
            }
        }
        Ui.requestUpdate();
    }

    // Schrodinger's cat: a tiny head that flickers between alive (open eyes)
    // and dead (X eyes); now and then it is both at once.
    hidden function cat(dc, x, y, r) {
        // 2 s each: alive, both, dead, both. In "both" the two sets of eyes are
        // drawn on top of each other, half transparent.
        var st = (_t / 20) % 4;
        var alive = (st != 2);
        var dead = (st != 0);
        var a = (st % 2 == 1) ? 140 : 255;
        dc.setColor(C_DIM, Gfx.COLOR_TRANSPARENT);
        dc.drawCircle(x, y, r);
        dc.drawLine(x - r, y - r * 3 / 10, x - r * 9 / 10, y - r * 14 / 10);
        dc.drawLine(x - r * 9 / 10, y - r * 14 / 10, x - r * 3 / 10, y - r * 85 / 100);
        dc.drawLine(x + r, y - r * 3 / 10, x + r * 9 / 10, y - r * 14 / 10);
        dc.drawLine(x + r * 9 / 10, y - r * 14 / 10, x + r * 3 / 10, y - r * 85 / 100);
        var ey = y - r / 8;
        var ex = r * 4 / 10;
        var e = r / 5 + 1;
        if (alive) {
            dc.setColor(blend(C_YELLOW, a), Gfx.COLOR_TRANSPARENT);
            dc.fillCircle(x - ex, ey, e);
            dc.fillCircle(x + ex, ey, e);
        }
        if (dead) {
            dc.setColor(blend(0xFF5A5A, a), Gfx.COLOR_TRANSPARENT);
            for (var sgn = -1; sgn <= 1; sgn += 2) {
                var cx2 = x + sgn * ex;
                dc.drawLine(cx2 - e, ey - e, cx2 + e, ey + e);
                dc.drawLine(cx2 - e, ey + e, cx2 + e, ey - e);
            }
        }
        dc.setColor(C_PINK, Gfx.COLOR_TRANSPARENT);
        dc.fillCircle(x, y + r * 3 / 10, 1);
    }

    // A color at the given opacity (0-255). Watches with API 4.0+ get a real
    // transparent color; older ones get the color pre-mixed with the background,
    // which looks faded but cannot show what is underneath.
    hidden function blend(rgb, a) {
        if (a >= 255) { return rgb; }
        var r = (rgb >> 16) & 0xFF;
        var g = (rgb >> 8) & 0xFF;
        var b = rgb & 0xFF;
        if (Gfx has :createColor) {
            return Gfx.createColor(a, r, g, b);
        }
        var bg = _on ? C_INK_RED : C_INK;
        r = (r * a + ((bg >> 16) & 0xFF) * (255 - a)) / 255;
        g = (g * a + ((bg >> 8) & 0xFF) * (255 - a)) / 255;
        b = (b * a + (bg & 0xFF) * (255 - a)) / 255;
        return (r << 16) | (g << 8) | b;
    }

    // Glitchy text: cyan copy on the right, pink on the left, white on top.
    // a < 255 draws it transparent (used when all texts are stacked).
    hidden function glitch(dc, x, y, font, str, dx, a) {
        if (a >= 255) {
            // soft white glow (the page's 30px text-shadow), approximated with 4 faint copies
            dc.setColor(_on ? 0xA84860 : 0x3A3A44, Gfx.COLOR_TRANSPARENT);
            dc.drawText(x, y - 2, font, str, Gfx.TEXT_JUSTIFY_CENTER);
            dc.drawText(x, y + 2, font, str, Gfx.TEXT_JUSTIFY_CENTER);
            dc.drawText(x - 2, y, font, str, Gfx.TEXT_JUSTIFY_CENTER);
            dc.drawText(x + 2, y, font, str, Gfx.TEXT_JUSTIFY_CENTER);
        }
        dc.setColor(blend(C_CYAN, a), Gfx.COLOR_TRANSPARENT);
        dc.drawText(x + dx, y, font, str, Gfx.TEXT_JUSTIFY_CENTER);
        dc.setColor(blend(C_PINK, a), Gfx.COLOR_TRANSPARENT);
        dc.drawText(x - dx, y, font, str, Gfx.TEXT_JUSTIFY_CENTER);
        dc.setColor(blend(0xFFFFFF, a), Gfx.COLOR_TRANSPARENT);
        dc.drawText(x, y, font, str, Gfx.TEXT_JUSTIFY_CENTER);
    }

    function onUpdate(dc) {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var m = w < h ? w : h;
        var cx = w / 2;
        var cy = h / 2;
        var t = _t * 0.1;

        // Siren flash: dark red <-> black
        var on = (_t / 3) % 2 == 0;
        _on = on;
        dc.setColor(Gfx.COLOR_WHITE, on ? C_INK_RED : C_INK);
        dc.clear();

        // Electrons in orbit, three superposed copies of each
        for (var k = 0; k < 4; k += 1) {
            var tilt = k * 0.7854 + t * 0.15;
            for (var g = 0; g < 3; g += 1) {
                var p = t * (1.1 + k * 0.25) + k * 1.7 + g * 0.55;
                var ex = m * 0.42 * Math.cos(p);
                var ey = m * 0.42 * 0.36 * Math.sin(p);
                var rx = ex * Math.cos(tilt) - ey * Math.sin(tilt);
                var ry = ex * Math.sin(tilt) + ey * Math.cos(tilt);
                // fading trail behind each ghost (the canvas does this with alpha)
                var sp = 1.1 + k * 0.25;
                dc.setColor(g == 0 ? 0x0F5A68 : (g == 1 ? 0x6A1A5C : 0x2C2C30), Gfx.COLOR_TRANSPARENT);
                for (var j = 1; j <= 4; j += 1) {
                    var pj = p - j * 0.16 * sp;
                    var tx = m * 0.42 * Math.cos(pj);
                    var ty2 = m * 0.42 * 0.36 * Math.sin(pj);
                    dc.fillCircle(cx + tx * Math.cos(tilt) - ty2 * Math.sin(tilt),
                                  cy + tx * Math.sin(tilt) + ty2 * Math.cos(tilt), 1);
                }
                // in the page the red overlay sits over the canvas only (text is above it), and
                // screen-blending it brightens the cyan electrons a little: 0x88E4FF
                dc.setColor(g == 0 ? (on ? 0x88E4FF : C_CYAN) : (g == 1 ? C_PINK : C_GHOST), Gfx.COLOR_TRANSPARENT);
                dc.fillCircle(cx + rx, cy + ry, g == 2 ? 1 : 2);
            }
        }
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, 3);

        // Warning sign
        var ty = h * 17 / 100;
        var s = h * 9 / 100;
        // outlined triangle like the page's warning glyph, always visible
        // (the flat flash color already matches what the page's red blend looks like)
        var bx = s + 2;
        var by = ty + s * 8 / 10;
        // glow (the page's yellow drop-shadow): two faint, larger outlines behind the sign
        dc.setColor(on ? 0xA06A1C : 0x5A4A06, Gfx.COLOR_TRANSPARENT);
        for (var gz = 2; gz <= 3; gz += 1) {
            dc.drawLine(cx, ty - s - gz, cx - bx - gz, by + gz);
            dc.drawLine(cx, ty - s - gz, cx + bx + gz, by + gz);
            dc.drawLine(cx - bx - gz, by + gz, cx + bx + gz, by + gz);
        }
        dc.setColor(C_YELLOW, Gfx.COLOR_TRANSPARENT);
        for (var o = 0; o < 2; o += 1) {
            dc.drawLine(cx + o, ty - s, cx - bx + o, by);
            dc.drawLine(cx + o, ty - s, cx + bx - o, by);
            dc.drawLine(cx - bx, by - o, cx + bx, by - o);
        }
        dc.drawText(cx, ty - s / 3, Gfx.FONT_XTINY, "!", Gfx.TEXT_JUSTIFY_CENTER);

        cat(dc, w * 16 / 100, h * 27 / 100, m * 6 / 100);

        // Text jitter, like the CSS glitch animation
        // keyframes of @keyframes glitch (0.9 s): shadow spread, x and y shift
        var f = _t % 9;
        var dxs = [1, 1, 2, 2, 1, 1, -2, -2, 1];
        var txs = [0, -1, -1, 0, 1, 1, 0, 0, 0];
        var tys = [0, 0, 1, 0, -1, 0, 1, 1, 0];
        var dx = dxs[f];
        var jy = tys[f];
        cx = cx + txs[f];

        // 0-29 title | 30-64 round 1 (word said normally) | 65-125 round 2 (word drawn out)
        // | 126-165 everything superposed
        var pos = _t % 166;
        if (pos >= 126) {
            // the pause between rounds: every text at once, all superposed
            // every layer is half transparent so you can see them through each other
            glitch(dc, cx, h * 42 / 100 + jy, Gfx.FONT_MEDIUM, _title, dx, 110);
            glitch(dc, cx, h * 33 / 100 + jy, Gfx.FONT_SMALL, _w1, dx, 110);
            glitch(dc, cx, h * 48 / 100 + jy, Gfx.FONT_SMALL, _w2, dx, 110);
            glitch(dc, cx, h * 63 / 100 + jy, Gfx.FONT_SMALL, _w3, dx, 110);
            glitch(dc, cx, h * 44 / 100 + jy, Gfx.FONT_MEDIUM, _mouth, dx, 110);
            dc.setColor(blend(C_DIM, 140), Gfx.COLOR_TRANSPARENT);
            dc.drawText(cx, h * 78 / 100, Gfx.FONT_XTINY, _sub1, Gfx.TEXT_JUSTIFY_CENTER);
            dc.drawText(cx, h * 82 / 100, Gfx.FONT_XTINY, _sub2, Gfx.TEXT_JUSTIFY_CENTER);
        } else if (pos < 30) {
            glitch(dc, cx, h * 42 / 100 + jy, Gfx.FONT_MEDIUM, _title, dx, 255);
            dc.setColor(C_DIM, Gfx.COLOR_TRANSPARENT);
            dc.drawText(cx, h * 78 / 100, Gfx.FONT_XTINY, _sub1, Gfx.TEXT_JUSTIFY_CENTER);
        } else {
            var second = (pos >= 65);
            var q = second ? pos - 65 : pos - 30;
            if (q < 25) {
                glitch(dc, cx, h * 33 / 100 + jy, Gfx.FONT_SMALL, _w1, dx, 255);
                glitch(dc, cx, h * 48 / 100 + jy, Gfx.FONT_SMALL, _w2, dx, 255);
                glitch(dc, cx, h * 63 / 100 + jy, Gfx.FONT_SMALL, _w3, dx, 255);
                dc.setColor(C_DIM, Gfx.COLOR_TRANSPARENT);
                dc.drawText(cx, h * 82 / 100, Gfx.FONT_XTINY, _sub2, Gfx.TEXT_JUSTIFY_CENTER);
            } else {
                // the word comes twice: said normally in round 1, drawn out only in round 2
                // (one more letter every 0.23 s)
                var word = _word;
                if (second) {
                    var n = 3 + (q - 25) * 10 / 23;
                    if (q >= 57 || n > _mouth.length()) { n = _mouth.length(); }
                    word = _mouth.substring(0, n);
                }
                glitch(dc, cx, h * 44 / 100 + jy, Gfx.FONT_MEDIUM, word, dx, 255);
                dc.setColor(C_DIM, Gfx.COLOR_TRANSPARENT);
                dc.drawText(cx, h * 78 / 100, Gfx.FONT_XTINY, _sub2, Gfx.TEXT_JUSTIFY_CENTER);
            }
        }
    }
}
