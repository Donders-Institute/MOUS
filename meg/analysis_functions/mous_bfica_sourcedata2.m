function [sdata] = mous_bfica_sourcedata2(source, freq, toi)

if nargin==3
  freq = ft_selectdata(freq, 'toilim', toi+[-eps eps]);
else
  freq = mtmconvol2mtmfft(freq, 200);
end

% compute single taper fourier coefficients
trial = zeros(numel(freq.cumtapcnt), numel(source.inside));
for k = 1:numel(source.inside)
  filt = source.avg.filter{source.inside(k)};
  trial(:,k) = freq.fourierspctrm(1:3:end,:)*filt';
end
trial = transpose(trial);
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
