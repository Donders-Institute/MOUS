function [sdata] = mous_bfica_sourcedata(source, freq, toi, powflag)

warning off;
freq = ft_struct2double(freq);
warning on;

if nargin<4
  powflag = 1;
end
if nargin>=3 && ~isempty(toi)
  freq =  ft_selectdata(freq, 'toilim', toi+[-0.1 0.1]*mean(diff(freq.time)));
% below, and "elseif" is implemented instead of an "else" so that the code works for corrmnebf
% This was this on 18.4.2013 btw JM and NL, but NL didn't push the change
% the first time but only changed her own local copy
elseif isfield(freq,'time') 
  freq = mtmconvol2mtmfft(freq, 300); %FIXME used to be 200, we should have access to the downsample freq: NOTE the second input does not seem to be  used in the function
end

% ensure the inside to be an indexed vector (new convention of FT is
% boolean)
if all(islogical(source.inside))
  source.outside = find(~source.inside);
  source.inside  = find(source.inside);
end


if powflag
  trial = zeros(sum(freq.cumtapcnt),numel(source.inside));
  % compute single 'trial' power
  ix  = 1:numel(freq.cumtapcnt);
  ix  = repmat(ix, freq.cumtapcnt(1),1);
  ix  = ix(:);
  iy  = 1:sum(freq.cumtapcnt);
  val = ones(numel(iy),1)./freq.cumtapcnt(1);
  P   = sparse(ix,iy,val);
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
else
  filt  = cat(1,source.avg.filter{source.inside});
  trial = filt*transpose(freq.fourierspctrm);
end

% convert to a raw array
sdata = [];
sdata.trial{1} = trial;
sdata.time{1}  = 1:size(trial,2);
sdata.label    = cell(size(trial,1),1);
for k = 1:numel(sdata.label);
  sdata.label{k} = num2str(source.pos(source.inside(k),:));
end
sdata.trialinfo = freq.trialinfo;
