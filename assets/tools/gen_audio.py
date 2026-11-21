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
AMBIENCE_DIR = os.path.join(BASE_DIR, "ambience")
os.makedirs(MUSIC_DIR, exist_ok=True)
os.makedirs(SFX_DIR, exist_ok=True)
os.makedirs(AMBIENCE_DIR, exist_ok=True)

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


def synth_felt_piano(dur, freq, amp=0.22, pan=0.0):
    """Warm felt upright piano with stretched inharmonic partials, unison string detune & soft felt hammer thud."""
    n = int(dur * SR)
    t = np.arange(n, dtype=np.float64) / SR
    two_pi = 2.0 * math.pi
    att = np.minimum(1.0, t / 0.008)
    rel = np.minimum(1.0, np.maximum(0.0, (dur - t) / 0.035))
    # Dual-stage upright piano soundboard envelope
    env_body = (0.58 * np.exp(-t * (1.8 / max(dur, 0.35))) + 0.42 * np.exp(-t * 4.6)) * att * rel
    B = 0.00038
    s = np.zeros(n, dtype=np.float64)
    weights = (1.0, 0.44, 0.20, 0.09, 0.04, 0.018)
    for k, w in enumerate(weights, start=1):
        fk = freq * k * math.sqrt(1.0 + B * k * k)
        if fk >= SR * 0.42:
            break
        det = 1.0 + (0.00045 if k % 2 == 1 else -0.00045)
        p_env = np.exp(-t * (1.4 * k))
        s += w * (0.65 * np.sin(two_pi * fk * t) + 0.35 * np.sin(two_pi * fk * det * t + 0.2 * k)) * p_env
    # Soft felt hammer thump transient
    thump_f = 135.0 + 95.0 * np.exp(-t * 90.0)
    thump = np.sin(np.cumsum(two_pi * thump_f / SR)) * np.minimum(1.0, t / 0.0025) * np.exp(-t * 72.0) * 0.14
    sig = (s * env_body + thump) * amp
    gl, gr = _pan_gains(pan)
    return sig * gl, sig * gr


def synth_plucked_harp(dur, freq, amp=0.19, pan=0.0):
    """Karplus-Strong physical-modeled plucked acoustic harp with spruce soundboard resonance."""
    n = int(dur * SR)
    t = np.arange(n, dtype=np.float64) / SR
    two_pi = 2.0 * math.pi
    att = np.minimum(1.0, t / 0.0045)
    rel = np.minimum(1.0, np.maximum(0.0, (dur - t) / 0.025))
    s = np.zeros(n, dtype=np.float64)
    # Karplus-Strong loop-filter damping law: higher partials damp quadratically faster
    for k in range(1, 9):
        fk = freq * k
        if fk >= SR * 0.42:
            break
        damp = (1.6 / max(dur, 0.25)) + 0.55 * (k ** 1.65)
        amp_k = (1.0 / (k ** 1.15)) * (0.85 if k % 2 == 0 else 1.0)
        s += amp_k * np.sin(two_pi * fk * t + 0.15 * k) * np.exp(-t * damp)
    # Finger-pluck wooden body transient
    pluck_click = np.sin(two_pi * min(freq * 2.5, 1800.0) * t) * np.exp(-t * 115.0) * 0.12
    sig = (s * att * rel + pluck_click) * amp
    gl, gr = _pan_gains(pan)
    return sig * gl, sig * gr


def synth_brass_horn(dur, freq, amp=0.20, pan=0.0):
    """Warm French horn / brass swell with dynamic low-pass filter bloom and lip-reed vibrato."""
    n = int(dur * SR)
    t = np.arange(n, dtype=np.float64) / SR
    two_pi = 2.0 * math.pi
    att_t = min(0.22, dur * 0.32)
    rel_t = min(0.24, dur * 0.32)
    env = np.ones(n, dtype=np.float64)
    m_att = t < att_t
    env[m_att] = 0.5 - 0.5 * np.cos(math.pi * t[m_att] / max(att_t, 1e-4))
    m_rel = t > (dur - rel_t)
    env[m_rel] = 0.5 - 0.5 * np.cos(math.pi * np.maximum(0.0, dur - t[m_rel]) / max(rel_t, 1e-4))
    # Subtle expressive vibrato blooming after attack
    vib = (0.0032 * freq) * np.minimum(1.0, np.maximum(0.0, (t - att_t * 0.8) / 0.18)) * np.sin(two_pi * 4.8 * t)
    ph = np.cumsum(two_pi * (freq + vib) / SR)
    # Dynamic brass filter opening with envelope swell
    swell_bright = 0.35 + 0.65 * env
    s = np.zeros(n, dtype=np.float64)
    brass_weights = (1.0, 0.78, 0.54, 0.34, 0.20, 0.11, 0.06, 0.03)
    for k, w in enumerate(brass_weights, start=1):
        if freq * k >= SR * 0.42:
            break
        # Bell formant emphasis around 550-1100 Hz
        fk = freq * k
        formant = 1.25 if 480.0 <= fk <= 1150.0 else 1.0
        filt = np.power(swell_bright, 0.55 * (k - 1))
        s += (w * formant) * np.sin(ph * k + 0.1 * k) * filt
    sig = s * env * (amp * 0.58)
    gl, gr = _pan_gains(pan)
    return sig * gl, sig * gr


def synth_anvil_marimba(dur, freq, amp=0.21, pan=0.0):
    """Resonant wooden marimba bar + tuned metallic bronze anvil bell overtone."""
    n = int(dur * SR)
    t = np.arange(n, dtype=np.float64) / SR
    two_pi = 2.0 * math.pi
    att = np.minimum(1.0, t / 0.0035)
    # Rosewood arch-cut marimba (1.0x + 3.98x) + tuned bronze anvil chime (2.756x + 5.40x)
    s = (
        0.74 * np.sin(two_pi * freq * t) * np.exp(-t * (3.2 / max(dur, 0.22)))
        + 0.24 * np.sin(two_pi * freq * 2.756 * t) * np.exp(-t * (4.2 / max(dur, 0.22)))
        + 0.18 * np.sin(two_pi * freq * 3.98 * t) * np.exp(-t * 16.0)
        + 0.08 * np.sin(two_pi * freq * 5.40 * t) * np.exp(-t * 24.0)
    ) * att * amp
    gl, gr = _pan_gains(pan)
    return s * gl, s * gr


def synth_koto(dur, freq, amp=0.22, pan=0.0):
    """Plucked Japanese koto with sharp ivory plectrum attack, paulownia body & subtle oshide bend."""
    n = int(dur * SR)
    t = np.arange(n, dtype=np.float64) / SR
    two_pi = 2.0 * math.pi
    att = np.minimum(1.0, t / 0.003)
    rel = np.minimum(1.0, np.maximum(0.0, (dur - t) / 0.025))
    # Subtle koto string tension pitch dip & shimmer after pluck
    f_curve = freq * (1.0 + 0.006 * np.exp(-t * 28.0) + 0.0018 * np.sin(two_pi * 5.4 * t) * np.minimum(1.0, t / 0.16))
    ph = np.cumsum(two_pi * f_curve / SR)
    s = (
        0.66 * np.sin(ph) * np.exp(-t * (2.5 / max(dur, 0.25)))
        + 0.34 * np.sin(ph * 2.0 + 0.3) * np.exp(-t * 4.8)
        + 0.22 * np.sin(ph * 3.0 + 0.7) * np.exp(-t * 7.5)
        + 0.14 * np.sin(ph * 4.01) * np.exp(-t * 12.0)
        + 0.08 * np.sin(ph * 5.03) * np.exp(-t * 18.0)
        + 0.05 * np.sin(ph * 6.06) * np.exp(-t * 26.0)
    ) * att * rel
    # Crisp tsume plectrum transient
    plectrum = np.sin(two_pi * min(freq * 4.5, 2900.0) * t) * np.exp(-t * 150.0) * 0.16
    sig = (s + plectrum) * amp
    gl, gr = _pan_gains(pan)
    return sig * gl, sig * gr


def synth_shakuhachi(dur, freq, amp=0.21, pan=0.0, seed=1):
    """Breathy bamboo shakuhachi flute with portamento attack, airy breath chiff & hollow tube vibrato."""
    rng = np.random.default_rng(seed)
    n = int(dur * SR)
    t = np.arange(n, dtype=np.float64) / SR
    two_pi = 2.0 * math.pi
    att_t = min(0.14, dur * 0.28)
    rel_t = min(0.18, dur * 0.28)
    env = np.ones(n, dtype=np.float64)
    m_att = t < att_t
    env[m_att] = 0.5 - 0.5 * np.cos(math.pi * t[m_att] / max(att_t, 1e-4))
    m_rel = t > (dur - rel_t)
    env[m_rel] = 0.5 - 0.5 * np.cos(math.pi * np.maximum(0.0, dur - t[m_rel]) / max(rel_t, 1e-4))
    # Expressive pitch scoop + delayed human vibrato
    scoop = freq * (0.972 + 0.028 * (1.0 - np.exp(-t * 24.0)))
    vib = (0.0055 * freq) * np.minimum(1.0, np.maximum(0.0, (t - 0.16) / 0.18)) * np.sin(two_pi * 5.2 * t)
    ph = np.cumsum(two_pi * (scoop + vib) / SR)
    tone = (
        0.76 * np.sin(ph)
        + 0.16 * np.sin(ph * 2.0 + 0.4)
        + 0.22 * np.sin(ph * 3.0 + 0.8) * (0.65 + 0.35 * env)
        + 0.05 * np.sin(ph * 5.0) * env
    ) * env
    # Airy bamboo edge-tone breath transient + soft sustained air whisper
    raw_nz = rng.standard_normal(n)
    air = np.diff(raw_nz, prepend=0.0) * 0.35
    air_lp = np.convolve(air, np.ones(12) / 12.0, mode="same")
    chiff_env = np.minimum(1.0, t / 0.016) * np.exp(-t * 16.0) * 0.22 + env * 0.055
    sig = (tone + air_lp * chiff_env) * amp
    gl, gr = _pan_gains(pan)
    return sig * gl, sig * gr


def synth_celesta(dur, freq, amp=0.20, pan=0.0):
    """Haunting celesta / glass music-box with crystalline high tine chime and warm resonator box."""
    n = int(dur * SR)
    t = np.arange(n, dtype=np.float64) / SR
    two_pi = 2.0 * math.pi
    att = np.minimum(1.0, t / 0.004)
    rel = np.minimum(1.0, np.maximum(0.0, (dur - t) / 0.03))
    s = (
        0.74 * np.sin(two_pi * freq * t) * np.exp(-t * (2.4 / max(dur, 0.24)))
        + 0.18 * np.sin(two_pi * freq * 2.0 * t) * np.exp(-t * 6.5)
        + 0.22 * np.sin(two_pi * freq * 4.015 * t) * np.exp(-t * 14.5)
        + 0.09 * np.sin(two_pi * freq * 6.28 * t) * np.exp(-t * 26.0)
    ) * att * rel * amp
    gl, gr = _pan_gains(pan)
    return s * gl, s * gr


def synth_bowed_strings(dur, freqs, amp=0.14):
    """Lush bowed string ensemble pad (cellos, violas, violins) with rosin swell & rich stereo detune."""
    n = int(dur * SR)
    t = np.arange(n, dtype=np.float64) / SR
    two_pi = 2.0 * math.pi
    att = min(0.38, dur * 0.28)
    rel = min(0.45, dur * 0.30)
    env = np.ones(n, dtype=np.float64)
    m_att = t < att
    env[m_att] = 0.5 - 0.5 * np.cos(math.pi * t[m_att] / max(att, 1e-4))
    m_rel = t > (dur - rel)
    env[m_rel] = 0.5 - 0.5 * np.cos(math.pi * np.maximum(0.0, dur - t[m_rel]) / max(rel, 1e-4))
    out_l = np.zeros(n, dtype=np.float64)
    out_r = np.zeros(n, dtype=np.float64)
    for fi, f in enumerate(freqs):
        pan = -0.45 + 0.90 * (fi / max(1, len(freqs) - 1))
        gl, gr = _pan_gains(pan)
        vib1 = 0.0028 * f * np.sin(two_pi * (5.0 + 0.3 * fi) * t + fi)
        vib2 = 0.0028 * f * np.sin(two_pi * (5.4 - 0.2 * fi) * t + 1.7 * fi)
        ph1 = np.cumsum(two_pi * (f * 0.9978 + vib1) / SR)
        ph2 = np.cumsum(two_pi * (f * 1.0022 + vib2) / SR)
        voice = np.zeros(n, dtype=np.float64)
        for k, wk in enumerate((1.0, 0.52, 0.30, 0.16, 0.08, 0.04), start=1):
            if f * k >= SR * 0.40:
                break
            voice += wk * (0.5 * np.sin(ph1 * k) + 0.5 * np.sin(ph2 * k + 0.4 * k))
        voice *= env * amp * 0.62
        out_l += voice * gl
        out_r += voice * gr
    return out_l, out_r


