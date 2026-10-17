"""Procedural SFX + music for Çatı Kedisi (numpy/scipy, written as OGG Vorbis)."""
import numpy as np, os, sys
import soundfile as sf
from scipy import signal

SR = 44100
OUT = sys.argv[1] if len(sys.argv) > 1 else "/root/cati-kedisi/assets/audio"
os.makedirs(OUT, exist_ok=True)
rng = np.random.default_rng(7)


def t_(d):
    return np.arange(int(d * SR)) / SR


def env(n, a=0.005, d=0.1, s=0.0, r=0.05, sustain_time=0.0):
    a_n, d_n, s_n, r_n = int(a * SR), int(d * SR), int(sustain_time * SR), int(r * SR)
    e = np.concatenate([np.linspace(0, 1, max(a_n, 1)), np.linspace(1, s, max(d_n, 1)), np.full(s_n, s), np.linspace(s, 0, max(r_n, 1))])
    if len(e) < n:
        e = np.concatenate([e, np.zeros(n - len(e))])
    return e[:n]


def expdec(n, tau):
    return np.exp(-np.arange(n) / SR / tau)


def sweep_sine(f0, f1, d, curve=1.0):
    t = t_(d)
    k = (t / d) ** curve
    f = f0 + (f1 - f0) * k
    ph = 2 * np.pi * np.cumsum(f) / SR
    return np.sin(ph)


def osc(freqs, kind="sine"):
    ph = 2 * np.pi * np.cumsum(freqs) / SR
    if kind == "sine":
        return np.sin(ph)
    if kind == "saw":
        return 2 * ((ph / (2 * np.pi)) % 1.0) - 1
    if kind == "tri":
        x = (ph / (2 * np.pi)) % 1.0
        return 4 * np.abs(x - 0.5) - 1
    if kind == "square":
        return np.sign(np.sin(ph))


def noise(d):
    return rng.uniform(-1, 1, int(d * SR))


def bp(x, lo, hi, order=2):
    b, a = signal.butter(order, [lo / (SR / 2), min(hi / (SR / 2), 0.99)], btype="band")
    return signal.lfilter(b, a, x)


def lp(x, f, order=2):
    b, a = signal.butter(order, min(f / (SR / 2), 0.99), btype="low")
    return signal.lfilter(b, a, x)


def hp(x, f, order=2):
    b, a = signal.butter(order, f / (SR / 2), btype="high")
    return signal.lfilter(b, a, x)


def reverb(x, decay=1.2, mix=0.25, pre=0.01):
    n = int(decay * SR)
    ir = rng.normal(0, 1, n) * np.exp(-np.arange(n) / SR / (decay / 5.0))
    ir = lp(ir, 5000)
    ir[: int(pre * SR)] = 0
    ir /= np.sqrt(np.sum(ir ** 2)) + 1e-9
    wet = signal.fftconvolve(x, ir)[: len(x) + n]
    dry = np.concatenate([x, np.zeros(n)])
    m = min(len(wet), len(dry))
    wet, dry = wet[:m], dry[:m]
    return dry * (1 - mix) + wet * mix * 0.6


def norm(x, peak=0.89):
    m = np.max(np.abs(x)) + 1e-9
    return x / m * peak


def fade(x, fin=0.002, fout=0.01):
    x = x.copy()
    a, b = int(fin * SR), int(fout * SR)
    if a > 0:
        x[:a] *= np.linspace(0, 1, a)
    if b > 0:
        x[-b:] *= np.linspace(1, 0, b)
    return x


def save(name, x, peak=0.89, rev=None):
    if rev:
        x = reverb(x, *rev)
    x = fade(norm(x, peak)).astype(np.float32)
    with sf.SoundFile(os.path.join(OUT, name + ".ogg"), "w", SR, 1, format="OGG", subtype="VORBIS") as f:
        for i in range(0, len(x), 4096):
            f.write(x[i:i + 4096])


