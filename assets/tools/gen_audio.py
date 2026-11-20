"""
Fast Vectorized NumPy Audio Synthesizer for Solstice Spire (runs inside Blender 5.2.1's Python!)
Generates studio-warm 44.1kHz stereo .wav stems & tactile SFX in ~2 seconds total:
  - 6 Biomes × 2 sample-exact seamless looping stems (base harmonic atmosphere + Flow percussion/bass/arp)
  - 22 crisp tactile Foley & musical dopamine SFX
"""

import os
import math
import wave
import numpy as np

BASE_DIR = "/Users/ethanpeleg/Desktop/Dev/Parkour/assets/audio"
MUSIC_DIR = os.path.join(BASE_DIR, "music")
SFX_DIR = os.path.join(BASE_DIR, "sfx")
os.makedirs(MUSIC_DIR, exist_ok=True)
os.makedirs(SFX_DIR, exist_ok=True)

SR = 44100


def midi_to_hz(m):
    return 440.0 * (2.0 ** ((m - 69.0) / 12.0))


def save_wav(l, r, path):
    peak = max(float(np.max(np.abs(l))), float(np.max(np.abs(r))), 1e-5)
    gain = min(0.88 / peak, 1.0) if peak > 0.88 else 1.0
    sl = np.tanh(l * gain) * 0.90
    sr = np.tanh(r * gain) * 0.90
    interleaved = np.empty(len(sl) * 2, dtype=np.int16)
    interleaved[0::2] = (sl * 32767.0).astype(np.int16)
    interleaved[1::2] = (sr * 32767.0).astype(np.int16)
    with wave.open(path, "wb") as wf:
        wf.setnchannels(2)
        wf.setsampwidth(2)
        wf.setframerate(SR)
        wf.writeframes(interleaved.tobytes())


def add_reverb(l, r, decay=0.36, wrap=True):
    ol, or_ = l.copy(), r.copy()
    taps = (0.067, 0.113, 0.173, 0.241)
    for idx, dt in enumerate(taps):
        d = int(dt * SR)
        g = decay * (0.70 ** idx)
        if wrap:
            sl, sr = np.roll(ol, d), np.roll(or_, d)
            if idx % 2 == 0:
                ol += sr * g
                or_ += sl * g * 0.85
            else:
                ol += sl * g * 0.85
                or_ += sr * g
        else:
            if d < len(l):
                if idx % 2 == 0:
                    ol[d:] += or_[:-d] * g
                    or_[d:] += ol[:-d] * g * 0.85
                else:
                    ol[d:] += ol[:-d] * g * 0.85
                    or_[d:] += or_[:-d] * g
    return ol, or_


def mix_wrapped(buf_l, buf_r, start_idx, sig_l, sig_r, wrap=True):
    n = len(buf_l)
    m = len(sig_l)
    if wrap:
        idx = (np.arange(m) + start_idx) % n
        np.add.at(buf_l, idx, sig_l)
        np.add.at(buf_r, idx, sig_r)
    else:
        end = min(n, start_idx + m)
        if end > start_idx:
            buf_l[start_idx:end] += sig_l[:end - start_idx]
            buf_r[start_idx:end] += sig_r[:end - start_idx]


def synth_bell(dur, freq, amp=0.24, pan=0.0, bright=1.0, mod_ratio=2.0, mod_idx=1.3):
    t = np.arange(int(dur * SR), dtype=np.float64) / SR
    env = np.minimum(1.0, t / 0.007) * np.exp(-t * (3.5 / max(dur, 0.22)))
    m_env = np.exp(-t * 7.5) * mod_idx * bright
    two_pi = 2.0 * math.pi
    s = np.sin(two_pi * freq * t + m_env * np.sin(two_pi * freq * mod_ratio * t))
    s += 0.26 * bright * np.sin(two_pi * freq * 2.0 * t) * np.exp(-t * 5.8)
    s *= env * amp
    gl = math.cos((pan + 1.0) * math.pi * 0.25)
    gr = math.sin((pan + 1.0) * math.pi * 0.25)
    return s * gl, s * gr