def synth_kalimba(dur, freq, amp=0.23, pan=0.0):
    """Cozy thumb-plucked kalimba with metallic tine ping overtone (6.18x) and warm wood box resonance."""
    n = int(dur * SR)
    t = np.arange(n, dtype=np.float64) / SR
    two_pi = 2.0 * math.pi
    att = np.minimum(1.0, t / 0.0035)
    rel = np.minimum(1.0, np.maximum(0.0, (dur - t) / 0.025))
    s = (
        0.78 * np.sin(two_pi * freq * t) * np.exp(-t * (2.6 / max(dur, 0.24)))
        + 0.16 * np.sin(two_pi * freq * 2.0 * t) * np.exp(-t * 8.5)
        + 0.26 * np.sin(two_pi * min(freq * 6.18, SR * 0.40) * t) * np.exp(-t * 28.0)
        + 0.08 * np.sin(two_pi * min(freq * 11.4, SR * 0.42) * t) * np.exp(-t * 65.0)
    ) * att * rel * amp
    gl, gr = _pan_gains(pan)
    return s * gl, s * gr


def synth_choir_pad(dur, freqs, amp=0.14):
    """Shimmering nocturnal choir / vocal formant pad ('Ahh / Ooh' vowel formants)."""
    n = int(dur * SR)
    t = np.arange(n, dtype=np.float64) / SR
    two_pi = 2.0 * math.pi
    att = min(0.45, dur * 0.28)
    rel = min(0.52, dur * 0.30)
    env = np.ones(n, dtype=np.float64)
    m_att = t < att
    env[m_att] = 0.5 - 0.5 * np.cos(math.pi * t[m_att] / max(att, 1e-4))
    m_rel = t > (dur - rel)
    env[m_rel] = 0.5 - 0.5 * np.cos(math.pi * np.maximum(0.0, dur - t[m_rel]) / max(rel, 1e-4))
    out_l = np.zeros(n, dtype=np.float64)
    out_r = np.zeros(n, dtype=np.float64)
    for fi, f in enumerate(freqs):
        pan = -0.48 + 0.96 * (fi / max(1, len(freqs) - 1))
        gl, gr = _pan_gains(pan)
        vib = 0.0035 * f * np.sin(two_pi * (4.6 + 0.25 * fi) * t + fi * 1.1)
        ph = np.cumsum(two_pi * (f + vib) / SR)
        voice = np.zeros(n, dtype=np.float64)
        for k in range(1, 10):
            fk = f * k
            if fk >= SR * 0.40:
                break
            # Vocal formants around F1=730 Hz, F2=1150 Hz, F3=2450 Hz
            f1 = math.exp(-((fk - 730.0) / 210.0) ** 2)
            f2 = 0.75 * math.exp(-((fk - 1150.0) / 260.0) ** 2)
            f3 = 0.35 * math.exp(-((fk - 2450.0) / 380.0) ** 2)
            base_w = (1.0 / (k ** 1.1)) * (0.45 + 0.85 * (f1 + f2 + f3))
            voice += base_w * (0.55 * np.sin(ph * k) + 0.45 * np.sin(ph * k * 1.0025 + 0.5 * k))
        voice *= env * amp * 0.52
        out_l += voice * gl
        out_r += voice * gr
    return out_l, out_r


def synth_carillon_bell(dur, freq, amp=0.22, pan=0.0):
    """Radiant bronze carillon summit bell with minor/major third & fifth chime partials."""
    n = int(dur * SR)
    t = np.arange(n, dtype=np.float64) / SR
    two_pi = 2.0 * math.pi
    att = np.minimum(1.0, t / 0.004)
    s = (
        0.58 * np.sin(two_pi * freq * t) * np.exp(-t * (2.0 / max(dur, 0.3)))
        + 0.32 * np.sin(two_pi * freq * 2.0 * t) * np.exp(-t * (3.2 / max(dur, 0.3)))
        + 0.18 * np.sin(two_pi * freq * 2.40 * t) * np.exp(-t * 6.5)
        + 0.16 * np.sin(two_pi * freq * 3.0 * t) * np.exp(-t * 8.5)
        + 0.10 * np.sin(two_pi * freq * 4.0 * t) * np.exp(-t * 13.0)
    ) * att * amp
    gl, gr = _pan_gains(pan)
    return s * gl, s * gr


def synth_brushed_shaker(dur=0.11, amp=0.11, pan=0.2, seed=1):
    rng = np.random.default_rng(seed)
    n = int(dur * SR)
    t = np.arange(n, dtype=np.float64) / SR
    w = rng.standard_normal(n)
    bp = np.convolve(np.diff(w, prepend=0.0), np.ones(6) / 6.0, mode="same")
    env = np.sin(math.pi * np.clip(t / dur, 0.0, 1.0)) ** 1.4 * np.exp(-t * 14.0)
    sig = bp * env * amp
    gl, gr = _pan_gains(pan)
    return sig * gl, sig * gr


def synth_woodblock(freq=680.0, amp=0.16, pan=-0.2):
    n = int(0.085 * SR)
    t = np.arange(n, dtype=np.float64) / SR
    two_pi = 2.0 * math.pi
    env = np.minimum(1.0, t / 0.0018) * np.exp(-t * 48.0)
    s = (0.78 * np.sin(two_pi * freq * t) + 0.22 * np.sin(two_pi * freq * 2.42 * t) * np.exp(-t * 85.0)) * env * amp
    gl, gr = _pan_gains(pan)
    return s * gl, s * gr


def synth_clockwork_rim(amp=0.18, pan=0.22, seed=1):
    rng = np.random.default_rng(seed)
    n = int(0.075 * SR)
    t = np.arange(n, dtype=np.float64) / SR
    two_pi = 2.0 * math.pi
    click = (
        0.55 * np.sin(two_pi * 880.0 * t)
        + 0.35 * np.sin(two_pi * 1640.0 * t)
        + 0.25 * rng.uniform(-1.0, 1.0, n)
    ) * np.minimum(1.0, t / 0.0012) * np.exp(-t * 62.0) * amp
    gl, gr = _pan_gains(pan)
    return click * gl, click * gr


def synth_taiko(freq=72.0, amp=0.38, pan=0.0):
    """Warm resonant Japanese barrel taiko drum thud."""
    n = int(0.28 * SR)
    t = np.arange(n, dtype=np.float64) / SR
    two_pi = 2.0 * math.pi
    f = freq + 68.0 * np.exp(-t * 28.0)
    ph = np.cumsum(two_pi * f / SR)
    body = (0.76 * np.sin(ph) + 0.24 * np.sin(ph * 1.84) * np.exp(-t * 18.0)) * np.minimum(1.0, t / 0.0035) * np.exp(-t * 11.5)
    sig = body * amp
    gl, gr = _pan_gains(pan)
    return sig * gl, sig * gr


def synth_bamboo_clack(amp=0.16, pan=0.28, seed=1):
    rng = np.random.default_rng(seed)
    n = int(0.07 * SR)
    t = np.arange(n, dtype=np.float64) / SR
    two_pi = 2.0 * math.pi
    s = (
        0.62 * np.sin(two_pi * 1120.0 * t)
        + 0.28 * np.sin(two_pi * 1890.0 * t)
        + 0.15 * rng.standard_normal(n)
    ) * np.minimum(1.0, t / 0.0015) * np.exp(-t * 68.0) * amp
    gl, gr = _pan_gains(pan)
    return s * gl, s * gr


def synth_glass_triangle(dur=0.45, freq=2640.0, amp=0.11, pan=0.25):
    n = int(dur * SR)
    t = np.arange(n, dtype=np.float64) / SR
    two_pi = 2.0 * math.pi
    att = np.minimum(1.0, t / 0.002)
    s = (
        0.65 * np.sin(two_pi * freq * t) * np.exp(-t * (4.5 / max(dur, 0.15)))
        + 0.25 * np.sin(two_pi * freq * 1.48 * t) * np.exp(-t * 11.0)
        + 0.10 * np.sin(two_pi * freq * 2.11 * t) * np.exp(-t * 18.0)
    ) * att * amp
    gl, gr = _pan_gains(pan)
    return s * gl, s * gr


def synth_heartbeat_sub(amp=0.32):
    """Cozy nocturnal library lub-dub soft sub-bass heartbeat pulse."""
    n = int(0.42 * SR)
    l = np.zeros(n, dtype=np.float64)
    two_pi = 2.0 * math.pi
    for t0, f0, g in [(0.0, 52.0, 0.85), (0.15, 46.0, 1.0)]:
        m = int(0.18 * SR)
        t = np.arange(m, dtype=np.float64) / SR
        f = f0 + 36.0 * np.exp(-t * 28.0)
        th = np.sin(np.cumsum(two_pi * f / SR)) * np.minimum(1.0, t / 0.008) * np.exp(-t * 16.0) * amp * g
        end = min(n, int(t0 * SR) + m)
        l[int(t0 * SR):end] += th[:end - int(t0 * SR)]
    return l, l.copy()


# Iconic "Solstice Spire" Main Leitmotif:
#   Section A contour: scale degrees [0, 2, 4, 7, 6, 4, 2, 4]
#   Section B contour: scale degrees [4, 7, 9, 7, 6, 4, 2, 0]
# Expressed as (beat_offset_in_4_bar_phrase, degree_index, duration_beats, velocity, pan)
# Includes dotted-note phrasing, syncopated ties across barlines, and multi-beat breathing rests!
LEITMOTIF_4_4_A1 = [
    (0.0,  0, 1.5, 0.84, -0.22),
    (1.5,  2, 0.5, 0.76, -0.10),
    (2.0,  4, 2.0, 0.90,  0.08),
    (4.0,  7, 2.5, 1.00,  0.24),
    (6.5,  6, 1.5, 0.88,  0.12),
    (8.0,  4, 1.5, 0.85, -0.08),
    (9.5,  2, 1.0, 0.78, -0.20),
    (10.5, 4, 3.0, 0.92,  0.05),
    # 2.5 beats of breathing rest (13.5 .. 16.0)
]

LEITMOTIF_4_4_A2 = [
    (0.0,  0, 1.5, 0.86, -0.20),
    (1.5,  2, 0.5, 0.78, -0.06),
    (2.0,  4, 1.5, 0.90,  0.10),
    (3.5,  7, 3.0, 1.02,  0.26),
    (6.5,  6, 1.5, 0.90,  0.14),
    (8.0,  4, 1.5, 0.86, -0.10),
    (9.5,  2, 1.5, 0.82, -0.22),
    (11.0, 4, 2.5, 0.94,  0.12),
    # 2.5 beats of breathing rest (13.5 .. 16.0)
]

LEITMOTIF_4_4_B1 = [
    (0.0,  4, 1.5, 0.90, -0.18),
    (1.5,  7, 1.5, 0.96,  0.06),
    (3.0,  9, 3.0, 1.06,  0.28),
    (6.0,  7, 2.0, 0.94,  0.14),
    (8.0,  6, 1.5, 0.88, -0.05),
    (9.5,  4, 1.5, 0.84, -0.18),
    (11.0, 2, 1.0, 0.78, -0.24),
    (12.0, 0, 2.5, 0.90,  0.00),
    # 1.5 beats of breathing rest (14.5 .. 16.0)
]

LEITMOTIF_4_4_B2 = [
    (0.0,  4, 1.5, 0.92, -0.15),
    (1.5,  7, 1.0, 0.95,  0.08),
    (2.5,  9, 2.5, 1.05,  0.26),
    (5.0,  7, 1.5, 0.92,  0.12),
    (6.5,  6, 1.5, 0.88, -0.06),
    (8.0,  4, 2.0, 0.86, -0.16),
    (10.0, 2, 1.5, 0.82,  0.10),
    (11.5, 0, 3.0, 0.96,  0.00),
    # 1.5 beats of breathing rest (14.5 .. 16.0)
]

# 3/4 Waltz Leitmotif phrases for World 4 (4 bars × 3 beats = 12 beats per phrase, 16 bars total!)
LEITMOTIF_3_4_A1 = [
    (0.0,  0, 2.0, 0.86, -0.24),
    (2.0,  2, 1.0, 0.76, -0.08),
    (3.0,  4, 2.0, 0.92,  0.12),
    (5.0,  7, 2.5, 1.02,  0.26),
    (7.5,  6, 1.5, 0.88,  0.10),
    (9.0,  4, 1.0, 0.84, -0.12),
    (10.0, 2, 0.5, 0.78, -0.20),
    (10.5, 4, 1.2, 0.90,  0.06),
]

LEITMOTIF_3_4_B1 = [
    (0.0,  4, 2.0, 0.90, -0.18),
    (2.0,  7, 1.0, 0.94,  0.08),
    (3.0,  9, 2.5, 1.05,  0.28),
    (5.5,  7, 1.5, 0.92,  0.14),
    (7.0,  6, 1.0, 0.86, -0.06),
    (8.0,  4, 1.0, 0.82, -0.18),
    (9.0,  2, 1.0, 0.78, -0.12),
    (10.0, 0, 1.6, 0.94,  0.00),
]


