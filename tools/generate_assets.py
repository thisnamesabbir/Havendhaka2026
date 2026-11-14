#!/usr/bin/env python3
"""Generate original procedural textures, music, SFX and fonts for Haven Dhaka 2026."""
from __future__ import annotations

import math
import shutil
import wave
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets"
TEX = ASSETS / "generated"
AUDIO = ASSETS / "audio"
FONTS = ASSETS / "fonts"
for folder in (TEX, AUDIO, FONTS):
    folder.mkdir(parents=True, exist_ok=True)

rng = np.random.default_rng(20260714)


# ---------------------------------------------------------------------------
# Textures
# ---------------------------------------------------------------------------

def periodic_noise(size: int, frequencies: list[tuple[int, int, float]]) -> np.ndarray:
    y, x = np.mgrid[0:size, 0:size].astype(np.float32)
    out = np.zeros((size, size), dtype=np.float32)
    for fx, fy, amp in frequencies:
        phase = rng.uniform(0.0, math.tau)
        out += amp * np.sin(math.tau * (fx * x + fy * y) / size + phase)
    return out


def make_sand_tile() -> None:
    size = 512
    y, x = np.mgrid[0:size, 0:size].astype(np.float32)
    noise = periodic_noise(size, [
        (2, 3, 4.0), (5, 2, 3.0), (7, 9, 1.6), (13, 11, 0.9), (23, 19, 0.5),
    ])
    flow = np.sin(math.tau * (6 * x + 1.2 * np.sin(math.tau * 2 * y / size)) / size)
    fine = rng.normal(0.0, 2.4, (size, size))
    grain = rng.integers(-3, 4, (size, size))
    value = 232.0 + noise * 1.9 + flow * 3.4 + fine + grain
    # Fine wind ripples: small bright crests and shadowed troughs.
    crest = np.clip(np.sin(math.tau * (17 * x + 3 * y) / size), 0.0, 1.0) ** 18
    value += crest * 9.0
    value = np.clip(value, 0, 255)
    rgba = np.empty((size, size, 4), dtype=np.uint8)
    rgba[..., 0] = np.clip(value * 1.0, 0, 255).astype(np.uint8)
    rgba[..., 1] = np.clip(value * 0.975, 0, 255).astype(np.uint8)
    rgba[..., 2] = np.clip(value * 0.935, 0, 255).astype(np.uint8)
    rgba[..., 3] = 255
    Image.fromarray(rgba, "RGBA").save(TEX / "sand_tile.png", optimize=True)

    # Transparent sand ripple overlay with long horizontal strokes.
    overlay = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
    d = ImageDraw.Draw(overlay)
    for i in range(90):
        px = rng.integers(0, 512)
        py = rng.integers(0, 512)
        length = rng.integers(18, 90)
        alpha = rng.integers(6, 22)
        d.line((px, py, px + length, py + rng.integers(-3, 4)),
               fill=(255, 240, 214, int(alpha)), width=1)
    overlay = overlay.filter(ImageFilter.GaussianBlur(0.35))
    overlay.save(TEX / "sand_ripples.png", optimize=True)


def make_clouds() -> None:
    w, h = 1280, 360
    alpha = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(alpha)
    for i in range(26):
        cx = rng.integers(80, w - 80)
        cy = rng.integers(int(h * 0.35), int(h * 0.78))
        rx = rng.integers(80, 250)
        ry = rng.integers(22, 82)
        d.ellipse((cx - rx, cy - ry, cx + rx, cy + ry), fill=int(rng.integers(30, 100)))
    alpha = alpha.filter(ImageFilter.GaussianBlur(34))
    arr = np.zeros((h, w, 4), dtype=np.uint8)
    arr[..., :3] = 255
    arr[..., 3] = np.array(alpha, dtype=np.uint8)
    Image.fromarray(arr, "RGBA").save(TEX / "cloud_soft.png", optimize=True)


