#!/usr/bin/env python3
"""SULTAN: Hanedanın Kaderi — özgün sentezlenmiş ses efektleri ve Hicaz makamında tema müziği.
Tüm sesler bu betikle sıfırdan üretilir; hiçbir kayıt kullanılmaz."""
import os, sys, math
import numpy as np
import soundfile as sf

OUT = sys.argv[1]
os.makedirs(OUT, exist_ok=True)
rng = np.random.default_rng(1071)


def write(name, data, sr, subtype="VORBIS"):
    data = np.asarray(data, dtype=np.float32)
    peak = np.max(np.abs(data)) + 1e-9
    data = data / peak * 0.92
    sf.write(os.path.join(OUT, name + ".ogg"), data, sr, format="OGG", subtype=subtype)
    print("wrote", name, data.shape, sr)


def env_ad(n, sr, a, d, curve=4.0):
    t = np.arange(n) / sr
    e = np.where(t < a, t / max(a, 1e-6), np.exp(-(t - a) * curve / max(d, 1e-6)))
    return e


def lowpass(x, sr, cutoff):
    X = np.fft.rfft(x)
    f = np.fft.rfftfreq(len(x), 1 / sr)
    X *= 1.0 / (1.0 + (f / cutoff) ** 4)
    return np.fft.irfft(X, len(x))


def bandpass(x, sr, lo, hi):
    X = np.fft.rfft(x)
    f = np.fft.rfftfreq(len(x), 1 / sr)
    g = (1.0 / (1.0 + (lo / np.maximum(f, 1)) ** 4)) * (1.0 / (1.0 + (f / hi) ** 4))
    X *= g
    return np.fft.irfft(X, len(x))


def seamless(x, sr, fade=0.5):
    """Döngü sınırında yumuşak geçiş (kuyruğu başa katlar)."""
    n = int(fade * sr)
    head = x[:n].copy()
    tail = x[-n:].copy()
    w = np.linspace(0, 1, n)
    x = x[:-n].copy()
    x[:n] = head * w + tail * (1 - w)
    return x


# ------------------------------------------------------------ UI sesleri
SR = 32000
n = int(0.07 * SR)
t = np.arange(n) / SR
click = np.sin(2 * np.pi * 1650 * t) * env_ad(n, SR, 0.002, 0.04, 6) * 0.6
click += lowpass(rng.normal(size=n), SR, 3000) * env_ad(n, SR, 0.001, 0.01, 8) * 0.4
write("click", click, SR)


def bell(freq, dur, sr=SR, bright=1.0):
    n = int(dur * sr)
    t = np.arange(n) / sr
    out = np.zeros(n)
    for ratio, amp, dec in [(1.0, 1.0, 1.2), (2.01, 0.5 * bright, 2.0), (2.76, 0.28 * bright, 2.8), (4.07, 0.15 * bright, 4.0), (5.4, 0.08 * bright, 5.5)]:
        out += amp * np.sin(2 * np.pi * freq * ratio * t) * np.exp(-t * dec / dur * 2.5)
    out *= np.minimum(1, t / 0.004)
    return out


def seq(notes, sr=SR, total=None):
    end = max(o + d for o, f, d, a in notes)
    n = int((total or end + 0.2) * sr)
    out = np.zeros(n)
    for o, f, d, a in notes:
        b = bell(f, d, sr) * a
        i = int(o * sr)
        out[i:i + len(b)] += b[:max(0, n - i)]
    return out


write("notify", seq([(0, 659.25, 0.9, 0.7), (0.12, 880.0, 1.0, 0.6)]), SR)
write("chime", seq([(0, 587.33, 0.7, 0.5), (0.08, 739.99, 0.7, 0.5), (0.16, 880.0, 0.9, 0.6)]), SR)
write("low", seq([(0, 293.66, 0.7, 0.6), (0.14, 261.63, 0.9, 0.5)]), SR)
n = int(0.32 * SR)
sweep = bandpass(rng.normal(size=n), SR, 500, 2400) * np.sin(np.linspace(0, np.pi, n)) ** 2 * 0.35
op = sweep + np.pad(bell(1174.66, 0.3, SR, 0.6), (int(0.05 * SR), 0))[:n] * 0.25
write("open", op, SR)
write("close", sweep[::-1] * 0.8 + np.pad(bell(880.0, 0.25, SR, 0.5), (0, n))[:n] * 0.2, SR)

