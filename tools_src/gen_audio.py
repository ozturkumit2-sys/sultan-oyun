#!/usr/bin/env python3
"""FUSE CHEF — tüm ses efektleri ve müzikler bu betikle sıfırdan sentezlenir.
Hiçbir kayıt veya telifli müzik kullanılmaz. Çıktı: OGG Vorbis.
Kullanım: python3 gen_audio.py <çıktı_klasörü>"""
import os
import sys
import numpy as np
import soundfile as sf

OUT = sys.argv[1] if len(sys.argv) > 1 else "assets/audio"
SFX = os.path.join(OUT, "sfx")
MUS = os.path.join(OUT, "music")
os.makedirs(SFX, exist_ok=True)
os.makedirs(MUS, exist_ok=True)
SR = 32000
rng = np.random.default_rng(2026)


def t_arr(dur, sr=SR):
    return np.arange(int(dur * sr)) / sr


def write(path, x, sr=SR, peak=0.9, q=0.4):
    x = np.asarray(x, dtype=np.float64)
    m = np.max(np.abs(x)) + 1e-9
    x = x / m * peak
    sf.write(path, x.astype(np.float32), sr, format="OGG", subtype="VORBIS")


TARGET_RMS = {"tick": -20.0, "tap": -18.0, "click": -17.0, "page": -20.0, "sizzle": -22.0, "bubble": -20.0,
              "grill_hiss": -19.0, "whoosh": -18.0, "drumroll": -18.0, "munch": -17.0}


def level(x, target_db, ceiling=0.85):
    """RMS normalizasyonu + yumuşak tepe sınırlayıcı: sesler arasında tutarlı yükseklik."""
    x = np.asarray(x, dtype=np.float64)
    rms = np.sqrt(np.mean(x ** 2)) + 1e-9
    x = x * (10 ** (target_db / 20.0) / rms)
    return ceiling * np.tanh(x / ceiling)


def sfx(name, x, peak=0.9):
    y = level(x, TARGET_RMS.get(name, -15.0))
    sf.write(os.path.join(SFX, name + ".ogg"), y.astype(np.float32), SR, format="OGG", subtype="VORBIS")
    print("sfx", name, round(len(x) / SR, 2))


def env_exp(n, decay):
    t = np.arange(n) / SR
    return np.exp(-t / max(decay, 1e-4))


def adsr(n, a=0.01, d=0.05, s=0.7, r=0.1):
    t = np.arange(n) / SR
    dur = n / SR
    e = np.ones(n) * s
    e[t < a] = t[t < a] / max(a, 1e-5)
    m = (t >= a) & (t < a + d)
    e[m] = 1 - (1 - s) * (t[m] - a) / max(d, 1e-5)
    rel = t > dur - r
    e[rel] *= np.clip((dur - t[rel]) / max(r, 1e-5), 0, 1)
    return e


def lowpass(x, cutoff, order=2):
    X = np.fft.rfft(x)
    f = np.fft.rfftfreq(len(x), 1 / SR)
    X *= 1.0 / np.sqrt(1.0 + (f / cutoff) ** (2 * order))
    return np.fft.irfft(X, len(x))


def highpass(x, cutoff, order=2):
    X = np.fft.rfft(x)
    f = np.fft.rfftfreq(len(x), 1 / SR)
    X *= 1.0 / np.sqrt(1.0 + (cutoff / np.maximum(f, 1)) ** (2 * order))
    return np.fft.irfft(X, len(x))


def bandpass(x, lo, hi):
    return highpass(lowpass(x, hi), lo)


def sweep(f0, f1, dur, shape="exp"):
    n = int(dur * SR)
    if shape == "exp":
        f = f0 * (f1 / f0) ** (np.arange(n) / max(n - 1, 1))
    else:
        f = np.linspace(f0, f1, n)
    return np.cumsum(f) / SR * 2 * np.pi


def tone(freq, dur, kind="sine"):
    t = t_arr(dur)
    ph = 2 * np.pi * freq * t
    if kind == "sine":
        return np.sin(ph)
    if kind == "tri":
        return 2 / np.pi * np.arcsin(np.sin(ph))
    if kind == "square":
        out = np.zeros_like(t)
        k = 1
        while k * freq < SR / 2.2 and k < 30:
            out += np.sin(ph * k) / k
            k += 2
        return out * 4 / np.pi
    if kind == "saw":
        out = np.zeros_like(t)
        k = 1
        while k * freq < SR / 2.2 and k < 40:
            out += np.sin(ph * k) / k
            k += 1
        return out * 0.6
    return np.sin(ph)


def noise(dur):
    return rng.normal(size=int(dur * SR))


def pad_to(x, n):
    if len(x) >= n:
        return x[:n]
    return np.concatenate([x, np.zeros(n - len(x))])


def mix(*parts):
    n = max(len(p) for p in parts)
    out = np.zeros(n)
    for p in parts:
        out[:len(p)] += p
    return out


def at(x, start, total):
    out = np.zeros(int(total * SR))
    s = int(start * SR)
    e = min(len(out), s + len(x))
    out[s:e] += x[:e - s]
    return out


def bell(freq, dur, decay=0.4, ratio=3.5, index=2.0):
    t = t_arr(dur)
    mod = np.sin(2 * np.pi * freq * ratio * t) * index * np.exp(-t / (decay * 0.5))
    return np.sin(2 * np.pi * freq * t + mod) * np.exp(-t / decay)


