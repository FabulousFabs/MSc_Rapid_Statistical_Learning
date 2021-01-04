# RSL main experiment
This directory is for the main experiment used. Essentially, it consists of several learning epochs followed by two testing phases:

1. Learning epochs
   1. Exposure task
   2. 2AFC&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*(cue = definition)*
   3. 2AFC&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*(cue = word)*
   4. Cued recall *(cue = definition)*
2. Testing phase
   1. MEG semantic judgments
   2. 4AFC&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*(cue = word)*

More information on each of these tasks can be found below. As is the case for the SCT, this experiment was written in NeuroBS Presentation 22.1 (but should work from 20.0 onwards).

## Learning epochs
For learning, we use only two of the nine conditions previously created for stimuli. These are `pool1 x list1` and `pool2 x list2` (such that, for P1L1 we have one speaker per word producing multiple variants, whereas for P2L2 we have multiple speakers per word producing a single variant each). As such, we have `2*20*4=160` stimuli for every learning task.

### Exposure task
This is a very simple task where participants are given the full list of items they have to learn as well as corresponding definitions. No further instructions are given (except to listen and read carefully to memorise the items as best they can):

1. Fixation cross&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*(750ms)*
2. Audio&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*(~500ms)*
3. Delay&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*(250ms)*
4. Definition&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; *(4000ms)*
5. Delay&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*(jittered, ~1500ms)*

### 2AFC (cue = definition)
***TODO:*** Write task + description.

### 2AFC (cue = word)
***TODO:*** Write task + description.

### Cued recall (cue = definition)
***TODO:*** Write task + description.

## Testing phase
For testing phases, we use bigger subsets of the conditions. For more information, check the relevant subheadings.

### MEG semantic judgment
***TODO:*** Write task + description.

### 4AFC (cue = word)
***TODO:*** Write task + description.