def bell(f, d=0.6, bright=1.0):
    t = t_(d)
    parts = [(1.0, 1.0, 1.0), (2.0, 0.5 * bright, 0.6), (3.01, 0.25 * bright, 0.4), (4.17, 0.12 * bright, 0.25)]
    y = np.zeros_like(t)
    for ratio, amp, tdec in parts:
        y += amp * np.sin(2 * np.pi * f * ratio * t) * np.exp(-t / (d * tdec * 0.5))
    y *= env(len(t), 0.002, 0.01, 1.0, 0.01, d)
    return y


def note(n):  # midi -> Hz
    return 440.0 * 2 ** ((n - 69) / 12)


def place(buf, x, at):
    i = int(at * SR)
    end = min(len(buf), i + len(x))
    buf[i:end] += x[: end - i]


# ----------------------------------------------------------------- meow synthesis
FORMANTS = {"i": (310, 2300, 3000), "e": (500, 1900, 2600), "a": (780, 1250, 2600), "o": (520, 900, 2500), "u": (360, 800, 2400)}


def formant_voice(f0_curve, vowels, d, breath=0.08, nasal=0.0):
    n = int(d * SR)
    src = osc(f0_curve[:n], "saw")
    src = lp(src, 5000) + breath * noise(d)[:n]
    out = np.zeros(n)
    # piecewise vowel interpolation, process in blocks
    blk = 256
    keys = np.linspace(0, 1, len(vowels))
    zi = [None, None, None]
    for s in range(0, n, blk):
        pos = s / n
        j = min(np.searchsorted(keys, pos, side="right") - 1, len(vowels) - 2)
        k = (pos - keys[j]) / (keys[j + 1] - keys[j] + 1e-9)
        fa = np.array(FORMANTS[vowels[j]])
        fb = np.array(FORMANTS[vowels[j + 1]])
        fm = fa + (fb - fa) * k
        seg = src[s:s + blk]
        acc = np.zeros_like(seg)
        for q, (ff, g) in enumerate(zip(fm, (1.0, 0.7, 0.35))):
            bw = 80 + ff * 0.08
            b, a = signal.iirpeak(ff / (SR / 2), ff / bw)
            if zi[q] is None:
                zi[q] = signal.lfilter_zi(b, a) * 0
            y, zi[q] = signal.lfilter(b, a, seg, zi=zi[q])
            acc += g * y
        out[s:s + blk] = acc
    return out


def meow(base=520, d=0.62, kitten=False):
    n = int(d * SR)
    t = np.arange(n) / SR
    x = t / d
    contour = base * (1.0 + 0.45 * np.sin(np.pi * np.clip(x * 1.25, 0, 1)) - 0.25 * x)
    contour *= 1 + 0.015 * np.sin(2 * np.pi * 6 * t)
    v = formant_voice(contour, ["i", "e", "a", "a", "o", "u"], d, 0.06)
    e = env(n, 0.03, 0.05, 0.85, 0.16, d - 0.24)
    y = v * e
    return hp(y, 250)