def marimba(freq, dur, vel=1.0):
    t = t_arr(dur)
    x = np.sin(2 * np.pi * freq * t) * np.exp(-t / 0.35)
    x += 0.35 * np.sin(2 * np.pi * freq * 4.0 * t) * np.exp(-t / 0.05)
    x += 0.12 * np.sin(2 * np.pi * freq * 9.9 * t) * np.exp(-t / 0.012)
    return x * vel


def formant_voice(f0_curve, vowels, dur, breath=0.05):
    """Basit formant sentezi: glottal darbe dizisi + üç rezonans."""
    n = int(dur * SR)
    f0 = np.interp(np.arange(n), np.linspace(0, n - 1, len(f0_curve)), f0_curve)
    ph = np.cumsum(f0) / SR
    glott = (ph % 1.0)
    src = (1 - glott) ** 3 - 0.25
    src += rng.normal(size=n) * breath
    out = np.zeros(n)
    # zamanla değişen ünlüler: segmentlere böl
    seg = len(vowels)
    for i, (f1, f2, f3) in enumerate(vowels):
        s = int(i * n / seg)
        e = int((i + 1) * n / seg)
        piece = src[max(0, s - 400):min(n, e + 400)]
        y = 0
        for fc, bw, g in ((f1, 90, 1.0), (f2, 120, 0.6), (f3, 160, 0.3)):
            y = y + g * bandpass(piece, fc - bw, fc + bw)
        y = y[(s - max(0, s - 400)):(s - max(0, s - 400)) + (e - s)]
        w = np.ones(e - s)
        fade = min(300, (e - s) // 3)
        if fade > 0:
            w[:fade] = np.linspace(0, 1, fade)
            w[-fade:] = np.linspace(1, 0, fade)
        out[s:e] += y * w
    return out


A = (800, 1200, 2500)
O = (500, 900, 2400)
U = (350, 800, 2200)
E = (550, 1800, 2600)
I = (300, 2300, 3000)

# ======================================================================== SFX
sfx("click", tone(1600, 0.05) * env_exp(int(0.05 * SR), 0.012) + 0.4 * highpass(noise(0.05), 2000) * env_exp(int(0.05 * SR), 0.004))
sfx("tap", tone(900, 0.06) * env_exp(int(0.06 * SR), 0.015), peak=0.6)
n = int(0.09 * SR)
sfx("pop", np.sin(sweep(380, 1300, 0.09)) * env_exp(n, 0.03))
w = noise(0.42)
ph = sweep(250, 3500, 0.42)
wb = np.zeros_like(w)
for i, (lo, hi) in enumerate(((250, 700), (600, 1500), (1300, 3500))):
    seg = bandpass(w, lo, hi)
    e = np.exp(-((np.linspace(0, 1, len(w)) - (0.25 + i * 0.25)) ** 2) / 0.02)
    wb += seg * e
sfx("whoosh", wb, peak=0.7)
# füzyon: yükselen zil arpeji + parıltı
notes = [523.25, 659.25, 783.99, 1046.5, 1318.5]
x = np.zeros(int(0.9 * SR))
for i, f in enumerate(notes):
    x += at(bell(f, 0.6, 0.25, 2.0, 1.2), i * 0.07, 0.9)
x += at(highpass(noise(0.7), 4000) * np.linspace(0, 1, int(0.7 * SR)) ** 2 * np.exp(-np.linspace(0, 3, int(0.7 * SR))) * 0.2, 0.0, 0.9)
sfx("fuse", x)
x = np.zeros(int(1.4 * SR))
for i, f in enumerate([392.0, 523.25, 659.25, 783.99, 1046.5, 1318.5, 1568.0]):
    x += at(bell(f, 0.9, 0.35, 2.0, 1.4), i * 0.06, 1.4)
for f in (523.25, 659.25, 783.99):
    x += at(tone(f, 0.9, "tri") * adsr(int(0.9 * SR), 0.05, 0.2, 0.5, 0.5) * 0.3, 0.45, 1.4)
sfx("fuse_special", x)
x = np.zeros(int(1.1 * SR))
for i, f in enumerate([523.25, 659.25, 783.99, 1046.5]):
    x += at(marimba(f, 0.5), i * 0.09, 1.1)
x += at(bell(2093, 0.7, 0.3, 3.0, 1.0) * 0.5, 0.36, 1.1)
sfx("discover", x)
sfx("ding", mix(bell(1318.5, 1.4, 0.55, 2.76, 1.8), 0.4 * bell(2637, 1.0, 0.3, 2.0, 1.0)))
# cızırtı döngüsü
n = int(2.0 * SR)
crack = np.zeros(n)
for k in range(260):
    p = rng.integers(0, n - 200)
    crack[p:p + 120] += rng.normal(size=120) * np.exp(-np.arange(120) / 18) * rng.uniform(0.3, 1.0)
hiss = highpass(noise(2.0), 3000) * 0.18
sz = highpass(crack, 1500) + hiss
fade = int(0.1 * SR)
sz[:fade] *= np.linspace(0.5, 1, fade)
sz[-fade:] *= np.linspace(1, 0.5, fade)
sfx("sizzle", sz, peak=0.6)
# fokurdama döngüsü
n = int(2.0 * SR)
bub = lowpass(noise(2.0), 300) * 0.4
for k in range(28):
    s = rng.uniform(0, 1.85)
    d = rng.uniform(0.05, 0.1)
    b = np.sin(sweep(rng.uniform(200, 400), rng.uniform(600, 1100), d)) * env_exp(int(d * SR), d * 0.4)
    bub += at(b * rng.uniform(0.3, 0.8), s, 2.0)
sfx("bubble", bub, peak=0.6)
x = np.zeros(int(0.9 * SR))
for i, f in enumerate([3136, 2637, 2349, 1976, 1760]):
    x += at(bell(f, 0.5, 0.15, 1.5, 0.6) * 0.5, i * 0.05, 0.9)
x += highpass(noise(0.9), 5000) * env_exp(int(0.9 * SR), 0.25) * 0.3
sfx("freeze", x)
sfx("grill_hiss", highpass(noise(0.7), 2500) * adsr(int(0.7 * SR), 0.02, 0.1, 0.6, 0.4), peak=0.6)
x = np.zeros(int(1.0 * SR))
for i in range(10):
    f = 880 * 2 ** (i / 7)
    x += at(bell(f, 0.4, 0.2, 2.5, 0.8) * 0.4, i * 0.05, 1.0)
x += highpass(noise(1.0), 6000) * np.sin(np.linspace(0, np.pi, int(1.0 * SR))) * 0.15
sfx("magic", x)
sfx("perfect", mix(bell(1046.5, 0.6, 0.3, 2.0, 1.0), at(bell(1568, 0.6, 0.3, 2.0, 1.0), 0.09, 0.69)))
sfx("fail", tone(110, 0.45, "square") * adsr(int(0.45 * SR), 0.01, 0.05, 0.8, 0.1) * 0.5 + tone(116, 0.45, "square") * 0.3 * adsr(int(0.45 * SR), 0.01, 0.05, 0.8, 0.1), peak=0.6)
x = np.zeros(int(1.0 * SR))
for i in range(3):
    x += at(tone(988, 0.15, "tri") * adsr(int(0.15 * SR), 0.005, 0.02, 0.9, 0.03), i * 0.32, 1.0)
    x += at(tone(740, 0.15, "tri") * adsr(int(0.15 * SR), 0.005, 0.02, 0.9, 0.03), i * 0.32 + 0.16, 1.0)
sfx("warning", x, peak=0.7)
x = mix(lowpass(noise(0.3), 400) * env_exp(int(0.3 * SR), 0.08), at(bell(1760, 0.5, 0.25, 2.0, 0.7), 0.05, 0.55))
sfx("shield", x)
boom = np.sin(sweep(160, 40, 0.6)) * env_exp(int(0.6 * SR), 0.18)
blast = lowpass(noise(0.8), 900) * env_exp(int(0.8 * SR), 0.15)
boing = np.sin(2 * np.pi * np.cumsum(420 + 140 * np.sin(np.linspace(0, 30, int(0.6 * SR))) * np.linspace(1, 0, int(0.6 * SR))) / SR) * env_exp(int(0.6 * SR), 0.25) * 0.4
sfx("backfire", mix(boom, blast * 0.7, at(boing, 0.25, 0.85)))
n = int(0.6 * SR)
sfx("boing", np.sin(2 * np.pi * np.cumsum(300 + 160 * np.sin(np.linspace(0, 40, n)) * np.linspace(1, 0, n) + np.linspace(0, 200, n)) / SR) * env_exp(n, 0.25))
# kurbağa vrak
croak = np.zeros(int(0.5 * SR))
for i, s in enumerate((0.0, 0.2)):
    d = 0.16
    pulses = (np.sin(2 * np.pi * 28 * t_arr(d)) > 0.3).astype(float)
    v = formant_voice([140, 120], [(400, 900, 2200)], d, 0.02) * pulses * adsr(int(d * SR), 0.01, 0.03, 0.8, 0.04)
    croak += at(v, s, 0.5)
sfx("croak", croak)
n = int(1.1 * SR)
tt = t_arr(1.1)
f = 330 + 110 * np.sin(np.linspace(0, np.pi, n)) + 8 * np.sin(2 * np.pi * 6 * tt)
sfx("ghost", np.sin(np.cumsum(f) / SR * 2 * np.pi) * adsr(n, 0.2, 0.2, 0.8, 0.4) * (0.7 + 0.3 * np.sin(2 * np.pi * 4 * tt)) + 0.05 * lowpass(noise(1.1), 800))
x = np.zeros(int(0.55 * SR))
for i, f in enumerate([1200, 900, 1500, 1100]):
    x += at(tone(f, 0.09, "square") * adsr(int(0.09 * SR), 0.003, 0.01, 0.9, 0.01) * 0.4, i * 0.12, 0.55)
sfx("robot", x, peak=0.6)
x = np.zeros(int(0.7 * SR))
for i in range(4):
    crunch = bandpass(noise(0.1), 800, 4000) * env_exp(int(0.1 * SR), 0.025)
    x += at(crunch * rng.uniform(0.6, 1.0), i * 0.16 + rng.uniform(0, 0.03), 0.7)
sfx("munch", x, peak=0.7)
sfx("gulp", np.sin(sweep(500, 160, 0.25)) * env_exp(int(0.25 * SR), 0.08))
# kahkaha: "ha-ha-ha-ha"
lg = np.zeros(int(1.1 * SR))
for i in range(4):
    d = 0.17
    v = formant_voice([230 - i * 12, 200 - i * 12], [A], d, 0.25) * adsr(int(d * SR), 0.015, 0.05, 0.7, 0.07)
    asp = bandpass(noise(0.05), 800, 3000) * env_exp(int(0.05 * SR), 0.015) * 0.3
    lg += at(asp, i * 0.23, 1.1) + at(v, i * 0.23 + 0.03, 1.1)
sfx("laugh", lg)
cr = formant_voice([420, 470, 380, 440, 320], [A, A, O, A, U], 1.3, 0.12) * adsr(int(1.3 * SR), 0.05, 0.1, 0.8, 0.3)
cr *= 0.75 + 0.25 * np.sin(2 * np.pi * 7 * t_arr(1.3))
sfx("cry", cr)
yay = formant_voice([260, 340, 420], [E, A, I], 0.6, 0.15) * adsr(int(0.6 * SR), 0.03, 0.1, 0.8, 0.2)
crowd = bandpass(noise(1.2), 400, 2500) * adsr(int(1.2 * SR), 0.1, 0.3, 0.5, 0.6) * 0.25
sfx("cheer", mix(yay, crowd, at(np.sin(sweep(400, 1200, 0.08)) * env_exp(int(0.08 * SR), 0.03) * 0.4, 0.5, 0.6)))
cg = np.zeros(int(0.7 * SR))
for i, s in enumerate((0.0, 0.3)):
    burst = bandpass(noise(0.2), 300, 2500) * adsr(int(0.2 * SR), 0.005, 0.05, 0.5, 0.1)
    cg += at(burst * (1.0 - i * 0.3), s, 0.7)
sfx("cough", cg)
n = int(0.9 * SR)
fl = np.sin(sweep(1400, 220, 0.8)) * adsr(int(0.8 * SR), 0.02, 0.1, 0.8, 0.1) * 0.6
thud = np.sin(sweep(120, 50, 0.2)) * env_exp(int(0.2 * SR), 0.06)
sfx("faint", mix(fl, at(thud, 0.75, 0.95)))
fu = np.sin(sweep(300, 1400, 1.0)) * adsr(int(1.0 * SR), 0.05, 0.1, 0.8, 0.3) * 0.5
sfx("float", mix(fu, highpass(noise(1.0), 6000) * 0.1 * np.linspace(0, 1, int(1.0 * SR))))
poof = lowpass(noise(0.4), 1500) * env_exp(int(0.4 * SR), 0.1)
x = mix(poof, at(np.sin(sweep(200, 900, 0.5)) * adsr(int(0.5 * SR), 0.01, 0.1, 0.7, 0.2) * 0.4, 0.1, 0.6))
for i in range(6):
    x = mix(x, at(bell(1400 + i * 260, 0.3, 0.12, 2.0, 0.6) * 0.3, 0.25 + i * 0.05, 1.0))
sfx("transform", x)
sfx("yuck", formant_voice([180, 150], [U, E], 0.6, 0.1) * adsr(int(0.6 * SR), 0.04, 0.1, 0.8, 0.2))
sfx("surprise", formant_voice([220, 320], [O, O], 0.55, 0.1) * adsr(int(0.55 * SR), 0.04, 0.1, 0.8, 0.2))
sfx("aww", formant_voice([330, 260], [A, O], 0.8, 0.12) * adsr(int(0.8 * SR), 0.05, 0.1, 0.8, 0.3))
n = int(1.8 * SR)
roll = bandpass(noise(1.8), 1500, 7000) * (0.6 + 0.4 * (np.sin(2 * np.pi * 22 * t_arr(1.8)) > 0)) * np.linspace(0.3, 1.0, n)
sfx("drumroll", mix(roll, at(highpass(noise(1.0), 3000) * env_exp(int(1.0 * SR), 0.35), 1.6, 2.6)), peak=0.7)
sfx("tick", bandpass(noise(0.05), 1500, 4000) * env_exp(int(0.05 * SR), 0.008) + tone(2200, 0.05) * env_exp(int(0.05 * SR), 0.01) * 0.5, peak=0.6)
x = highpass(noise(1.0), 4000) * env_exp(int(1.0 * SR), 0.3) * 0.6
for f in (523.25, 659.25, 783.99, 1046.5):
    x = mix(x, tone(f, 0.8, "saw") * adsr(int(0.8 * SR), 0.01, 0.15, 0.4, 0.4) * 0.25)
sfx("score_big", x)


def brass(freq, dur, vel=1.0):
    tt2 = t_arr(dur)
    out = np.zeros_like(tt2)
    bright = np.clip(tt2 / 0.06, 0, 1)
    for k in range(1, 18):
        if k * freq > SR / 2.2:
            break
        out += np.sin(2 * np.pi * freq * k * tt2) / k * np.exp(-(k - 1) * 0.35 * (1.2 - bright))
    return out * adsr(len(tt2), 0.03, 0.08, 0.8, 0.12) * vel


x = np.zeros(int(2.0 * SR))
for s, f, d in ((0.0, 523.25, 0.15), (0.16, 523.25, 0.15), (0.32, 523.25, 0.15), (0.5, 659.25, 0.3), (0.85, 783.99, 0.3), (1.2, 1046.5, 0.75)):
    x += at(brass(f, d), s, 2.0) + at(brass(f / 2, d) * 0.4, s, 2.0)
x += at(highpass(noise(0.8), 4000) * env_exp(int(0.8 * SR), 0.25) * 0.3, 1.2, 2.0)
sfx("fanfare", x)
x = np.zeros(int(2.4 * SR))
for i, (f, d) in enumerate(((392.0, 0.4), (369.99, 0.4), (349.23, 0.4), (329.63, 1.0))):
    tt3 = t_arr(d)
    vib = np.sin(2 * np.pi * 5 * tt3) * (6 if i == 3 else 2)
    ph3 = np.cumsum(f + vib) / SR * 2 * np.pi
    sig = np.zeros_like(tt3)
    for k in range(1, 12):
        sig += np.sin(ph3 * k) / k * np.exp(-(k - 1) * 0.4)
    wah = 0.6 + 0.4 * np.sin(np.linspace(0, np.pi * (1 if i < 3 else 3), len(tt3)))
    x += at(sig * wah * adsr(len(tt3), 0.03, 0.05, 0.85, 0.1), i * 0.45, 2.4)
sfx("sad_trombone", x)
x = np.zeros(int(0.7 * SR))
for i in range(5):
    x += at(bell(2000 + rng.uniform(-200, 600), 0.4, 0.12, 2.4, 0.8) * 0.5, i * 0.06, 0.7)
sfx("coins", x)
x = np.zeros(int(0.9 * SR))
for i, f in enumerate((523.25, 659.25, 783.99, 1046.5, 1318.5)):
    x += at(marimba(f, 0.4) + bell(f * 2, 0.4, 0.15, 2.0, 0.5) * 0.3, i * 0.08, 0.9)
sfx("levelup", x)
sfx("star", mix(bell(1568, 0.5, 0.2, 2.0, 0.8), at(bell(2093, 0.5, 0.2, 2.0, 0.8) * 0.7, 0.07, 0.57)))
x = mix(bell(784, 0.7, 0.3, 2.0, 1.0), at(bell(1175, 0.7, 0.3, 2.0, 1.0), 0.1, 0.8), at(bell(1568, 0.6, 0.3, 2.0, 1.0), 0.2, 0.8))
sfx("unlock", x)
sfx("page", bandpass(noise(0.25), 1500, 6000) * np.sin(np.linspace(0, np.pi, int(0.25 * SR))) ** 2, peak=0.5)
sfx("timeout", mix(tone(220, 0.6, "square") * adsr(int(0.6 * SR), 0.01, 0.05, 0.8, 0.2) * 0.5, tone(233, 0.6, "square") * adsr(int(0.6 * SR), 0.01, 0.05, 0.8, 0.2) * 0.3), peak=0.6)
sfx("steal", mix(bandpass(noise(0.35), 1000, 5000) * np.sin(np.linspace(0, np.pi, int(0.35 * SR))), at(np.sin(sweep(900, 300, 0.2)) * env_exp(int(0.2 * SR), 0.08) * 0.5, 0.15, 0.4)))
sfx("dark", mix(np.sin(sweep(220, 55, 0.9)) * adsr(int(0.9 * SR), 0.05, 0.1, 0.8, 0.3) * 0.6, lowpass(noise(0.9), 300) * env_exp(int(0.9 * SR), 0.4) * 0.5))
n = int(0.9 * SR)
fg = 400 + 300 * np.sin(np.linspace(0, 12, n)) * np.linspace(1, 0.2, n)
sfx("gravity", np.sin(np.cumsum(fg) / SR * 2 * np.pi) * adsr(n, 0.05, 0.1, 0.8, 0.3) * 0.6)
x = highpass(noise(0.9), 5000) * np.sin(np.linspace(0, np.pi, int(0.9 * SR))) * 0.3
for i, f in enumerate((1318.5, 1568.0, 1975.5, 2637.0)):
    x = mix(x, at(bell(f, 0.5, 0.25, 1.5, 0.5) * 0.4, i * 0.1, 0.9))
sfx("purify", x)
x = np.zeros(int(0.9 * SR))
for i, f in enumerate((740, 622, 523, 440, 370)):
    x += at(bell(f, 0.5, 0.2, 1.41, 1.5) * 0.5, i * 0.08, 0.9)
x += lowpass(noise(0.9), 600) * env_exp(int(0.9 * SR), 0.3) * 0.3
sfx("hex", x)
sfx("jar", mix(bell(2400, 0.3, 0.08, 1.6, 0.4), at(np.sin(sweep(300, 120, 0.15)) * env_exp(int(0.15 * SR), 0.05) * 0.6, 0.12, 0.4)))
sfx("catch", mix(np.sin(sweep(500, 1400, 0.08)) * env_exp(int(0.08 * SR), 0.03), at(bell(1760, 0.4, 0.2, 2.0, 0.8) * 0.6, 0.05, 0.45)))
sfx("escape", mix(np.sin(sweep(600, 1500, 0.35)) * adsr(int(0.35 * SR), 0.01, 0.05, 0.8, 0.1) * 0.4, bandpass(noise(0.45), 800, 3000) * np.sin(np.linspace(0, np.pi, int(0.45 * SR))) * 0.4))
sfx("cook_start", mix(lowpass(noise(0.45), 2500) * adsr(int(0.45 * SR), 0.05, 0.1, 0.6, 0.25), at(bell(880, 0.3, 0.12, 2.0, 0.6) * 0.4, 0.0, 0.45)))
sfx("serve", mix(bell(1900, 0.45, 0.12, 2.7, 0.9) * 0.7, at(bell(2600, 0.3, 0.08, 2.1, 0.5) * 0.4, 0.03, 0.45)))


# ======================================================================== MÜZİK
NOTE = {"C": 0, "C#": 1, "Db": 1, "D": 2, "D#": 3, "Eb": 3, "E": 4, "F": 5, "F#": 6, "Gb": 6, "G": 7, "G#": 8, "Ab": 8, "A": 9, "A#": 10, "Bb": 10, "B": 11}


def midi(name):
    if name[1:2] in ("#", "b"):
        p, o = name[:2], int(name[2:])
    else:
        p, o = name[:1], int(name[1:])
    return 12 * (o + 1) + NOTE[p]


def mf(m):
    return 440.0 * 2 ** ((m - 69) / 12)


def parse(seq):
    """'A4:0.5 C5:0.5 r:1 F5:1' -> [(beat, midi, dur)]"""
    out = []
    b = 0.0
    for tok in seq.split():
        nm, d = tok.split(":")
        d = float(d)
        if nm != "r":
            out.append((b, midi(nm), d))
        b += d
    return out


def kick(vel=1.0):
    n_ = int(0.28 * SR)
    click_ = pad_to(lowpass(noise(0.01), 3000) * 0.3, n_)
    return (np.sin(sweep(130, 42, 0.28)) * env_exp(n_, 0.09) + click_) * vel


def snare(vel=1.0):
    n2 = int(0.22 * SR)
    return (bandpass(noise(0.22), 1200, 7000) * env_exp(n2, 0.05) * 0.8 + np.sin(2 * np.pi * 190 * t_arr(0.22)) * env_exp(n2, 0.04) * 0.5) * vel


def hat(vel=1.0, open_=False):
    d = 0.18 if open_ else 0.05
    return highpass(noise(d), 7000) * env_exp(int(d * SR), 0.06 if open_ else 0.012) * vel * 0.5


def clap(vel=1.0):
    x2 = np.zeros(int(0.2 * SR))
    for i in range(3):
        x2 += at(bandpass(noise(0.03), 900, 5000) * env_exp(int(0.03 * SR), 0.008), i * 0.012, 0.2)
    x2 += at(bandpass(noise(0.15), 900, 5000) * env_exp(int(0.15 * SR), 0.04), 0.036, 0.2) * 0.7
    return x2 * vel


def shaker(vel=1.0):
    return bandpass(noise(0.07), 4000, 10000) * np.sin(np.linspace(0, np.pi, int(0.07 * SR))) * vel * 0.35


def taiko(vel=1.0):
    return (np.sin(sweep(95, 55, 0.5)) * env_exp(int(0.5 * SR), 0.16) + lowpass(noise(0.5), 500) * env_exp(int(0.5 * SR), 0.05) * 0.4) * vel


def pluck(freq, dur, vel=1.0, bright=0.5):
    tt4 = t_arr(dur)
    out = np.zeros_like(tt4)
    for k in range(1, 10):
        if k * freq > SR / 2.2:
            break
        out += np.sin(2 * np.pi * freq * k * tt4) / k * np.exp(-tt4 * (3 + k * (6 - bright * 4)))
    return out * vel


def bass(freq, dur, vel=1.0):
    tt5 = t_arr(dur)
    x5 = np.sin(2 * np.pi * freq * tt5) + 0.3 * np.sin(4 * np.pi * freq * tt5) + 0.12 * np.sin(6 * np.pi * freq * tt5)
    return np.tanh(x5 * 1.3) * adsr(len(tt5), 0.008, 0.08, 0.7, 0.06) * vel


def lead(freq, dur, vel=1.0, kind="square"):
    tt6 = t_arr(dur)
    vib = 1 + 0.004 * np.sin(2 * np.pi * 5.5 * tt6) * np.clip(tt6 / 0.25, 0, 1)
    ph6 = np.cumsum(freq * vib) / SR * 2 * np.pi
    out = np.zeros_like(tt6)
    step = 2 if kind == "square" else 1
    k = 1
    while k * freq < SR / 2.5 and k < 16:
        out += np.sin(ph6 * k) / k
        k += step
    return lowpass(out, 3500) * adsr(len(tt6), 0.01, 0.06, 0.65, 0.05) * vel


def pad(freqs, dur, vel=1.0):
    tt7 = t_arr(dur)
    out = np.zeros_like(tt7)
    for f in freqs:
        for det in (-0.004, 0.0, 0.004):
            ph7 = 2 * np.pi * f * (1 + det) * tt7
            for k in range(1, 7):
                out += np.sin(ph7 * k) / k / 3.0
    return lowpass(out, 1800) * adsr(len(tt7), 0.4, 0.3, 0.8, 0.5) * vel / max(1, len(freqs))


def render(bpm, bars, layers, name, tail=2.0, gain=0.9):
    beat = 60.0 / bpm
    length = bars * 4 * beat
    total = length + tail
    out = np.zeros(int(total * SR))
    for inst, events, vol in layers:
        for ev in events:
            b, m, d = ev[0], ev[1], ev[2]
            v = ev[3] if len(ev) > 3 else 1.0
            dur_s = max(0.05, d * beat)
            if inst == "drum":
                sig = m(v)
            elif inst == "pad":
                sig = pad([mf(x) for x in m], dur_s + 0.4, v)
            else:
                f = mf(m)
                if inst == "marimba":
                    sig = marimba(f, min(dur_s + 0.3, 1.2), v)
                elif inst == "glock":
                    sig = bell(f, 1.0, 0.45, 3.5, 0.8) * v * 0.5
                elif inst == "pluck":
                    sig = pluck(f, min(dur_s + 0.2, 0.9), v)
                elif inst == "bass":
                    sig = bass(f, dur_s, v)
                elif inst == "lead":
                    sig = lead(f, dur_s, v)
                elif inst == "saw":
                    sig = lead(f, dur_s, v, "saw")
                elif inst == "brass":
                    sig = brass(f, dur_s, v)
                else:
                    sig = tone(f, dur_s) * adsr(int(dur_s * SR))
            s = int(b * beat * SR)
            e = min(len(out), s + len(sig))
            out[s:e] += sig[:e - s] * vol
    n = int(length * SR)
    looped = out[:n].copy()
    looped[:len(out) - n] += out[n:]
    looped = np.tanh(looped * 1.2) / np.tanh(1.2)
    looped = level(looped, -14.5)
    sf.write(os.path.join(MUS, name + ".ogg"), looped.astype(np.float32), SR, format="OGG", subtype="VORBIS")
    print("music", name, round(length, 1), "s")


def chord_notes(root, kind):
    iv = {"maj": (0, 4, 7), "min": (0, 3, 7), "7": (0, 4, 7, 10), "m7": (0, 3, 7, 10), "maj7": (0, 4, 7, 11)}[kind]
    return [root + i for i in iv]


def drums_pattern(bars, pattern):
    """pattern: {'k': [beats in bar], 's': [...], 'h': [...], ...}"""
    ev = []
    fns = {"k": kick, "s": snare, "h": hat, "c": clap, "sh": shaker, "t": taiko, "ho": lambda v=1.0: hat(v, True)}
    for bar in range(bars):
        for key, beats in pattern.items():
            for item in beats:
                bt, vel = (item if isinstance(item, tuple) else (item, 1.0))
                ev.append((bar * 4 + bt, fns[key], 0, vel))
    return ev


# ---------------------------------------------------------- Ana menü (Fa majör, 112 BPM)
prog = [("F3", "maj"), ("C3", "maj"), ("D3", "min"), ("A#2", "maj"), ("F3", "maj"), ("C3", "maj"), ("A#2", "maj"), ("C3", "maj")] * 2
bass_ev, pad_ev, pl_ev = [], [], []
for i, (r, k) in enumerate(prog):
    root = midi(r)
    b = i * 4
    bass_ev += [(b, root - 12, 0.9, 0.9), (b + 1.5, root - 12, 0.4, 0.6), (b + 2, root - 5, 0.9, 0.8), (b + 3.5, root, 0.4, 0.6)]
    cn = chord_notes(root + 12, k)
    for j, off in enumerate((0.5, 1.5, 2.5, 3.5)):
        pl_ev.append((b + off, cn[j % len(cn)], 0.4, 0.45))
    pad_ev.append((b, cn, 4.0, 0.35))
mel1 = parse("A4:0.5 C5:0.5 F5:1 E5:0.5 D5:0.5 C5:1 G4:0.5 A4:0.5 C5:1 E5:1 r:1 F5:0.5 E5:0.5 D5:1 A4:0.5 C5:0.5 D5:1 r:1 "
             "C5:0.5 D5:0.5 F5:1 G5:1 A5:0.5 G5:0.5 F5:1 E5:1 r:0.5 G4:0.5 A#4:1 D5:1 F5:0.5 E5:0.5 C5:1 D5:0.5 E5:0.5 F5:2")
mel2 = [(b + 32, m, d) for (b, m, d) in parse("F5:0.5 A5:0.5 C6:1 A#5:0.5 A5:0.5 G5:1 E5:0.5 F5:0.5 G5:1 C6:1 r:1 A5:0.5 G5:0.5 F5:1 D5:0.5 F5:0.5 A5:1 r:1 "
                                                "G5:0.5 A5:0.5 A#5:1 D6:1 C6:0.5 A#5:0.5 A5:1 G5:1 r:0.5 D5:0.5 F5:1 A#5:1 A5:0.5 G5:0.5 E5:1 G5:0.5 E5:0.5 F5:2")]
glock = [(b, m + 12, d, 0.5) for (b, m, d) in mel2 if int(b * 2) % 4 == 0]
dr = drums_pattern(16, {"k": [0, 2, 2.5], "s": [(1, 0.6), (3, 0.6)], "sh": [(x * 0.5, 0.6 + 0.3 * (x % 2)) for x in range(8)]})
render(112, 16, [("bass", bass_ev, 0.55), ("pluck", pl_ev, 0.35), ("pad", pad_ev, 0.25), ("marimba", mel1 + mel2, 0.75),
                 ("glock", glock, 0.3), ("drum", dr, 0.45)], "menu")

# ---------------------------------------------------------- Yarışma (La minör, 132 BPM)
prog = [("A2", "min"), ("F2", "maj"), ("G2", "maj"), ("E2", "maj")] * 4
bass_ev, stab_ev, pad_ev = [], [], []
for i, (r, k) in enumerate(prog):
    root = midi(r)
    b = i * 4
    for off, oc, d in ((0, 0, 0.4), (0.75, 0, 0.2), (1.5, 12, 0.3), (2, 0, 0.4), (2.75, 0, 0.2), (3.25, 7, 0.2), (3.5, 12, 0.4)):
        bass_ev.append((b + off, root + oc, d, 0.9))
    cn = chord_notes(root + 24, k)
    for off in (0.5, 1.5, 2.5, 3.5):
        for nn in cn:
            stab_ev.append((b + off, nn, 0.2, 0.3))
    pad_ev.append((b, chord_notes(root + 12, k), 4.0, 0.25))
hook = parse("E5:0.5 E5:0.25 A5:0.75 G5:0.5 E5:0.5 D5:0.5 C5:0.5 D5:1 C5:0.5 A4:0.5 C5:0.75 D5:0.75 E5:0.5 r:2 "
             "E5:0.5 E5:0.25 A5:0.75 B5:0.5 C6:0.5 B5:0.5 G5:0.5 A5:1 G5:0.5 E5:0.5 G#5:1 B5:1 r:1")
hook2 = [(b + 32, m, d) for (b, m, d) in parse("A5:0.75 G5:0.75 E5:0.5 D5:0.5 E5:0.5 C5:1 C5:0.5 D5:0.5 E5:0.5 G5:0.5 F5:1 E5:0.5 D5:0.5 "
                                                 "E5:0.75 D5:0.75 C5:0.5 B4:0.5 C5:0.5 D5:1 E5:0.5 F5:0.5 G#5:0.5 B5:0.5 A5:2 r:2")]
lead_ev = [(b, m, d, 0.8) for (b, m, d) in hook] + [(b + 16, m, d, 0.8) for (b, m, d) in hook] + [(b, m, d, 0.8) for (b, m, d) in hook2]
dr = drums_pattern(16, {"k": [0, 1.5, 2, 3.5], "c": [(1, 0.8), (3, 0.8)], "h": [(x * 0.5, 0.5 + 0.4 * (x % 2)) for x in range(8)]})
render(132, 16, [("bass", bass_ev, 0.55), ("pluck", stab_ev, 0.3), ("pad", pad_ev, 0.2), ("lead", lead_ev, 0.32), ("drum", dr, 0.5)], "battle")

# ---------------------------------------------------------- Boss (Re minör, 140 BPM)
prog = [("D2", "min"), ("A#1", "maj"), ("C2", "maj"), ("A1", "maj")] * 4
bass_ev, ost_ev, br_ev, pad_ev = [], [], [], []
for i, (r, k) in enumerate(prog):
    root = midi(r)
    b = i * 4
    for x in range(8):
        bass_ev.append((b + x * 0.5, root + (12 if x % 4 == 3 else 0), 0.45, 0.85))
    cn = chord_notes(root + 24, k)
    for x in range(16):
        ost_ev.append((b + x * 0.25, cn[[0, 1, 2, 1][x % 4]] + (12 if x % 8 >= 4 else 0), 0.2, 0.4))
    br_ev += [(b, nn, 0.75, 0.7) for nn in chord_notes(root + 12, k)]
    br_ev += [(b + 2.5, nn, 0.5, 0.6) for nn in chord_notes(root + 12, k)]
    pad_ev.append((b, chord_notes(root + 24, k), 4.0, 0.3))
dr = drums_pattern(16, {"t": [0, 0.75, 2, 2.5], "s": [(1, 0.7), (3, 0.9)], "h": [(x * 0.5, 0.6) for x in range(8)]})
mel = parse("D5:1.5 E5:0.5 F5:1 A5:1 G5:1.5 F5:0.5 E5:2 F5:1.5 G5:0.5 A5:1 C6:1 C#6:3 r:1")
lead_ev = [(b + 16 * k, m, d, 0.7) for k in range(2) for (b, m, d) in mel] + [(b + 32 * 0 + 32 + 16 * k, m + 12 * (k == 1), d, 0.7) for k in range(2) for (b, m, d) in mel]
render(140, 16, [("bass", bass_ev, 0.5), ("pluck", ost_ev, 0.3), ("brass", br_ev, 0.3), ("pad", pad_ev, 0.2), ("saw", lead_ev, 0.25), ("drum", dr, 0.55)], "boss")

# ---------------------------------------------------------- Laboratuvar (Mi dorian, 96 BPM)
prog = [("E2", "m7"), ("A2", "7"), ("E2", "m7"), ("A2", "7"), ("C3", "maj7"), ("D3", "maj"), ("E2", "min"), ("E2", "min")] * 2
bass_ev, arp_ev, pad_ev = [], [], []
for i, (r, k) in enumerate(prog):
    root = midi(r)
    b = i * 4
    bass_ev += [(b, root, 1.4, 0.8), (b + 1.5, root + 7, 0.5, 0.6), (b + 2.5, root + 12, 1.0, 0.7), (b + 3.5, root + 10, 0.5, 0.5)]
    cn = chord_notes(root + 24, k)
    for x in range(16):
        arp_ev.append((b + x * 0.25, cn[x % len(cn)] + (12 if (x // 4) % 2 else 0), 0.2, 0.35 + 0.15 * (x % 4 == 0)))
    pad_ev.append((b, chord_notes(root + 12, k), 4.0, 0.3))
sparks = [(b * 2.0 + 0.75, midi("B5") + [0, 3, 5, 7, 10][b % 5], 0.5, 0.5) for b in range(32) if b % 3 != 2]
dr = drums_pattern(16, {"k": [0, 2.75], "sh": [(x * 0.5, 0.5 + 0.3 * (x % 2)) for x in range(8)], "s": [(3, 0.4)]})
render(96, 16, [("bass", bass_ev, 0.5), ("marimba", arp_ev, 0.45), ("pad", pad_ev, 0.3), ("glock", sparks, 0.35), ("drum", dr, 0.35)], "lab")

# ---------------------------------------------------------- Jüri (Sol majör, 100 BPM, gerilimli)
prog = [("G2", "maj"), ("E2", "min"), ("C2", "maj"), ("D2", "maj")] * 2
bass_ev, piz_ev, mel_ev = [], [], []
for i, (r, k) in enumerate(prog):
    root = midi(r)
    b = i * 4
    for x in range(4):
        bass_ev.append((b + x, root + (7 if x % 2 else 0), 0.35, 0.8))
    cn = chord_notes(root + 24, k)
    for x in range(8):
        piz_ev.append((b + x * 0.5 + 0.25, cn[x % 3], 0.2, 0.45))
mm = parse("B4:1 r:0.5 D5:0.5 C5:1 B4:0.5 A4:0.5 G4:1 r:1 E5:1 D5:1 C5:0.5 B4:0.5 A4:1 B4:0.5 C5:0.5 D5:2 F#4:1 A4:1")
mel_ev = [(b, m, d, 0.6) for (b, m, d) in mm]
dr = drums_pattern(8, {"k": [0, 2], "sh": [(x * 0.5, 0.4) for x in range(8)]})
render(100, 8, [("bass", bass_ev, 0.5), ("pluck", piz_ev, 0.45), ("lead", mel_ev, 0.22), ("drum", dr, 0.3)], "judging")
print("ok")
