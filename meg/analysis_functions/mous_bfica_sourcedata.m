function [sdata] = mous_bfica_sourcedata(source, freq, toi)

warning off;
freq = ft_struct2double(freq);
warning on;

if nargin==3
  freq =  ft_selectdata(freq, 'toilim', toi+[-0.1 0.1]*mean(diff(freq.time)));
else
  freq = mtmconvol2mtmfft(freq, 200);
end

% compute single 'trial' power
ix  = 1:numel(freq.cumtapcnt);
ix  = repmat(ix, freq.cumtapcnt(1),1);
ix  = ix(:);
iy  = 1:sum(freq.cumtapcnt);
val = ones(numel(iy),1)./freq.cumtapcnt(1);
P   = sparse(ix,iy,val);
trial = zeros(numel(freq.cumtapcnt), numel(source.inside));
for k = 1:numel(source.inside)
  filt = source.avg.filter{source.inside(k)};
  trial(:,k) = P*(abs(freq.fourierspctrm*filt').^2);
end
trial  = trial';
% trial  = log10(trial)';
% mtrial = nanmean(trial,2);
% for k = 1:size(trial,2)
%   trial(:,k) = trial(:,k)-mtrial;
% end

% convert to a raw array
sdata = [];
sdata.trial{1} = trial;
sdata.time{1}  = 1:size(trial,2);
sdata.label    = cell(size(trial,1),1);
for k = 1:numel(sdata.label);
  sdata.label{k} = num2str(source.pos(source.inside(k),:));
end
sdata.trialinfo = freq.trialinfo;
