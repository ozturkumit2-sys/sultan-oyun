#!/usr/bin/env python3
"""Synthesizes every sound effect and the background music for Office Chaos.
All audio is generated from scratch here (no samples) -> assets/audio/*.ogg"""
import numpy as np, os, subprocess, wave

SR = 44100
OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "audio")
TMP = "/tmp/claude-0/oc_audio"
os.makedirs(OUT, exist_ok=True)
os.makedirs(TMP, exist_ok=True)
rng = np.random.default_rng(7)


def t(d):
    return np.arange(int(SR * d)) / SR


def env(n, a=0.005, r=0.1, shape=1.0):
    e = np.ones(n)
    na = max(1, int(a * SR)); nr = max(1, int(r * SR))
    e[:na] = np.linspace(0, 1, na)
    if nr < n:
        e[-nr:] *= np.linspace(1, 0, nr) ** shape
    return e


def expdecay(n, k):
    return np.exp(-np.arange(n) / SR * k)


def lp(x, cutoff):
    # one-pole low-pass (cutoff may be an array)
    y = np.zeros_like(x)
    c = np.broadcast_to(np.asarray(cutoff, dtype=float), x.shape)
    a = 1 - np.exp(-2 * np.pi * c / SR)
    acc = 0.0
    for i in range(len(x)):
        acc += a[i] * (x[i] - acc)
        y[i] = acc
    return y


def hp(x, cutoff):
    return x - lp(x, cutoff)


def bp(x, lo, hi):
    return lp(hp(x, lo), hi)


def noise(n):
    return rng.uniform(-1, 1, n)


def sine(f, d, ph=0.0):
    tt = t(d)
    f = np.broadcast_to(np.asarray(f, dtype=float), tt.shape)
    return np.sin(2 * np.pi * np.cumsum(f) / SR + ph)


def tri(f, d):
    tt = t(d)
    f = np.broadcast_to(np.asarray(f, dtype=float), tt.shape)
    ph = np.cumsum(f) / SR
    return 2 * np.abs(2 * (ph - np.floor(ph + 0.5))) - 1


def square(f, d, duty=0.5):
    tt = t(d)
    f = np.broadcast_to(np.asarray(f, dtype=float), tt.shape)
    ph = np.cumsum(f) / SR
    return np.where((ph % 1.0) < duty, 1.0, -1.0)


def saw(f, d):
    tt = t(d)
    f = np.broadcast_to(np.asarray(f, dtype=float), tt.shape)
    ph = np.cumsum(f) / SR
    return 2 * (ph % 1.0) - 1


def mix(*parts):
    n = max(len(p[1]) + int(p[0] * SR) for p in parts)
    out = np.zeros(n)
    for off, sig, *g in parts:
        gain = g[0] if g else 1.0
        i = int(off * SR)
        out[i:i + len(sig)] += sig * gain
    return out


def bell(f, d, k=5.0, partials=((1, 1), (2.01, .4), (3.03, .2), (4.2, .1))):
    s = sum(a * sine(f * m, d) for m, a in partials)
    return s * expdecay(len(s), k)


def pluck(f, d, k=7.0):
    s = sine(f, d) + 0.35 * sine(2 * f, d) + 0.12 * sine(3 * f, d)
    return s * expdecay(len(s), k) * env(len(s), 0.003, 0.05)


def save(name, x, vol=0.85):
    x = np.asarray(x, dtype=float)
    # loudness-match everything to a common RMS, then soft-limit peaks
    rms = np.sqrt(np.mean(x ** 2)) + 1e-9
    target = 10 ** ((-19.0 + (vol - 0.65) * 10.0) / 20.0)
    x = x * (target / rms)
    x = np.tanh(x * 1.1) / np.tanh(1.1)
    x = np.clip(x, -0.98, 0.98)
    wav = os.path.join(TMP, name + ".wav")
    with wave.open(wav, "w") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes((x * 32767).astype(np.int16).tobytes())
    ogg = os.path.join(OUT, name + ".ogg")
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav, "-c:a", "libvorbis", "-q:a", "4", ogg], check=True)


def midi(n):
    return 440.0 * 2 ** ((n - 69) / 12)


# ======================================================================= SFX
def sfx_click():
    n = noise(int(0.03 * SR))
    s = bp(n, 1200, 5000) * expdecay(len(n), 160)
    th = sine(180, 0.03) * expdecay(int(0.03 * SR), 90) * 0.5
    return s + th


