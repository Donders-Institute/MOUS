function [badsegments] = mous_cleandata(data)

% HCP_ICA_QUALITYCHECK_PIPELINE allows the rejection of channels and intervals
% harmful for an Independent Component Analysis. It is babsed on an
% iterative procedure updating the list of bad segments and channels each
% iteration ending when no channels and intervals are found.
%
% Output data are vectors containing the bad channels and intervals
% selected.
%
% Use as
% [skint, bch, iter_res] = hcp_ICA_qualitycheck_pipeline(filename, options_ICA)
%
% where filename is a string that points to a raw data file in the database
% and options_ICA is a cell-array specifying the behaviour of the
% algorithm. Cell-arrays need to be organized as sets of key-value pairs,
% i.e. {'key1', 'value1', ...}.
%
% Options needs to contain the following key:
%   channel: channel selection, in case of bad channels previously selected
%   skipped_intervals: Nx2 matrix of skipped intervals previusoly selected (t11 t12 ; t21 t22; ... ; tn1 tn2)
%   bandpass (optional): band pass intervals ([f1 f2] default [1 150])
%   bandstop (optional): band stop intervals ([fs1 fs2] default [59 61 ; 119 121])
%
% The following steps are performed:
% -reading in all data from disk
% -band pass and if required band stop filtering of the selected channels
% -FastICA analysis
% -Find Bad Channels according to the weight of the Mixing matrix
% -Find large artifact in the IC time courses according to a local variance
% -Selects the intervals to be cutted
%
% Example use:
% fname='0';
% options_ICA = {'channels', 'MEG', 'skipped_intervals', [], 'bandpass', [1 150], 'bandstop', [59 61 ; 119 121]};
% [skipped_intervals, bad_channels ] = hcp_ICA_qualitycheck_pipeline(fname,options_ICA)

dataorig = data;

% These are hard coded thresholds. Should we consider to make them
% configurable?
num_std = 10;
num_sig     = 10; % number of standard deviation out of the mean from the artifact detection
sic_thr_par = 5;  % factor of multiplication of the threshold for the determination of the intervals to be skipped

badchannels = zeros(0,1);
badchanindx = zeros(0,1);
badcompindx = zeros(0,1);
badsegments  = zeros(0,2);
  
goodtrials  = 1:numel(data.trial);
goodchanindx = 1:numel(data.label);
stop         = false;
while ~stop
  
  
  
  %data = ft_selectdata(dataorig, 'rpt',     goodtrials);
  %data = ft_selectdata(data,     'channel', goodchanindx);
 
  % specify options for fastica, probably icasso is not needed at the moment, purpose is to remove 
  % bad channels and bad segments.
  cfg                          = [];
  cfg.cellmode                 = 'yes';
  cfg.method                   = 'fastica';
  cfg.numcomponent             = 100;
  cfg.fastica.maxNumIterations = 250;
  cfg.fastica.approach         = 'defl';
  cfg.fastica.g                = 'tanh';
%  cfg.fastica.finetune         = 'tanh'; % does not work yet in cell-mode
  cfg.fastica.numOfIC          = 100;
  cfg.fastica.lastEig          = 120; 
  comp                         = ft_componentanalysis(cfg, data);
  
  % compute per trial a local mean and a local std, 
  % and zscore the data
  nsmooth    = round(1*comp.fsample);
  offset     = 0;
  thrdat     = false(numel(comp.label), sum(cellfun('size',comp.trial,2)));
  trlcnt     = zeros(1, size(thrdat,2));
  for k = 1:numel(comp.trial)
    thistrial   = abs(comp.trial{k});
    localmean   = ft_preproc_smooth(thistrial, nsmooth);
    localstd    = sqrt(ft_preproc_smooth(thistrial.^2, nsmooth));
    localstd    = clip_boxplotrule(localstd);
    localzscore = (thistrial-localmean)./localstd;
    thrdat(:,offset + (1:numel(comp.time{k}))) = localzscore > num_std;
    trlcnt(offset + (1:numel(comp.time{k})))   = k;
    offset      = offset + numel(comp.time{k});
  end 
  
  % if more than 2 components are simultaneously suprathreshold, mark the
  % segments as bad
  sel = unique(trlcnt(sum(thrdat,1)>2));
  nbadseg = 0;
  for k = sel(:)'
    tmpthrdat   = thrdat(:, trlcnt==k);
    selcomp     = sum(tmpthrdat(:,sum(tmpthrdat,1)>2),2)>0;
    thistrial   = mean(abs(comp.trial{k}(selcomp,:)));
    localmean   = ft_preproc_smooth(thistrial, nsmooth);
    localstd    = sqrt(ft_preproc_smooth(thistrial.^2, nsmooth));
    localstd    = clip_boxplotrule(localstd);
    localzscore = (thistrial-localmean)./localstd;
    
    tmp = ft_preproc_smooth(double(localzscore-num_std>0), 0.5*nsmooth)>0;
    
    % identify clipped localstd segments as bad segments
    if sum(tmp>0)
      % detect on/off samples
      on  = find([tmp 0]==1 & [0 tmp]==0);
      off = find([0 tmp]==1 & [tmp 0]==0);
      
      badsegments = cat(1, badsegments, data.sampleinfo(k,1)-1+[on(:) off(:)]);
      nbadseg     = numel(on) + nbadseg;
    else
      % skip
    end
  end

  if nbadseg > 0
    cfg = [];
    cfg.artfctdef.badsegments.artifact = badsegments;
    cfg.artfctdef.reject               = 'partial';
    data                               = ft_rejectartifact(cfg, data);
  else
    stop = true;
  end