REALM_COMPOSITIONS = [
    {
        "name": "world1",
        "bpm": 112,
        "beats_per_bar": 4,
        # 16-bar A/B harmonic progression (Fmaj7 - G6 - Em7 - Am7 / Dm7 - G7 - Cmaj7 - Am9)
        "chords": [
            [53, 60, 64, 69], [55, 62, 67, 71], [52, 59, 64, 67], [57, 64, 69, 72],
            [53, 60, 64, 69], [55, 62, 67, 71], [48, 55, 60, 64], [57, 64, 69, 71],
            [50, 57, 60, 65], [55, 62, 65, 71], [48, 55, 60, 64], [57, 64, 67, 72],
            [53, 60, 64, 69], [50, 57, 62, 65], [55, 62, 67, 71], [48, 55, 60, 64],
        ],
        # C Major / F Lydian scale degrees 0..9: [0,2,4,7,6,4,2,4] -> C4, E4, G4, C5, B4, G4, E4, G4
        "scale": [60, 62, 64, 65, 67, 69, 71, 72, 74, 76, 79, 81],
    },
    {
        "name": "world2",
        "bpm": 120,
        "beats_per_bar": 4,
        # 16-bar D Dorian heroic forge progression
        "chords": [
            [50, 57, 62, 65], [46, 53, 58, 62], [48, 55, 60, 64], [45, 52, 57, 60],
            [50, 57, 62, 65], [52, 59, 64, 67], [48, 55, 60, 64], [50, 57, 62, 65],
            [46, 53, 58, 62], [48, 55, 60, 64], [50, 57, 62, 65], [52, 59, 64, 67],
            [46, 53, 58, 62], [43, 50, 55, 59], [45, 52, 57, 61], [50, 57, 62, 65],
        ],
        # D Dorian scale degrees 0..9: D4, E4, F4, G4, A4, B4, C5, D5, E5, F5
        "scale": [62, 64, 65, 67, 69, 71, 72, 74, 76, 77, 79, 81],
    },
    {
        "name": "world3",
        "bpm": 114,
        "beats_per_bar": 4,
        # 16-bar E Minor / Monsoon Dorian progression
        "chords": [
            [52, 59, 64, 67], [48, 55, 60, 64], [50, 57, 62, 66], [47, 54, 59, 62],
            [52, 59, 64, 67], [48, 55, 60, 64], [50, 57, 62, 66], [52, 59, 64, 67],
            [48, 55, 60, 64], [50, 57, 62, 66], [52, 59, 64, 67], [55, 62, 67, 71],
            [48, 55, 60, 64], [50, 57, 62, 66], [47, 54, 59, 62], [52, 59, 64, 67],
        ],
        # E Minor / Dorian scale degrees 0..9: E4, F#4, G4, A4, B4, C#5, D5, E5, F#5, G5
        "scale": [64, 66, 67, 69, 71, 73, 74, 76, 78, 79, 81, 83],
    },
    {
        "name": "world4",
        "bpm": 126,
        "beats_per_bar": 3,  # 3/4 Waltz feel — 3 beats per bar, 16 bars!
        # 16-bar F#m9 / Dmaj7 / Aadd9 / C#m7 waltz progression
        "chords": [
            [54, 61, 66, 69], [50, 57, 62, 66], [45, 52, 57, 61], [49, 56, 61, 64],
            [54, 61, 66, 69], [50, 57, 62, 66], [52, 59, 64, 68], [54, 61, 66, 69],
            [50, 57, 62, 66], [45, 52, 57, 61], [52, 59, 64, 68], [54, 61, 66, 69],
            [50, 57, 62, 66], [47, 54, 59, 62], [49, 56, 61, 65], [54, 61, 66, 69],
        ],
        # F# Minor scale degrees 0..9: F#4, G#4, A4, B4, C#5, D5, E5, F#5, G#5, A5
        "scale": [66, 68, 69, 71, 73, 74, 76, 78, 80, 81, 83, 85],
    },
    {
        "name": "world5",
        "bpm": 104,
        "beats_per_bar": 4,
        # 16-bar Eb Major 7 / Cm9 nocturnal cosmic library progression
        "chords": [
            [51, 58, 63, 67], [48, 55, 60, 63], [44, 51, 56, 60], [46, 53, 58, 62],
            [51, 58, 63, 67], [48, 55, 60, 63], [44, 51, 56, 60], [51, 58, 63, 67],
            [44, 51, 56, 60], [46, 53, 58, 62], [48, 55, 60, 63], [51, 58, 63, 67],
            [44, 51, 56, 60], [41, 48, 53, 56], [46, 53, 58, 62], [51, 58, 63, 67],
        ],
        # Eb Major scale degrees 0..9: Eb4, F4, G4, Ab4, Bb4, C5, D5, Eb5, F5, G5
        "scale": [63, 65, 67, 68, 70, 72, 74, 75, 77, 79, 82, 84],
    },
    {
        "name": "world6",
        "bpm": 128,
        "beats_per_bar": 4,
        # 16-bar Triumphant Summit Anthem (C - G/B - Am7 - Fmaj7 / Dm7 - Em7 - Fmaj7 - G6 - Cmaj9)
        "chords": [
            [48, 55, 60, 64], [47, 55, 62, 67], [45, 52, 60, 64], [53, 60, 65, 69],
            [48, 55, 60, 64], [55, 62, 67, 71], [53, 60, 64, 69], [48, 55, 60, 64],
            [53, 60, 65, 69], [55, 62, 67, 71], [48, 55, 60, 64], [45, 52, 60, 64],
            [50, 57, 62, 65], [52, 59, 64, 67], [53, 60, 65, 69], [55, 62, 67, 71],
        ],
        # C Lydian / Major Summit scale degrees 0..9: C4, D4, E4, F#4, G4, A4, B4, C5, D5, E5
        "scale": [60, 62, 64, 66, 67, 69, 71, 72, 74, 76, 79, 81],
    },
]


def _render_lead_note(realm_name, dur, hz, vel, pan, phrase_idx, note_idx):
    """Synthesizes the realm's physical-modeled lead instrument(s) for the Solstice Spire Leitmotif."""
    if realm_name == "world1":
        # Felt upright piano lead + delicate plucked acoustic harp octave/unison double on phrase peaks
        pl, pr = synth_felt_piano(dur * 1.15, hz, amp=0.22 * vel, pan=pan)
        if phrase_idx >= 2 or note_idx in (3, 7):
            hl, hr = synth_plucked_harp(dur * 1.2, hz * (2.0 if phrase_idx == 2 else 1.0), amp=0.11 * vel, pan=-pan)
            mix_wrapped(pl, pr, int(0.012 * SR), hl, hr, wrap=False)
        return pl, pr
    elif realm_name == "world2":
        # Warm brass horn swell + resonant metallic anvil/marimba bell attack
        bl, br = synth_brass_horn(dur * 1.08, hz, amp=0.22 * vel, pan=pan)
        ml, mr = synth_anvil_marimba(min(dur * 1.1, 0.85), hz, amp=0.14 * vel, pan=-pan * 0.7)
        mix_wrapped(bl, br, 0, ml, mr, wrap=False)
        return bl, br
    elif realm_name == "world3":
        # Section A: Plucked Japanese koto lead with soft shakuhachi halo; Section B: Soaring shakuhachi flute + koto pluck
        kl, kr = synth_koto(dur * 1.18, hz, amp=(0.22 if phrase_idx < 2 else 0.14) * vel, pan=pan)
        if phrase_idx >= 1 or dur >= 1.8:
            fl_amp = (0.21 if phrase_idx >= 2 else 0.13) * vel
            fl, fr = synth_shakuhachi(dur * 1.06, hz, amp=fl_amp, pan=-pan * 0.6, seed=100 + phrase_idx * 10 + note_idx)
            mix_wrapped(kl, kr, 0, fl, fr, wrap=False)
        return kl, kr
    elif realm_name == "world4":
        # Haunting celesta / glass music-box + octave crystalline shimmer in Section B
        cl, cr = synth_celesta(dur * 1.22, hz, amp=0.21 * vel, pan=pan)
        if phrase_idx >= 2:
            cl2, cr2 = synth_celesta(dur * 1.1, hz * 2.0, amp=0.09 * vel, pan=-pan)
            mix_wrapped(cl, cr, int(0.018 * SR), cl2, cr2, wrap=False)
        return cl, cr
    elif realm_name == "world5":
        # Cozy thumb-plucked kalimba + soft octave kalimba harmonic resonance
        kl, kr = synth_kalimba(dur * 1.25, hz, amp=0.23 * vel, pan=pan)
        if phrase_idx >= 2 or note_idx == 3:
            kl2, kr2 = synth_kalimba(dur * 1.1, hz * 2.0, amp=0.09 * vel, pan=-pan * 0.8)
            mix_wrapped(kl, kr, int(0.015 * SR), kl2, kr2, wrap=False)
        return kl, kr
    else:
        # World 6: Triumphant Summit Anthem uniting felt piano, plucked harp, soaring brass, and carillon bells!
        pl, pr = synth_felt_piano(dur * 1.18, hz, amp=0.18 * vel, pan=pan * 0.6)
        hl, hr = synth_plucked_harp(dur * 1.15, hz, amp=0.13 * vel, pan=-pan * 0.7)
        mix_wrapped(pl, pr, 0, hl, hr, wrap=False)
        brl, brr = synth_brass_horn(dur * 1.06, hz, amp=0.17 * vel, pan=pan * 0.4)
        mix_wrapped(pl, pr, 0, brl, brr, wrap=False)
        if phrase_idx >= 1 or note_idx in (0, 3, 7):
            cbl, cbr = synth_carillon_bell(dur * 1.25, hz * 2.0, amp=0.12 * vel, pan=-pan)
            mix_wrapped(pl, pr, 0, cbl, cbr, wrap=False)
        return pl, pr


