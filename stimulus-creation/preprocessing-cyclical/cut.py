# simple script to cut our massive recordings into separate files of fixed length each
# this is used only in case that accurate timestamping did not work in Presentation (again)
# if accurate timestamps are available, refer to preprocessing-timed

from pydub import AudioSegment
from math import ceil
import os, sys

audio_folder = '/users/fabianschneider/desktop/university/master/dissertation/project/stimulus-creation/preprocessing-cyclical/ins/'
out_folder = '/users/fabianschneider/desktop/university/master/dissertation/project/stimulus-creation/preprocessing-cyclical/outs/'
target = None
cycle = 6 # s

def preprocess_cyclical():
    """ Main logic """
    if target is None:
        print('Please supply a target file name.')
        return 0

    audio = AudioSegment.from_wav(os.path.join(audio_folder, target))
    audio_ms = len(audio)
    ms = 1000

    for i in range(ceil(audio_ms / ms / cycle)):
        print('Segment %d' % (i), end='\r')
        window_start = i * ms * cycle
        window_end = (i + 1) * ms * cycle
        window_end = audio_ms if window_end > audio_ms else window_end

        new_audio = audio[window_start:window_end]
        new_audio.export(os.path.join(out_folder, str(i) + '.wav'), format="wav")

    print('Segmentation completed.')


if __name__ == '__main__':
    if len(sys.argv) <= 1:
        print('\nPlease supply a target file name.\n')
        print('---------------------------------')
        print('For example:')
        print('\tcut.py my_input.wav')
        print('---------------------------------\n')
    else:
        target = sys.argv[1]
        preprocess_cyclical()