def synth_pad(dur, freqs, amp=0.14):
    n = int(dur * SR)
    t = np.arange(n, dtype=np.float64) / SR
    att = min(0.45, dur * 0.25)
    rel = min(0.55, dur * 0.28)
    env = np.ones(n, dtype=np.float64)
    m_att = t < att
    env[m_att] = 0.5 - 0.5 * np.cos(math.pi * t[m_att] / att)
    m_rel = t > (dur - rel)
    env[m_rel] = 0.5 - 0.5 * np.cos(math.pi * np.maximum(0.0, dur - t[m_rel]) / rel)
    out_l = np.zeros(n, dtype=np.float64)
    out_r = np.zeros(n, dtype=np.float64)
    two_pi = 2.0 * math.pi
    for fi, f in enumerate(freqs):
        pan = -0.35 + 0.70 * (fi / max(1, len(freqs) - 1))
        gl = amp * math.cos((pan + 1.0) * math.pi * 0.25)
        gr = amp * math.sin((pan + 1.0) * math.pi * 0.25)
        det = 1.0032 if fi % 2 == 0 else 0.9968
        s = (
            0.55 * np.sin(two_pi * f * t)
            + 0.30 * np.sin(two_pi * f * det * t)
            + 0.15 * np.sin(two_pi * f * 2.0 * t) * (0.6 + 0.4 * np.sin(two_pi * 0.32 * t))
        ) * env
        out_l += s * gl
        out_r += s * gr
    return out_l, out_r


def synth_kick(amp=0.45):
    t = np.arange(int(0.18 * SR), dtype=np.float64) / SR
    freq = 46.0 + 115.0 * np.exp(-t * 36.0)
    phase = np.cumsum(2.0 * math.pi * freq / SR)
    s = np.sin(phase) * np.exp(-t * 18.0) * np.minimum(1.0, t / 0.003) * amp
    return s, s


def synth_hat(amp=0.14, decay=38.0, pan=0.15, seed=1):
    rng = np.random.default_rng(seed)
    n = int(0.09 * SR)
    t = np.arange(n, dtype=np.float64) / SR
    w = rng.uniform(-1.0, 1.0, n)
    hp = np.diff(w, prepend=0.0)
    s = hp * np.exp(-t * decay) * amp
    gl = math.cos((pan + 1.0) * math.pi * 0.25)
    gr = math.sin((pan + 1.0) * math.pi * 0.25)
    return s * gl, s * gr


def synth_bass(dur, freq, amp=0.28):
    t = np.arange(int(dur * SR), dtype=np.float64) / SR
    two_pi = 2.0 * math.pi
    env = np.minimum(1.0, t / 0.006) * np.exp(-t * 5.0)
    s = (0.72 * np.sin(two_pi * freq * t) + 0.28 * np.sin(two_pi * freq * 2.0 * t) * np.exp(-t * 9.0)) * env * amp
    return s, s


BIOME_THEMES = [
    ("world1", 112, [[53, 60, 64, 69], [55, 62, 67, 71], [52, 59, 64, 67], [57, 64, 67, 71]],
     [72, 74, 76, 79, 81, 84, 86, 88], 2.0, 0.90),
    ("world2", 120, [[50, 57, 60, 64], [46, 53, 57, 62], [48, 55, 60, 65], [45, 52, 57, 62]],
     [69, 72, 74, 76, 79, 81, 84, 86], 2.756, 1.35),
    ("world3", 116, [[52, 59, 62, 66], [48, 55, 59, 64], [50, 57, 62, 66], [47, 54, 59, 62]],
     [71, 74, 76, 78, 83, 86, 88, 90], 3.0, 1.05),
    ("world4", 124, [[54, 61, 64, 68], [50, 57, 61, 66], [45, 52, 57, 61], [52, 59, 64, 68]],
     [73, 76, 78, 80, 83, 85, 88, 92], 3.5, 1.50),
    ("world5", 108, [[51, 58, 62, 65], [48, 55, 58, 62], [44, 51, 55, 60], [46, 53, 58, 62]],
     [70, 72, 74, 77, 79, 82, 84, 86], 2.0, 0.75),
    ("world6", 128, [[48, 55, 59, 62], [47, 55, 62, 67], [45, 52, 59, 64], [53, 60, 64, 71]],
     [72, 76, 79, 81, 83, 84, 88, 91], 2.0, 1.45),
]


