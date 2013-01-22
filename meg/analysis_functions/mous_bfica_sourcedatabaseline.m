function [sdata] = mous_bfica_sourcedatabaseline(source, freq, frequency)

warning off;
freq = ft_struct2double(freq);
warning on;

freq = ft_selectdata(freq, 'foilim', frequency);


% compute single 'trial' power
ix = zeros(0,1);
iy = zeros(0,1);
val = zeros(0,1);
for k = 1:numel(freq.cumtapcnt)
  ix = cat(1,ix,ones(freq.cumtapcnt(k),1)*k);
  iy = cat(1,iy,(numel(iy)+[1:freq.cumtapcnt(k)]'));
  val = cat(1,val,ones(freq.cumtapcnt(k),1)./freq.cumtapcnt(k));
end
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