def make_glow() -> None:
    size = 512
    y, x = np.mgrid[0:size, 0:size].astype(np.float32)
    cx = cy = (size - 1) / 2.0
    r = np.sqrt((x - cx) ** 2 + (y - cy) ** 2) / (size / 2.0)
    alpha = np.clip(1.0 - r, 0.0, 1.0) ** 2.4
    arr = np.zeros((size, size, 4), dtype=np.uint8)
    arr[..., :3] = 255
    arr[..., 3] = (alpha * 255).astype(np.uint8)
    Image.fromarray(arr, "RGBA").save(TEX / "glow.png", optimize=True)

    # Very soft, wide halo for large suns.
    halo = np.clip(1.0 - r, 0.0, 1.0) ** 1.25
    arr[..., 3] = (halo * 150).astype(np.uint8)
    Image.fromarray(arr, "RGBA").save(TEX / "halo.png", optimize=True)


def make_dust() -> None:
    size = 64
    y, x = np.mgrid[0:size, 0:size].astype(np.float32)
    cx = cy = (size - 1) / 2.0
    r = np.sqrt((x - cx) ** 2 + (y - cy) ** 2) / (size / 2.0)
    alpha = np.clip(1.0 - r, 0.0, 1.0) ** 1.6
    arr = np.zeros((size, size, 4), dtype=np.uint8)
    arr[..., :3] = 255
    arr[..., 3] = (alpha * 255).astype(np.uint8)
    Image.fromarray(arr, "RGBA").save(TEX / "dust.png", optimize=True)

    # Little golden four-point sparkle used for pickups.
    s = 96
    img = Image.new("RGBA", (s * 4, s * 4), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    c = s * 2
    d.polygon([(c, 10), (c + 14, c - 14), (c, c + 14), (c - 14, c - 14)], fill=(255, 247, 214, 255))
    d.polygon([(10, c), (c - 14, c - 14), (c + 14, c), (c - 14, c + 14)], fill=(255, 247, 214, 255))
    img = img.resize((s, s), Image.Resampling.LANCZOS)
    img.save(TEX / "sparkle.png", optimize=True)


def make_grain() -> None:
    size = 256
    noise = rng.integers(0, 255, (size, size, 3), dtype=np.uint8)
    alpha = rng.integers(4, 18, (size, size, 1), dtype=np.uint8)
    arr = np.concatenate([noise, alpha], axis=2)
    Image.fromarray(arr, "RGBA").save(TEX / "grain.png", optimize=True)


def make_icon() -> None:
    size = 512
    ss = 4
    img = Image.new("RGBA", (size * ss, size * ss), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Sky disc.
    for i in range(size * ss, 0, -4):
        t = i / (size * ss)
        col = (int(28 + 60 * t), int(24 + 45 * t), int(60 + 30 * (1 - t)), 255)
        d.ellipse((size * ss / 2 - i / 2, size * ss / 2 - i / 2,
                   size * ss / 2 + i / 2, size * ss / 2 + i / 2), fill=col)
    d.rectangle((0, 0, size * ss, size * ss), fill=None)
    # Sun.
    d.ellipse((150 * ss, 160 * ss, 360 * ss, 370 * ss), fill=(255, 183, 99, 255))
    d.ellipse((190 * ss, 200 * ss, 320 * ss, 330 * ss), fill=(255, 224, 160, 255))
    # Dunes.
    d.polygon([(0, 300 * ss), (140 * ss, 250 * ss), (280 * ss, 330 * ss),
               (420 * ss, 265 * ss), (512 * ss, 320 * ss), (512 * ss, 512 * ss), (0, 512 * ss)],
              fill=(160, 84, 68, 255))
    d.polygon([(0, 360 * ss), (170 * ss, 300 * ss), (330 * ss, 390 * ss),
               (512 * ss, 330 * ss), (512 * ss, 512 * ss), (0, 512 * ss)],
              fill=(96, 48, 52, 255))
    # Rider silhouette on a tiny board.
    d.line((240 * ss, 330 * ss, 310 * ss, 315 * ss), fill=(30, 20, 28, 255), width=7 * ss)
    d.ellipse((278 * ss, 255 * ss, 300 * ss, 277 * ss), fill=(30, 20, 28, 255))
    d.polygon([(280 * ss, 279 * ss), (300 * ss, 288 * ss), (288 * ss, 316 * ss),
               (265 * ss, 312 * ss), (264 * ss, 290 * ss)], fill=(210, 92, 66, 255))
    d.line((281 * ss, 287 * ss, 260 * ss, 303 * ss), fill=(30, 20, 28, 255), width=5 * ss)
    d.line((292 * ss, 292 * ss, 318 * ss, 300 * ss), fill=(30, 20, 28, 255), width=5 * ss)
    d.line((278 * ss, 314 * ss, 270 * ss, 329 * ss), fill=(30, 20, 28, 255), width=6 * ss)
    d.line((293 * ss, 315 * ss, 306 * ss, 329 * ss), fill=(30, 20, 28, 255), width=6 * ss)
    d.arc((260 * ss, 280 * ss, 305 * ss, 330 * ss), 210, 330, fill=(255, 207, 144, 255), width=3 * ss)
    img = img.resize((size, size), Image.Resampling.LANCZOS)
    img.save(ROOT / "icon.png", optimize=True)


# ---------------------------------------------------------------------------
# Audio synthesis
# ---------------------------------------------------------------------------

SR = 22050


def env_adsr(n: int, attack: float, decay: float, sustain: float, release: float) -> np.ndarray:
    a = max(1, int(attack * SR))
    d = max(1, int(decay * SR))
    r = max(1, int(release * SR))
    s = max(0, n - a - d - r)
    arr = np.concatenate([
        np.linspace(0, 1, a, endpoint=False) ** 1.5,
        np.linspace(1, sustain, d, endpoint=False),
        np.full(s, sustain),
        np.linspace(sustain, 0, r),
    ])
    if len(arr) < n:
        arr = np.pad(arr, (0, n - len(arr)))
    return arr[:n].astype(np.float32)


def add_note(buf: np.ndarray, t0: float, dur: float, freq: float, amp: float,
             timbre: str = "pluck", pan: float = 0.0) -> None:
    start = int(t0 * SR)
    n = min(int(dur * SR), len(buf) - start)
    if n <= 0:
        return
    t = np.arange(n, dtype=np.float32) / SR
    if timbre == "pluck":
        # Karplus-style plucked string using layered decaying harmonics.
        sig = np.zeros(n, dtype=np.float32)
        for h, ha in [(1, 1.0), (2, 0.42), (3, 0.2), (4, 0.1), (5, 0.05)]:
            sig += ha * np.sin(math.tau * freq * h * t + rng.uniform(0, 0.2))
        sig *= np.exp(-t * 2.6)
        sig += 0.06 * rng.normal(0, 1, n) * np.exp(-t * 20.0)
        env = env_adsr(n, 0.005, 0.06, 0.72, min(0.4, dur * 0.4))
    elif timbre == "bell":
        sig = np.zeros(n, dtype=np.float32)
        for h, ha, dec in [(1, 1.0, 1.2), (2.01, 0.45, 2.0), (3.02, 0.2, 3.2), (4.1, 0.08, 4.5)]:
            sig += ha * np.sin(math.tau * freq * h * t) * np.exp(-t * dec)
        env = env_adsr(n, 0.003, 0.02, 1.0, dur * 0.6)
    elif timbre == "flute":
        vibrato = 1.0 + 0.004 * np.sin(math.tau * 5.1 * t)
        sig = np.sin(math.tau * freq * vibrato * t)
        sig += 0.2 * np.sin(math.tau * freq * 2 * t) + 0.05 * np.sin(math.tau * freq * 3 * t)
        sig += 0.035 * rng.normal(0, 1, n) * (0.5 + 0.5 * np.sin(math.tau * 3 * t))
        env = env_adsr(n, 0.09, 0.2, 0.65, min(0.8, dur * 0.55))
    elif timbre == "bass":
        sig = np.sin(math.tau * freq * t) + 0.18 * np.sin(math.tau * freq * 2 * t)
        sig *= np.exp(-t * 0.3)
        env = env_adsr(n, 0.03, 0.25, 0.6, min(1.4, dur * 0.6))
    else:  # pad
        sig = np.zeros(n, dtype=np.float32)
        for det, ha in [(-0.004, 0.5), (0.0, 0.7), (0.0035, 0.4), (0.006, 0.22)]:
            sig += ha * np.sin(math.tau * freq * (1 + det) * t)
            sig += 0.18 * ha * np.sin(math.tau * freq * 2 * (1 + det) * t + 0.7)
        sig *= 0.8
        env = env_adsr(n, min(2.0, dur * 0.35), 0.4, 0.65, min(2.6, dur * 0.5))
    # Stereo spread.
    left = np.cos((pan + 1.0) * math.pi / 4.0)
    right = np.sin((pan + 1.0) * math.pi / 4.0)
    buf[start:start + n, 0] += sig * env * amp * left
    buf[start:start + n, 1] += sig * env * amp * right


def reverb_stereo(x: np.ndarray, decay: float = 2.6, wet: float = 0.32) -> np.ndarray:
    n = x.shape[0]
    ir_n = int(decay * SR)
    t = np.arange(ir_n, dtype=np.float32) / SR
    ir = rng.normal(0, 1, (ir_n, 2)).astype(np.float32)
    ir *= np.exp(-t / (decay / 3.0))[:, None]
    # Soften highs with a moving-average lowpass.
    kernel = np.ones(18, dtype=np.float32) / 18
    for ch in range(2):
        ir[:, ch] = np.convolve(ir[:, ch], kernel, mode="same")
    ir /= np.max(np.abs(ir)) + 1e-6
    out = np.zeros_like(x)
    fft_n = 1 << (n + ir_n - 1).bit_length()
    for ch in range(2):
        y = np.fft.irfft(np.fft.rfft(x[:, ch], fft_n) * np.fft.rfft(ir[:, ch], fft_n), fft_n)[:n]
        out[:, ch] = y
    return x * (1.0 - wet) + out * wet * 0.9


def loop_crossfade(x: np.ndarray, seconds: float = 1.0) -> np.ndarray:
    n = int(seconds * SR)
    head = x[:n].copy()
    x = x.copy()
    fade = np.linspace(0, 1, n, dtype=np.float32)[:, None]
    x[-n:] = x[-n:] * (1 - fade) + head * fade
    return x[:-1] if False else x


def normalize(x: np.ndarray, peak: float = 0.82) -> np.ndarray:
    m = np.max(np.abs(x))
    if m > 0:
        x = x / m * peak
    return x


def write_wav(path: Path, stereo: np.ndarray, sr: int = SR) -> None:
    data = np.clip(stereo, -1, 1)
    pcm = (data * 32767).astype(np.int16)
    with wave.open(str(path), "wb") as f:
        f.setnchannels(2)
        f.setsampwidth(2)
        f.setframerate(sr)
        f.writeframes(pcm.tobytes())
    print(f"wrote {path.name} ({path.stat().st_size / 1024:.0f} KiB)")


def make_music() -> None:
    dur = 17.0
    n = int(dur * SR)
    t = np.arange(n, dtype=np.float32) / SR

    def pad_chord(buf: np.ndarray, start: float, length: float, freqs: list[float], amp: float) -> None:
        for i, f in enumerate(freqs):
            add_note(buf, start, length, f, amp / max(1.0, len(freqs) * 0.7),
                     "pad", pan=(-0.35 + i * 0.23))

    # ---- Day / dawn: warm, wide, gently optimistic.
    day = np.zeros((n, 2), dtype=np.float32)
    chords_day = [[146.83, 220.0, 293.66, 369.99], [123.47, 185.0, 293.66, 349.23],
                  [98.0, 196.0, 246.94, 329.63], [110.0, 220.0, 277.18, 329.63]]
    for i, chord in enumerate(chords_day):
        pad_chord(day, i * 4.0, 5.5, chord, 0.25)
    add_note(day, 0, 17, 73.42, 0.2, "bass", -0.2)
    add_note(day, 8.5, 8.5, 55.0, 0.16, "bass", 0.15)
    scale = [293.66, 329.63, 369.99, 440.0, 493.88, 587.33, 659.25, 739.99]
    pattern = [0, 2, 4, 6, 4, 2, 1, 3, 5, 3, 2, 4, 6, 7, 5, 3]
    for i in range(56):
        note = scale[pattern[i % len(pattern)]]
        if i % 8 == 7:
            note *= 2
        add_note(day, i * 0.31 + 0.2, 1.4, note, 0.10, "pluck", -0.55 + (i % 3) * 0.45)
    for i in range(34):
        add_note(day, 0.4 + i * 0.5, 0.35, 196.0 + (i % 4) * 49.0, 0.025, "pluck", 0.0)
    # soft shaker
    for i in range(0, 34):
        start = int(i * 0.5 * SR)
        nn = min(int(0.045 * SR), n - start)
        if nn > 0:
            noise = rng.normal(0, 1, nn).astype(np.float32)
            noise *= np.linspace(1, 0, nn) ** 2
            day[start:start + nn, 0] += noise * 0.025
            day[start:start + nn, 1] += noise * 0.025
    day = reverb_stereo(day, 2.8, 0.35)
    day = loop_crossfade(day, 1.2)
    write_wav(AUDIO / "music_dawn.wav", normalize(day, 0.72))

    # ---- Dusk / ruins: low, mysterious, plucked.
    dusk = np.zeros((n, 2), dtype=np.float32)
    chords = [[146.83, 174.61, 220.0], [116.54, 174.61, 233.08], [130.81, 196.0, 261.63], [110.0, 164.81, 220.0]]
    for i, chord in enumerate(chords):
        pad_chord(dusk, i * 4.25, 6.2, chord, 0.28)
    add_note(dusk, 0.5, 16, 73.42, 0.22, "bass", -0.3)
    melody = [349.23, 440.0, 523.25, 440.0, 392.0, 349.23, 293.66, 261.63,
              349.23, 392.0, 440.0, 523.25, 466.16, 392.0, 349.23, 293.66]
    for i, note in enumerate(melody):
        add_note(dusk, 0.8 + i * 0.95, 1.5, note, 0.11, "flute", 0.1)
    arp = [146.83, 220.0, 174.61, 261.63, 196.0, 293.66, 220.0, 329.63]
    for i in range(44):
        add_note(dusk, i * 0.37, 1.1, arp[i % len(arp)] * (2 if i % 7 == 0 else 1), 0.07, "pluck", -0.5 + (i % 4) * 0.3)
    for i in range(10):
        start = int((1.0 + i * 1.7) * SR)
        nn = min(int(0.6 * SR), n - start)
        if nn > 0:
            tt = np.arange(nn) / SR
            kick = np.sin(math.tau * (70 - 28 * tt) * tt) * np.exp(-tt * 9) * 0.12
            dusk[start:start + nn, 0] += kick
            dusk[start:start + nn, 1] += kick
    dusk = reverb_stereo(dusk, 3.5, 0.42)
    dusk = loop_crossfade(dusk, 1.5)
    write_wav(AUDIO / "music_dusk.wav", normalize(dusk, 0.7))

    # ---- Night: deep, sparse, shimmering.
    night = np.zeros((n, 2), dtype=np.float32)
    chords_n = [[73.42, 146.83, 174.61, 220.0], [58.27, 116.54, 174.61, 233.08],
                [65.41, 130.81, 196.0, 246.94], [55.0, 110.0, 164.81, 220.0]]
    for i, chord in enumerate(chords_n):
        pad_chord(night, i * 4.25, 6.2, chord, 0.33)
    add_note(night, 0, 17, 36.71, 0.19, "bass", 0.0)
    bells = [587.33, 739.99, 880.0, 1174.66, 987.77, 739.99, 659.25, 587.33]
    for i, note in enumerate(bells):
        add_note(night, 1.2 + i * 1.75, 2.8, note, 0.055, "bell", -0.4 + (i % 3) * 0.4)
    for i in range(12):
        add_note(night, 0.6 + i * 1.37, 0.6, [293.66, 349.23, 440.0][i % 3], 0.025, "flute", 0.5)
    night = reverb_stereo(night, 4.2, 0.5)
    night = loop_crossfade(night, 1.6)
    write_wav(AUDIO / "music_night.wav", normalize(night, 0.66))

    # ---- Flight: airy, faster arpeggios.
    flight = np.zeros((n, 2), dtype=np.float32)
    chords_f = [[164.81, 246.94, 329.63, 415.3], [123.47, 246.94, 311.13, 415.3],
                [138.59, 207.65, 277.18, 415.3], [110.0, 220.0, 277.18, 329.63]]
    for i, chord in enumerate(chords_f):
        pad_chord(flight, i * 4.25, 5.8, chord, 0.19)
    add_note(flight, 0, 17, 82.41, 0.17, "bass", -0.15)
    scale_f = [329.63, 415.3, 493.88, 554.37, 659.25, 830.61, 987.77, 1108.73]
    pattern_f = [0, 2, 4, 6, 7, 5, 3, 1, 2, 4, 6, 7, 6, 4, 2, 0]
    for i in range(72):
        note = scale_f[pattern_f[i % len(pattern_f)]]
        add_note(flight, i * 0.235 + 0.1, 0.9, note, 0.075, "pluck", -0.6 + (i % 5) * 0.3)
    wind = rng.normal(0, 1, n).astype(np.float32)
    kernel = np.ones(64, dtype=np.float32) / 64
    wind = np.convolve(wind, kernel, mode="same")
    wind *= 0.05 * (0.5 + 0.5 * np.sin(math.tau * 0.08 * t))[:, None] if False else 0.05
    flight[:, 0] += wind * 0.8
    flight[:, 1] += np.roll(wind, 700) * 0.8
    flight = reverb_stereo(flight, 2.4, 0.3)
    flight = loop_crossfade(flight, 1.0)
    write_wav(AUDIO / "music_flight.wav", normalize(flight, 0.66))


def sfx_buf(seconds: float) -> np.ndarray:
    return np.zeros((int(seconds * 44100), 2), dtype=np.float32)


def write_sfx(path: Path, buf: np.ndarray, peak: float = 0.8) -> None:
    write_wav(path, normalize(buf, peak), 44100)


def make_sfx() -> None:
    sr = 44100

    def n_of(seconds: float) -> int:
        return int(seconds * sr)

    # Soft UI tick.
    n = n_of(0.09)
    t = np.arange(n) / sr
    ui = np.sin(math.tau * 880 * t) * np.exp(-t * 48) * 0.5
    ui += np.sin(math.tau * 1320 * t) * np.exp(-t * 70) * 0.2
    write_sfx(AUDIO / "sfx_ui.wav", np.column_stack([ui, ui]), 0.45)

    # Airy jump whoosh.
    n = n_of(0.5)
    t = np.arange(n) / sr
    noise = rng.normal(0, 1, n).astype(np.float32)
    kernel = np.ones(30, dtype=np.float32) / 30
    noise = np.convolve(noise, kernel, mode="same")
    sweep = np.sin(math.tau * (180 + 520 * t) * t) * 0.18
    env = env_adsr(n, 0.02, 0.08, 0.38, 0.26)
    jump = (noise * 0.4 + sweep) * env
    write_sfx(AUDIO / "sfx_jump.wav", np.column_stack([jump * 0.9, jump]), 0.55)

    # Landing thud + sand.
    n = n_of(0.55)
    t = np.arange(n) / sr
    thud = np.sin(math.tau * (90 - 40 * t) * t) * np.exp(-t * 13) * 0.95
    noise = rng.normal(0, 1, n).astype(np.float32)
    noise = np.convolve(noise, np.ones(12) / 12, mode="same") * np.exp(-t * 9) * 0.6
    land = thud + noise
    write_sfx(AUDIO / "sfx_land.wav", np.column_stack([land, land * 0.95]), 0.6)

    # Perfect landing chime.
    n = n_of(1.2)
    t = np.arange(n) / sr
    perfect = np.zeros(n, dtype=np.float32)
    for i, f in enumerate([587.33, 880.0, 1174.66, 1760.0]):
        start = int(i * 0.075 * sr)
        tt = t[:n - start]
        perfect[start:] += np.sin(math.tau * f * tt) * np.exp(-tt * 4.2) * (0.35 - i * 0.06)
    write_sfx(AUDIO / "sfx_perfect.wav", np.column_stack([perfect, np.roll(perfect, 180)]), 0.5)

    # Coin.
    n = n_of(0.42)
    t = np.arange(n) / sr
    coin = (np.sin(math.tau * 1318.5 * t) * 0.6 + np.sin(math.tau * 1760 * t) * 0.35)
    coin *= np.exp(-t * 9) + 0.2 * np.exp(-t * 28)
    coin += rng.normal(0, 1, n) * np.exp(-t * 30) * 0.03
    write_sfx(AUDIO / "sfx_coin.wav", np.column_stack([coin, np.roll(coin, 90)]), 0.42)

    # Rare shard.
    n = n_of(1.5)
    t = np.arange(n) / sr
    shard = np.zeros(n, dtype=np.float32)
    for i, f in enumerate([880, 1174.66, 1567.98, 2349.32, 3135.96]):
        shard += np.sin(math.tau * f * t + i) * np.exp(-t * (2.0 + i * 0.4)) * 0.2
    write_sfx(AUDIO / "sfx_shard.wav", np.column_stack([shard, np.roll(shard, 260)]), 0.4)

    # Flip whoosh.
    n = n_of(0.66)
    t = np.arange(n) / sr
    noise = rng.normal(0, 1, n).astype(np.float32)
    noise = np.convolve(noise, np.ones(44) / 44, mode="same")
    env = env_adsr(n, 0.08, 0.12, 0.4, 0.3)
    whoosh = noise * env * 0.9 + np.sin(math.tau * (240 + 300 * t) * t) * env * 0.08
    write_sfx(AUDIO / "sfx_flip.wav", np.column_stack([whoosh, np.roll(whoosh, 300)]), 0.38)

    # Combo reward arpeggio.
    n = n_of(0.9)
    t = np.arange(n) / sr
    combo = np.zeros(n, dtype=np.float32)
    for i, f in enumerate([659.25, 830.61, 987.77, 1318.5]):
        start = int(i * 0.07 * sr)
        tt = t[:n - start]
        combo[start:] += np.sin(math.tau * f * tt) * np.exp(-tt * 6) * 0.3
    write_sfx(AUDIO / "sfx_combo.wav", np.column_stack([combo, np.roll(combo, 120)]), 0.4)

    # Crash.
    n = n_of(1.0)
    t = np.arange(n) / sr
    noise = rng.normal(0, 1, n).astype(np.float32)
    noise = np.convolve(noise, np.ones(6) / 6, mode="same")
    crash = noise * np.exp(-t * 7) * 0.8
    crash += np.sin(math.tau * (62 - 20 * t) * t) * np.exp(-t * 6) * 0.8
    crash += np.sin(math.tau * 180 * t) * np.exp(-t * 15) * 0.15
    write_sfx(AUDIO / "sfx_crash.wav", np.column_stack([crash, crash * 0.9]), 0.65)

    # Wingsuit deploy cloth flap.
    n = n_of(0.9)
    t = np.arange(n) / sr
    noise = rng.normal(0, 1, n).astype(np.float32)
    kernel = np.ones(100, dtype=np.float32) / 100
    noise = np.convolve(noise, kernel, mode="same")
    env = env_adsr(n, 0.03, 0.1, 0.35, 0.4)
    air = np.sin(math.tau * (140 + 220 * t) * t) * env * 0.18
    flap = (noise * 0.8 + air) * (1 + 0.3 * np.sin(math.tau * 18 * t))
    write_sfx(AUDIO / "sfx_deploy.wav", np.column_stack([flap, np.roll(flap, 260)]), 0.5)

    # Biome reveal gong.
    n = n_of(2.4)
    t = np.arange(n) / sr
    gong = np.zeros(n, dtype=np.float32)
    for i, f in enumerate([98, 146.83, 196, 293.66, 440]):
        gong += np.sin(math.tau * f * t) * np.exp(-t * (0.8 + i * 0.25)) * 0.4
    gong += rng.normal(0, 1, n) * np.exp(-t * 6) * 0.08
    write_sfx(AUDIO / "sfx_biome.wav", np.column_stack([gong, np.roll(gong, 500)]), 0.42)

    # Achievement flourish.
    n = n_of(1.4)
    t = np.arange(n) / sr
    ach = np.zeros(n, dtype=np.float32)
    for i, f in enumerate([523.25, 659.25, 783.99, 1046.5]):
        start = int(i * 0.11 * sr)
        tt = t[:n - start]
        ach[start:] += np.sin(math.tau * f * tt) * np.exp(-tt * 3.2) * 0.3
    write_sfx(AUDIO / "sfx_achievement.wav", np.column_stack([ach, np.roll(ach, 180)]), 0.43)

    # Sand loop.
    sr2 = SR
    n = int(4.0 * sr2)
    t = np.arange(n) / sr2
    noise = rng.normal(0, 1, n).astype(np.float32)
    lo = np.convolve(noise, np.ones(4) / 4, mode="same")
    mid = np.convolve(noise, np.ones(32) / 32, mode="same")
    sand = (lo * 0.5 + mid * 0.8) * (0.6 + 0.4 * np.sin(math.tau * 0.25 * t))
    sand = normalize(sand, 0.25)
    write_wav(AUDIO / "loop_sand.wav", np.column_stack([sand, np.roll(sand, 300)]), sr2)

    # Wind loop.
    n = int(6.0 * sr2)
    t = np.arange(n) / sr2
    noise = rng.normal(0, 1, n).astype(np.float32)
    kernel = np.ones(64, dtype=np.float32) / 64
    wind = np.convolve(noise, kernel, mode="same")
    wind = wind * (0.5 + 0.5 * np.sin(math.tau * 0.13 * t)) * (0.7 + 0.3 * np.sin(math.tau * 0.043 * t))
    wind = normalize(wind, 0.22)
    write_wav(AUDIO / "loop_wind.wav", np.column_stack([wind, np.roll(wind, 1700)]), sr2)

    # Wingsuit flight loop.
    n = int(5.0 * sr2)
    t = np.arange(n) / sr2
    noise = rng.normal(0, 1, n).astype(np.float32)
    wind = np.convolve(noise, np.ones(90) / 90, mode="same")
    wind *= 0.65 + 0.35 * np.sin(math.tau * 0.19 * t)
    tone = np.sin(math.tau * 110 * t) * 0.03
    wing = normalize(wind + tone, 0.24)
    write_wav(AUDIO / "loop_wing.wav", np.column_stack([wing, np.roll(wing, 900)]), sr2)


def copy_fonts() -> None:
    wanted = {
        "/usr/share/fonts/marcellus/Marcellus-Regular.ttf": "Marcellus-Regular.ttf",
        "/usr/share/fonts/cormorant-garamond/CormorantGaramond[wght].ttf": "CormorantGaramond.ttf",
        "/usr/share/fonts/inter-tight/InterTight[wght].ttf": "InterTight.ttf",
        "/usr/share/fonts/noto/NotoSansBengali-Regular.ttf": "NotoSansBengali-Regular.ttf",
        "/usr/share/fonts/ibm-plex-mono/IBMPlexMono-Regular.ttf": "IBMPlexMono-Regular.ttf",
    }
    for src, dst in wanted.items():
        p = Path(src)
        if p.exists():
            shutil.copy(p, FONTS / dst)
            print("font", dst)
        else:
            print("missing font", src)


if __name__ == "__main__":
    make_sand_tile()
    make_clouds()
    make_glow()
    make_dust()
    make_grain()
    make_icon()
    copy_fonts()
    make_music()
    make_sfx()
    print("Asset generation complete.")