def sfx_page():
    d = 0.32
    n = noise(int(d * SR))
    sweep = np.linspace(900, 4500, len(n))
    s = lp(hp(n, 500), sweep) * np.sin(np.linspace(0, np.pi, len(n))) ** 1.5
    return s


def sfx_meddle():
    notes = [76, 79, 83, 88, 91]
    parts = []
    for i, m in enumerate(notes):
        f = midi(m)
        d = 0.6
        vib = f * (1 + 0.006 * np.sin(2 * np.pi * 6 * t(d)))
        parts.append((i * 0.06, bell(vib, d, 6.0) * 0.6))
    air = bp(noise(int(0.8 * SR)), 2000, 8000) * np.sin(np.linspace(0, np.pi, int(0.8 * SR))) * 0.25
    parts.append((0.0, air))
    return mix(*parts)


def sfx_coffee():
    d = 1.3
    n = len(t(d))
    rumble = lp(noise(n), 220) * 1.4
    bub = np.zeros(n)
    for i in range(26):
        st = rng.integers(0, n - 4000)
        f0 = rng.uniform(250, 600)
        dd = 0.05
        b = sine(np.linspace(f0, f0 * 1.8, int(dd * SR)), dd) * expdecay(int(dd * SR), 50)
        bub[st:st + len(b)] += b * 0.4
    hiss = bp(noise(n), 3000, 9000) * 0.15
    return (rumble + bub + hiss) * env(n, 0.05, 0.3)


def sfx_printer():
    d = 1.0
    n = len(t(d))
    motor = lp(square(np.full(n, 95.0) + 8 * np.sin(2 * np.pi * 3 * t(d)), d, 0.3), 900) * 0.5
    clicks = np.zeros(n)
    for k in range(9):
        i = int((0.05 + k * 0.1) * SR)
        c = bp(noise(400), 1500, 6000) * expdecay(400, 120)
        clicks[i:i + 400] += c
    return (motor + clicks[:n]) * env(n, 0.03, 0.15)


def sfx_printer_fail():
    a = square(midi(70), 0.13, 0.3) * env(int(0.13 * SR), 0.002, 0.03)
    b = square(midi(64), 0.22, 0.3) * env(int(0.22 * SR), 0.002, 0.08)
    crunch = bp(noise(int(0.35 * SR)), 300, 2500) * expdecay(int(0.35 * SR), 10) * 0.7
    return mix((0, lp(a, 3000) * 0.5), (0.16, lp(b, 3000) * 0.5), (0.38, crunch))


def sfx_phone():
    return mix((0, pluck(midi(88), 0.35, 10) * 0.7), (0.12, pluck(midi(93), 0.5, 8) * 0.8))


def sfx_email():
    d = 0.5
    n = noise(int(d * SR))
    sweep = np.linspace(500, 6000, len(n)) ** 1.0
    s = lp(hp(n, 300), sweep) * np.sin(np.linspace(0, np.pi, len(n))) ** 2
    return mix((0, s), (0.05, bell(midi(84), 0.3, 12) * 0.25))


def brass(f, d, k=3.0):
    n = len(t(d))
    vib = f * (1 + 0.004 * np.sin(2 * np.pi * 5 * t(d)))
    s = saw(vib, d) + 0.5 * saw(vib * 1.005, d)
    cut = 600 + 2200 * np.exp(-np.arange(n) / SR * k)
    return lp(s, cut) * env(n, 0.02, 0.12)


def sfx_gasp():
    return mix((0, brass(midi(45), 0.22) * 0.9), (0.25, brass(midi(44), 0.7, 2.0)))


def sfx_argue():
    d = 0.9
    n = len(t(d))
    out = np.zeros(n)
    for v in range(3):
        f0 = rng.uniform(110, 180)
        wob = f0 * (1 + 0.25 * np.sin(2 * np.pi * rng.uniform(5, 9) * t(d) + v))
        g = saw(wob, d)
        g = bp(g, 300, 1400 + 600 * np.sin(2 * np.pi * 7 * t(d) + v))
        out += g
    return out * env(n, 0.03, 0.25)


def sfx_thump():
    d = 0.4
    n = len(t(d))
    th = sine(np.linspace(140, 60, n), d) * expdecay(n, 18)
    clank = sum(a * sine(f, d) for f, a in ((523, .3), (1187, .2), (1733, .15), (2470, .1))) * expdecay(n, 14)
    return th + clank * 0.6 + lp(noise(n), 1200) * expdecay(n, 40) * 0.5