end

%   
%   
%   % now look at the mixing matrices per component
%   for k = 1:size(comp.topo,2)
%     flag_bad    = false(1,numel(comp.topolabel));
%     [vt,order]  = sort(abs(comp.topo(:,k)),'descend');
%     if vt(1)/vt(2) > 15
%       flag_bad(1) = vt(1)/vt(2) > 15; % discard when IC weight 10 times greater than the second
%       badcompindx = [badcompindx; k];
%     end 
%     mvt = median(vt);
%     svt = std(vt);
%     if any(vt > mvt + 15*svt)
%       flag_bad(vt > mvt + 15*svt) = true; % discard when IC weight > median+10*std
%       badcompindx = [badcompindx; k];
%     end    
%     if sum(flag_bad)
%       badchanindx = [badchanindx;order(flag_bad)];
%       badchannels = [badchannels;comp.topolabel(badchanindx)];
%     end
%   end
%   badcompindx = unique(badcompindx);
%   badchanindx = unique(badchanindx);
%   badchannels = unique(badchannels);
%   
%   % remove the components that represent bad channels from the data
%   compsmooth = ft_selectdata(compsmooth, 'channel', comp.label(setdiff(1:numel(comp.label), badcompindx)));
%   comp       = ft_selectdata(comp,       'channel', comp.label(setdiff(1:numel(comp.label), badcompindx)));
% 
%   clear std_IC mean_sIC max_std max_val
%   max_val = -inf+zeros(size(comp.topo,2),1);
%   badtrials = zeros(0,1);
%   for k = 1:numel(comp.trial)
%     std_IC(:,k)   = std(comp.trial{k}, [], 2);
%     mean_sIC(:,k) = mean(compsmooth.trial{k}, 2);
%     max_val = max(max_val, max(abs(comp.trial{k}),[],2));
%   end
%   max_std  = max(std_IC,[], 2);
%   mean_std = mean(std_IC,   2);
%   std_std  = std(std_IC,[], 2);
% 
%   ic_ind  = std_IC>repmat(mean_std+num_sig*std_std, [1 numel(comp.trial)]);
%   [i1,i2] = find(ic_ind);
%   for k = 1:numel(i1)
%     IC2     = abs(comp.trial{i2(k)}(i1(k),:));
%     sIC2    = abs(compsmooth.trial{i2(k)}(i1(k),:));
%     ref_sIC = median(mean_sIC(i1(k),:));
%     
%     [junk, max_ind2] = max(IC2);
%     over_thr         = sIC2 > sic_thr_par*ref_sIC;
%     
%     if sum(over_thr)
%       badtrials                  = [badtrials; i2(k)];
%       comp.trial{i2(k)}(i1(k),:) = 0;
%       compsmooth.trial{i2(k)}(i1(k), :) = 0;
%     end
%   end
%   badtrials = goodtrials(badtrials);
% 
% goodtrials = setdiff(goodtrials, badtrials);
% badtrials  = setdiff(1:numel(dataorig.trial), goodtrials);
% 
% 
function out = clip_boxplotrule(in)

[m,n]    = size(in);

[t1, t2] = percthreshold(in, 0.25, 2);
iq       = t2-t1;
upper    = t2+1.5*iq;
%lower    = t1-1.5*iq; % don't clip the lower

out      = min(in, upper*ones(1,n));

