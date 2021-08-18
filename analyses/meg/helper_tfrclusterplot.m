% @Description: A slightly altered version of Eelke's TFR plotting
% function that works better with what we're doing here.

function helper_tfrclusterplot(stat, alpha, hq, include_posclusters, include_negclusters)
%
% Copyright (C) Eelke Spaak, Donders Institute, Nijmegen, The Netherlands, 2019.
% 
% This code is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% This code is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this code. If not, see <https://www.gnu.org/licenses/>.

if nargin < 2 || isempty(alpha)
  alpha = 0.05;
end

if nargin < 3 || isempty(hq)
  hq = 0;
end

if nargin < 4 || isempty(include_posclusters)
  include_posclusters = 1:100;
end

if nargin < 5 || isempty(include_negclusters)
  include_negclusters = 1:100;
end

if hq
  % interpolate stat and mask
  tim_interp = linspace(min(stat.time), max(stat.time), 512);
  freq_interp = linspace(min(stat.freq), max(stat.freq), 512);
  chanax = 1:numel(stat.label);
  
  % We need to make a full time/frequency grid of both the original and
  % interpolated coordinates. Matlab's meshgrid() does this for us:
  [chan_grid_orig, freq_grid_orig, tim_grid_orig] = ndgrid(chanax, stat.freq, stat.time);
  [chan_grid_interp, freq_grid_interp, tim_grid_interp] = ndgrid(chanax, freq_interp, tim_interp);

  F = griddedInterpolant(chan_grid_orig, freq_grid_orig, tim_grid_orig, stat.stat);
  stat.stat = F(chan_grid_interp, freq_grid_interp, tim_grid_interp);
  F = griddedInterpolant(chan_grid_orig, freq_grid_orig, tim_grid_orig, double(stat.mask));
  stat.mask = F(chan_grid_interp, freq_grid_interp, tim_grid_interp);
  
  if isfield(stat, 'posclusters')
    F = griddedInterpolant(chan_grid_orig, freq_grid_orig, tim_grid_orig, double(stat.posclusterslabelmat), 'nearest');
    stat.posclusterslabelmat = F(chan_grid_interp, freq_grid_interp, tim_grid_interp);
  end
  if isfield(stat, 'negclusters')
    F = griddedInterpolant(chan_grid_orig, freq_grid_orig, tim_grid_orig, double(stat.negclusterslabelmat), 'nearest');
    stat.negclusterslabelmat = F(chan_grid_interp, freq_grid_interp, tim_grid_interp);
  end

  stat.time = tim_interp;
  stat.freq = freq_interp;
end

if isfield(stat, 'posclusters')
  makeplots(stat.posclusters, stat.posclusterslabelmat, include_posclusters);
end

if isfield(stat, 'negclusters')
  makeplots(stat.negclusters, stat.negclusterslabelmat, include_negclusters);
end

function makeplots(clusters, labelmat, include)
  for k = 1:numel(clusters)
    if clusters(k).prob < alpha && ismember(k, include)
      f = figure();
      
      % make one topo with highlighted channels that have *any* significant
      % time/freq voxel (chanmask)
      chanmask = squeeze(any(any(labelmat==k,2),3));
      tfrmask = squeeze(any(labelmat==k,1)); % any sig channel (tfrmask)
      
      % the TFR
      %axes('Position', [0.1 0.3 0.64 0.64]);
      ax1 = axes();
      ax1.Position = [0.1 0.2 0.64 0.64];
      
      cfg = [];
      cfg.channel = stat.label(chanmask);
      cfg.avgoverchan = 'yes';
      tmpstat = ft_selectdata(cfg, stat);
      tmpstat.mask = reshape(tfrmask, [1 size(tfrmask)]);
      cfg = [];
      cfg.parameter = 'stat';
      cfg.maskparameter = 'mask';
      cfg.maskalpha = 0.4;
      cfg.zlim = [-2.5 2.5];
      cfg.colormap = brewermap(256, '*RdYlBu');
      cfg.colorbar = 'no';
      cfg.figure = f;
      ft_singleplotTFR(cfg, tmpstat);
      title('');
      % silly little insertion to hide uneven y-ticklabels
      ytck = yticks();
      ytcklabels = yticklabels();
      for j = 1:numel(ytck)
          if round(ytck(j)) ~= ytck(j)
              ytcklabels{j} = '';
          end
      end
      yticklabels(ytcklabels);
      xlabel('Time (s)', 'FontWeight', 'bold');
      ylabel('Frequency (Hz)', 'FontWeight', 'bold');
      c = colorbar('northoutside');
      c.Position = c.Position + [0.31 0.15 -0.4 -0.03];
      c.Label.String = 'Power (t-statistic)';
      c.Label.FontName = 'Roboto';
      c.Label.FontWeight = 'bold';
      c.Label.FontSize = 8;
      ax1.FontName = 'Roboto'; 
      ax1.FontSize = 8;
      
      %axes('Position', [0.1 0.7 0.3 0.3]);
      ax2 = axes();
      ax2.Position = [0.1 0.7 0.28 0.28];
      
      cfg = [];
      cfg.parameter = 'stat';
      cfg.layout = 'CTF275_helmet.mat';
      cfg.marker = 'off';
      cfg.highlight = 'on';
      cfg.interactive = 'no';
      cfg.style = 'straight';
      cfg.zlim = [-2.5 2.5];
      cfg.comment = 'no';
      cfg.colormap = brewermap(256, '*RdYlBu');
      cfg.gridscale = 96;
      % time and freq limits determined by circumscribed rectangle in
      % tfrmask
      tmp = squeeze(any(tfrmask, 1));
      cfg.xlim = [stat.time(find(tmp, 1, 'first')) stat.time(find(tmp, 1, 'last'))];
      tmp = squeeze(any(tfrmask, 2));
      cfg.ylim = [stat.freq(find(tmp, 1, 'first')) stat.freq(find(tmp, 1, 'last'))];
      cfg.highlightchannel = find(chanmask);
      cfg.highlightsymbol = '.';
      cfg.figure = f;
      ft_topoplotTFR(cfg, stat);
      ax2.FontName = 'Roboto'; 
      ax2.FontSize = 8;

      %title(sprintf('p = %.03f', clusters(k).prob));
    end
  end

end

end