def generate_music():
    for name, bpm, chords, scale, ratio, bright in BIOME_THEMES:
        beat = 60.0 / bpm
        bar = beat * 4.0
        n = int(bar * len(chords) * SR)

        bl, br = np.zeros(n), np.zeros(n)
        for ci, chord in enumerate(chords):
            t0 = ci * bar
            pl, pr = synth_pad(bar * 1.06, [midi_to_hz(m) for m in chord], amp=0.14)
            mix_wrapped(bl, br, int(t0 * SR), pl, pr, wrap=True)
            for step in range(4):
                m = scale[(ci * 2 + step * 2) % len(scale)]
                sl, sr = synth_bell(beat * 1.4, midi_to_hz(m), amp=0.16, pan=-0.45 if step % 2 == 0 else 0.45,
                                    bright=bright * 0.85, mod_ratio=ratio, mod_idx=1.1)
                mix_wrapped(bl, br, int((t0 + step * beat) * SR), sl, sr, wrap=True)
        bl, br = add_reverb(bl, br, decay=0.35, wrap=True)
        save_wav(bl, br, os.path.join(MUSIC_DIR, f"{name}_base.wav"))

        fl, fr = np.zeros(n), np.zeros(n)
        seed = 10
        for ci, chord in enumerate(chords):
            t0 = ci * bar
            r_hz = midi_to_hz(chord[0] - 12)
            f_hz = midi_to_hz(chord[0] - 5)
            for b in range(4):
                tb = t0 + b * beat
                if b in (0, 2):
                    kl, kr = synth_kick(0.45)
                    mix_wrapped(fl, fr, int(tb * SR), kl, kr, wrap=True)
                if b == 1:
                    kl, kr = synth_kick(0.32)
                    mix_wrapped(fl, fr, int((tb + beat * 0.5) * SR), kl, kr, wrap=True)
                bsl, bsr = synth_bass(beat * 0.45, r_hz, 0.28)
                mix_wrapped(fl, fr, int(tb * SR), bsl, bsr, wrap=True)
                bsl2, bsr2 = synth_bass(beat * 0.40, f_hz if b % 2 else r_hz * 2.0, 0.22)
                mix_wrapped(fl, fr, int((tb + beat * 0.5) * SR), bsl2, bsr2, wrap=True)
                hl, hr = synth_hat(0.15, 34.0, 0.22, seed)
                seed += 1
                mix_wrapped(fl, fr, int((tb + beat * 0.5) * SR), hl, hr, wrap=True)
                hl2, hr2 = synth_hat(0.09, 52.0, -0.22, seed)
                seed += 1
                mix_wrapped(fl, fr, int((tb + beat * 0.75) * SR), hl2, hr2, wrap=True)
                for sub in range(2):
                    m = scale[(ci * 3 + b * 2 + sub) % len(scale)]
                    al, ar = synth_bell(beat * 0.55, midi_to_hz(m), amp=0.15, pan=-0.35 if sub == 0 else 0.35,
                                        bright=bright * 1.15, mod_ratio=ratio, mod_idx=1.6)
                    mix_wrapped(fl, fr, int((tb + sub * beat * 0.5) * SR), al, ar, wrap=True)
        fl, fr = add_reverb(fl, fr, decay=0.22, wrap=True)
        save_wav(fl, fr, os.path.join(MUSIC_DIR, f"{name}_flow.wav"))
        print(f"[gen_audio] Generated {name} base + flow (.wav)")


