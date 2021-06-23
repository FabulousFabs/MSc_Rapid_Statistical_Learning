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
    subjects(1).include = true;
    
    % sub001
    subjects(2).ppn = 1;
    subjects(2).code = 'LJYOF';
    subjects(2).raw_meg = fullfile(rootdir, 'raw', 'sub-001', 'ses-meg01', 'meg', 'sub001ses01_3018012.23_20210412_01.ds');
    subjects(2).raw_mri = fullfile(rootdir, 'raw', 'sub-001', 'ses-1', 'mri', '022-t1_mprage_sag_p2_iso_1.0', '00001_1.3.12.2.1107.5.2.19.45416.2021040212443212786713242.IMA');
    subjects(2).raw_edf = fullfile(rootdir, 'raw', 'sub-001', 'ses-1', 'beh', 'Sub1-1.edf');
    subjects(2).raw_pol = fullfile(rootdir, 'raw', 'sub-001', 'ses-1', 'pol', 'S1-1.pos');
    subjects(2).beh_meg = fullfile(rootdir, 'raw', 'sub-001', 'ses-1', 'beh', 'LJYOF_MEG.txt');
    subjects(2).include = true;
    
    % sub002
    subjects(3).ppn = 2;
    subjects(3).code = 'VGYEQ';
    subjects(3).raw_meg = fullfile(rootdir, 'raw', 'sub-002', 'ses-meg01', 'meg', 'sub002ses01_3018012.23_20210415_01.ds');
    subjects(3).raw_mri = fullfile(rootdir, 'raw', 'sub-002', 'ses-mri01', '006-t1_mprage_sag_ipat2_1p0iso_20ch_head-neck', '00001_1.3.12.2.1107.5.2.43.67027.2021043014200019311227090.IMA');
    subjects(3).raw_edf = fullfile(rootdir, 'raw', 'sub-002', 'ses-1', 'beh', 'Sub2-1.edf');
    subjects(3).raw_pol = fullfile(rootdir, 'raw', 'sub-002', 'ses-1', 'pol', 'S2-1.pos');
    subjects(3).beh_meg = fullfile(rootdir, 'raw', 'sub-002', 'ses-1', 'beh', 'VGYEQ_MEG.txt');
    subjects(3).include = true;
    
    % sub008
    subjects(4).ppn = 8;
    subjects(4).code = 'PKWKL';
    subjects(4).raw_meg = fullfile(rootdir, 'raw', 'sub-008', 'ses-meg01', 'meg', 'sub008ses01_3018012.23_20210420_01.ds');
    subjects(4).raw_mri = fullfile(rootdir, 'raw', 'sub-008', 'ses-mri01', '006-t1_mprage_sag_ipat2_1p0iso_20ch-head-neck', '00001_1.3.12.2.1107.5.2.19.45416.2021042912553445360907087.IMA');
    subjects(4).raw_edf = fullfile(rootdir, 'raw', 'sub-008', 'ses-1', 'beh', 'Sub8-1.edf');
    subjects(4).raw_pol = fullfile(rootdir, 'raw', 'sub-008', 'ses-1', 'pol', 'S8-1.pos');
    subjects(4).beh_meg = fullfile(rootdir, 'raw', 'sub-008', 'ses-1', 'beh', 'PKWKL_MEG.txt');
    subjects(4).include = true;
    
    % sub003
    subjects(5).ppn = 3;
    subjects(5).code = 'IFGIY';
    subjects(5).raw_meg = fullfile(rootdir, 'raw', 'sub-003', 'ses-meg01', 'meg', 'sub003ses01_3018012.23_20210422_01.ds');
    subjects(5).raw_mri = fullfile(rootdir, 'raw', 'sub-003', 'ses-1', 'mri', '006-t1_mprage_sag_ipat2_1p0iso_20ch-head-neck', '00001_1.3.12.2.1107.5.2.19.45416.2021022616592441700587720.IMA');
    subjects(5).raw_edf = fullfile(rootdir, 'raw', 'sub-003', 'ses-1', 'beh', 'Sub3-1.edf');
    subjects(5).raw_pol = fullfile(rootdir, 'raw', 'sub-003', 'ses-1', 'pol', 'S3-1.pos');
    subjects(5).beh_meg = fullfile(rootdir, 'raw', 'sub-003', 'ses-1', 'beh', 'IFGIY_MEG.txt');
    subjects(5).include = true;
    
    % sub005
    subjects(6).ppn = 5;
    subjects(6).code = 'CLCRF';
    subjects(6).raw_meg = fullfile(rootdir, 'raw', 'sub-005', 'ses-meg01', 'meg', 'sub005ses01_3018012.23_20210529_01.ds');
    subjects(6).raw_mri = fullfile(rootdir, 'raw', 'sub-005', 'ses-mri01', '006-t1_mprage_sag_ipat2_1p0iso_20ch-head-neck', '00001_1.3.12.2.1107.5.2.19.45416.2021061617203612868643497.IMA');
    subjects(6).raw_edf = fullfile(rootdir, 'raw', 'sub-005', 'ses-1', 'beh', 'Sub5-1.edf');
    subjects(6).raw_pol = fullfile(rootdir, 'raw', 'sub-005', 'ses-1', 'pol', 'S5-1.pos');
    subjects(6).beh_meg = fullfile(rootdir, 'raw', 'sub-005', 'ses-1', 'beh', 'CLCRF_MEG.txt');
    subjects(6).include = true;
    
    % sub013
    subjects(7).ppn = 13;
    subjects(7).code = 'HXCWT';
    subjects(7).raw_meg = fullfile(rootdir, 'raw', 'sub-013', 'ses-meg01', 'meg', 'sub013ses01_3018012.23_20210601_01.ds');
    subjects(7).raw_mri = fullfile(rootdir, 'raw', 'sub-013', 'ses-1', 'mri', '006-t1_mprage_sag_ipat2_1p0iso_20ch-head-neck', '00001_1.3.12.2.1107.5.2.19.45416.2021040812121943247423814.IMA');
    subjects(7).raw_edf = fullfile(rootdir, 'raw', 'sub-013', 'ses-1', 'beh', 'Sub13-1.edf');
    subjects(7).raw_pol = fullfile(rootdir, 'raw', 'sub-013', 'ses-1', 'pol', 'S13-1.pos');
    subjects(7).beh_meg = fullfile(rootdir, 'raw', 'sub-013', 'ses-1', 'beh', 'HXCWT_MEG.txt');
    subjects(7).include = true;
    
    % sub014
    subjects(8).ppn = 14;
    subjects(8).code = 'ZJAGN';
    subjects(8).raw_meg = fullfile(rootdir, 'raw', 'sub-014', 'ses-meg01', 'meg', 'sub014ses01_3018012.23_20210602_01.ds');
    subjects(8).raw_mri = fullfile(rootdir, 'raw', 'sub-014', 'ses-mri01', '006-t1_mprage_sag_ipat2_1p0iso_20ch-head-neck', '00001_1.3.12.2.1107.5.2.19.45416.2021061814480580628709583.IMA');
    subjects(8).raw_edf = fullfile(rootdir, 'raw', 'sub-014', 'ses-1', 'beh', 'Sub14-1.edf');
    subjects(8).raw_pol = fullfile(rootdir, 'raw', 'sub-014', 'ses-1', 'pol', 'S14-1.pos');
    subjects(8).beh_meg = fullfile(rootdir, 'raw', 'sub-014', 'ses-1', 'beh', 'ZJAGN_MEG.txt');
    subjects(8).include = true;
    
    % sub015
    subjects(9).ppn = 15;
    subjects(9).code = 'IIAJF';
    subjects(9).raw_meg = fullfile(rootdir, 'raw', 'sub-015', 'ses-meg01', 'meg', 'sub015ses01_3018012.23_20210603_01.ds');
    subjects(9).raw_mri = fullfile(rootdir, 'raw', 'sub-015', 'ses-1', 'mri', '002-t1_mprage_sag_p2_iso_1.0_20ch_head', '00001_1.3.12.2.1107.5.2.43.66068.2020010811102215973101094.IMA');
    subjects(9).raw_edf = fullfile(rootdir, 'raw', 'sub-015', 'ses-1', 'beh', 'Sub15-1.edf');
    subjects(9).raw_pol = fullfile(rootdir, 'raw', 'sub-015', 'ses-1', 'pol', 'S15-1.pos');
    subjects(9).beh_meg = fullfile(rootdir, 'raw', 'sub-015', 'ses-1', 'beh', 'IIAJF_MEG.txt');
    subjects(9).include = true;
    
    % sub016
    subjects(10).ppn = 16;
    subjects(10).code = 'GWZIR';
    subjects(10).raw_meg = fullfile(rootdir, 'raw', 'sub-016', 'ses-meg01', 'meg', 'sub016ses01_3018012.23_20210604_01.ds');
    subjects(10).raw_mri = fullfile(rootdir, 'raw', 'sub-016', 'ses-1', 'mri', '006-t1_mprage_sag_ipat2_1p0iso_20ch-head-neck', '00001_1.3.12.2.1107.5.2.19.45416.2021011513121073910912534.IMA');
    subjects(10).raw_edf = fullfile(rootdir, 'raw', 'sub-016', 'ses-1', 'beh', 'Sub16-1.edf');
    subjects(10).raw_pol = fullfile(rootdir, 'raw', 'sub-016', 'ses-1', 'pol', 'S16-1.pos');
    subjects(10).beh_meg = fullfile(rootdir, 'raw', 'sub-016', 'ses-1', 'beh', 'GWZIR_MEG.txt');
    subjects(10).include = true;
    
    % sub018
    subjects(11).ppn = 18;
    subjects(11).code = 'VEYZW';
    subjects(11).raw_meg = fullfile(rootdir, 'raw', 'sub-018', 'ses-meg01', 'meg', 'sub018ses01_3018012.23_20210608_01.ds');
    subjects(11).raw_mri = fullfile(rootdir, 'raw', 'sub-018', 'ses-mri01', '006-t1_mprage_sag_ipat2_1p0iso_20ch-head-neck', '00001_1.3.12.2.1107.5.2.19.45416.2021061411461875678902407.IMA');
    subjects(11).raw_edf = fullfile(rootdir, 'raw', 'sub-018', 'ses-1', 'beh', 'Sub18-1.edf');
    subjects(11).raw_pol = fullfile(rootdir, 'raw', 'sub-018', 'ses-1', 'pol', 'S18-1.pos');
    subjects(11).beh_meg = fullfile(rootdir, 'raw', 'sub-018', 'ses-1', 'beh', 'VEYZW_MEG.txt');
    subjects(11).include = true;
    
    % sub021
    subjects(12).ppn = 21;
    subjects(12).code = 'WFUQS';
    subjects(12).raw_meg = fullfile(rootdir, 'raw', 'sub-021', 'ses-meg01', 'meg', 'sub021ses01_3018012.23_20210608_01.ds');
    %subjects(12).raw_mri = fullfile(rootdir, 'raw', 'sub-021', 'ses-1', 'mri', '006-t1_mprage_sag_ipat2_1p0iso_20ch-head-neck', '00001_1.3.12.2.1107.5.2.19.45416.2021011513121073910912534.IMA');
    subjects(12).raw_edf = fullfile(rootdir, 'raw', 'sub-021', 'ses-1', 'beh', 'Sub21-1.edf');
    subjects(12).raw_pol = fullfile(rootdir, 'raw', 'sub-021', 'ses-1', 'pol', 'S21-1.pos');
    subjects(12).beh_meg = fullfile(rootdir, 'raw', 'sub-021', 'ses-1', 'beh', 'WFUQS_MEG.txt');
    subjects(12).include = false;
    
    % sub019
    subjects(13).ppn = 19;
    subjects(13).code = 'BMDMO';
    subjects(13).raw_meg = fullfile(rootdir, 'raw', 'sub-019', 'ses-meg01', 'meg', 'sub019ses01_3018012.23_20210609_01.ds');
    %subjects(13).raw_mri = fullfile(rootdir, 'raw', 'sub-019', 'ses-1', 'mri', '006-t1_mprage_sag_ipat2_1p0iso_20ch-head-neck', '00001_1.3.12.2.1107.5.2.19.45416.2021011513121073910912534.IMA');
    subjects(13).raw_edf = fullfile(rootdir, 'raw', 'sub-019', 'ses-1', 'beh', 'Sub19-1.edf');
    subjects(13).raw_pol = fullfile(rootdir, 'raw', 'sub-019', 'ses-1', 'pol', 'S19-1.pos');
    subjects(13).beh_meg = fullfile(rootdir, 'raw', 'sub-019', 'ses-1', 'beh', 'BMDMO_MEG.txt');
    subjects(13).include = false;
    
    % sub006
    subjects(14).ppn = 6;
    subjects(14).code = 'NTBBK';
    subjects(14).raw_meg = fullfile(rootdir, 'raw', 'sub-006', 'ses-meg01', 'meg', 'sub006ses01_3018012.23_20210611_01.ds');
    subjects(14).raw_mri = fullfile(rootdir, 'raw', 'sub-006', 'ses-1', 'mri', '002-t1_mprage_sag_p2_iso_1.0_20ch_head', '00001_1.3.12.2.1107.5.2.19.45416.2020021209273730721801115.IMA');
    subjects(14).raw_edf = fullfile(rootdir, 'raw', 'sub-006', 'ses-1', 'beh', 'Sub6-1.edf');
    subjects(14).raw_pol = fullfile(rootdir, 'raw', 'sub-006', 'ses-1', 'pol', 'S6-1.pos');
    subjects(14).beh_meg = fullfile(rootdir, 'raw', 'sub-006', 'ses-1', 'beh', 'NTBBK_MEG.txt');
    subjects(14).include = true;
    
    % sub022
    subjects(15).ppn = 22;
    subjects(15).code = 'WUJCA';
    subjects(15).raw_meg = fullfile(rootdir, 'raw', 'sub-022', 'ses-meg01', 'meg', 'sub022ses01_3018012.23_20210613_01.ds');
    subjects(15).raw_mri = fullfile(rootdir, 'raw', 'sub-022', 'ses-1', 'mri', 'PAUGAA_20170105_S09.MR.DCCN_SKYRA.0002.0001.2017.01.05.11.21.07.149215.1339150432.IMA');
    subjects(15).raw_edf = fullfile(rootdir, 'raw', 'sub-022', 'ses-1', 'beh', 'Sub22-1.edf');
    subjects(15).raw_pol = fullfile(rootdir, 'raw', 'sub-022', 'ses-1', 'pol', 'S22-1.pos');
    subjects(15).beh_meg = fullfile(rootdir, 'raw', 'sub-022', 'ses-1', 'beh', 'WUJCA_MEG.txt');
    subjects(15).include = true;
    
    % sub027
    subjects(16).ppn = 27;
    subjects(16).code = 'VVQEC';
    subjects(16).raw_meg = fullfile(rootdir, 'raw', 'sub-027', 'ses-meg01', 'meg', 'sub027ses01_3018012.23_20210615_01.ds');
    subjects(16).raw_mri = fullfile(rootdir, 'raw', 'sub-027', 'ses-1', 'mri', '009-t1_mprage_sag_ipat2_1p0iso', '00001_1.3.12.2.1107.5.2.19.45416.2021042715334073579920583.IMA');
    subjects(16).raw_edf = fullfile(rootdir, 'raw', 'sub-027', 'ses-1', 'beh', 'Sub27-1.edf');
    subjects(16).raw_pol = fullfile(rootdir, 'raw', 'sub-027', 'ses-1', 'pol', 'S27-1.pos');
    subjects(16).beh_meg = fullfile(rootdir, 'raw', 'sub-027', 'ses-1', 'beh', 'VVQEC_MEG.txt');
    subjects(16).include = true;
    
    % sub010
    subjects(17).ppn = 10;
    subjects(17).code = 'NDMPI';
    subjects(17).raw_meg = fullfile(rootdir, 'raw', 'sub-010', 'ses-meg01', 'meg', 'sub010ses01_3018012.23_20210615_01.ds');
    subjects(17).raw_mri = fullfile(rootdir, 'raw', 'sub-010', 'ses-1', 'mri', '002-t1_mprage_sag_p2_iso_1.0_20ch_head', '00001_1.3.12.2.1107.5.2.43.67027.2019121609435959700759152.IMA');
    subjects(17).raw_edf = fullfile(rootdir, 'raw', 'sub-010', 'ses-1', 'beh', 'Sub10-1.edf');
    subjects(17).raw_pol = fullfile(rootdir, 'raw', 'sub-010', 'ses-1', 'pol', 'S10-1.pos');
    subjects(17).beh_meg = fullfile(rootdir, 'raw', 'sub-010', 'ses-1', 'beh', 'NDMPI_MEG.txt');
    subjects(17).include = true;
    
    % sub026
    subjects(18).ppn = 26;
    subjects(18).code = 'DSMNW';
    subjects(18).raw_meg = fullfile(rootdir, 'raw', 'sub-026', 'ses-meg01', 'meg', 'sub026ses01_3018012.23_20210616_01.ds');
    subjects(18).raw_mri = fullfile(rootdir, 'raw', 'sub-026', 'ses-1', 'mri', '002-t1_mprage_sag_p2_iso_1.0', '00001_1.3.12.2.1107.5.2.43.67027.2017101810554757885961327.IMA');
    subjects(18).raw_edf = fullfile(rootdir, 'raw', 'sub-026', 'ses-1', 'beh', 'Sub26-1.edf');
    subjects(18).raw_pol = fullfile(rootdir, 'raw', 'sub-026', 'ses-1', 'pol', 'S26-1.pos');
    subjects(18).beh_meg = fullfile(rootdir, 'raw', 'sub-026', 'ses-1', 'beh', 'DSMNW_MEG.txt');
    subjects(18).include = true;
    
    % sub009
    subjects(19).ppn = 9;
    subjects(19).code = 'UNPWH';
    subjects(19).raw_meg = fullfile(rootdir, 'raw', 'sub-009', 'ses-meg01', 'meg', 'sub009ses01_3018012.23_20210616_01.ds');
    subjects(19).raw_mri = fullfile(rootdir, 'raw', 'sub-009', 'ses-1', 'mri', '006-t1_mprage_sag_ipat2_1p0iso_20ch-head-neck', '00001_1.3.12.2.1107.5.2.19.45416.2021060315503715506186994.IMA');
    subjects(19).raw_edf = fullfile(rootdir, 'raw', 'sub-009', 'ses-1', 'beh', 'Sub9-1.edf');
    subjects(19).raw_pol = fullfile(rootdir, 'raw', 'sub-009', 'ses-1', 'pol', 'S09-1.pos');
    subjects(19).beh_meg = fullfile(rootdir, 'raw', 'sub-009', 'ses-1', 'beh', 'UNPWH_MEG.txt');
    subjects(19).include = true;
    
    % sub004
    subjects(20).ppn = 4;
    subjects(20).code = 'RCPSD';
    subjects(20).raw_meg = fullfile(rootdir, 'raw', 'sub-004', 'ses-meg01', 'meg', 'sub004ses01_3018012.23_20210621_02.ds');
    %subjects(20).raw_mri = fullfile(rootdir, 'raw', 'sub-004', 'ses-1', 'mri', '', '');
    subjects(20).raw_edf = fullfile(rootdir, 'raw', 'sub-004', 'ses-1', 'beh', 'Sub4-1.edf');
    subjects(20).raw_pol = fullfile(rootdir, 'raw', 'sub-004', 'ses-1', 'pol', 'S4-1.pos');
    subjects(20).beh_meg = fullfile(rootdir, 'raw', 'sub-004', 'ses-1', 'beh', 'RCPSD_MEG.txt');
    subjects(20).include = false;
    
    % add outputs + dirs
    for sid = 1:numel(subjects)
        subjects(sid).out = fullfile(rootdir, 'processed', sprintf('sub-%02d', subjects(sid).ppn));
        warning('off', 'MATLAB:MKDIR:DirectoryExists');
        mkdir(subjects(sid).out);
        warning('on', 'MATLAB:MKDIR:DirectoryExists');
    end
    
    warning('off', 'MATLAB:MKDIR:DirectoryExists');
    mkdir(fullfile(rootdir, 'processed', 'combined'));
    warning('on', 'MATLAB:MKDIR:DirectoryExists');
end