# ----------------------------------------------------------------- SFX
def sfx():
    # jump: soft rising "fwip-boing"
    d = 0.16
    y = sweep_sine(280, 720, d, 0.7) * env(int(d * SR), 0.004, 0.05, 0.4, 0.08, 0.03)
    y += 0.25 * bp(noise(d), 1500, 5000) * env(int(d * SR), 0.002, 0.06, 0, 0.01)
    save("jump", y, 0.8)
    # double jump: higher + sparkle
    d = 0.22
    y = sweep_sine(520, 1250, d, 0.6) * env(int(d * SR), 0.003, 0.06, 0.3, 0.1, 0.04)
    y += 0.3 * bell(2093, d, 0.5)[: int(d * SR)] + 0.2 * bell(2637, d, 0.5)[: int(d * SR)]
    save("jump2", y, 0.8)
    # land: little thump
    d = 0.14
    y = sweep_sine(130, 55, d, 0.5) * expdec(int(d * SR), 0.035)
    y += 0.4 * lp(noise(d), 900) * expdec(int(d * SR), 0.02)
    save("land", y, 0.8)
    # step: paw pat
    d = 0.05
    y = lp(noise(d), 1800) * expdec(int(d * SR), 0.008)
    save("step", y, 0.6)
    # fish: bright bell ding
    y = bell(1568, 0.45) + 0.4 * bell(3136, 0.25)[: int(0.45 * SR)].tolist() + np.zeros(0) if False else bell(1568, 0.45)
    y = y + 0.35 * np.pad(bell(2349, 0.3), (0, len(y) - int(0.3 * SR)))
    save("fish", y, 0.75)
    # golden fish: quick arpeggio
    buf = np.zeros(int(0.9 * SR))
    for i, m in enumerate([84, 88, 91, 96]):
        place(buf, bell(note(m), 0.5) * (0.9 - i * 0.1), i * 0.06)
    save("fish_gold", buf, 0.8, (0.8, 0.2))
    # kitten rescued: happy jingle + meow
    buf = np.zeros(int(1.6 * SR))
    for i, m in enumerate([79, 83, 86, 91, 95]):
        place(buf, bell(note(m), 0.6) * 0.8, i * 0.08)
    place(buf, meow(780, 0.45, True) * 1.2, 0.5)
    save("kitten", buf, 0.85, (1.0, 0.2))
    # meows
    save("meow", meow(500, 0.6), 0.8)
    save("meow_kitten", meow(820, 0.42, True), 0.8)
    # bounce: springy boing
    d = 0.42
    t = t_(d)
    f = 180 + 240 * (t / d) + 60 * np.sin(2 * np.pi * 22 * t) * np.exp(-t / 0.15)
    y = osc(f, "sine") * env(len(t), 0.003, 0.08, 0.5, 0.2, 0.1)
    y += 0.3 * osc(f * 2, "tri") * expdec(len(t), 0.08)
    save("bounce", y, 0.85)
    # stomp: pop + squeak
    d = 0.25
    y = 0.8 * bp(noise(d), 300, 2500) * expdec(int(d * SR), 0.02)
    y += sweep_sine(1100, 380, d, 0.4) * env(int(d * SR), 0.002, 0.06, 0.3, 0.1, 0.02) * 0.7
    save("stomp", y, 0.85)
    # hurt: grumpy short "mrraw" + thud
    m = meow(330, 0.32)
    th = sweep_sine(150, 60, 0.15, 0.5) * expdec(int(0.15 * SR), 0.05)
    buf = np.zeros(int(0.45 * SR))
    place(buf, th, 0)
    place(buf, m, 0.03)
    save("hurt", buf, 0.85)
    # seagull cry: "kyah-kyah"
    buf = np.zeros(int(1.1 * SR))
    for i in range(3):
        d = 0.24 - i * 0.03
        t = t_(d)
        f0 = 1350 * (1 - 0.35 * (t / d)) * (1 + 0.04 * np.sin(2 * np.pi * 38 * t))
        v = formant_voice(f0, ["e", "a", "a"], d, 0.25)
        v *= env(len(t), 0.01, 0.04, 0.8, 0.06, d - 0.11)
        place(buf, v, i * 0.28)
    save("gull", hp(buf, 500), 0.8)
    # dive whoosh
    d = 0.7
    n = int(d * SR)
    y = np.zeros(n)
    nz = noise(d)
    for s in range(0, n, 512):
        k = s / n
        f = 3000 - 2300 * k
        seg = bp(nz[s:s + 512], f * 0.7, f * 1.3, 1)
        y[s:s + 512] = seg[: len(y[s:s + 512])]
    y *= env(n, 0.15, 0.2, 0.7, 0.3, 0.05)
    save("gull_dive", y, 0.6)
    # checkpoint chime
    buf = np.zeros(int(1.4 * SR))
    for i, m in enumerate([79, 83, 86, 91]):
        place(buf, bell(note(m), 0.9) * 0.8, i * 0.09)
    save("checkpoint", buf, 0.8, (1.2, 0.3))
    # dash whoosh
    d = 0.28
    n = int(d * SR)
    y = bp(noise(d), 800, 4500) * env(n, 0.01, 0.1, 0.4, 0.12, 0.05)
    y += 0.3 * sweep_sine(300, 900, d) * env(n, 0.005, 0.1, 0.2, 0.1, 0.02)
    save("dash", y, 0.7)
    # wall jump: scratch + boing
    d = 0.2
    n = int(d * SR)
    y = 0.6 * bp(noise(d), 2000, 7000) * expdec(n, 0.03)
    y += sweep_sine(350, 800, d) * env(n, 0.003, 0.05, 0.3, 0.1, 0.03)
    save("wall", y, 0.75)
    # respawn: descending "wah wah" + poof
    buf = np.zeros(int(1.1 * SR))
    for i, m in enumerate([67, 63]):
        d = 0.32
        t = t_(d)
        f = note(m) * (1 - 0.05 * t / d)
        v = lp(osc(f, "saw"), 1400) * env(len(t), 0.02, 0.1, 0.7, 0.12, 0.1)
        v *= 1 + 0.3 * np.sin(2 * np.pi * 7 * t)
        place(buf, v * 0.6, i * 0.3)
    place(buf, lp(noise(0.3), 1200) * expdec(int(0.3 * SR), 0.08) * 0.5, 0.7)
    save("respawn", buf, 0.8)
    # pigeons flutter
    d = 0.9
    n = int(d * SR)
    t = t_(d)
    am = (0.5 + 0.5 * np.sin(2 * np.pi * 17 * t)) ** 3
    y = bp(noise(d), 400, 3500) * am * env(n, 0.02, 0.2, 0.6, 0.4, 0.2)
    buf = y.copy()
    buf += np.roll(y, int(0.037 * SR)) * 0.7
    save("pigeons", buf, 0.7)
    # win fanfare
    buf = np.zeros(int(3.2 * SR))
    mel = [(72, 0.0, 0.18), (76, 0.18, 0.18), (79, 0.36, 0.18), (84, 0.54, 0.5), (81, 1.08, 0.18), (84, 1.26, 0.9)]
    for m, at, du in mel:
        t = t_(du + 0.3)
        f = note(m) * (1 + 0.006 * np.sin(2 * np.pi * 5.5 * t))
        v = lp(osc(f, "saw") + 0.5 * osc(f * 2, "saw"), 2400) * env(len(t), 0.02, 0.1, 0.8, 0.3, du - 0.1)
        place(buf, v * 0.5, at)
        place(buf, bell(note(m + 12), 0.8) * 0.35, at)
    # drum roll
    for i in range(14):
        place(buf, bp(noise(0.06), 200, 4000) * expdec(int(0.06 * SR), 0.02) * (0.2 + i * 0.03), i * 0.04)
    place(buf, sweep_sine(120, 50, 0.4) * expdec(int(0.4 * SR), 0.12), 1.26)
    save("win", buf, 0.85, (1.4, 0.3))
    # ui click
    d = 0.06
    y = bell(1800, d)[: int(d * SR)] * expdec(int(d * SR), 0.015)
    save("click", y, 0.6)
    # transition whoosh
    d = 0.6
    n = int(d * SR)
    y = lp(noise(d), 2500) * env(n, 0.25, 0.1, 0.6, 0.25, 0.0)
    save("whoosh", y, 0.6)
    # tram bell: ding-ding
    buf = np.zeros(int(1.4 * SR))
    for i in range(2):
        t = t_(1.0)
        y = np.zeros_like(t)
        for ratio, amp in [(1, 1), (2.76, 0.5), (5.4, 0.3), (8.93, 0.15)]:
            y += amp * np.sin(2 * np.pi * 1180 * ratio * t) * np.exp(-t / (0.5 / ratio ** 0.5))
        place(buf, y * env(len(t), 0.001, 0.01, 1, 0.01, 1.0), i * 0.28)
    save("tram_bell", buf, 0.7)
    # ferry horn
    d = 2.2
    t = t_(d)
    f = 98 * (1 + 0.003 * np.sin(2 * np.pi * 4 * t))
    y = lp(osc(f, "saw") + 0.7 * osc(f * 1.5, "saw"), 900) * env(len(t), 0.15, 0.2, 0.85, 0.5, d - 0.85)
    save("ferry_horn", y, 0.7, (2.0, 0.4))


