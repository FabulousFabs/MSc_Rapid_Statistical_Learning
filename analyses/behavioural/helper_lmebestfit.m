% @Description: Wrapper function that fits multiple LME models with varying
% random effects to determine the best RE structure. Determine best fixed
% effects structure prior to this call. It should also be noted that you
% should have some idea (or good motivations) for specific ways of
% formulating your random effects at this stage already.
%
% INPUTS:
%   data                -   Data structure to fit to
%   fixed_structure     -   String of the fixed effect structure
%   random_structures   -   Array of random effect formulas
%   fit_method          -   (Optional) FitMethod for lme
%   dummy_coding        -   (Optional) DummyVarCoding for lme
%
% OUTPUTS:
%   models              -   All models, each with a .lme and .rel object
%   model_best          -   Index of the best model in models{}

function [models, model_best] = helper_lmebestfit(data, fixed_structure, random_structures, fit_method, dummy_coding, alpha)
    if ~exist('fit_method', 'var')
        fit_method = 'REML';
    end
    
    if ~exist('dummy_coding', 'var')
        dummy_coding = 'full';
    end
    
    if ~exist('alpha', 'var')
        alpha = .05;
    end
    
    models = {};
    model_best = 0;
    current_terms = {fixed_structure};
    
    for i = 1:size(random_structures, 1)
        fprintf('\n*** Fitting model%.0d. ***\n', i);
        
        formula = sprintf('%s + %s', strjoin(current_terms, ' + '), random_structures{i,1});
        fprintf('Formula: %s\n', formula);
        
        models{i}.lme = fitlme(data, formula, 'FitMethod', fit_method, 'DummyVarCoding', dummy_coding);
        fprintf('Model fit.\n');
        
        if i > 1
            fprintf('Running comparison.\n');
            
            models{i}.rel = compare(models{model_best}.lme, models{i}.lme);
            
            if (models{i}.rel.AIC(2) < models{i}.rel.AIC(1)) & (models{i}.rel.pValue <= alpha)
                fprintf('Significant improvement achieved.\n');
                
                model_best = i;
                current_terms{end+1} = random_structures{i,1};
            else
                fprintf('No significant improvement achieved.\n');
            end
        else
            model_best = 1;
            current_terms{end+1} = random_structures{i,1};
            models{i}.rel = {};
        end
    end
end

