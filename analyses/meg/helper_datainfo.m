% @Description: Make subject info.
%
% INPUTS:
%       rootdir     -   Root directory
%
% OUTPUTS:
%       subjects    -   Subject data

function subjects = helper_datainfo(rootdir)
    assert(isempty(rootdir) == false);
    
    % setup
    subjects = [];
    
    % sub007
    subjects(1).ppn = 7;
    subjects(1).code = 'SPEZL';
    subjects(1).raw_meg = fullfile(rootdir, 'raw', 'sub-007', 'ses-meg01', 'meg', 'sub007ses01SPEZL_3018012.23_20210410_01.ds');
    subjects(1).raw_mri = fullfile(rootdir, 'raw', 'sub-007', 'ses-1', 'mri', '002-t1_mprage_sag_p2_iso_1.0_20ch_head', '00001_1.3.12.2.1107.5.2.43.67027.2020021714192118491311094.IMA');
    subjects(1).raw_edf = fullfile(rootdir, 'raw', 'sub-007', 'ses-1', 'beh', 'Sub7-1.edf');
    subjects(1).raw_pol = fullfile(rootdir, 'raw', 'sub-007', 'ses-1', 'pol', 'S7-1.pos');
    subjects(1).beh_meg = fullfile(rootdir, 'raw', 'sub-007', 'ses-1', 'beh', 'SPEZL_MEG.txt');
    
    % sub001
    subjects(2).ppn = 1;
    subjects(2).code = 'LJYOF';
    subjects(2).raw_meg = fullfile(rootdir, 'raw', 'sub-001', 'ses-meg01', 'meg', 'sub001ses01_3018012.23_20210412_01.ds');
    subjects(2).raw_mri = fullfile(rootdir, 'raw', 'sub-001', 'ses-1', 'mri', '022-t1_mprage_sag_p2_iso_1.0', '00001_1.3.12.2.1107.5.2.19.45416.2021040212443212786713242.IMA');
    subjects(2).raw_edf = fullfile(rootdir, 'raw', 'sub-001', 'ses-1', 'beh', 'Sub1-1.edf');
    subjects(2).raw_pol = fullfile(rootdir, 'raw', 'sub-001', 'ses-1', 'pol', 'S1-1.pos');
    subjects(2).beh_meg = fullfile(rootdir, 'raw', 'sub-001', 'ses-1', 'beh', 'LJYOF_MEG.txt');
    
    % sub002
    subjects(3).ppn = 2;
    subjects(3).code = 'VGYEQ';
    subjects(3).raw_meg = fullfile(rootdir, 'raw', 'sub-002', 'ses-meg01', 'meg', 'sub002ses01_3018012.23_20210415_01.ds');
    %subjects(3).raw_mri = fullfile(rootdir, 'raw', 'sub-002', 'ses-1', 'mri', '022-t1_mprage_sag_p2_iso_1.0', '00001_1.3.12.2.1107.5.2.19.45416.2021040212443212786713242.IMA');
    subjects(3).raw_edf = fullfile(rootdir, 'raw', 'sub-002', 'ses-1', 'beh', 'Sub2-1.edf');
    subjects(3).raw_pol = fullfile(rootdir, 'raw', 'sub-002', 'ses-1', 'pol', 'S2-1.pos');
    subjects(3).beh_meg = fullfile(rootdir, 'raw', 'sub-002', 'ses-1', 'beh', 'VGYEQ_MEG.txt');
    
    % add outputs + dirs
    for sid = 1:numel(subjects)
        subjects(sid).out = fullfile(rootdir, 'processed', sprintf('sub-%02d', subjects(sid).ppn));
        warning('off', 'MATLAB:MKDIR:DirectoryExists');
        mkdir(subjects(sid).out);
        warning('on', 'MATLAB:MKDIR:DirectoryExists');
    end
end