def sfx_splash():
    d = 0.7
    n = len(t(d))
    s = lp(noise(n), np.linspace(6000, 600, n)) * expdecay(n, 8)
    drips = np.zeros(n)
    for k in range(6):
        i = int(rng.uniform(0.15, 0.6) * SR)
        f0 = rng.uniform(700, 1400)
        dd = 0.06
        b = sine(np.linspace(f0, f0 * 2.2, int(dd * SR)), dd) * expdecay(int(dd * SR), 60)
        drips[i:i + len(b)] += b * 0.3
    return s + drips


def sfx_papers():
    d = 0.45
    n = len(t(d))
    out = np.zeros(n)
    for k in range(7):
        i = int(rng.uniform(0, 0.33) * SR)
        g = bp(noise(int(0.07 * SR)), 1500, 7000) * np.sin(np.linspace(0, np.pi, int(0.07 * SR)))
        out[i:i + len(g)] += g * rng.uniform(0.5, 1.0)
    return out


def sfx_fixed():
    return mix((0, bell(midi(72), 0.5, 6) * 0.7), (0.09, bell(midi(76), 0.5, 6) * 0.7), (0.18, bell(midi(79), 0.9, 4)))


def sfx_lights_off():
    d = 0.8
    n = len(t(d))
    sw = sine(np.geomspace(620, 60, n), d) * env(n, 0.005, 0.3) * 0.7
    click = bp(noise(600), 800, 5000) * expdecay(600, 90)
    return mix((0, click), (0.01, sw))


def sfx_lights_on():
    d = 0.9
    n = len(t(d))
    clunk = lp(noise(2000), 800) * expdecay(2000, 40)
    hum = (sine(120, d) * 0.5 + square(120, d, 0.1) * 0.1)
    flick = np.ones(n)
    for k in range(5):
        i = int(rng.uniform(0.05, 0.4) * SR)
        flick[i:i + int(0.04 * SR)] = 0.0
    return mix((0, clunk), (0.05, hum * flick * env(n, 0.02, 0.3) * 0.5))


def sfx_crowd():
    d = 1.2
    n = len(t(d))
    out = np.zeros(n)
    for v in range(7):
        f0 = rng.uniform(150, 320)
        sl = f0 * (1 + 0.35 * np.sin(np.linspace(0, np.pi, n)))
        voice = saw(sl, d)
        voice = bp(voice, 250, 900)
        out += voice * rng.uniform(0.5, 1.0)
    return out * env(n, 0.15, 0.4)


def sfx_slam():
    d = 0.5
    n = len(t(d))
    thud = sine(np.linspace(110, 45, n), d) * expdecay(n, 12)
    crack = hp(noise(n), 1500) * expdecay(n, 60) * 0.6
    return thud + crack


def sfx_pop():
    d = 0.12
    n = len(t(d))
    return sine(np.geomspace(900, 300, n), d) * expdecay(n, 30)


def sfx_paper_day():
    chord = [60, 64, 67, 72]
    fan = sum(brass(midi(m), 0.75, 2.5) for m in chord) / 3
    lead = mix((0, brass(midi(72), 0.14) * 0.8), (0.16, brass(midi(76), 0.14) * 0.8), (0.32, brass(midi(79), 0.6)))
    return mix((0, sfx_page() * 0.6), (0.18, lead), (0.5, fan))


def sfx_sparkle():
    parts = []
    for i, m in enumerate([84, 88, 91, 96, 100]):
        parts.append((i * 0.045, bell(midi(m), 0.45, 9) * 0.5))
    return mix(*parts)


SFX = {
    "click": (sfx_click, 0.6), "page": (sfx_page, 0.55), "meddle": (sfx_meddle, 0.75), "coffee": (sfx_coffee, 0.6),
    "printer": (sfx_printer, 0.55), "printer_fail": (sfx_printer_fail, 0.7), "phone": (sfx_phone, 0.7), "email": (sfx_email, 0.65),
    "gasp": (sfx_gasp, 0.75), "argue": (sfx_argue, 0.65), "thump": (sfx_thump, 0.8), "splash": (sfx_splash, 0.65),
    "papers": (sfx_papers, 0.6), "fixed": (sfx_fixed, 0.65), "lights_off": (sfx_lights_off, 0.75), "lights_on": (sfx_lights_on, 0.6),
    "crowd": (sfx_crowd, 0.55), "slam": (sfx_slam, 0.8), "pop": (sfx_pop, 0.55), "paper_day": (sfx_paper_day, 0.75),
    "sparkle": (sfx_sparkle, 0.6),
}


