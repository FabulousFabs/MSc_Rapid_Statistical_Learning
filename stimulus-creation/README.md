# Stimulus Creation
Everything in this directory is concerned with creation of the auditory stimuli from our text lists. All text stimuli can be found in ```./experiment/stimuli.txt``` with practice stimuli being stored in ```./experiment/practice.txt```.

## Experiment
The experiment is written for NeuroBS Presentation 22.1 but has been tested to work at least from 20.0 onwards. It is a very simple setup where each trial follows:

1. Blank&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;(*200ms*)
2. Fixation cross &nbsp;(*500ms*)
3. Delay&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;(*200ms*)
4. Prompt&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;(*5100ms*)

At prompt, participants pronounce whatever stimulus was presented to them, making sure to also adopt the stress pattern that is represented by CAPITAL letters (e.g., PAttern). The full experiment includes twenty practice trials followed by five pseudo-randomised blocks of presentation of the 60 targets and takes approximately 35 minutes. For target trials, stimulus on- and offset times are saved such that relevant audio segments may later be cut from the full recording. These recordings are *no longer handled by NeuroBS Presentation* due to excessive levels of noise in the data, but are handled externally (and hence trigger data are required).

## Preprocessing
Preprocessing of auditory stimuli consists of four steps:

1. **Semi-automatic noise/artefact reduction:** The full recording file (sampled at 48kHz, 32 PCM, stereo as a .w4a) of a participant is cut such that its beginning matches with the first trigger (```sctINFO.pcl::i_BaseTimer``` as set by ```sctSUBS.pcl::Synchronise()``` upon starting the presentation of target trials) using Reaper 6.18/OSX64. Apparent, non-periodic noise (e.g., clicks, rustling, etc.) is removed manually from the data. Soft denoising is performed through Cockos VST ReaFir where ```edit_mode=precise, fft_size = 4096, mode=subtract, automatic_noise_profile=true``` and Cockos VST ReaGate where ```dB=-50```. Data are exported to 48kHz, 32 PCM, stereo wave.
2. **Automatic trial segmentation:** In the case of correct timing data from NeuroBS Presentation, this is handled by ```python3 ./preprocessing-timed/cut.py PPN.wav PPN.txt``` which will segment and label the data from PPN.wav  as per the timing and label data from PPN.txt. In one fringe case, Presentation did not save timing data correctly such that data were simply cut periodically (since every trial takes 6s) which is handled by ```python3 ./preprocessing-cyclical/cut.py PPN.wav```.
3. **Automatic voice detection:** For this to work, data must be downsampled to 32kHz. Next, python VAD is employed for voice onset detection through-out the buffer, binning all frames that do not cross the threshold of activation (this threshold is mendable through the aggressiveness parameter). Optionally, butter bandpass filters can be applied to eliminate sources of low-/high-frequency noise (if still present). Optionally, A-, B- or C- weighting can further be applied to soften out sound pressure levels. In almost all cases, this step is handled by ```python3 ./preprocessing-vod/preprocessing.py --Fs=32000 -resample -nopass --a=2 -voice -lean``` (i.e., no bandpass or weighting filters are applied at this stage).
4. **Automatic sound pressure equalisation:** To ensure that sound pressure levels are in a desirable and comparable range across speakers and items, we use Praat 6.1.08 (on MacOS BigSur) to normalise SPLs (aiming for roughly 60dB peaks). This is achieved through ```./preprocessing-spl/spl.praat```. *Note: Praat overwrites the specified files so this should be run on a copy of the full data, not the actual files (in case something goes awry).*

## Assignment
To be able to present participants with stimuli manipulated in variability along the dimensions of speaker and item, we create 9 conditions by crossing the factors speaker (pool 1 and 3: only one speaker per item with four variants; pool 2: four speakers per item with one variant each) and item (lists 1-3). Both are randomised on a per-participant basis (with the additional constraint that m:f ratio in speaker pools must always be 2:2). To generate fourty such lists, we use ```python3 ./preprocessing-assignment/preprocess_assign.py --N=40```.

***TODO:*** Write script to populate definitions, correct answers, filler definitions, etc. in specific lists.

***TODO:*** Write script to tease the assigned lists apart into the stimuli we need per task that can be used as inputs for Presentation.

## Data availability
***TODO:*** At some point, these data will have to be made public via the Donders repository.
