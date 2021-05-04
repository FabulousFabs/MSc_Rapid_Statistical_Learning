% @Description: Applies filters to compute source power.
% 
% INPUTS:
%   source      - DICS filters
%   freq        - Fourier spectra
%
% OUTPUTS:
%   source_pow  - Source power

function source_pow = helper_compute_single_trial_power(source, freq)
    npos = sum(source.inside);
    ntim = numel(freq.time);
    nfreq = numel(freq.freq);
    nrpttap = size(freq.fourierspctrm, 1);
    assert(nfreq == 1);
    
    fullfilt = cat(1, source.avg.filter{source.inside});
    source_fourier = mtimesx(fullfilt, freq.fourierspctrm, 'T');
    source_fourier = reshape(source_fourier, [npos nrpttap ntim]);
    ntap = freq.cumtapcnt(1);
    nrpt = numel(freq.cumtapcnt);
    assert(all(freq.cumtapcnt == ntap));
    
    pow = zeros(npos, nrpt, ntim);
    for k = 1:ntap
        pow = pow + abs(source_fourier(:,k:ntap:end,:)).^2;
    end
    pow = pow ./ ntap;
    
    source_pow = [];
    source_pow.pos = source.pos(source.inside,:);
    source_pow.inside = true(npos,1);
    source_pow.pow = pow;
    source_pow.time = freq.time;
    source_pow.dimord = 'pos_rpt_time';
end