def generate_music():
    for realm in REALM_COMPOSITIONS:
        name = realm["name"]
        bpm = realm["bpm"]
        bpb = realm["beats_per_bar"]
        chords = realm["chords"]
        scale = realm["scale"]

        beat = 60.0 / bpm
        bar = beat * float(bpb)
        num_bars = len(chords)  # 16 bars!
        total_dur = bar * num_bars
        n = int(round(total_dur * SR))

        bl, br = np.zeros(n, dtype=np.float64), np.zeros(n, dtype=np.float64)
        fl, fr = np.zeros(n, dtype=np.float64), np.zeros(n, dtype=np.float64)

        # 1. Harmonic Pads & Plucked Accompaniment across all 16 bars
        for ci, chord in enumerate(chords):
            t0 = ci * bar
            chord_hz = [midi_to_hz(m) for m in chord]
            section_b = (ci >= 8)
            pad_gain = 0.14 if section_b else 0.115

            if name == "world4":
                pl, pr = synth_bowed_strings(bar * 1.08, chord_hz, amp=pad_gain * 1.15)
            elif name == "world5":
                pl, pr = synth_choir_pad(bar * 1.10, chord_hz, amp=pad_gain * 1.15)
            elif name == "world6":
                pl, pr = synth_bowed_strings(bar * 1.08, chord_hz, amp=pad_gain)
                cl, cr = synth_choir_pad(bar * 1.08, chord_hz, amp=pad_gain * 0.72)
                pl, pr = pl + cl, pr + cr
            elif name == "world2":
                pl, pr = synth_pad(bar * 1.06, chord_hz, amp=pad_gain * 0.85)
                hl, hr = synth_brass_horn(bar * 1.02, midi_to_hz(chord[1]), amp=0.085, pan=-0.25 if ci % 2 == 0 else 0.25)
                mix_wrapped(pl, pr, 0, hl, hr, wrap=False)
            else:
                pl, pr = synth_pad(bar * 1.06, chord_hz, amp=pad_gain)
            mix_wrapped(bl, br, int(t0 * SR), pl, pr, wrap=True)

            # Warm acoustic accompaniment figures with natural breathing space
            if name == "world1":
                # Plucked Karplus-Strong harp broken triad arpeggio on beats 0, 1.5, 2.5 (leaving beat 3 airy)
                for b_off, c_idx, pan in [(0.0, 0, -0.35), (0.5, 1, -0.15), (1.5, 2, 0.18), (2.5, 3, 0.35)]:
                    hl, hr = synth_plucked_harp(beat * 1.6, midi_to_hz(chord[c_idx] + 12), amp=0.105, pan=pan)
                    mix_wrapped(bl, br, int((t0 + b_off * beat) * SR), hl, hr, wrap=True)
            elif name == "world2":
                # Resonant anvil-marimba warm fifth ostinato on beats 0 and 2.5
                for b_off, c_idx, pan in [(0.0, 0, -0.32), (1.5, 2, 0.28), (2.5, 3, -0.18)]:
                    ml, mr = synth_anvil_marimba(beat * 1.4, midi_to_hz(chord[c_idx] + 12), amp=0.095, pan=pan)
                    mix_wrapped(bl, br, int((t0 + b_off * beat) * SR), ml, mr, wrap=True)
            elif name == "world3":
                # Sparse Japanese koto accompaniment plucks
                for b_off, c_idx, pan in [(0.0, 0, -0.38), (2.0, 2, 0.32), (3.0, 3, -0.15)]:
                    kl, kr = synth_koto(beat * 1.5, midi_to_hz(chord[c_idx] + 12), amp=0.095, pan=pan)
                    mix_wrapped(bl, br, int((t0 + b_off * beat) * SR), kl, kr, wrap=True)
            elif name == "world4":
                # 3/4 Waltz accompaniment: Beat 1 warm low cello pluck, Beats 2 & 3 celesta waltz chords
                bl_p, br_p = synth_plucked_harp(beat * 1.4, midi_to_hz(chord[0]), amp=0.12, pan=-0.2)
                mix_wrapped(bl, br, int(t0 * SR), bl_p, br_p, wrap=True)
                for w_beat, pan in [(1.0, 0.32), (2.0, -0.32)]:
                    for m_c in chord[1:3]:
                        cl, cr = synth_celesta(beat * 0.95, midi_to_hz(m_c + 12), amp=0.068, pan=pan)
                        mix_wrapped(bl, br, int((t0 + w_beat * beat) * SR), cl, cr, wrap=True)
            elif name == "world5":
                # Gentle kalimba starry chord plucks on beats 0 and 2.5
                for b_off, c_idx, pan in [(0.0, 1, -0.35), (1.5, 2, 0.30), (2.5, 3, -0.22)]:
                    kl, kr = synth_kalimba(beat * 1.6, midi_to_hz(chord[c_idx] + 12), amp=0.095, pan=pan)
                    mix_wrapped(bl, br, int((t0 + b_off * beat) * SR), kl, kr, wrap=True)
            elif name == "world6":
                # Sweeping Summit Harp & Felt Piano chordal cascade
                for b_off, c_idx, pan in [(0.0, 0, -0.40), (0.5, 1, -0.18), (1.0, 2, 0.18), (2.0, 3, 0.40), (3.0, 2, -0.15)]:
                    hl, hr = synth_plucked_harp(beat * 1.5, midi_to_hz(chord[c_idx] + 12), amp=0.11, pan=pan)
                    mix_wrapped(bl, br, int((t0 + b_off * beat) * SR), hl, hr, wrap=True)

        # 2. The "Solstice Spire" Main Leitmotif across 4 phrases (4 bars each = 16 bars)
        if bpb == 3:
            phrases = [LEITMOTIF_3_4_A1, LEITMOTIF_3_4_A1, LEITMOTIF_3_4_B1, LEITMOTIF_3_4_B1]
        else:
            phrases = [LEITMOTIF_4_4_A1, LEITMOTIF_4_4_A2, LEITMOTIF_4_4_B1, LEITMOTIF_4_4_B2]

        for p_idx, phrase in enumerate(phrases):
            phrase_t0 = p_idx * 4.0 * bar
            for n_idx, (b_off, deg, dur_beats, vel, pan) in enumerate(phrase):
                note_midi = scale[deg % len(scale)]
                hz = midi_to_hz(note_midi)
                ndur = dur_beats * beat
                nl, nr = _render_lead_note(name, ndur, hz, vel, pan, p_idx, n_idx)
                mix_wrapped(bl, br, int((phrase_t0 + b_off * beat) * SR), nl, nr, wrap=True)

        bl, br = add_reverb(bl, br, decay=0.38, wrap=True)
        save_wav(bl, br, os.path.join(MUSIC_DIR, f"{name}_base.wav"))

        # 3. Realm-Specific Physical-Modeled Flow Stem (_flow.wav: groove + bass + counter-harmony)
        seed = 10 + len(name) * 17
        for ci, chord in enumerate(chords):
            t0 = ci * bar
            r_hz = midi_to_hz(chord[0] - 12)
            f_hz = midi_to_hz(chord[0] - 5)
            section_b = (ci >= 8)
            dyn = 1.08 if section_b else 0.92

            if name == "world4":
                # 3/4 Waltz Flow Groove (3 beats per bar): delicate glass-triangle waltz pulse + bowed bass + celesta counter-melody
                bsl, bsr = synth_bass(beat * 0.85, r_hz, 0.24 * dyn)
                mix_wrapped(fl, fr, int(t0 * SR), bsl, bsr, wrap=True)
                tl1, tr1 = synth_glass_triangle(0.55, 2640.0, 0.12 * dyn, -0.25)
                mix_wrapped(fl, fr, int(t0 * SR), tl1, tr1, wrap=True)
                for wb in (1, 2):
                    tb = t0 + wb * beat
                    tl2, tr2 = synth_glass_triangle(0.22, 3520.0 if wb == 1 else 3120.0, 0.075 * dyn, 0.25 if wb == 1 else -0.15)
                    mix_wrapped(fl, fr, int(tb * SR), tl2, tr2, wrap=True)
                    m_arp = scale[(ci * 2 + wb * 2) % 8] + 12
                    cl, cr = synth_celesta(beat * 0.85, midi_to_hz(m_arp), amp=0.11 * dyn, pan=-0.32 if wb == 1 else 0.32)
                    mix_wrapped(fl, fr, int(tb * SR), cl, cr, wrap=True)
                continue

            # 4/4 Realms (Worlds 1, 2, 3, 5, 6)
            for b in range(4):
                tb = t0 + b * beat
                if name == "world1":
                    # Light brushed shaker / woodblock bounce + plucked harp flow counter-arpeggio
                    if b in (0, 2):
                        kl, kr = synth_kick(0.32 * dyn)
                        mix_wrapped(fl, fr, int(tb * SR), kl, kr, wrap=True)
                    bsl, bsr = synth_bass(beat * 0.55, r_hz if b % 2 == 0 else f_hz, 0.22 * dyn)
                    mix_wrapped(fl, fr, int(tb * SR), bsl, bsr, wrap=True)
                    shl, shr = synth_brushed_shaker(0.11, 0.11 * dyn, 0.25 if b % 2 == 0 else -0.25, seed)
                    seed += 1
                    mix_wrapped(fl, fr, int((tb + beat * 0.5) * SR), shl, shr, wrap=True)
                    if b in (1, 3):
                        wbl, wbr = synth_woodblock(680.0 if b == 1 else 820.0, 0.14 * dyn, -0.22 if b == 1 else 0.22)
                        mix_wrapped(fl, fr, int((tb + (0.0 if b == 1 else beat * 0.5)) * SR), wbl, wbr, wrap=True)
                    if b in (0, 1, 2):
                        m_h = scale[(ci + b * 2) % 8] + 12
                        hl, hr = synth_plucked_harp(beat * 0.9, midi_to_hz(m_h), amp=0.115 * dyn, pan=-0.35 if b % 2 == 0 else 0.35)
                        mix_wrapped(fl, fr, int((tb + beat * 0.5) * SR), hl, hr, wrap=True)

                elif name == "world2":
                    # Driving clockwork rim / kick groove + anvil-marimba syncopation
                    if b in (0, 2):
                        kl, kr = synth_kick(0.44 * dyn)
                        mix_wrapped(fl, fr, int(tb * SR), kl, kr, wrap=True)
                    elif b == 1:
                        kl, kr = synth_kick(0.30 * dyn)
                        mix_wrapped(fl, fr, int((tb + beat * 0.5) * SR), kl, kr, wrap=True)
                    bsl, bsr = synth_bass(beat * 0.48, r_hz if b != 3 else f_hz, 0.26 * dyn)
                    mix_wrapped(fl, fr, int(tb * SR), bsl, bsr, wrap=True)
                    rl1, rr1 = synth_clockwork_rim(0.16 * dyn, 0.24 if b % 2 == 0 else -0.24, seed)
                    seed += 1
                    mix_wrapped(fl, fr, int((tb + beat * 0.5) * SR), rl1, rr1, wrap=True)
                    if b in (1, 3):
                        rl2, rr2 = synth_clockwork_rim(0.19 * dyn, -0.18, seed)
                        seed += 1
                        mix_wrapped(fl, fr, int(tb * SR), rl2, rr2, wrap=True)
                        m_a = scale[(ci * 2 + b) % 8] + 12
                        ml, mr = synth_anvil_marimba(beat * 0.85, midi_to_hz(m_a), amp=0.12 * dyn, pan=0.3 * (1 if b == 1 else -1))
                        mix_wrapped(fl, fr, int((tb + beat * 0.5) * SR), ml, mr, wrap=True)

                elif name == "world3":
                    # Warm wooden taiko & bamboo clack rhythm + nimble koto flow plucks
                    if b == 0:
                        tkl, tkr = synth_taiko(68.0, 0.40 * dyn, -0.08)
                        mix_wrapped(fl, fr, int(tb * SR), tkl, tkr, wrap=True)
                    elif b == 2:
                        tkl, tkr = synth_taiko(76.0, 0.34 * dyn, 0.08)
                        mix_wrapped(fl, fr, int((tb + beat * 0.5) * SR), tkl, tkr, wrap=True)
                    bsl, bsr = synth_bass(beat * 0.50, r_hz, 0.22 * dyn)
                    mix_wrapped(fl, fr, int(tb * SR), bsl, bsr, wrap=True)
                    bcl, bcr = synth_bamboo_clack(0.15 * dyn, 0.28 if b % 2 == 0 else -0.28, seed)
                    seed += 1
                    mix_wrapped(fl, fr, int((tb + beat * 0.5) * SR), bcl, bcr, wrap=True)
                    if b in (0, 2, 3):
                        m_k = scale[(ci + b * 2) % 8] + 12
                        kl, kr = synth_koto(beat * 0.85, midi_to_hz(m_k), amp=0.115 * dyn, pan=-0.32 if b % 2 == 0 else 0.32)
                        mix_wrapped(fl, fr, int((tb + beat * 0.5) * SR), kl, kr, wrap=True)

                elif name == "world5":
                    # Soft heartbeat sub-pulse + brushed page shaker + twinkling kalimba response
                    if b in (0, 2):
                        hbl, hbr = synth_heartbeat_sub(0.32 * dyn)
                        mix_wrapped(fl, fr, int(tb * SR), hbl, hbr, wrap=True)
                    shl, shr = synth_brushed_shaker(0.10, 0.085 * dyn, -0.22 if b % 2 == 0 else 0.22, seed)
                    seed += 1
                    mix_wrapped(fl, fr, int((tb + beat * 0.5) * SR), shl, shr, wrap=True)
                    if b in (1, 3):
                        m_kal = scale[(ci * 2 + b) % 8] + 12
                        kl, kr = synth_kalimba(beat * 1.1, midi_to_hz(m_kal), amp=0.12 * dyn, pan=0.32 if b == 1 else -0.32)
                        mix_wrapped(fl, fr, int((tb + beat * 0.5) * SR), kl, kr, wrap=True)

                else:
                    # World 6: Triumphant Summit Anthem flow groove (kick + taiko timpani + shaker + carillon/harp)
                    if b in (0, 2):
                        kl, kr = synth_kick(0.42 * dyn)
                        mix_wrapped(fl, fr, int(tb * SR), kl, kr, wrap=True)
                        tkl, tkr = synth_taiko(65.0 if b == 0 else 73.0, 0.26 * dyn, 0.0)
                        mix_wrapped(fl, fr, int(tb * SR), tkl, tkr, wrap=True)
                    bsl, bsr = synth_bass(beat * 0.5, r_hz if b % 2 == 0 else f_hz, 0.26 * dyn)
                    mix_wrapped(fl, fr, int(tb * SR), bsl, bsr, wrap=True)
                    shl, shr = synth_brushed_shaker(0.10, 0.11 * dyn, 0.26 if b % 2 == 0 else -0.26, seed)
                    seed += 1
                    mix_wrapped(fl, fr, int((tb + beat * 0.5) * SR), shl, shr, wrap=True)
                    m_c = scale[(ci * 2 + b * 2) % 8] + 12
                    hl, hr = synth_plucked_harp(beat * 0.85, midi_to_hz(m_c), amp=0.12 * dyn, pan=-0.36 if b % 2 == 0 else 0.36)
                    mix_wrapped(fl, fr, int((tb + beat * 0.5) * SR), hl, hr, wrap=True)
                    if b in (1, 3):
                        cbl, cbr = synth_carillon_bell(beat * 1.1, midi_to_hz(m_c), amp=0.105 * dyn, pan=0.28 if b == 1 else -0.28)
                        mix_wrapped(fl, fr, int(tb * SR), cbl, cbr, wrap=True)

        fl, fr = add_reverb(fl, fr, decay=0.24, wrap=True)
        save_wav(fl, fr, os.path.join(MUSIC_DIR, f"{name}_flow.wav"))
        print(f"[gen_audio] Generated 16-bar Leitmotif {name} base + flow (.wav)")

    # Generate summit_swell.wav (~16.0s seamless loop of soaring golden celestial choir + high strings
    # playing the Solstice Leitmotif in radiant harmony for altitude > 980m!)
    swell_bpm = 120.0
    swell_beat = 60.0 / swell_bpm
    swell_bar = swell_beat * 4.0
    swell_bars = 8
    swell_dur = swell_bar * swell_bars  # 16.0s exact
    sn = int(round(swell_dur * SR))
    sl_buf, sr_buf = np.zeros(sn, dtype=np.float64), np.zeros(sn, dtype=np.float64)

    swell_chords = [
        [60, 67, 72, 76], [62, 67, 71, 74], [57, 64, 69, 72], [53, 60, 65, 69],
        [60, 67, 72, 76], [62, 67, 71, 76], [65, 69, 72, 79], [67, 71, 74, 79],
    ]
    swell_scale = [60, 62, 64, 66, 67, 69, 71, 72, 74, 76, 79, 81]
    for ci, schord in enumerate(swell_chords):
        t0 = ci * swell_bar
        chz = [midi_to_hz(m) for m in schord]
        chl, chr_ = synth_choir_pad(swell_bar * 1.12, chz, amp=0.145)
        stl, str_ = synth_bowed_strings(swell_bar * 1.12, [h * 2.0 for h in chz[:3]], amp=0.11)
        mix_wrapped(sl_buf, sr_buf, int(t0 * SR), chl + stl, chr_ + str_, wrap=True)

    for p_idx, phrase in enumerate([LEITMOTIF_4_4_A1, LEITMOTIF_4_4_B1]):
        pt0 = p_idx * 4.0 * swell_bar
        for b_off, deg, dur_beats, vel, pan in phrase:
            hz = midi_to_hz(swell_scale[deg % len(swell_scale)] + 12)
            ndur = dur_beats * swell_beat
            chl, chr_ = synth_choir_pad(ndur * 1.15, [hz, hz * 0.5], amp=0.13 * vel)
            cbl, cbr = synth_carillon_bell(ndur * 1.3, hz, amp=0.11 * vel, pan=pan)
            mix_wrapped(sl_buf, sr_buf, int((pt0 + b_off * swell_beat) * SR), chl, chr_, wrap=True)
            mix_wrapped(sl_buf, sr_buf, int((pt0 + b_off * swell_beat) * SR), cbl, cbr, wrap=True)

    sl_buf, sr_buf = add_reverb(sl_buf, sr_buf, decay=0.45, wrap=True)
    save_wav(sl_buf, sr_buf, os.path.join(MUSIC_DIR, "summit_swell.wav"))
    print("[gen_audio] Generated summit_swell.wav (16.0s radiant celestial choir & strings Leitmotif swell)")


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


