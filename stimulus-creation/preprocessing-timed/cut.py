# simple script to cut our denoised long audio file into audio snippets as
# per the trigger timings retrieved from NeuroBS presentation
# if triggers were not received properly. please refer to preprocessing-cyclical
# NOTE: extras will have to be cut manually (recommended) or using cyclical cutting

from pydub import AudioSegment
from math import ceil
import os, sys, string

trigger_folder = '/users/fabianschneider/desktop/university/master/dissertation/project/stimulus-creation/experiment/logs/'
audio_folder = '/users/fabianschneider/desktop/university/master/dissertation/project/stimulus-creation/preprocessing-timed/ins/'
out_folder = '/users/fabianschneider/desktop/university/master/dissertation/project/stimulus-creation/preprocessing-timed/outs/'
target_audio = None
target_triggers = None

def preprocess_timed():
    """ Main logic """
    if target_audio is None:
        print('Please supply an audio target file.')
        return 0
    if target_triggers is None:
        print('Please supply a trigger target file.')
        return 0

    """ Load triggers """
    triggers = []

    with open(os.path.join(trigger_folder, target_triggers), 'r') as ftrig:
        td = ftrig.readlines()

        for i in range(len(td)):
            if i == 0: continue # skip header

            entry = td[i].replace('\n', '').split('\t')
            triggers.append(entry)

    """ Load audio """
    audio = AudioSegment.from_wav(os.path.join(audio_folder, target_audio))
    audio_ms = len(audio)
    ms = 1000

    """ Segment audio """
    for trigger in triggers:
        print('Segment %d-%d' % (int(trigger[3]), int(trigger[4])), end='\r')
        f = str(trigger[0]) + '_' + str(trigger[1]) + '_' + str(trigger[2]) + '.wav'
        snippet = audio[int(trigger[3]):int(trigger[4])]
        snippet.export(os.path.join(out_folder, f), format="wav")

    print('Segmentation completed. Please check output folder for results.')

if __name__ == '__main__':
    if len(sys.argv) <= 2:
        print('\nPlease supply target trigger and audio files.\n')
        print('---------------------------------')
        print('For example:')
        print('\tcut.py my_input.wav my_triggers.txt')
        print('---------------------------------\n')
    else:
        target_audio = sys.argv[1]
        target_triggers = sys.argv[2]

        preprocess_timed()
