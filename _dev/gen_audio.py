"""Synthesizes the game's original UI sounds and ambient music (no external samples).
Run: python3 _dev/gen_audio.py  (writes assets/audio/*.wav and music.ogg via ffmpeg)"""
import numpy as np, wave, os, subprocess

SR = 44100
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")
os.makedirs(OUT, exist_ok=True)


def env(n, a=0.005, d=0.2, curve=4.0):
    t = np.arange(n) / SR
    e = np.minimum(1.0, t / max(a, 1e-4)) * np.exp(-t * curve / max(d, 1e-3))
    return e


def tone(f, dur, amp=0.5, a=0.004, d=0.25, harm=((1, 1.0),), curve=4.0):
    n = int(dur * SR)
    t = np.arange(n) / SR
    s = sum(w * np.sin(2 * np.pi * f * h * t) for h, w in harm)
    return amp * s * env(n, a, d, curve)


def mix(*parts):
    n = max(len(p) for _, p in parts)
    out = np.zeros(n)
    for off, p in parts:
        o = int(off * SR)
        if o + len(p) > len(out):
            out = np.pad(out, (0, o + len(p) - len(out)))
        out[o:o + len(p)] += p
    return out


def write(name, x, sr=SR):
    x = x / max(1e-9, np.max(np.abs(x))) * 0.85
    fade = int(0.01 * sr)
    x[-fade:] *= np.linspace(1, 0, fade)
    with wave.open(os.path.join(OUT, name), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes((x * 32767).astype(np.int16).tobytes())


BELL = ((1, 1.0), (2.01, 0.35), (3.02, 0.12), (4.2, 0.05))
SOFT = ((1, 1.0), (2, 0.15))

# click: short glassy tick
n = int(0.06 * SR)
noise = np.random.default_rng(1).standard_normal(n) * env(n, 0.0005, 0.012, 3)
write("click.wav", tone(2400, 0.06, 0.4, 0.0008, 0.02, SOFT) + 0.15 * noise)
# page: soft airy swish
n = int(0.22 * SR)
r = np.random.default_rng(2).standard_normal(n)
from scipy.signal import butter, lfilter
b, a = butter(2, [900 / (SR / 2), 4200 / (SR / 2)], "band")
sw = lfilter(b, a, r) * np.sin(np.linspace(0, np.pi, n)) ** 2
write("page.wav", sw * 0.6 + tone(1320, 0.22, 0.05, 0.03, 0.15, SOFT))
# coin: two bright bells
write("coin.wav", mix((0, tone(1568, 0.5, 0.5, 0.002, 0.25, BELL)), (0.07, tone(2093, 0.6, 0.5, 0.002, 0.3, BELL))))
# success: rising major arpeggio
notes = [523.25, 659.25, 783.99, 1046.5]
write("success.wav", mix(*[(i * 0.085, tone(f, 0.9, 0.45, 0.003, 0.45, BELL, 3.0)) for i, f in enumerate(notes)]))
# error: two soft low tones descending
write("error.wav", mix((0, tone(392, 0.3, 0.5, 0.005, 0.18, SOFT)), (0.13, tone(311.1, 0.4, 0.5, 0.005, 0.22, SOFT))))
# week: gentle chime chord (new week)
write("week.wav", mix((0, tone(587.33, 1.2, 0.35, 0.01, 0.6, BELL, 3.0)), (0.05, tone(880, 1.2, 0.3, 0.01, 0.6, BELL, 3.0)), (0.1, tone(1174.7, 1.2, 0.25, 0.01, 0.6, BELL, 3.0))))

# ---------------------------------------------------------------- ambient music loop
MSR = 32000
bpm = 72
beat = 60.0 / bpm
bars = 16
dur = bars * 4 * beat
N = int(dur * MSR)
t = np.arange(N) / MSR
music = np.zeros(N)


def m2f(m):
    return 440.0 * 2 ** ((m - 69) / 12.0)


# Dm9 - Bbmaj7 - Fmaj7/A - C(add9), 4 bars each repeated over 16 bars
chords = [[50, 57, 60, 64, 69], [46, 53, 57, 62, 65], [45, 53, 57, 60, 64], [48, 55, 59, 62, 67]]
rng = np.random.default_rng(7)
for bi in range(bars):
    ch = chords[(bi // 2) % 4]
    start = bi * 4 * beat
    length = 2 * 4 * beat if bi % 2 == 0 else 0
    if length:
        n0 = int(start * MSR)
        nn = int((length + 1.5) * MSR)
        tt = np.arange(nn) / MSR
        pad_env = np.minimum(1, tt / 1.6) * np.minimum(1, np.maximum(0, (length + 1.5 - tt) / 1.8))
        pad = np.zeros(nn)
        for m in ch:
            f = m2f(m)
            for det in (-0.12, 0.0, 0.11):
                ff = f * 2 ** (det / 12)
                pad += np.sin(2 * np.pi * ff * tt + rng.uniform(0, 6.28)) * (0.6 if m > 52 else 0.9)
        pad *= pad_env * (0.75 + 0.25 * np.sin(2 * np.pi * 0.11 * tt))
        end = min(N, n0 + nn)
        music[n0:end] += 0.05 * pad[: end - n0]
        # wrap the tail into the beginning for a seamless loop
        if n0 + nn > N:
            music[: n0 + nn - N] += 0.05 * pad[end - n0:]
    # arpeggio: soft plucked bells, 8th notes with gaps
    arp = sorted(ch[1:]) + [ch[2] + 12]
    for k in range(8):
        if rng.random() < 0.35:
            continue
        m = arp[(k * 3 + bi) % len(arp)] + 12
        st = start + k * beat / 2
        nn = int(2.2 * MSR)
        tt = np.arange(nn) / MSR
        f = m2f(m)
        pl = (np.sin(2 * np.pi * f * tt) + 0.25 * np.sin(2 * np.pi * 2 * f * tt) + 0.06 * np.sin(2 * np.pi * 3.01 * f * tt)) * np.exp(-tt * 2.6) * np.minimum(1, tt / 0.004)
        n0 = int(st * MSR)
        end = min(N, n0 + nn)
        music[n0:end] += 0.06 * pl[: end - n0] * rng.uniform(0.6, 1.0)
        if n0 + nn > N:
            music[: n0 + nn - N] += 0.06 * pl[end - n0:]
    # deep bass on the first beat
    if bi % 2 == 0:
        nn = int(4 * 4 * beat * MSR / 2)
        tt = np.arange(nn) / MSR
        f = m2f(ch[0] - 12)
        bs = np.sin(2 * np.pi * f * tt) * np.minimum(1, tt / 0.3) * np.exp(-tt * 0.25)
        n0 = int(start * MSR)
        end = min(N, n0 + nn)
        music[n0:end] += 0.09 * bs[: end - n0]

# simple stereo-less reverb: multi-tap feedback delays (circular so the loop stays seamless)
wet = np.zeros(N)
for d, g in ((0.113, 0.45), (0.171, 0.38), (0.237, 0.32), (0.331, 0.27), (0.457, 0.2)):
    s = int(d * MSR)
    acc = music.copy()
    for rep in range(6):
        acc = np.roll(acc, s) * g
        wet += acc
b, a = butter(1, 3500 / (MSR / 2), "low")
wet = lfilter(b, a, wet)
music = music + 0.55 * wet
music = music / np.max(np.abs(music)) * 0.8
tmp = os.path.join(OUT, "_music_tmp.wav")
with wave.open(tmp, "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(MSR)
    w.writeframes((music * 32767).astype(np.int16).tobytes())
subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", tmp, "-c:a", "libvorbis", "-q:a", "3", os.path.join(OUT, "music.ogg")], check=True)
os.remove(tmp)
print("audio written, music %.1fs" % dur)