def _pan_gains(pan):
    pan_c = max(-1.0, min(1.0, float(pan)))
    return math.cos((pan_c + 1.0) * math.pi * 0.25), math.sin((pan_c + 1.0) * math.pi * 0.25)


def _snap_loop_freq(hz, dur):
    """Snap a frequency to an integer number of cycles over dur for 100% phase-exact looping."""
    cycles = max(1, int(round(hz * dur)))
    return cycles / dur


def _spectral_filter_loop(sig, low_hz=None, high_hz=None, bp_center=None, bp_q=None, tilt_db_oct=0.0):
    """Zero-phase circular FFT spectral filter: preserves mathematically exact loop boundaries."""
    n = len(sig)
    spec = np.fft.rfft(sig)
    freqs = np.fft.rfftfreq(n, 1.0 / SR)
    h = np.ones_like(freqs, dtype=np.float64)
    h[0] = 0.0
    f_safe = np.maximum(freqs, 1e-3)

    if tilt_db_oct != 0.0:
        h *= np.power(np.maximum(freqs, 24.0) / 500.0, tilt_db_oct / 6.0206)
    if low_hz is not None and low_hz > 0.0:
        h *= 1.0 / np.sqrt(1.0 + np.power(low_hz / f_safe, 6.0))
    if high_hz is not None and high_hz > 0.0:
        h *= 1.0 / np.sqrt(1.0 + np.power(freqs / high_hz, 6.0))
    if bp_center is not None and bp_q is not None and bp_center > 0.0:
        bw_term = bp_q * (f_safe / bp_center - bp_center / f_safe)
        h *= 1.0 / np.sqrt(1.0 + bw_term * bw_term)

    h[0] = 0.0
    return np.fft.irfft(spec * h, n=n)


def _loop_crossfade(l, r, target_n):
    """Equal-power overlap crossfade from an extended buffer down to exact target_n samples."""
    xf = len(l) - target_n
    if xf <= 0:
        return l[:target_n].copy(), r[:target_n].copy()
    out_l = l[:target_n].copy()
    out_r = r[:target_n].copy()
    theta = 0.5 * math.pi * np.linspace(0.0, 1.0, xf, endpoint=False, dtype=np.float64)
    fade_in = np.sin(theta)
    fade_out = np.cos(theta)
    out_l[:xf] = out_l[:xf] * fade_in + l[target_n:target_n + xf] * fade_out
    out_r[:xf] = out_r[:xf] * fade_in + r[target_n:target_n + xf] * fade_out
    return out_l, out_r


def _stereo_filtered_noise(n, rng, low_hz=None, high_hz=None, bp_center=None, bp_q=None,
                           tilt_db_oct=-3.0, width=0.65):
    """Warm, mono-compatible stereo filtered noise bed with mathematically seamless loop seam."""
    common = rng.standard_normal(n)
    side_l = rng.standard_normal(n)
    side_r = rng.standard_normal(n)
    raw_l = common * (1.0 - width * 0.5) + side_l * (width * 0.5)
    raw_r = common * (1.0 - width * 0.5) + side_r * (width * 0.5)
    fl = _spectral_filter_loop(raw_l, low_hz=low_hz, high_hz=high_hz,
                               bp_center=bp_center, bp_q=bp_q, tilt_db_oct=tilt_db_oct)
    fr = _spectral_filter_loop(raw_r, low_hz=low_hz, high_hz=high_hz,
                               bp_center=bp_center, bp_q=bp_q, tilt_db_oct=tilt_db_oct)
    rms = math.sqrt(0.5 * (float(np.mean(fl * fl)) + float(np.mean(fr * fr))) + 1e-12)
    return fl / rms, fr / rms


def _fade_tail(l, r, ms=18.0):
    """Smooth cosine end-taper for one-shot SFX to guarantee zero buffer-end click."""
    m = min(len(l), max(1, int(ms * 0.001 * SR)))
    taper = 0.5 + 0.5 * np.cos(math.pi * np.linspace(0.0, 1.0, m, dtype=np.float64))
    out_l = l.copy()
    out_r = r.copy()
    out_l[-m:] *= taper
    out_r[-m:] *= taper
    return out_l, out_r


def _finalize_ambience(l, r, target_rms=0.11, peak_ceiling=0.48):
    l = l - float(np.mean(l))
    r = r - float(np.mean(r))
    rms = math.sqrt(0.5 * (float(np.mean(l * l)) + float(np.mean(r * r))) + 1e-12)
    scale = target_rms / rms
    l = l * scale
    r = r * scale
    peak = max(float(np.max(np.abs(l))), float(np.max(np.abs(r))), 1e-6)
    if peak > peak_ceiling:
        att = peak_ceiling / peak
        l = l * att
        r = r * att
    return l, r


def _synth_songbird_trill(notes_hz, dur_note=0.14, gap=0.055, amp=0.085, pan=0.0, vib_hz=14.0):
    """Soft distant morning songbird two/three-note filtered sine trill (warm, zero harshness)."""
    two_pi = 2.0 * math.pi
    total_dur = len(notes_hz) * (dur_note + gap) + 0.08
    n = int(total_dur * SR)
    buf = np.zeros(n, dtype=np.float64)
    cursor = 0
    for idx, f_end in enumerate(notes_hz):
        nd = dur_note * (1.28 if idx == len(notes_hz) - 1 else 0.90)
        m = int(nd * SR)
        t = np.arange(m, dtype=np.float64) / SR
        f_start = f_end * (0.86 if idx == 0 else 0.94)
        glide = f_start + (f_end - f_start) * (1.0 - np.exp(-t * 28.0))
        vib_amt = (0.018 * f_end) * np.minimum(1.0, t / 0.045) if idx == len(notes_hz) - 1 else 0.006 * f_end
        f = glide + vib_amt * np.sin(two_pi * vib_hz * t)
        ph = np.cumsum(two_pi * f / SR)
        env = np.sin(math.pi * np.clip(t / nd, 0.0, 1.0)) ** 1.35
        # Pure warm flute-like bird tone (tiny soft 2nd harmonic only)
        s = (0.94 * np.sin(ph) + 0.06 * np.sin(ph * 2.0)) * env * amp
        end = min(n, cursor + m)
        buf[cursor:end] += s[:end - cursor]
        cursor += int((nd + gap) * SR)
    gl, gr = _pan_gains(pan)
    return buf * gl, buf * gr


def _synth_bamboo_chime(dur, freq, amp=0.11, pan=0.0):
    """Hollow warm bamboo wind-chime with muted woody partials and breathy knock."""
    n = int(dur * SR)
    t = np.arange(n, dtype=np.float64) / SR
    two_pi = 2.0 * math.pi
    att = np.minimum(1.0, t / 0.014)
    s = (
        0.78 * np.sin(two_pi * freq * t) * np.exp(-t * (2.6 / max(dur, 0.4)))
        + 0.16 * np.sin(two_pi * freq * 2.71 * t) * np.exp(-t * 9.5)
        + 0.06 * np.sin(two_pi * freq * 4.18 * t) * np.exp(-t * 18.0)
    ) * att * amp
    gl, gr = _pan_gains(pan)
    return s * gl, s * gr


def _synth_glass_harp(dur, freq, amp=0.075, pan=0.0, shimmer_hz=4.4):
    """Hushed bowed twilight glass-harp swell with silky crystalline harmonics."""
    n = int(dur * SR)
    t = np.arange(n, dtype=np.float64) / SR
    two_pi = 2.0 * math.pi
    env = np.sin(math.pi * np.clip(t / dur, 0.0, 1.0)) ** 1.65
    trem = 0.88 + 0.12 * np.sin(two_pi * shimmer_hz * t)
    s = (
        0.80 * np.sin(two_pi * freq * t)
        + 0.15 * np.sin(two_pi * freq * 2.0 * t + 0.3) * (0.7 + 0.3 * np.sin(two_pi * 0.8 * t))
        + 0.05 * np.sin(two_pi * freq * 3.004 * t)
    ) * env * trem * amp
    gl, gr = _pan_gains(pan)
    return s * gl, s * gr


def _synth_ocarina_note(dur, f_start, f_end, amp=0.36, rng=None, breath=0.08):
    """Warm wooden ocarina note with rounded belly resonance and gentle breath chiff."""
    n = int(dur * SR)
    t = np.arange(n, dtype=np.float64) / SR
    two_pi = 2.0 * math.pi
    f = f_start + (f_end - f_start) * (1.0 - np.exp(-t * 36.0))
    ph = np.cumsum(two_pi * f / SR)
    att = np.minimum(1.0, t / 0.011)
    rel = np.minimum(1.0, np.maximum(0.0, (dur - t) / 0.024))
    env = att * rel * np.exp(-t * 6.5)
    body = (
        0.82 * np.sin(ph)
        + 0.14 * np.sin(ph * 2.0) * np.exp(-t * 10.0)
        + 0.04 * np.sin(ph * 3.0) * np.exp(-t * 16.0)
    ) * env
    if rng is not None and breath > 0.0:
        nz = _spectral_filter_loop(rng.standard_normal(n), bp_center=1750.0, bp_q=1.8, high_hz=3200.0)
        nz_rms = math.sqrt(float(np.mean(nz * nz)) + 1e-12)
        chiff = (nz / nz_rms) * np.minimum(1.0, t / 0.004) * np.exp(-t * 58.0) * breath
        body += chiff
    return body * amp


def _synth_fox_yip(dur, f_start, f_peak, f_end, amp=0.30, pan=0.0):
    """Playful cheerful stylized fox-like musical formant chirp (never shrill)."""
    n = int(dur * SR)
    t = np.arange(n, dtype=np.float64) / SR
    two_pi = 2.0 * math.pi
    u = np.clip(t / max(dur, 1e-4), 0.0, 1.0)
    # Rise quickly to bright peak then taper cheekily
    arch = np.sin(math.pi * np.power(u, 0.72))
    f = f_start + (f_peak - f_start) * arch - (f_peak - f_end) * np.maximum(0.0, u - 0.55) * 1.4
    ph = np.cumsum(two_pi * f / SR)
    env = np.minimum(1.0, t / 0.006) * np.power(np.maximum(0.0, 1.0 - u), 0.95) * np.exp(-t * 5.0)
    # Warm vocal-like triangle/sine hybrid with soft 2nd & 3rd formant
    s = (
        0.64 * np.sin(ph)
        + 0.25 * np.sin(ph * 2.0) * (0.55 + 0.45 * arch)
        + 0.11 * np.sin(ph * 3.0) * np.exp(-t * 14.0)
    ) * env * amp
    gl, gr = _pan_gains(pan)
    return s * gl, s * gr


def _synth_fairy_harp(dur, freq, amp=0.28, pan=0.0):
    """Delicate airy plucked origami-harp / celesta tone."""
    n = int(dur * SR)
    t = np.arange(n, dtype=np.float64) / SR
    two_pi = 2.0 * math.pi
    att = np.minimum(1.0, t / 0.004)
    s = (
        0.72 * np.sin(two_pi * freq * t) * np.exp(-t * (5.2 / max(dur, 0.14)))
        + 0.20 * np.sin(two_pi * freq * 2.0 * t) * np.exp(-t * 14.0)
        + 0.08 * np.sin(two_pi * freq * 3.0 * t) * np.exp(-t * 24.0)
    ) * att * amp
    gl, gr = _pan_gains(pan)
    return s * gl, s * gr