# ======================================================================= MUSIC
def music():
    bpm = 112
    beat = 60.0 / bpm
    bars = 16
    total = bars * 4 * beat
    n = int(total * SR)
    tail = int(2.0 * SR)
    out = np.zeros(n + tail)

    def put(sig, at, gain=1.0):
        i = int(at * SR)
        j = min(len(out), i + len(sig))
        out[i:j] += sig[:j - i] * gain

    # progression (two passes, second with variation)
    prog = [("Cmaj7", 48, [0, 4, 7, 11]), ("Am7", 45, [0, 3, 7, 10]), ("Dm7", 50, [0, 3, 7, 10]), ("G7", 43, [0, 4, 7, 10]),
            ("Em7", 52, [0, 3, 7, 10]), ("Am7", 45, [0, 3, 7, 10]), ("Dm7", 50, [0, 3, 7, 10]), ("G7", 43, [0, 4, 7, 10])]
    melody_a = [76, None, 74, 72, 74, None, 76, 79, 77, None, 76, 74, 72, None, 71, 72]
    melody_b = [79, 81, 79, 76, 74, None, 72, 74, 76, None, 74, 72, 71, 72, 74, None]
    for bar in range(bars):
        name, root, iv = prog[bar % 8]
        t0 = bar * 4 * beat
        # electric-piano chords (soft sine stack with tremolo), on beats 1 and 3 with swing stabs
        for hit, length in ((0.0, 1.6), (2.5, 1.2)):
            d = length * beat
            ch = np.zeros(int(d * SR))
            for k in iv:
                f = midi(root + 12 + k)
                tone = sine(f, d) + 0.25 * sine(2 * f, d)
                ch += tone
            ch *= expdecay(len(ch), 2.2) * env(len(ch), 0.01, 0.2) * (1 + 0.15 * np.sin(2 * np.pi * 5 * t(d)))
            put(ch, t0 + hit * beat, 0.055)
        # walking bass (triangle)
        walk = [root, root + iv[2], root + 12, root + iv[2] + (2 if bar % 2 else -1)]
        for b in range(4):
            d = beat * 0.9
            s = tri(midi(walk[b] - 12), d) * expdecay(int(d * SR), 3.5) * env(int(d * SR), 0.005, 0.05)
            put(lp(s, 900), t0 + b * beat, 0.32)
        # marimba melody (8th notes)
        mel = melody_a if (bar // 4) % 2 == 0 else melody_b
        for e in range(8):
            idx = (bar % 2) * 8 + e
            m = mel[idx]
            if m is None:
                continue
            if bar >= 8 and e % 4 == 3:
                m += 12 if (bar + e) % 3 == 0 else 0
            sw = 0.08 if e % 2 else 0.0   # light swing
            d = 0.45
            put(pluck(midi(m), d, 9.0), t0 + (e * 0.5 + sw) * beat, 0.18)
        # glockenspiel sparkle every 2 bars
        if bar % 2 == 1:
            put(bell(midi(root + 36 + iv[1]), 0.8, 5.0), t0 + 3.5 * beat, 0.05)
        # drums: soft kick, rim, shaker
        for b in range(4):
            if b in (0, 2):
                d = 0.25
                k = sine(np.geomspace(120, 45, int(d * SR)), d) * expdecay(int(d * SR), 18)
                put(k, t0 + b * beat, 0.35)
            if b in (1, 3):
                d = 0.08
                r = bp(noise(int(d * SR)), 1200, 4500) * expdecay(int(d * SR), 70)
                put(r, t0 + b * beat, 0.12)
            for h in range(2):
                d = 0.05
                sh = hp(noise(int(d * SR)), 6000) * expdecay(int(d * SR), 80)
                put(sh, t0 + (b + h * 0.5 + (0.08 if h else 0)) * beat, 0.06 if h else 0.04)
    # wrap the tail into the start for a seamless loop
    out[:tail] += out[n:n + tail]
    out = out[:n]
    # gentle stereo-free master: soft clip
    out = np.tanh(out * 1.6) / 1.6
    return out


if __name__ == "__main__":
    for name, (fn, vol) in SFX.items():
        save(name, fn(), vol)
        print("sfx", name)
    save("music_office", music(), 0.7)
    print("music done")
