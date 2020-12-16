# Quick script to scale SPL intensity peaks in our audio files
# TODO: find 'ideal' values (from the literature, we should probably aim for ~60dB)

form Extract Time Indices from Textgrids
   sentence Directory_name: /users/fabianschneider/desktop/university/master/dissertation/project/stimulus-creation/preprocessing-spl/targets/
endform

Create Strings as file list... list 'directory_name$'/*.wav
numberOfFiles = Get number of strings
for ifile to numberOfFiles
	select Strings list
	fileName$ = Get string... ifile
	Read from file... 'directory_name$'/'fileName$'
	Scale peak: 0.99
	lengthFN = length (fileName$)
	newfilename$ = left$ (fileName$, lengthFN-4)
	Save as WAV file: "'directory_name$'/'newfilename$'.wav"
endfor
select all
Remove