def generate_ambience():
    two_pi = 2.0 * math.pi
    dur = 12.0
    n = int(dur * SR)
    t = np.arange(n, dtype=np.float64) / SR

    # 1. World 1 — The Sunken Conservatory: sunlit breeze + distant morning songbirds
    rng = np.random.default_rng(101)
    bl, br = _stereo_filtered_noise(n, rng, low_hz=95.0, high_hz=920.0, bp_center=340.0, bp_q=0.75, tilt_db_oct=-3.5, width=0.68)
    gust_l = 0.72 + 0.18 * np.sin(two_pi * (1.0 / dur) * t + 0.4) + 0.10 * np.sin(two_pi * (2.0 / dur) * t + 1.8)
    gust_r = 0.72 + 0.18 * np.sin(two_pi * (1.0 / dur) * t + 1.2) + 0.10 * np.sin(two_pi * (3.0 / dur) * t + 0.5)
    l = bl * gust_l * 0.14
    r = br * gust_r * 0.14
    # Feathery canopy leaf rustle (soft, breathing with gusts, strictly below 2600 Hz)
    rl, rr = _stereo_filtered_noise(n, rng, low_hz=1150.0, high_hz=2550.0, bp_center=1750.0, bp_q=1.1, tilt_db_oct=-2.0, width=0.80)
    leaf_env = np.power(0.5 + 0.5 * np.sin(two_pi * (2.0 / dur) * t + 0.9), 2.2)
    l += rl * leaf_env * 0.022
    r += rr * leaf_env * 0.022
    # Distant sunlit harmonic air warmth (very soft C4/G4 open breath)
    for hz_raw, amp_d in [(261.63, 0.012), (392.00, 0.008)]:
        f = _snap_loop_freq(hz_raw, dur)
        swell = 0.55 + 0.45 * np.sin(two_pi * (1.0 / dur) * t + hz_raw * 0.01)
        pad = np.sin(two_pi * f * t) * swell * amp_d
        l += pad
        r += pad
    # 4 natural spaced distant morning songbird trills (C major / A minor pentatonic)
    bird_phrases = [
        (1.35, [midi_to_hz(88), midi_to_hz(91)], 0.13, 0.045, 0.070, -0.52),
        (4.65, [midi_to_hz(86), midi_to_hz(84), midi_to_hz(88)], 0.11, 0.040, 0.058, 0.58),
        (7.85, [midi_to_hz(91), midi_to_hz(93)], 0.14, 0.050, 0.062, -0.35),
        (10.35, [midi_to_hz(88), midi_to_hz(86), midi_to_hz(84)], 0.12, 0.042, 0.052, 0.44),
    ]
    birds_l, birds_r = np.zeros(n), np.zeros(n)
    for t0, notes, nd, gap, amp_b, pan in bird_phrases:
        sl, sr = _synth_songbird_trill(notes, dur_note=nd, gap=gap, amp=amp_b, pan=pan)
        mix_wrapped(birds_l, birds_r, int(t0 * SR), sl, sr, wrap=True)
    birds_l, birds_r = add_reverb(birds_l, birds_r, decay=0.42, wrap=True)
    l += birds_l
    r += birds_r
    l, r = _finalize_ambience(l, r, target_rms=0.105, peak_ceiling=0.45)
    save_wav(l, r, os.path.join(AMBIENCE_DIR, "amb_world1.wav"))

    # 2. World 2 — Foundry of Floating Bells: cozy forge-hearth crackle + warm embers + distant bronze hum
    rng = np.random.default_rng(202)
    hl, hr = _stereo_filtered_noise(n, rng, low_hz=45.0, high_hz=260.0, bp_center=115.0, bp_q=0.7, tilt_db_oct=-5.0, width=0.45)
    ml, mr = _stereo_filtered_noise(n, rng, low_hz=240.0, high_hz=760.0, bp_center=440.0, bp_q=0.9, tilt_db_oct=-3.5, width=0.60)
    hearth_lfo = 0.78 + 0.14 * np.sin(two_pi * (2.0 / dur) * t) + 0.08 * np.sin(two_pi * (3.0 / dur) * t + 1.1)
    l = hl * hearth_lfo * 0.14 + ml * (0.75 + 0.25 * np.sin(two_pi * (1.0 / dur) * t + 0.8)) * 0.055
    r = hr * hearth_lfo * 0.14 + mr * (0.75 + 0.25 * np.sin(two_pi * (1.0 / dur) * t + 1.5)) * 0.055
    # Distant resonant bronze bell hum in D Dorian (D2, A2, D3 + soft bronze overtone)
    bronze_partials = [
        (midi_to_hz(38), 0.048, 1.0, 0.0, -0.15),
        (midi_to_hz(45), 0.036, 2.0, 1.1, 0.18),
        (midi_to_hz(50), 0.026, 1.0, 2.4, -0.22),
        (midi_to_hz(50) * 2.756, 0.011, 2.0, 0.7, 0.26),
    ]
    for hz_raw, amp_p, cyc, ph0, pan in bronze_partials:
        f = _snap_loop_freq(hz_raw, dur)
        sw = 0.62 + 0.38 * np.sin(two_pi * (cyc / dur) * t + ph0)
        sig = np.sin(two_pi * f * t) * sw * amp_p
        gl, gr = _pan_gains(pan)
        l += sig * gl
        r += sig * gr
    # Warm cozy ember crackles & gentle hearth pops (organic, soft, non-harsh)
    crack_l, crack_r = np.zeros(n), np.zeros(n)
    for _ in range(64):
        cdur = float(rng.uniform(0.014, 0.034))
        cn = int(cdur * SR)
        ct = np.arange(cn, dtype=np.float64) / SR
        cf = float(rng.uniform(620.0, 1950.0))
        cdec = float(rng.uniform(110.0, 230.0))
        cpop = (
            np.sin(two_pi * cf * ct) * 0.65
            + np.sin(two_pi * cf * 1.63 * ct) * 0.35
        ) * np.minimum(1.0, ct / 0.0018) * np.exp(-ct * cdec) * float(rng.uniform(0.045, 0.13))
        gl, gr = _pan_gains(float(rng.uniform(-0.72, 0.72)))
        mix_wrapped(crack_l, crack_r, int(float(rng.uniform(0.0, dur)) * SR), cpop * gl, cpop * gr, wrap=True)
    crack_l, crack_r = add_reverb(crack_l, crack_r, decay=0.22, wrap=True)
    l += crack_l
    r += crack_r
    l, r = _finalize_ambience(l, r, target_rms=0.115, peak_ceiling=0.46)
    save_wav(l, r, os.path.join(AMBIENCE_DIR, "amb_world2.wav"))

    # 3. World 3 — The Origami Monsoon: cozy stylized warm steady rain + distant bamboo wind-chimes
    rng = np.random.default_rng(303)
    # Warm rain curtain (bandpass sculpted 300-2350 Hz, zero piercing sibilance)
    rain1_l, rain1_r = _stereo_filtered_noise(n, rng, low_hz=280.0, high_hz=2350.0, bp_center=920.0, bp_q=0.55, tilt_db_oct=-3.4, width=0.72)
    rain2_l, rain2_r = _stereo_filtered_noise(n, rng, low_hz=520.0, high_hz=1650.0, bp_center=1080.0, bp_q=0.85, tilt_db_oct=-2.8, width=0.82)
    swell_r1 = 0.86 + 0.14 * np.sin(two_pi * (1.0 / dur) * t + 0.5)
    swell_r2 = 0.84 + 0.16 * np.sin(two_pi * (2.0 / dur) * t + 2.1)
    l = rain1_l * swell_r1 * 0.115 + rain2_l * swell_r2 * 0.055
    r = rain1_r * swell_r1 * 0.115 + rain2_r * swell_r2 * 0.055
    # Individual cozy stylized rain droplets (tiny rising bubble-plip drops)
    drop_l, drop_r = np.zeros(n), np.zeros(n)
    for _ in range(125):
        ddur = float(rng.uniform(0.015, 0.028))
        dn = int(ddur * SR)
        dt = np.arange(dn, dtype=np.float64) / SR
        f0 = float(rng.uniform(720.0, 1780.0))
        f_drop = f0 * (1.0 + 0.52 * (dt / ddur))
        ph = np.cumsum(two_pi * f_drop / SR)
        env = np.minimum(1.0, dt / 0.0022) * np.exp(-dt * float(rng.uniform(115.0, 190.0)))
        ds = np.sin(ph) * env * float(rng.uniform(0.030, 0.082))
        gl, gr = _pan_gains(float(rng.uniform(-0.82, 0.82)))
        mix_wrapped(drop_l, drop_r, int(float(rng.uniform(0.0, dur)) * SR), ds * gl, ds * gr, wrap=True)
    # Delicate distant bamboo wind-chime shimmer in World 3 E minor / G major pentatonic
    chime_l, chime_r = np.zeros(n), np.zeros(n)
    bamboo_events = [
        (0.90, 76, 1.35, 0.072, -0.48),
        (1.38, 78, 1.15, 0.056, -0.22),
        (4.10, 83, 1.45, 0.068, 0.52),
        (4.52, 74, 1.25, 0.058, 0.30),
        (7.70, 76, 1.40, 0.064, -0.36),
        (10.15, 71, 1.50, 0.062, 0.44),
    ]
    for t0, mnote, cdur, camp, pan in bamboo_events:
        sl, sr = _synth_bamboo_chime(cdur, midi_to_hz(mnote), amp=camp, pan=pan)
        mix_wrapped(chime_l, chime_r, int(t0 * SR), sl, sr, wrap=True)
    chime_l, chime_r = add_reverb(chime_l, chime_r, decay=0.40, wrap=True)
    l += drop_l + chime_l
    r += drop_r + chime_r
    l, r = _finalize_ambience(l, r, target_rms=0.11, peak_ceiling=0.44)
    save_wav(l, r, os.path.join(AMBIENCE_DIR, "amb_world3.wav"))

    # 4. World 4 — The Shattered Mirror Gallery: twilight glass-harp shimmer + high-altitude breeze
    rng = np.random.default_rng(404)
    al, ar = _stereo_filtered_noise(n, rng, low_hz=200.0, high_hz=1250.0, bp_center=540.0, bp_q=0.85, tilt_db_oct=-3.6, width=0.75)
    air_l = 0.74 + 0.26 * np.sin(two_pi * (1.0 / dur) * t + 0.2)
    air_r = 0.74 + 0.26 * np.sin(two_pi * (1.0 / dur) * t + 2.3)
    l = al * air_l * 0.088
    r = ar * air_r * 0.088
    # Hushed overlapping twilight glass-harp harmonic swells (F#m9 / Aadd9)
    gh_l, gh_r = np.zeros(n), np.zeros(n)
    glass_notes = [
        (0.20, 66, 3.6, 0.062, -0.55, 3.8),
        (1.60, 73, 3.4, 0.054, 0.45, 4.6),
        (3.10, 76, 3.2, 0.050, -0.25, 5.1),
        (4.50, 80, 3.5, 0.044, 0.60, 4.2),
        (6.00, 69, 3.6, 0.058, -0.45, 3.6),
        (7.40, 76, 3.2, 0.052, 0.35, 4.9),
        (8.90, 83, 3.0, 0.038, -0.50, 5.4),
        (10.20, 73, 3.4, 0.052, 0.50, 4.1),
    ]
    for t0, mnote, gdur, gamp, pan, shz in glass_notes:
        sl, sr = _synth_glass_harp(gdur, midi_to_hz(mnote), amp=gamp, pan=pan, shimmer_hz=shz)
        mix_wrapped(gh_l, gh_r, int(t0 * SR), sl, sr, wrap=True)
    gh_l, gh_r = add_reverb(gh_l, gh_r, decay=0.48, wrap=True)
    l += gh_l
    r += gh_r
    l, r = _finalize_ambience(l, r, target_rms=0.10, peak_ceiling=0.44)
    save_wav(l, r, os.path.join(AMBIENCE_DIR, "amb_world4.wav"))

    # 5. World 5 — The Cloud-Whale Library: velvet cosmic aurora hum + soft turning storybook pages
    rng = np.random.default_rng(505)
    # Deep velvet cosmic breath
    vl, vr = _stereo_filtered_noise(n, rng, low_hz=75.0, high_hz=620.0, bp_center=240.0, bp_q=0.75, tilt_db_oct=-4.8, width=0.65)
    l = vl * (0.78 + 0.22 * np.sin(two_pi * (1.0 / dur) * t)) * 0.075
    r = vr * (0.78 + 0.22 * np.sin(two_pi * (1.0 / dur) * t + 1.6)) * 0.075
    # Deep velvet cosmic aurora harmonic hum (EbMaj7 / Cm9, phase-locked to 12s)
    aurora_voices = [
        (midi_to_hz(39), 0.068, 1.0, 0.0, -0.20),   # Eb2
        (midi_to_hz(46), 0.054, 1.0, 1.4, 0.22),    # Bb2
        (midi_to_hz(51), 0.046, 2.0, 0.6, -0.35),   # Eb3
        (midi_to_hz(55), 0.034, 1.0, 2.5, 0.38),    # G3
        (midi_to_hz(58), 0.028, 2.0, 1.9, -0.42),   # Bb3
        (midi_to_hz(62), 0.020, 1.0, 3.8, 0.45),    # D4
        (midi_to_hz(75), 0.012, 2.0, 0.3, -0.55),   # Eb5 aurora shimmer
        (midi_to_hz(77), 0.010, 1.0, 2.9, 0.55),    # F5 aurora shimmer
    ]
    for hz_raw, amp_v, cyc, ph0, pan in aurora_voices:
        f = _snap_loop_freq(hz_raw, dur)
        sw = 0.58 + 0.42 * np.sin(two_pi * (cyc / dur) * t + ph0)
        sig = np.sin(two_pi * f * t) * sw * amp_v
        gl, gr = _pan_gains(pan)
        l += sig * gl
        r += sig * gr
    # Soft whispered flutter of distant turning storybook pages
    pg_l, pg_r = np.zeros(n), np.zeros(n)
    page_times = [(1.4, -0.45), (3.9, 0.50), (6.8, -0.35), (9.3, 0.42), (11.1, -0.25)]
    for t0, base_pan in page_times:
        flutters = int(rng.integers(2, 4))
        for k in range(flutters):
            pdur = float(rng.uniform(0.16, 0.28))
            pn = int(pdur * SR)
            pt = np.arange(pn, dtype=np.float64) / SR
            pnoise = _spectral_filter_loop(rng.standard_normal(pn), low_hz=520.0, high_hz=2150.0,
                                           bp_center=float(rng.uniform(950.0, 1550.0)), bp_q=1.2, tilt_db_oct=-2.5)
            prms = math.sqrt(float(np.mean(pnoise * pnoise)) + 1e-12)
            # Soft whispered paper-arch envelope
            u = pt / pdur
            penv = np.power(np.sin(math.pi * u), 1.8) * (0.65 + 0.35 * np.sin(two_pi * 11.0 * pt))
            psig = (pnoise / prms) * penv * float(rng.uniform(0.032, 0.052))
            gl, gr = _pan_gains(base_pan + (k - 1) * 0.12)
            mix_wrapped(pg_l, pg_r, int((t0 + k * 0.095) * SR), psig * gl, psig * gr, wrap=True)
    pg_l, pg_r = add_reverb(pg_l, pg_r, decay=0.44, wrap=True)
    l += pg_l
    r += pg_r
    l, r = _finalize_ambience(l, r, target_rms=0.11, peak_ceiling=0.45)
    save_wav(l, r, os.path.join(AMBIENCE_DIR, "amb_world5.wav"))

    # 6. World 6 — The Crown of the Sun: ethereal golden stratosphere wind + harmonic fifth shimmer
    rng = np.random.default_rng(606)
    wl_lo, wr_lo = _stereo_filtered_noise(n, rng, low_hz=120.0, high_hz=520.0, bp_center=260.0, bp_q=0.75, tilt_db_oct=-4.0, width=0.62)
    wl_hi, wr_hi = _stereo_filtered_noise(n, rng, low_hz=640.0, high_hz=1950.0, bp_center=1150.0, bp_q=1.15, tilt_db_oct=-2.6, width=0.80)
    sky_l = 0.72 + 0.20 * np.sin(two_pi * (1.0 / dur) * t + 0.3) + 0.08 * np.sin(two_pi * (2.0 / dur) * t + 1.4)
    sky_r = 0.72 + 0.20 * np.sin(two_pi * (1.0 / dur) * t + 1.9) + 0.08 * np.sin(two_pi * (2.0 / dur) * t + 0.2)
    l = wl_lo * sky_l * 0.095 + wl_hi * sky_l * 0.048
    r = wr_lo * sky_r * 0.095 + wr_hi * sky_r * 0.048
    # Radiant distant open harmonic fifth shimmer (C-G-D-E golden stratosphere choir)
    crown_partials = [
        (midi_to_hz(48), 0.052, 1.0, 0.0, -0.25),   # C3
        (midi_to_hz(55), 0.048, 1.0, 1.2, 0.25),    # G3
        (midi_to_hz(60), 0.036, 2.0, 0.5, -0.40),   # C4
        (midi_to_hz(67), 0.034, 2.0, 2.1, 0.40),    # G4
        (midi_to_hz(74), 0.020, 1.0, 3.0, -0.52),   # D5
        (midi_to_hz(76), 0.016, 2.0, 1.0, 0.52),    # E5
        (midi_to_hz(79), 0.013, 1.0, 4.4, 0.0),     # G5 halo
    ]
    sh_l, sh_r = np.zeros(n), np.zeros(n)
    for hz_raw, amp_c, cyc, ph0, pan in crown_partials:
        f = _snap_loop_freq(hz_raw, dur)
        sw = 0.56 + 0.44 * np.sin(two_pi * (cyc / dur) * t + ph0)
        sig = np.sin(two_pi * f * t) * sw * amp_c
        gl, gr = _pan_gains(pan)
        sh_l += sig * gl
        sh_r += sig * gr
    sh_l, sh_r = add_reverb(sh_l, sh_r, decay=0.45, wrap=True)
    l += sh_l
    r += sh_r
    l, r = _finalize_ambience(l, r, target_rms=0.11, peak_ceiling=0.46)
    save_wav(l, r, os.path.join(AMBIENCE_DIR, "amb_world6.wav"))

    # 7. Falling Wind Rush — 5.0s seamless dynamic whistling air rush (with equal-power crossfade tail)
    rng = np.random.default_rng(707)
    fdur = 5.0
    fn = int(fdur * SR)
    xf_n = int(0.55 * SR)
    ext_n = fn + xf_n
    ft = np.arange(ext_n, dtype=np.float64) / SR
    # Deep rolling wind body + rushing mid-air + dual silky whistling air formants
    body_l, body_r = _stereo_filtered_noise(ext_n, rng, low_hz=90.0, high_hz=420.0, bp_center=210.0, bp_q=0.70, tilt_db_oct=-4.2, width=0.58)
    rush_l, rush_r = _stereo_filtered_noise(ext_n, rng, low_hz=360.0, high_hz=1850.0, bp_center=860.0, bp_q=0.80, tilt_db_oct=-2.8, width=0.76)
    wh1_l, wh1_r = _stereo_filtered_noise(ext_n, rng, low_hz=420.0, high_hz=1250.0, bp_center=680.0, bp_q=4.8, tilt_db_oct=-1.5, width=0.65)
    wh2_l, wh2_r = _stereo_filtered_noise(ext_n, rng, low_hz=720.0, high_hz=1650.0, bp_center=1060.0, bp_q=5.5, tilt_db_oct=-1.5, width=0.72)
    # Organic billowing turbulence + alternating whistling air sweeps
    billow_l = 0.78 + 0.16 * np.sin(two_pi * 0.60 * ft + 0.3) + 0.08 * np.sin(two_pi * 1.40 * ft + 1.7)
    billow_r = 0.78 + 0.16 * np.sin(two_pi * 0.60 * ft + 1.5) + 0.08 * np.sin(two_pi * 1.40 * ft + 0.4)
    wh_sw1 = 0.45 + 0.55 * np.sin(two_pi * 0.40 * ft + 0.2)
    wh_sw2 = 0.45 + 0.55 * np.sin(two_pi * 0.60 * ft + 2.4)
    # Subtle smooth airy flute-like wind pitch glide (never harsh, adds visceral speed sensation)
    w_freq = 540.0 + 135.0 * np.sin(two_pi * 0.40 * ft) + 45.0 * np.sin(two_pi * 0.80 * ft + 1.1)
    w_tone = np.sin(np.cumsum(two_pi * w_freq / SR)) * (0.014 + 0.010 * wh_sw1)
    fl_ext = body_l * billow_l * 0.15 + rush_l * billow_l * 0.13 + wh1_l * wh_sw1 * 0.072 + wh2_l * wh_sw2 * 0.046 + w_tone
    fr_ext = body_r * billow_r * 0.15 + rush_r * billow_r * 0.13 + wh1_r * wh_sw1 * 0.072 + wh2_r * wh_sw2 * 0.046 + w_tone * 0.92
    fl, fr = _loop_crossfade(fl_ext, fr_ext, fn)
    fl, fr = _finalize_ambience(fl, fr, target_rms=0.145, peak_ceiling=0.55)
    save_wav(fl, fr, os.path.join(AMBIENCE_DIR, "amb_fall_wind.wav"))
    print("[gen_audio] All 7 seamless looping ambience beds (.wav) synthesized successfully.")


