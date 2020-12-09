# pipeline to preprocess our raw .wav data from NeuroBS Presentation
# essentially, this just removes non-voice components from the signal
# to make sure a) we have clear speech,  b) all our auditory stimuli
# start on the same beat (so, fix timing for presentation) and c)
# all our data are sampled at 32kHz

import collections
import contextlib
import sys
import os
import string
import wave
import webrtcvad
import librosa
import soundfile as sf
from numpy import pi, convolve
from scipy.signal.filter_design import bilinear
from scipy.signal import butter, lfilter

#audio_folder = '/users/fabianschneider/desktop/university/master/dissertation/project/stimulus-creation/preprocessing-vod/logs/'
#audio_folder = '/users/fabianschneider/desktop/university/master/dissertation/project/stimulus-creation/preprocessing-cyclical/outs/'
audio_folder = '/users/fabianschneider/desktop/university/master/dissertation/project/stimulus-creation/preprocessing-timed/outs/'
audio_targets = '.wav'
enforce_Fs = 32000
samp_width = 4 # note to self: bytes, not bits
samp_subtype = 'PCM_32'
bp = [8.0, 8000.0]
aggressiveness = 1
weighting = 'C'
resample_folder = '/users/fabianschneider/desktop/university/master/dissertation/project/stimulus-creation/preprocessing-vod/resamples/'
denoise_folder = '/users/fabianschneider/desktop/university/master/dissertation/project/stimulus-creation/preprocessing-vod/bandpassed/'
target_folder = '/users/fabianschneider/desktop/university/master/dissertation/project/stimulus-creation/preprocessing-vod/outputs/'
spl_folder = '/users/fabianschneider/desktop/university/master/dissertation/project/stimulus-creation/preprocessing-vod/weighted/'

def preprocess_voice():
    """Main logic for preprocessing voice"""
    n = 1
    at = find_recordings(denoise_folder, audio_targets)
    for f in at:
        Fs, a = read_wave(os.path.join(denoise_folder, f))
        Fs, na = grab_voice(Fs, a, aggressiveness)
        write_wave(os.path.join(target_folder, f), na, Fs)
        print("--- Preprocessing voice: " + str(round(n / len(at) * 100, 2)) + "% done. ---\t\t", end='\r')
        n += 1

def preprocess_resample():
    """Main logic for preprocessing resample"""
    n = 1
    at = find_recordings(audio_folder, audio_targets)
    for f in at:
        y, Fs = librosa.load(os.path.join(audio_folder, f), sr=enforce_Fs)
        sf.write(os.path.join(resample_folder, f), y, Fs, subtype=samp_subtype)
        print("--- Preprocessing resample: " + str(round(n / len(at) * 100, 2)) + "% done. ---\t\t", end='\r')
        n += 1

def preprocess_denoise():
    """Main logic for preprocessing bandpasses"""
    n = 1
    at = find_recordings(resample_folder, audio_targets)
    for f in at:
        a, Fs = librosa.load(os.path.join(resample_folder, f))
        na = butter_bandpass_filter(a, bp[0], bp[1], Fs)
        sf.write(os.path.join(denoise_folder, f), na, Fs, subtype=samp_subtype)
        print("--- Preprocessing bandpass: " + str(round(n / len(at) * 100, 2)) + "% done. ---\t\t", end='\r')
        n += 1

def preprocess_spl():
    """Main logic for SPL weighting"""
    n = 1
    at = find_recordings(target_folder, audio_targets)
    for f in at:
        x, Fs = librosa.load(os.path.join(target_folder, f))
        b, a = a_weighting_coeffs_design(Fs) if weighting == 'A' else c_weighting_coeffs_design(Fs) if weighting == 'C' else b_weighting_coeffs_design(Fs)
        y = lfilter(b, a, x)
        sf.write(os.path.join(spl_folder, f), y, Fs, subtype=samp_subtype)
        print("--- Preprocessing SPLs: " + str(round(n / len(at) * 100, 2)) + "% done. ---\t\t", end='\r')
        n += 1

def clean(d):
    """Remove temporary files"""
    n = 1
    at = find_recordings(d, audio_targets)
    for f in at:
        os.remove(os.path.join(d, f))
        print("--- Cleaning up: " + str(round(n / len(at) * 100, 2)) + "% done. ---\t\t", end='\r')
        n += 1

def clean_full():
    """Clean up resample and outputs"""
    clean(resample_folder)
    clean(denoise_folder)
    clean(target_folder)
    clean(spl_folder)

def clean_declutter():
    """Clean up resample"""
    clean(resample_folder)
    clean(denoise_folder)

def find_recordings(f, t):
    """Grab all recordings with extension t from f"""
    af = os.listdir(f)
    at = []
    for f in af:
        if f.endswith(t):
            at.append(f)
    return at

