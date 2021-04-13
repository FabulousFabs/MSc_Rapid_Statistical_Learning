% @Description: Takes PL condition and recodes to
% what the BITSI codes are in the MEG. This is the
% counterpart to rslSUBS.pcl::CodeOnsetTrigger() 
% in our experiment.
%
% INPUTS:
%       PL      -   Nx2 matrix of pools & lists
%
% OUTPUTS:
%       conds   -   Nx1 condition vector where:
%
%                          pool
%                   l	1	2	3
%                   i	4	5	6
%                   s	7	8	9
%                   t

function conds = helper_recode_condition(pl)
    assert(isempty(pl) == false);
    
    conds = (pl(:,2) - 1) * 3 + pl(:,1);
end