# ----------------------------------------------------------------- instruments
def pluck(f, d, bright=0.6, course=True):
    """Karplus-Strong saz-like pluck (paired courses)."""
    n = int(d * SR)
    out = np.zeros(n)
    for det in ([1.0, 1.004] if course else [1.0]):
        p = int(SR / (f * det))
        buf = rng.uniform(-1, 1, p)
        buf = lp(buf, 1500 + 6000 * bright, 1)
        y = np.zeros(n)
        idx = 0
        last = 0.0
        damp = 0.996
        for i in range(n):
            v = buf[idx]
            nv = damp * 0.5 * (v + last)
            last = v
            buf[idx] = nv
            y[i] = v
            idx = (idx + 1) % p
        out += y
    out = hp(out, 90)
    return out * env(n, 0.001, 0.02, 1.0, 0.05, d - 0.07)


_pluck_cache = {}


def pluck_c(m, d, bright=0.6):
    key = (m, round(d, 3), bright)
    if key not in _pluck_cache:
        _pluck_cache[key] = pluck(note(m), d, bright)
    return _pluck_cache[key]


def doum():
    d = 0.35
    return sweep_sine(110, 60, d, 0.4) * expdec(int(d * SR), 0.12) + 0.2 * lp(noise(d), 300) * expdec(int(d * SR), 0.03)