def read_wave(f):
    """Read a wave file, resample if necessary"""
    with contextlib.closing(wave.open(f, 'rb')) as wf:
        Fs = wf.getframerate()
        n = wf.getnframes()
        pcm = wf.readframes(n)
        return Fs, pcm

def write_wave(f, a, Fs):
    """Write a wave file"""
    with contextlib.closing(wave.open(f, 'wb')) as wf:
        wf.setnchannels(1)
        wf.setsampwidth(samp_width)
        wf.setframerate(Fs)
        wf.writeframes(a)

class Frame:
    """Frame of audio data"""
    def __init__(self, bytes, timestamp, duration):
        self.bytes = bytes
        self.timestamp = timestamp
        self.duration = duration

def frame_generator(frame_duration_ms, audio, sample_rate):
    """Generate audio frames from PCM"""
    n = int(sample_rate * (frame_duration_ms / 1000.0) * 2)
    offset = 0
    timestamp = 0.0
    duration = (float(n) / sample_rate) / 2.0
    while offset + n < len(audio):
        yield Frame(audio[offset:offset + n], timestamp, duration)
        timestamp += duration
        offset += n

def vad_collector(sample_rate, frame_duration_ms, padding_duration_ms, vad, frames):
    """Filter non-voice frames"""
    num_padding_frames = int(padding_duration_ms / frame_duration_ms)
    ring_buffer = collections.deque(maxlen=num_padding_frames)
    triggered = False

    voiced_frames = []
    for frame in frames:
        is_speech = vad.is_speech(frame.bytes, sample_rate)
        if not triggered:
            ring_buffer.append((frame, is_speech))
            num_voiced = len([f for f, speech in ring_buffer if speech])
            if num_voiced > 0.9 * ring_buffer.maxlen:
                triggered = True
                for f, s in ring_buffer:
                    voiced_frames.append(f)
                ring_buffer.clear()
        else:
            voiced_frames.append(frame)
            ring_buffer.append((frame, is_speech))
            num_unvoiced = len([f for f, speech in ring_buffer if not speech])
            if num_unvoiced > 0.9 * ring_buffer.maxlen:
                triggered = False
                yield b''.join([f.bytes for f in voiced_frames])
                ring_buffer.clear()
                voiced_frames = []

    if voiced_frames:
        yield b''.join([f.bytes for f in voiced_frames])

def grab_voice(Fs, a, agg):
    """Extract voice only from our sample"""
    vad = webrtcvad.Vad(int(agg))
    frames = frame_generator(10, a, Fs)
    frames = list(frames)
    segments = vad_collector(Fs, 10, 100, vad, frames)
    concataudio = [segment for segment in segments]
    joinedaudio = b"".join(concataudio)
    return Fs, joinedaudio

def butter_bandpass(lb, ub, Fs, o=5):
    nyquist = 0.5 * Fs
    lb = lb / nyquist
    ub = ub / nyquist
    b, a = butter(o, [lb, ub], btype='band')
    return b, a

def butter_bandpass_filter(ins, lb, ub, Fs, o=5):
    b, a = butter_bandpass(lb, ub, Fs, o=o)
    return lfilter(b, a, ins)

def a_weighting_coeffs_design(sample_rate):
    """Returns b and a coeff of a A-weighting filter.
    Parameters
    ----------
    sample_rate : scalar
        Sample rate of the signals that well be filtered.
    Returns
    -------
    b, a : ndarray
        Filter coefficients for a digital weighting filter.
    Examples
    --------
    >>> b, a = a_weighting_coeff_design(sample_rate)
    To Filter a signal use scipy lfilter:
    >>> from scipy.signal import lfilter
    >>> y = lfilter(b, a, x)
    See Also
    --------
    b_weighting_coeffs_design : B-Weighting coefficients.
    c_weighting_coeffs_design : C-Weighting coefficients.
    weight_signal : Apply a weighting filter to a signal.
    scipy.lfilter : Filtering signal with `b` and `a` coefficients.
    """

    f1 = 20.598997
    f2 = 107.65265
    f3 = 737.86223
    f4 = 12194.217
    A1000 = 1.9997
    numerators = [(2*pi*f4)**2 * (10**(A1000 / 20.0)), 0., 0., 0., 0.];
    denominators = convolve(
        [1., +4*pi * f4, (2*pi * f4)**2],
        [1., +4*pi * f1, (2*pi * f1)**2]
    )
    denominators = convolve(
        convolve(denominators, [1., 2*pi * f3]),
        [1., 2*pi * f2]
    )
    return bilinear(numerators, denominators, sample_rate)