# ayak sesi (taş)
SR2 = 22050
n = int(0.12 * SR2)
step = lowpass(rng.normal(size=n), SR2, 900) * env_ad(n, SR2, 0.003, 0.05, 5) * 0.8
step += np.sin(2 * np.pi * 90 * np.arange(n) / SR2) * env_ad(n, SR2, 0.002, 0.04, 6) * 0.5
write("step_stone", step, SR2)

# ------------------------------------------------------------ ortam döngüleri
# çeşme
dur = 9.0
n = int(dur * SR2)
water = bandpass(rng.normal(size=n), SR2, 300, 4500) * 0.5
water *= 0.8 + 0.2 * np.sin(2 * np.pi * 0.37 * np.arange(n) / SR2)
for i in range(260):
    pos = rng.integers(0, n - 2000)
    f = rng.uniform(600, 2200)
    m = 1200
    tt = np.arange(m) / SR2
    drop = np.sin(2 * np.pi * (f + 900 * tt / tt[-1]) * tt) * np.exp(-tt * 70) * rng.uniform(0.05, 0.22)
    water[pos:pos + m] += drop
write("fountain", seamless(water, SR2), SR2)

# kuşlar
dur = 14.0
n = int(dur * SR2)
wind = lowpass(rng.normal(size=n), SR2, 400) * 0.08
birds = wind.copy()
for i in range(55):
    pos = rng.integers(0, n - 8000)
    count = rng.integers(1, 5)
    base = rng.uniform(2600, 5200)
    for k in range(count):
        m = int(rng.uniform(0.05, 0.14) * SR2)
        tt = np.arange(m) / SR2
        fm = base * (1 + 0.25 * np.sin(2 * np.pi * rng.uniform(10, 30) * tt)) * (1 + rng.uniform(-0.3, 0.3) * tt / tt[-1])
        ph = 2 * np.pi * np.cumsum(fm) / SR2
        chirp = np.sin(ph) * np.sin(np.pi * tt / tt[-1]) ** 2 * rng.uniform(0.08, 0.25)
        p2 = pos + k * int(0.09 * SR2)
        if p2 + m < n:
            birds[p2:p2 + m] += chirp
write("birds", seamless(birds, SR2), SR2)

# mutfak
dur = 9.0
n = int(dur * SR2)
k = lowpass(rng.normal(size=n), SR2, 250) * 0.15
for i in range(380):
    pos = rng.integers(0, n - 3000)
    m = int(rng.uniform(0.01, 0.04) * SR2)
    tt = np.arange(m) / SR2
    f = rng.uniform(120, 420)
    k[pos:pos + m] += np.sin(2 * np.pi * f * tt) * np.exp(-tt * 90) * rng.uniform(0.05, 0.25)
for i in range(900):
    pos = rng.integers(0, n - 50)
    k[pos:pos + 30] += rng.normal(size=30) * np.exp(-np.arange(30) / 6) * 0.08
for i in range(5):
    pos = rng.integers(0, n - 12000)
    m = 11000
    tt = np.arange(m) / SR2
    clank = sum(np.sin(2 * np.pi * f * tt) * np.exp(-tt * d) for f, d in [(1320, 9), (2170, 12), (3480, 16)]) * 0.12
    k[pos:pos + m] += clank
write("kitchen", seamless(k, SR2), SR2)

# saray içi oda tonu ve uzak mırıltı
dur = 16.0
n = int(dur * SR2)
brown = np.cumsum(rng.normal(size=n))
brown -= np.linspace(brown[0], brown[-1], n)
brown = lowpass(brown, SR2, 180)
brown /= np.max(np.abs(brown))
murmur = bandpass(rng.normal(size=n), SR2, 250, 900)
mod = lowpass(rng.normal(size=n), SR2, 3)
mod = np.clip(mod / np.max(np.abs(mod)) * 1.5, 0, 1)
amb = brown * 0.35 + murmur * mod * 0.12
write("palace_amb", seamless(amb, SR2, 1.0), SR2)

# açık hava rüzgârı
wind2 = lowpass(rng.normal(size=n), SR2, 600)
wmod = lowpass(rng.normal(size=n), SR2, 0.5)
wmod = 0.5 + 0.5 * wmod / np.max(np.abs(wmod))
write("outdoor_amb", seamless(wind2 * wmod * 0.5, SR2, 1.0), SR2)