def tek():
    d = 0.12
    n = int(d * SR)
    y = bp(noise(d), 2500, 9000) * expdec(n, 0.012) + 0.5 * np.sin(2 * np.pi * 820 * t_(d)) * expdec(n, 0.03)
    return y


def ka():
    return tek() * 0.45


def shaker():
    d = 0.06
    return hp(noise(d), 6000) * env(int(d * SR), 0.01, 0.04, 0, 0.01) * 0.3


def bass_note(m, d):
    t = t_(d)
    f = note(m)
    y = osc(np.full(len(t), f), "tri") + 0.3 * osc(np.full(len(t), f * 2), "sine")
    return lp(y, 900) * env(len(t), 0.005, 0.08, 0.7, 0.08, d - 0.16)


def pad(ms, d):
    t = t_(d)
    y = np.zeros(len(t))
    for m in ms:
        for det in (-0.08, 0.0, 0.08):
            y += osc(np.full(len(t), note(m + det)), "saw")
    y = lp(y, 1400)
    return y * env(len(t), 0.4, 0.2, 0.8, 0.6, d - 1.2) / (3 * len(ms))


def ney(m, d):
    """breathy flute (ney-ish) lead."""
    t = t_(d)
    f = note(m) * (1 + 0.008 * np.sin(2 * np.pi * 5.2 * t) * np.clip(t / 0.25, 0, 1))
    y = osc(f, "sine") + 0.25 * osc(f * 2, "sine") + 0.08 * osc(f * 3, "sine")
    y += 0.12 * bp(noise(d), note(m) * 1.5, note(m) * 4)
    return y * env(len(t), 0.06, 0.1, 0.8, 0.12, d - 0.28)


# Hicaz on D: D Eb F# G A Bb C D
HICAZ = [62, 63, 66, 67, 69, 70, 72, 74, 75, 78, 79, 81]