def generate_character_chirps():
    rng = np.random.default_rng(808)
    two_pi = 2.0 * math.pi

    # 1. Pip Hop (~0.145s): warm wooden ocarina soft rising two-tone "hoo-pip!"
    n = int(0.145 * SR)
    l, r = np.zeros(n), np.zeros(n)
    n1 = _synth_ocarina_note(0.064, midi_to_hz(79), midi_to_hz(81), amp=0.38, rng=rng, breath=0.09)
    n2 = _synth_ocarina_note(0.088, midi_to_hz(83), midi_to_hz(86), amp=0.44, rng=rng, breath=0.06)
    gl1, gr1 = _pan_gains(-0.10)
    gl2, gr2 = _pan_gains(0.10)
    mix_wrapped(l, r, 0, n1 * gl1, n1 * gr1, wrap=False)
    mix_wrapped(l, r, int(0.054 * SR), n2 * gl2, n2 * gr2, wrap=False)
    l, r = _fade_tail(l, r, ms=14.0)
    save_wav(l, r, os.path.join(SFX_DIR, "chirp_pip_hop.wav"))

    # 2. Pip Joy (~0.33s): bright glowing ember triad chime-chirp
    n = int(0.33 * SR)
    l, r = np.zeros(n), np.zeros(n)
    for idx, (t0, m0, m1, pan) in enumerate([
        (0.000, 79, 81, -0.18),
        (0.062, 83, 84, 0.05),
        (0.128, 86, 88, 0.22),
    ]):
        oc = _synth_ocarina_note(0.135 if idx < 2 else 0.19, midi_to_hz(m0), midi_to_hz(m1), amp=0.34, rng=rng, breath=0.06)
        gl, gr = _pan_gains(pan)
        mix_wrapped(l, r, int(t0 * SR), oc * gl, oc * gr, wrap=False)
        bl, br = synth_bell(0.19, midi_to_hz(m1), amp=0.14, pan=pan, bright=1.05, mod_ratio=2.0, mod_idx=0.75)
        mix_wrapped(l, r, int((t0 + 0.008) * SR), bl, br, wrap=False)
    # Warm ember sparkle top note (G6)
    sl, sr = synth_bell(0.18, midi_to_hz(91), amp=0.15, pan=-0.12, bright=1.15, mod_ratio=2.0, mod_idx=0.8)
    mix_wrapped(l, r, int(0.155 * SR), sl, sr, wrap=False)
    l, r = add_reverb(l, r, decay=0.22, wrap=False)
    l, r = _fade_tail(l, r, ms=24.0)
    save_wav(l, r, os.path.join(SFX_DIR, "chirp_pip_joy.wav"))

    # 3. Koko Hop (~0.135s): playful crisp clockwork spring-bell + bright fox "yip!"
    n = int(0.135 * SR)
    l, r = np.zeros(n), np.zeros(n)
    # Snappy clockwork micro-spring flick
    sp_n = int(0.042 * SR)
    sp_t = np.arange(sp_n, dtype=np.float64) / SR
    sp_f = 580.0 + 780.0 * (1.0 - np.exp(-sp_t * 52.0)) + 28.0 * np.sin(two_pi * 64.0 * sp_t)
    sp = np.sin(np.cumsum(two_pi * sp_f / SR)) * np.minimum(1.0, sp_t / 0.002) * np.exp(-sp_t * 58.0) * 0.24
    mix_wrapped(l, r, 0, sp, sp, wrap=False)
    # Crisp little brass bell tick
    bl, br = synth_bell(0.095, midi_to_hz(86), amp=0.20, pan=0.18, bright=1.25, mod_ratio=2.756, mod_idx=1.1)
    mix_wrapped(l, r, int(0.008 * SR), bl, br, wrap=False)
    # Bright fox "yip!"
    yl, yr = _synth_fox_yip(0.115, midi_to_hz(81), midi_to_hz(88), midi_to_hz(85), amp=0.38, pan=-0.10)
    mix_wrapped(l, r, int(0.015 * SR), yl, yr, wrap=False)
    l, r = _fade_tail(l, r, ms=14.0)
    save_wav(l, r, os.path.join(SFX_DIR, "chirp_koko_hop.wav"))

    # 4. Koko Joy (~0.31s): celebratory springy bell arpeggio + upbeat fox chirp
    n = int(0.31 * SR)
    l, r = np.zeros(n), np.zeros(n)
    for t0, mnote, pan in [(0.000, 78, -0.24), (0.052, 81, 0.20), (0.104, 86, -0.16), (0.156, 90, 0.24)]:
        bl, br = synth_bell(0.15, midi_to_hz(mnote), amp=0.24, pan=pan, bright=1.05, mod_ratio=2.0, mod_idx=0.85)
        mix_wrapped(l, r, int(t0 * SR), bl, br, wrap=False)
    # Playful double fox "yip-yip!"
    y1l, y1r = _synth_fox_yip(0.095, midi_to_hz(79), midi_to_hz(84), midi_to_hz(81), amp=0.34, pan=-0.12)
    y2l, y2r = _synth_fox_yip(0.125, midi_to_hz(81), midi_to_hz(88), midi_to_hz(86), amp=0.38, pan=0.12)
    mix_wrapped(l, r, int(0.018 * SR), y1l, y1r, wrap=False)
    mix_wrapped(l, r, int(0.118 * SR), y2l, y2r, wrap=False)
    l, r = add_reverb(l, r, decay=0.20, wrap=False)
    l, r = _fade_tail(l, r, ms=22.0)
    save_wav(l, r, os.path.join(SFX_DIR, "chirp_koko_joy.wav"))

    # 5. Vesper Hop (~0.155s): airy delicate flutter-harp + papery whisper-chime
    n = int(0.155 * SR)
    l, r = np.zeros(n), np.zeros(n)
    # Soft origami paper wing-flutter breath
    wn = int(0.068 * SR)
    wt = np.arange(wn, dtype=np.float64) / SR
    wnz = _spectral_filter_loop(rng.standard_normal(wn), low_hz=950.0, high_hz=2650.0, bp_center=1650.0, bp_q=1.1, tilt_db_oct=-2.2)
    wrms = math.sqrt(float(np.mean(wnz * wnz)) + 1e-12)
    flutter = (wnz / wrms) * np.sin(math.pi * wt / 0.068) ** 1.4 * (0.65 + 0.35 * np.sin(two_pi * 34.0 * wt)) * 0.16
    mix_wrapped(l, r, 0, flutter * 0.85, flutter * 1.05, wrap=False)
    # Airy delicate two-string plucked fairy-harp (warm E5 -> B5 -> E6 shimmer)
    h1l, h1r = _synth_fairy_harp(0.135, midi_to_hz(83), amp=0.40, pan=-0.22)
    h2l, h2r = _synth_fairy_harp(0.125, midi_to_hz(88), amp=0.36, pan=0.24)
    mix_wrapped(l, r, int(0.010 * SR), h1l, h1r, wrap=False)
    mix_wrapped(l, r, int(0.036 * SR), h2l, h2r, wrap=False)
    l, r = add_reverb(l, r, decay=0.20, wrap=False)
    l, r = _fade_tail(l, r, ms=16.0)
    save_wav(l, r, os.path.join(SFX_DIR, "chirp_vesper_hop.wav"))

    # 6. Vesper Joy (~0.35s): dreamy ascending moth-wing shimmer chime
    n = int(0.35 * SR)
    l, r = np.zeros(n), np.zeros(n)
    # Gossamer fluttering wing shimmer underneath
    wn = int(0.16 * SR)
    wt = np.arange(wn, dtype=np.float64) / SR
    wnz = _spectral_filter_loop(rng.standard_normal(wn), low_hz=950.0, high_hz=2700.0, bp_center=1700.0, bp_q=1.2, tilt_db_oct=-2.2)
    wrms = math.sqrt(float(np.mean(wnz * wnz)) + 1e-12)
    wing = (wnz / wrms) * np.sin(math.pi * wt / 0.16) ** 1.5 * (0.62 + 0.38 * np.sin(two_pi * 26.0 * wt)) * 0.12
    mix_wrapped(l, r, 0, wing * 1.0, wing * 0.9, wrap=False)
    # Dreamy ascending Bmaj7 harp shimmer cascade (silky warm register)
    for t0, mnote, pan, hamp in [
        (0.000, 78, -0.35, 0.33),
        (0.042, 83, -0.16, 0.35),
        (0.088, 87, 0.08, 0.36),
        (0.138, 90, 0.28, 0.34),
        (0.192, 95, 0.42, 0.30),
    ]:
        hl, hr = _synth_fairy_harp(0.19, midi_to_hz(mnote), amp=hamp, pan=pan)
        mix_wrapped(l, r, int(t0 * SR), hl, hr, wrap=False)
    l, r = add_reverb(l, r, decay=0.30, wrap=False)
    l, r = _fade_tail(l, r, ms=24.0)
    save_wav(l, r, os.path.join(SFX_DIR, "chirp_vesper_joy.wav"))
    print("[gen_audio] All 6 expressive musical explorer chirps (.wav) synthesized successfully.")