# ------------------------------------------------------------ tema müziği (Hicaz)
MSR = 32000
BPM = 80.0
beat = 60.0 / BPM
D4 = 293.66
cents = {"D": 0, "Eb": 90, "F#": 380, "G": 498, "A": 702, "Bb": 792, "C": 996}


def hz(name, octv=4):
    base = D4 * (2 ** (octv - 4))
    return base * 2 ** (cents[name] / 1200.0)


# melodi: (nota, oktav, vuruş)
A1 = [("A", 4, 1), ("Bb", 4, .5), ("A", 4, .5), ("G", 4, 1), ("F#", 4, 1),
      ("G", 4, .5), ("A", 4, .5), ("F#", 4, 1), ("Eb", 4, 1), ("D", 4, 1),
      ("D", 4, .5), ("Eb", 4, .5), ("F#", 4, 1), ("G", 4, 1), ("A", 4, 1),
      ("Bb", 4, 1), ("A", 4, 1), ("G", 4, .5), ("F#", 4, .5), ("G", 4, 1)]
A2 = [("A", 4, 1), ("C", 5, .5), ("Bb", 4, .5), ("A", 4, 1), ("G", 4, 1),
      ("F#", 4, .5), ("G", 4, .5), ("A", 4, 1), ("G", 4, .5), ("F#", 4, .5), ("Eb", 4, 1),
      ("F#", 4, 1), ("Eb", 4, .5), ("D", 4, .5), ("Eb", 4, 1), ("F#", 4, 1),
      ("D", 4, 3), ("R", 4, 1)]
B1 = [("D", 5, 1), ("C", 5, .5), ("D", 5, .5), ("Eb", 5, 1), ("D", 5, 1),
      ("C", 5, .5), ("Bb", 4, .5), ("C", 5, 1), ("A", 4, 2),
      ("Bb", 4, .5), ("C", 5, .5), ("D", 5, 1), ("C", 5, .5), ("Bb", 4, .5), ("A", 4, 1),
      ("G", 4, 1), ("A", 4, 1), ("Bb", 4, .5), ("A", 4, .5), ("G", 4, 1)]
B2 = [("F#", 4, 1), ("G", 4, .5), ("A", 4, .5), ("Bb", 4, 1), ("A", 4, 1),
      ("G", 4, .5), ("F#", 4, .5), ("Eb", 4, 1), ("F#", 4, 2),
      ("G", 4, 1), ("F#", 4, .5), ("Eb", 4, .5), ("D", 4, 1), ("Eb", 4, 1),
      ("D", 4, 3), ("R", 4, 1)]
melody = A1 + A2 + B1 + B2
total_beats = sum(b for _, _, b in melody)
bars = int(math.ceil(total_beats / 4))
total_beats = bars * 4
L = total_beats * beat
N = int((L + 3.0) * MSR)
left = np.zeros(N)
right = np.zeros(N)


def add(sig, start, pan=0.0, gain=1.0):
    i = int(start * MSR)
    j = min(N, i + len(sig))
    lg = math.cos((pan + 1) * math.pi / 4) * gain
    rg = math.sin((pan + 1) * math.pi / 4) * gain
    left[i:j] += sig[:j - i] * lg
    right[i:j] += sig[:j - i] * rg


# ney: sürekli faz, vibrato, nefes
freq = np.zeros(N)
amp = np.zeros(N)
tpos = 0.0
for name, octv, b in melody:
    d = b * beat
    i = int(tpos * MSR)
    j = int((tpos + d) * MSR)
    if name != "R":
        f = hz(name, octv)
        freq[i:j] = f
        m = j - i
        tt = np.arange(m) / MSR
        a = np.minimum(1, tt / 0.07) * np.minimum(1, (d - tt) / 0.09)
        amp[i:j] = np.maximum(amp[i:j], np.clip(a, 0, 1))
    tpos += d
# boşlukları önceki frekansla doldur (portamento)
last = hz("D")
for k in range(N):
    if freq[k] == 0:
        freq[k] = last
    else:
        last = freq[k]
freq = lowpass(freq, MSR, 18)
tt = np.arange(N) / MSR
vib = 1 + 0.006 * np.sin(2 * np.pi * 5.2 * tt) * np.clip(amp * 1.5 - 0.3, 0, 1)
ph = 2 * np.pi * np.cumsum(freq * vib) / MSR
ney = np.sin(ph) + 0.18 * np.sin(2 * ph) + 0.08 * np.sin(3 * ph)
breath = bandpass(rng.normal(size=N), MSR, 800, 3500) * 0.22
ney = (ney * 0.8 + breath) * lowpass(amp, MSR, 30)
add(ney, 0.0, 0.0, 0.55)