def b_weighting_coeffs_design(sample_rate):
    """Returns `b` and `a` coeff of a B-weighting filter.
    B-Weighting is no longer described in DIN61672.
    Parameters
    ----------
    sample_rate : scalar
        Sample rate of the signals that well be filtered.
    Returns
    -------
    b, a : ndarray
        Filter coefficients for a digital weighting filter.
    Examples
    --------
    >>> b, a = b_weighting_coeff_design(sample_rate)
    To Filter a signal use :function: scipy.lfilter:
    >>> from scipy.signal import lfilter
    >>> y = lfilter(b, a, x)
    See Also
    --------
    a_weighting_coeffs_design : A-Weighting coefficients.
    c_weighting_coeffs_design : C-Weighting coefficients.
    weight_signal : Apply a weighting filter to a signal.
    """

    f1 = 20.598997
    f2 = 158.5
    f4 = 12194.217
    B1000 = 0.17
    numerators = [(2*pi*f4)**2 * (10**(B1000 / 20)), 0, 0, 0];
    denominators = convolve(
        [1, +4*pi * f4, (2*pi * f4)**2],
        [1, +4*pi * f1, (2*pi * f1)**2]
    )
    denominators = convolve(denominators, [1, 2*pi * f2])
    return bilinear(numerators, denominators, sample_rate)


def c_weighting_coeffs_design(sample_rate):
    """Returns b and a coeff of a C-weighting filter.
    Parameters
    ----------
    sample_rate : scalar
        Sample rate of the signals that well be filtered.
    Returns
    -------
    b, a : ndarray
        Filter coefficients for a digital weighting filter.
    Examples
    --------
    b, a = c_weighting_coeffs_design(sample_rate)
    To Filter a signal use scipy lfilter:
    from scipy.signal import lfilter
    y = lfilter(b, a, x)
    See Also
    --------
    a_weighting_coeffs_design : A-Weighting coefficients.
    b_weighting_coeffs_design : B-Weighting coefficients.
    weight_signal : Apply a weighting filter to a signal.
    """

    f1 = 20.598997
    f4 = 12194.217
    C1000 = 0.0619
    numerators = [(2*pi * f4)**2 * (10**(C1000 / 20)), 0, 0]
    denominators = convolve(
        [1, +4*pi * f4, (2*pi * f4)**2],
        [1, +4*pi * f1, (2*pi * f1)**2]
    )
    return bilinear(numerators, denominators, sample_rate)

if __name__ == '__main__':
    if len(sys.argv) <= 1:
        print('\nPlease supply at least one option.\n')
        print('---------------------------------')
        print('Options:')
        print('\t--Fs=n:\t\tSet enforced sampling rate to n for subsequent')
        print('\t\t\tresampling call.')
        print('\t-resample:\tResample all audio files to the target Fs.\n')
        print('\t--bp=lb,ub:\tSet bandpass filter lower and upper bound.')
        print('\t-denoise:\tApply bandpass filter on signal.')
        print('\t-nopass:\tSkip application of bandpass.\n')
        print('\t--a=n:\t\tSet aggressiveness of subsequent voice to n.')
        print('\t-voice:\t\tDetect voice on- and offset and cut non-voice.\n')
        print('\t--w=n:\t\tSet N-weighting for subsequent SPL control.')
        print('\t-spl:\t\tApply weighting filter for SPL control.\n')
        print('\t-lean:\t\tRemove resample and bandpass files.')
        print('\t-clean:\t\tRemove resample, bandpass, voice and weighting')
        print('\t\t\tfiles.')
        print('---------------------------------')
        print('\nTo chain operations, simply put them in order. For example,')
        print('\tpreprocessing.py -resample -nopass --a=3 -voice -spl -lean')
        print('will give you a full run and remove temporary resampling')
        print('files.\n')
    else:
        for arg in sys.argv[1:]:
            if len(arg) >= 6 and arg[0:5] == '--Fs=':
                enforce_Fs = int(arg[5:])
                print('--- Fs adjusted to ' + str(enforce_Fs) + '. ---\t\t')
            elif arg == '-resample':
                preprocess_resample()
            elif len(arg) >= 8 and arg[0:5] == '--bp=':
                b = arg[5:].split(',')
                bp = [float(b[0]), float(b[1])]
                print('--- Bandpass adjusted to ' + str(bp[0]) + '-' + str(bp[1]) + '. ---\t\t')
            elif arg == '-nopass':
                denoise_folder = resample_folder
                print('--- No bandpass applied to signal, folders changed. ---\t\t')
            elif arg == '-denoise':
                preprocess_denoise()
            elif len(arg) == 5 and arg[0:4] == '--a=':
                aggressiveness = int(arg[4])
                print('--- Aggressiveness adjusted to ' + str(aggressiveness) + '. ---\t\t')
            elif arg == '-voice':
                preprocess_voice()
            elif len(arg) == 5 and arg[0:4] == '--w=':
                if arg[4] in ['A', 'B', 'C', 'a', 'b', 'c']:
                    weighting = arg[4].upper()
                    print('--- ' + weighting + '-weighting will be used for SPLs. ---\t\t')
            elif arg == '-spl':
                preprocess_spl()
            elif arg == '-lean':
                clean_declutter()
            elif arg == '-clean':
                clean_full()