def generate_celebration_sfx():
    rng = np.random.default_rng(909)
    two_pi = 2.0 * math.pi

    # 1. Firework Pop (~0.68s): crisp celebratory sky-rocket pop + glittering sparkle tail
    n = int(0.68 * SR)
    l, r = np.zeros(n), np.zeros(n)
    # Tiny rapid ascending launch zip (0.00-0.046s)
    zn = int(0.046 * SR)
    zt = np.arange(zn, dtype=np.float64) / SR
    zf = 480.0 + 1350.0 * np.power(zt / 0.046, 1.4)
    zip_sig = np.sin(np.cumsum(two_pi * zf / SR)) * np.sin(math.pi * zt / 0.046) * 0.16
    mix_wrapped(l, r, 0, zip_sig, zip_sig, wrap=False)
    # Punchy celebratory burst pop at 0.044s (warm low-mid thump + crisp air crack)
    pn = int(0.22 * SR)
    pt = np.arange(pn, dtype=np.float64) / SR
    pf = 48.0 + 145.0 * np.exp(-pt * 34.0)
    thump = np.sin(np.cumsum(two_pi * pf / SR)) * np.minimum(1.0, pt / 0.0025) * np.exp(-pt * 15.0) * 0.56
    burst_nz = _spectral_filter_loop(rng.standard_normal(pn), low_hz=260.0, high_hz=4200.0, bp_center=1250.0, bp_q=0.75, tilt_db_oct=-2.0)
    brms = math.sqrt(float(np.mean(burst_nz * burst_nz)) + 1e-12)
    pop_air = (burst_nz / brms) * np.minimum(1.0, pt / 0.0018) * np.exp(-pt * 24.0) * 0.36
    mix_wrapped(l, r, int(0.044 * SR), thump + pop_air, thump + pop_air * 0.94, wrap=False)
    # Glittering wide-stereo sparkle tail (pentatonic micro-twinkles + dainty crackles)
    sparkle_notes = [84, 86, 88, 91, 93, 96, 98, 100, 103]
    for k in range(18):
        t0 = 0.068 + float(rng.uniform(0.0, 0.36))
        mnote = sparkle_notes[int(rng.integers(0, len(sparkle_notes)))]
        pan = float(rng.uniform(-0.82, 0.82))
        s_amp = float(rng.uniform(0.08, 0.16)) * (1.0 - 0.45 * (t0 / 0.45))
        bl, br = _synth_fairy_harp(float(rng.uniform(0.14, 0.24)), midi_to_hz(mnote), amp=s_amp, pan=pan)
        mix_wrapped(l, r, int(t0 * SR), bl, br, wrap=False)
        # Tiny warm spark crackle
        cn = int(0.018 * SR)
        ct = np.arange(cn, dtype=np.float64) / SR
        cf = float(rng.uniform(1400.0, 3400.0))
        ck = np.sin(two_pi * cf * ct) * np.exp(-ct * 220.0) * s_amp * 0.65
        gl, gr = _pan_gains(pan)
        mix_wrapped(l, r, int(t0 * SR), ck * gl, ck * gr, wrap=False)
    l, r = add_reverb(l, r, decay=0.34, wrap=False)
    l, r = _fade_tail(l, r, ms=36.0)
    save_wav(l, r, os.path.join(SFX_DIR, "firework_pop.wav"))

    # 2. Medal Chime (~0.94s): triumphant warm golden rank-medal reveal chord
    n = int(0.94 * SR)
    l, r = np.zeros(n), np.zeros(n)
    # Warm golden body bloom underneath (C4 + G4 + E5 soft pad)
    pl, pr = synth_pad(0.82, [midi_to_hz(60), midi_to_hz(67), midi_to_hz(76)], amp=0.14)
    mix_wrapped(l, r, 0, pl, pr, wrap=False)
    # Gleaming rolled golden Cmaj9 / Lydian reveal cascade
    medal_notes = [
        (0.000, 60, -0.35, 0.24, 1.10),
        (0.028, 67, 0.32, 0.24, 1.15),
        (0.058, 72, -0.22, 0.26, 1.25),
        (0.092, 76, 0.24, 0.26, 1.30),
        (0.128, 79, -0.14, 0.27, 1.35),
        (0.168, 83, 0.16, 0.23, 1.40),
        (0.210, 86, -0.08, 0.22, 1.42),
        (0.248, 91, 0.08, 0.20, 1.45),
    ]
    for t0, mnote, pan, bamp, bright in medal_notes:
        bl, br = synth_bell(0.68, midi_to_hz(mnote), amp=bamp, pan=pan, bright=bright, mod_ratio=2.0, mod_idx=1.05)
        mix_wrapped(l, r, int(t0 * SR), bl, br, wrap=False)
    l, r = add_reverb(l, r, decay=0.40, wrap=False)
    l, r = _fade_tail(l, r, ms=48.0)
    save_wav(l, r, os.path.join(SFX_DIR, "medal_chime.wav"))

    # 3. Shortcut Fanfare (~0.58s): punchy adventurous 4-note golden discovery fanfare
    n = int(0.58 * SR)
    l, r = np.zeros(n), np.zeros(n)
    fanfare_notes = [
        (0.000, 79, 0.12, -0.28, 0.30),  # G5
        (0.078, 83, 0.12, 0.22, 0.31),   # B5
        (0.156, 86, 0.12, -0.16, 0.33),  # D6
        (0.236, 91, 0.33, 0.08, 0.38),   # G6 triumph!
    ]
    for idx, (t0, mnote, ndur, pan, famp) in enumerate(fanfare_notes):
        hz = midi_to_hz(mnote)
        # Sparkling bell lead
        bl, br = synth_bell(ndur + 0.12, hz, amp=famp, pan=pan, bright=1.35, mod_ratio=2.0, mod_idx=1.15)
        mix_wrapped(l, r, int(t0 * SR), bl, br, wrap=False)
        # Warm brassy-marimba octave-below punch for heroic weight
        mn = int((ndur + 0.05) * SR)
        mt = np.arange(mn, dtype=np.float64) / SR
        hz_lo = hz * 0.5
        menv = np.minimum(1.0, mt / 0.006) * np.exp(-mt * (6.5 if idx < 3 else 4.2))
        horn = (0.68 * np.sin(two_pi * hz_lo * mt) + 0.24 * np.sin(two_pi * hz_lo * 2.0 * mt)
                + 0.08 * np.sin(two_pi * hz_lo * 3.0 * mt)) * menv * (famp * 0.55)
        gl, gr = _pan_gains(-pan * 0.5)
        mix_wrapped(l, r, int(t0 * SR), horn * gl, horn * gr, wrap=False)
    # Harmonizing radiant fifth + third shimmer on final beat
    for m_har, pan_h in [(86, -0.32), (83, 0.32)]:
        hl, hr = synth_bell(0.32, midi_to_hz(m_har), amp=0.18, pan=pan_h, bright=1.2, mod_ratio=2.0, mod_idx=0.85)
        mix_wrapped(l, r, int(0.240 * SR), hl, hr, wrap=False)
    l, r = add_reverb(l, r, decay=0.30, wrap=False)
    l, r = _fade_tail(l, r, ms=36.0)
    save_wav(l, r, os.path.join(SFX_DIR, "shortcut_fanfare.wav"))

    # 4. Heart Drop (~0.48s): dramatic deep hollow wind-thump + tense descending two-note sigh
    n = int(0.48 * SR)
    t = np.arange(n, dtype=np.float64) / SR
    l, r = np.zeros(n), np.zeros(n)
    # Deep hollow wind-thump (resonant downward stomach-drop impact)
    th_f = 38.0 + 82.0 * np.exp(-t * 14.0)
    thump = np.sin(np.cumsum(two_pi * th_f / SR)) * np.minimum(1.0, t / 0.008) * np.exp(-t * 8.5) * 0.48
    # Hollow descending wind whoosh cavity
    wnz = _spectral_filter_loop(rng.standard_normal(n), low_hz=110.0, high_hz=680.0, bp_center=290.0, bp_q=1.6, tilt_db_oct=-3.8)
    wrms = math.sqrt(float(np.mean(wnz * wnz)) + 1e-12)
    whoosh = (wnz / wrms) * np.minimum(1.0, t / 0.035) * np.exp(-t * 5.2) * 0.24
    l += thump + whoosh * 0.96
    r += thump + whoosh * 1.04
    # Tense descending two-note muted horn/flute sigh: F4 (65) -> D4 (62) -> trailing drop to B3 (59)
    sigh_notes = [
        (0.032, 0.19, midi_to_hz(65), midi_to_hz(64.2), 0.26, -0.18),
        (0.185, 0.27, midi_to_hz(62), midi_to_hz(59.0), 0.28, 0.18),
    ]
    for t0, sdur, f0, f1, samp, pan in sigh_notes:
        sn = int(sdur * SR)
        st = np.arange(sn, dtype=np.float64) / SR
        u = st / sdur
        sf = f0 + (f1 - f0) * np.power(u, 1.35)
        sph = np.cumsum(two_pi * sf / SR)
        senv = np.minimum(1.0, st / 0.022) * np.power(np.maximum(0.0, 1.0 - u), 1.25)
        # Warm dark low-passed horn sigh
        sig = (0.78 * np.sin(sph) + 0.17 * np.sin(sph * 2.0) * np.exp(-st * 6.0)
               + 0.05 * np.sin(sph * 3.0) * np.exp(-st * 12.0)) * senv * samp
        gl, gr = _pan_gains(pan)
        mix_wrapped(l, r, int(t0 * SR), sig * gl, sig * gr, wrap=False)
    l, r = add_reverb(l, r, decay=0.34, wrap=False)
    l, r = _fade_tail(l, r, ms=34.0)
    save_wav(l, r, os.path.join(SFX_DIR, "heart_drop.wav"))
    print("[gen_audio] All 4 celebration & drama SFX (.wav) synthesized successfully.")


if __name__ == "__main__":
    generate_music()
    generate_sfx()
    generate_ambience()
    generate_character_chirps()
    generate_celebration_sfx()
    print("[gen_audio] Complete!")
