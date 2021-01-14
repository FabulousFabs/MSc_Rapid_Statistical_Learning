# quick script that handles the final touches in our processes. this replaces
# both the assignment pcm script and the praat spl scripts because, quite frankly,
# this is just more convenient to use as our final step
# essentially, adjust dBFS levels across all targets and convert to correct PCM
# format such that presentation can actually handle stimuli

import os, sys
from pydub import AudioSegment
import librosa
import soundfile as sf

in_folder = '/users/fabianschneider/desktop/university/master/dissertation/project/stimulus-creation/preprocessing-finalise/data/'
spl_folder = '/users/fabianschneider/desktop/university/master/dissertation/project/stimulus-creation/preprocessing-finalise/spl/'
pcm_folder = '/users/fabianschneider/desktop/university/master/dissertation/project/stimulus-creation/preprocessing-finalise/pcm/'
audio_targets = '.wav'
target_pcm = 'PCM_16' # signed 16 bit pcm with little endian should be optimal for NeuroBS Presentation
target_db = -25

def preprocess_spl():
    """Equalise peak db across a range of audio targets as per target db"""
    targets = find_recordings(in_folder, audio_targets)
    audios = mass_read(targets)
    mass_scale(targets, audios)
    print('--- Sound pressure equalisation completed. ---\t\t')

def mass_read(targets):
    """Load list of audio targets"""
    n = 1
    audios = []

    for target in targets:
        print('--- Reading: ' + str(round(n / len(targets) * 100, 2)) + '%. ---', end='\r')
        audios.append(AudioSegment.from_file(os.path.join(in_folder, target), "wav"))
        n += 1

    return audios

def mass_scale(targets, audios):
    """Applies dBFS target to all audios"""
    n = 1

    for audio, target in zip(audios, targets):
        print('--- Scaling: ' + str(round(n / len(targets) * 100, 2)) + '%. ---', end='\r')
        scaled = audio.apply_gain(target_db - audio.dBFS)
        scaled.export(os.path.join(spl_folder, target), format="wav")
        n += 1

    return scaled

def preprocess_pcm():
    """Converts to prespecified PCM format."""
    n = 1
    targets = find_recordings(spl_folder, audio_targets)

    for target in targets:
        print('--- Converting: ' + str(round(n / len(targets) * 100, 2)) + '%. ---', end='\r')
        audio, fs = librosa.load(os.path.join(spl_folder, target))
        sf.write(os.path.join(pcm_folder, target), audio, fs, subtype=target_pcm)
        n += 1

    print('--- PCM conversion completed. ---\t\t')


def find_recordings(f, t):
    """Grab all recordings with extension t from f"""
    af = os.listdir(f)
    at = []
    for f in af:
        if f.endswith(t):
            at.append(f)
    return at

if __name__ == '__main__':
    if len(sys.argv) >= 1:
        for arg in sys.argv[1:]:
            if len(arg) >= 6 and arg[0:5] == '--db=':
                target_db = int(arg[5:])
                print('--- Adjusted peak dB to ' + str(target_db) + '. ---\t\t')
            elif len(arg) >= 7 and arg[0:6] == '--pcm=':
                target_pcm = string(arg[6:])
                print('--- Adjusted target PCM ' + str(target_pcm) + '. ---\t\t')
            elif arg == '-spl':
                preprocess_spl()
            elif arg == '--no-spl':
                spl_folder = in_folder
                print('--- Skipping SPL, folder changed. ---\t\t')
            elif arg == '-pcm':
                preprocess_pcm()