def generate_sfx():
    rng = np.random.default_rng(42)
    two_pi = 2.0 * math.pi

    # Jump & Double-Jump
    for fname, f0, f1, dur in [("jump.wav", 210, 560, 0.16), ("double_jump.wav", 340, 880, 0.20)]:
        n = int(dur * SR)
        t = np.arange(n) / SR
        f = f0 + (f1 - f0) * (1.0 - np.exp(-t * 22.0))
        ph = np.cumsum(two_pi * f / SR)
        env = np.minimum(1.0, t / 0.005) * np.exp(-t * 18.0)
        whoosh = rng.uniform(-1, 1, n) * np.exp(-t * 26.0) * 0.16
        v = ((np.sin(ph) * 0.65 + np.sin(ph * 2.0) * 0.25) * env + whoosh) * 0.65
        l, r = v.copy(), v.copy()
        if fname == "double_jump.wav":
            bl, br = synth_bell(0.16, midi_to_hz(79), amp=0.28, bright=1.2)
            mix_wrapped(l, r, int(0.02 * SR), bl, br, wrap=False)
        save_wav(l, r, os.path.join(SFX_DIR, fname))

    # Air-Dash
    n = int(0.32 * SR)
    t = np.arange(n) / SR
    f = 95.0 + 480.0 * np.exp(-t * 28.0)
    ph = np.cumsum(two_pi * f / SR)
    w = rng.uniform(-1, 1, n)
    bp = np.diff(w, prepend=0.0) * np.exp(-t * 11.0)
    v = (np.sin(ph) * np.exp(-t * 20.0) * 0.55 + bp * 0.42) * 0.72
    l, r = v.copy(), v.copy()
    for t0, m, pan in [(0.01, 84, -0.3), (0.03, 88, 0.3)]:
        bl, br = synth_bell(0.24, midi_to_hz(m), amp=0.22, pan=pan, bright=1.5)
        mix_wrapped(l, r, int(t0 * SR), bl, br, wrap=False)
    save_wav(l, r, os.path.join(SFX_DIR, "dash.wav"))

    # Tactile Surface Steps & Land
    for fname, bf, dec, nm in [
        ("step_stone.wav", 140.0, 26.0, 0.25),
        ("step_brass.wav", 420.0, 18.0, 0.15),
        ("step_paper.wav", 680.0, 38.0, 0.55),
        ("step_crystal.wav", 1280.0, 14.0, 0.12),
        ("land_thud.wav", 95.0, 22.0, 0.30),
    ]:
        n = int(0.14 * SR)
        t = np.arange(n) / SR
        env = np.minimum(1.0, t / 0.002) * np.exp(-t * dec)
        tone = np.sin(two_pi * bf * t) + 0.4 * np.sin(two_pi * bf * 2.38 * t)
        nz = rng.uniform(-1, 1, n) * np.exp(-t * (dec * 1.4))
        v = (tone * (1.0 - nm) + nz * nm) * env * 0.55
        save_wav(v, v, os.path.join(SFX_DIR, fname))

    # Slide & Wall-Kick
    n = int(0.28 * SR)
    t = np.arange(n) / SR
    v = rng.uniform(-1, 1, n) * np.minimum(1.0, t / 0.03) * np.exp(-t * 9.0) * 0.35
    save_wav(v, v, os.path.join(SFX_DIR, "slide.wav"))

    l, r = np.zeros(int(0.32 * SR)), np.zeros(int(0.32 * SR))
    kl, kr = synth_kick(0.45)
    mix_wrapped(l, r, 0, kl, kr, wrap=False)
    bl, br = synth_bell(0.28, midi_to_hz(74), amp=0.38, bright=1.5, mod_ratio=2.76)
    mix_wrapped(l, r, 0, bl, br, wrap=False)
    save_wav(l, r, os.path.join(SFX_DIR, "wall_kick.wav"))

    # Bronze Bell Ring
    l, r = np.zeros(int(1.15 * SR)), np.zeros(int(1.15 * SR))
    bl, br = synth_bell(1.05, midi_to_hz(69), amp=0.42, bright=1.6, mod_ratio=2.756, mod_idx=2.2)
    mix_wrapped(l, r, 0, bl, br, wrap=False)
    bl2, br2 = synth_bell(0.85, midi_to_hz(81), amp=0.22, pan=0.2, bright=1.3, mod_ratio=2.0)
    mix_wrapped(l, r, 0, bl2, br2, wrap=False)
    l, r = add_reverb(l, r, 0.38, wrap=False)
    save_wav(l, r, os.path.join(SFX_DIR, "bell_ring.wav"))

    # Pentatonic Flow Chime
    l, r = np.zeros(int(0.48 * SR)), np.zeros(int(0.48 * SR))
    bl, br = synth_bell(0.42, midi_to_hz(72), amp=0.38, bright=1.3, mod_ratio=2.0, mod_idx=1.0)
    mix_wrapped(l, r, 0, bl, br, wrap=False)
    l, r = add_reverb(l, r, 0.28, wrap=False)
    save_wav(l, r, os.path.join(SFX_DIR, "flow_chime.wav"))

    # Bounce Pad
    n = int(0.42 * SR)
    t = np.arange(n) / SR
    f = 160.0 + 520.0 * (1.0 - np.exp(-t * 14.0)) + 25.0 * np.sin(two_pi * 24.0 * t)
    v = np.sin(np.cumsum(two_pi * f / SR)) * np.exp(-t * 8.5) * 0.55
    l, r = v.copy(), v.copy()
    for t0, m in [(0.03, 76), (0.06, 83)]:
        bl, br = synth_bell(0.32, midi_to_hz(m), amp=0.24, bright=1.3)
        mix_wrapped(l, r, int(t0 * SR), bl, br, wrap=False)
    save_wav(l, r, os.path.join(SFX_DIR, "bounce.wav"))

    # Crystal Crack & Shatter
    l, r = np.zeros(int(0.24 * SR)), np.zeros(int(0.24 * SR))
    for k, f0 in enumerate([1800, 2650, 3400]):
        bl, br = synth_bell(0.12, f0, amp=0.22, pan=-0.3 + 0.3 * k, bright=1.8, mod_ratio=3.7)
        mix_wrapped(l, r, int(k * 0.025 * SR), bl, br, wrap=False)
    save_wav(l, r, os.path.join(SFX_DIR, "crystal_crack.wav"))

    l, r = np.zeros(int(0.50 * SR)), np.zeros(int(0.50 * SR))
    for _ in range(10):
        bl, br = synth_bell(0.25, float(rng.uniform(1400, 4600)), amp=0.14,
                            pan=float(rng.uniform(-0.7, 0.7)), bright=2.0, mod_ratio=3.1)
        mix_wrapped(l, r, int(float(rng.uniform(0.0, 0.14)) * SR), bl, br, wrap=False)
    save_wav(l, r, os.path.join(SFX_DIR, "crystal_shatter.wav"))

    # Portal Warp & Tether Zip
    n = int(0.56 * SR)
    t = np.arange(n) / SR
    f = 180.0 + 920.0 * np.sin(math.pi * np.minimum(1.0, t / 0.45))
    v = np.sin(np.cumsum(two_pi * f / SR)) * np.exp(-t * 4.5) * 0.45
    l, r = v.copy(), v.copy()
    for idx, m in enumerate([72, 76, 79, 84]):
        bl, br = synth_bell(0.35, midi_to_hz(m), amp=0.20, pan=-0.4 + idx * 0.25, bright=1.5)
        mix_wrapped(l, r, int(idx * 0.045 * SR), bl, br, wrap=False)
    l, r = add_reverb(l, r, 0.36, wrap=False)
    save_wav(l, r, os.path.join(SFX_DIR, "portal_warp.wav"))

    l, r = np.zeros(int(0.34 * SR)), np.zeros(int(0.34 * SR))
    for t0, m in [(0.0, 81), (0.04, 88)]:
        bl, br = synth_bell(0.26, midi_to_hz(m), amp=0.28, bright=1.5)
        mix_wrapped(l, r, int(t0 * SR), bl, br, wrap=False)
    save_wav(l, r, os.path.join(SFX_DIR, "tether_zip.wav"))

    # Checkpoint Bloom Chord
    l, r = np.zeros(int(1.65 * SR)), np.zeros(int(1.65 * SR))
    for idx, m in enumerate([60, 67, 72, 74, 76, 79, 84]):
        bl, br = synth_bell(1.1, midi_to_hz(m), amp=0.20, pan=-0.5 + idx * 0.16, bright=1.25)
        mix_wrapped(l, r, int(idx * 0.07 * SR), bl, br, wrap=False)
    l, r = add_reverb(l, r, 0.44, wrap=False)
    save_wav(l, r, os.path.join(SFX_DIR, "checkpoint.wav"))

    # Sun-Shard Sparkle
    l, r = np.zeros(int(0.88 * SR)), np.zeros(int(0.88 * SR))
    for idx, m in enumerate([76, 81, 83, 88, 93]):
        bl, br = synth_bell(0.55, midi_to_hz(m), amp=0.22, pan=-0.4 + idx * 0.2, bright=1.6)
        mix_wrapped(l, r, int(idx * 0.055 * SR), bl, br, wrap=False)
    l, r = add_reverb(l, r, 0.36, wrap=False)
    save_wav(l, r, os.path.join(SFX_DIR, "sun_shard.wav"))

    # Rewind Respawn Zip
    n = int(0.38 * SR)
    t = np.arange(n) / SR
    f = 240.0 + 760.0 * (t / 0.38) ** 1.8
    env = np.sin(math.pi * t / 0.38)
    v = (np.sin(np.cumsum(two_pi * f / SR)) * 0.45 + rng.uniform(-1, 1, n) * 0.18) * env * 0.65
    l, r = v.copy(), v.copy()
    bl, br = synth_bell(0.14, midi_to_hz(79), amp=0.24, bright=1.3)
    mix_wrapped(l, r, int(0.24 * SR), bl, br, wrap=False)
    save_wav(l, r, os.path.join(SFX_DIR, "rewind.wav"))

    # UI Click & Summit Fanfare
    bl, br = synth_bell(0.09, midi_to_hz(84), amp=0.32, bright=1.1)
    save_wav(bl, br, os.path.join(SFX_DIR, "ui_click.wav"))

    l, r = np.zeros(int(2.85 * SR)), np.zeros(int(2.85 * SR))
    pl, pr = synth_pad(2.6, [midi_to_hz(m) for m in [48, 60, 64, 67, 71]], amp=0.18)
    mix_wrapped(l, r, 0, pl, pr, wrap=False)
    for t0, m in [(0.0, 60), (0.0, 67), (0.14, 72), (0.28, 76), (0.42, 79), (0.58, 84), (0.78, 86), (0.98, 88), (1.18, 91)]:
        bl, br = synth_bell(1.45, midi_to_hz(m), amp=0.22, pan=float(rng.uniform(-0.4, 0.4)), bright=1.35)
        mix_wrapped(l, r, int(t0 * SR), bl, br, wrap=False)
    l, r = add_reverb(l, r, 0.46, wrap=False)
    save_wav(l, r, os.path.join(SFX_DIR, "summit_fanfare.wav"))
    print("[gen_audio] All 22 tactile SFX (.wav) synthesized successfully.")


if __name__ == "__main__":
    generate_music()
    generate_sfx()
    print("[gen_audio] Complete!")