def pluck(f, dur, bright=1.0, decay=1.0):
    n = int(dur * MSR)
    t = np.arange(n) / MSR
    s = np.zeros(n)
    for h in range(1, 12):
        inh = 1 + 0.0006 * h * h
        s += (1.0 / h ** 1.15) * (bright ** (h - 1)) * np.sin(2 * np.pi * f * h * inh * t) * np.exp(-t * (1.6 + h * 0.9) * decay)
    s += lowpass(rng.normal(size=n), MSR, 2500) * np.exp(-t * 60) * 0.25
    s *= np.minimum(1, t / 0.002)
    return s


# ud: her ölçünün başında dem (D-A) ve melodiye seyrek eşlik
for bar in range(bars):
    t0 = bar * 4 * beat
    root = "D" if bar % 4 != 2 else "G"
    add(pluck(hz(root, 2), 2.2, 0.75), t0, -0.45, 0.32)
    add(pluck(hz("A" if root == "D" else "D", 3), 1.6, 0.75), t0 + 2 * beat, -0.45, 0.22)
tpos = 0.0
for idx, (name, octv, b) in enumerate(melody):
    if name != "R" and idx % 3 == 0:
        add(pluck(hz(name, octv - 1), max(b * beat * 1.6, 0.6), 0.8), tpos, -0.35, 0.18)
    tpos += b * beat
# kanun: B bölümünde süslemeler
tpos = 0.0
for idx, (name, octv, b) in enumerate(melody):
    if name != "R" and idx >= len(A1) + len(A2) and idx % 2 == 0:
        add(pluck(hz(name, octv + 1), 0.5, 0.55, 2.2), tpos, 0.5, 0.12)
        add(pluck(hz(name, octv + 1), 0.4, 0.55, 2.4), tpos + 0.08, 0.5, 0.07)
    tpos += b * beat


# def / kudüm (sofyan usulü: düm - tek ke)
def dum():
    n = int(0.45 * MSR)
    t = np.arange(n) / MSR
    f = 55 + 70 * np.exp(-t * 30)
    s = np.sin(2 * np.pi * np.cumsum(f) / MSR) * np.exp(-t * 7)
    s += lowpass(rng.normal(size=n), MSR, 700) * np.exp(-t * 40) * 0.3
    return s


def tek(soft=1.0):
    n = int(0.15 * MSR)
    t = np.arange(n) / MSR
    s = bandpass(rng.normal(size=n), MSR, 1200, 5000) * np.exp(-t * 45) * 0.7
    s += np.sin(2 * np.pi * 330 * t) * np.exp(-t * 40) * 0.4
    return s * soft


for bar in range(bars):
    t0 = bar * 4 * beat
    add(dum(), t0, 0.0, 0.5)
    add(tek(1.0), t0 + 2 * beat, 0.1, 0.32)
    add(tek(0.6), t0 + 3 * beat, -0.1, 0.25)
    if bar % 4 == 3:
        add(tek(0.5), t0 + 3.5 * beat, 0.0, 0.2)

# yankı (sentetik oda yankısı) ve döngü katlama
ir_len = int(2.4 * MSR)
ir_t = np.arange(ir_len) / MSR
ir = rng.normal(size=ir_len) * np.exp(-ir_t * 2.6)
ir[:int(0.012 * MSR)] = 0
ir /= np.sqrt(np.sum(ir ** 2))
def conv(x):
    m = len(x) + len(ir)
    X = np.fft.rfft(x, m)
    H = np.fft.rfft(ir, m)
    return np.fft.irfft(X * H, m)[:len(x)]
wetL = conv(left)
wetR = conv(right)
outL = left * 0.8 + wetL * 0.25
outR = right * 0.8 + wetR * 0.25
loopN = int(L * MSR)
outL[:N - loopN] += outL[loopN:N]
outR[:N - loopN] += outR[loopN:N]
outL = outL[:loopN]
outR = outR[:loopN]
mix = np.stack([outL, outR], axis=1)
mix = np.tanh(mix / (np.max(np.abs(mix)) + 1e-9) * 1.4) / np.tanh(1.4)
write("theme", mix * 0.85, MSR)
print("theme length", L, "s")