def deg(i):
    o, k = divmod(i, 7)
    base = [62, 63, 66, 67, 69, 70, 72][k]
    return base + 12 * o


def music_galata():
    bpm = 116
    beat = 60 / bpm
    bars = 32
    L = bars * 4 * beat
    tail = 3.0
    buf = np.zeros(int((L + tail) * SR))
    # drums: maqsum  D T . T D . T .
    pat = [("D", 0), ("T", 0.5), ("T", 1.5), ("D", 2.0), ("T", 3.0)]
    fills = [("k", 1.0), ("k", 2.5), ("k", 3.5), ("k", 0.75), ("k", 3.25)]
    for b in range(bars):
        if b < 2:
            continue
        for kind, at in pat:
            place(buf, (doum() * 0.9 if kind == "D" else tek() * 0.55), (b * 4 + at) * beat)
        for kind, at in fills:
            if rng.random() < 0.6:
                place(buf, ka() * 0.6, (b * 4 + at) * beat)
        for s in range(8):
            place(buf, shaker() * (0.6 if s % 2 else 0.35), (b * 4 + s * 0.5) * beat)
    # bass: D drone with movement
    prog = [62, 62, 67, 62, 60, 60, 62, 69] * 4
    for b in range(bars):
        r = prog[b] - 24
        for at, dur in [(0, 1.5), (1.5, 0.5), (2, 1.5), (3.5, 0.5)]:
            m = r if at in (0, 2) else r + 7
            place(buf, bass_note(m, dur * beat) * 0.45, (b * 4 + at) * beat)
    # pad
    chords = {62: [62, 66, 69], 67: [67, 70, 74], 60: [60, 63, 67], 69: [61, 64, 69]}
    for b in range(0, bars, 2):
        place(buf, pad(chords.get(prog[b], [62, 66, 69]), 8 * beat) * 0.5, b * 4 * beat)
    # melody (scale degrees, durations in beats) — A A' B C phrases
    A = [(0, .5), (1, .5), (2, 1), (3, .5), (4, .5), (3, .5), (2, .5), (1, 1), (0, 1), (2, .5), (3, .5), (4, 1), (5, .5), (4, .5), (3, 2),
         (4, .5), (5, .5), (4, .5), (3, .5), (2, 1), (1, .5), (2, .5), (1, .5), (0, .5), (-1, .5), (0, 2.5)]
    B = [(7, 1), (6, .5), (5, .5), (4, 1), (5, .5), (4, .5), (3, 1), (4, .5), (3, .5), (2, 2), (4, .5), (5, .5), (6, .5), (7, .5), (8, 1), (7, .5), (6, .5),
         (5, .5), (4, .5), (3, .5), (2, .5), (1, 1), (2, .5), (1, .5), (0, 3)]
    def play_phrase(ph, start_bar, inst="saz", oct_=0):
        at = start_bar * 4 * beat
        for dg, du in ph:
            m = deg(dg) + 12 * oct_
            if inst == "saz":
                place(buf, pluck_c(m, du * beat + 0.3, 0.65) * 0.55, at)
                if du >= 1:
                    place(buf, pluck_c(m, 0.25, 0.8) * 0.25, at + du * beat * 0.5)
            else:
                place(buf, ney(m, du * beat + 0.05) * 0.32, at)
            at += du * beat
    # intro arps (bars 0-1)
    for i in range(16):
        place(buf, pluck_c(deg([0, 2, 4, 2][i % 4]), 0.4, 0.5) * 0.4, i * 0.5 * beat)
    play_phrase(A, 2, "saz")
    play_phrase(A, 10, "ney", 1)
    play_phrase(A, 10, "saz")
    play_phrase(B, 18, "saz")
    play_phrase(B, 26 - 2, "ney", 1)
    # counter arps under B
    for b in range(18, 32):
        for i in range(8):
            if i % 2 == 0:
                place(buf, pluck_c(deg([0, 4, 2, 4][(i // 2) % 4]) - 12, 0.3, 0.4) * 0.22, (b * 4 + i * 0.5) * beat)
    buf = reverb(buf, 1.3, 0.22)
    # seamless loop: fold the tail into the start
    n = int(L * SR)
    loop = buf[:n].copy()
    t_len = len(buf) - n
    loop[:t_len] += buf[n:n + t_len]
    return loop


def music_menu():
    bpm = 78
    beat = 60 / bpm
    bars = 16
    L = bars * 4 * beat
    buf = np.zeros(int((L + 4) * SR))
    prog = [62, 62, 67, 67, 60, 60, 62, 69] * 2
    chords = {62: [62, 66, 69], 67: [67, 70, 74], 60: [60, 63, 67], 69: [61, 64, 69]}
    for b in range(bars):
        place(buf, pad(chords[prog[b]], 4 * beat + 1.0) * 0.6, b * 4 * beat)
        place(buf, bass_note(prog[b] - 24, 3.5 * beat) * 0.35, b * 4 * beat)
        arp = [0, 2, 4, 7, 4, 2, 4, 2]
        root_deg = {62: 0, 67: 3, 60: -1, 69: 4}[prog[b]]
        for i in range(8):
            if rng.random() < 0.9:
                place(buf, pluck_c(deg(root_deg + arp[i]), 0.9, 0.45) * 0.3, (b * 4 + i * 0.5) * beat)
        place(buf, doum() * 0.25, b * 4 * beat)
    mel = [(4, 2), (3, 1), (2, 1), (1, 2), (0, 2), (2, 2), (3, 1), (4, 1), (5, 4), (4, 2), (3, 1), (2, 1), (1, 2), (2, 1), (1, 1), (0, 4)]
    at = 4 * 4 * beat
    for dg, du in mel:
        place(buf, ney(deg(dg) + 12, du * beat) * 0.3, at)
        at += du * beat
    buf = reverb(buf, 2.0, 0.35)
    n = int(L * SR)
    loop = buf[:n].copy()
    t_len = len(buf) - n
    loop[:t_len] += buf[n:n + t_len]
    return loop


def ambience():
    d = 40.0
    n = int(d * SR)
    t = np.arange(n) / SR
    waves = lp(noise(d), 700) * (0.55 + 0.45 * np.sin(2 * np.pi * t / 7.3) ** 2) * 0.5
    wind = bp(noise(d), 200, 1200) * (0.3 + 0.2 * np.sin(2 * np.pi * t / 11.0)) * 0.25
    buf = waves + wind
    # distant gulls
    for k in range(7):
        at = rng.uniform(1, d - 3)
        dd = 0.22
        tt = t_(dd)
        f0 = rng.uniform(1100, 1500) * (1 - 0.3 * (tt / dd))
        v = formant_voice(f0, ["e", "a"], dd, 0.3) * env(len(tt), 0.01, 0.04, 0.8, 0.06, dd - 0.11)
        v = lp(v, 2500) * 0.12
        for r in range(rng.integers(1, 3)):
            place(buf, v, at + r * 0.3)
    # far horn
    tt = t_(2.4)
    horn = lp(osc(np.full(len(tt), 92.0), "saw"), 500) * env(len(tt), 0.3, 0.2, 0.8, 0.8, 1.0) * 0.12
    place(buf, horn, 18.0)
    buf = reverb(buf, 2.5, 0.4)
    loop = buf[:n].copy()
    t_len = len(buf) - n
    loop[:t_len] += buf[n:n + t_len]
    # crossfade ends to hide noise seam
    return loop


if __name__ == "__main__":
    which = sys.argv[2] if len(sys.argv) > 2 else "all"
    if which in ("all", "sfx"):
        sfx()
        print("sfx done")
    if which in ("all", "music"):
        save("music_menu", music_menu(), 0.8)
        print("menu done")
        save("music_galata", music_galata(), 0.82)
        print("galata done")
        save("ambience_city", ambience(), 0.6)
        print("ambience done")
