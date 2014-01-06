function [comp, avgpre, avgcomp] = mous_bfica_dss(subjectname, p)

% get data and apply artifact rejection
dataset   = mous_db_getfilename(subjectname, 'meg_ds_task');

if numel(dataset)>1
    for k = 1:numel(dataset)
        tmpdataset          = dataset{k};
        mous_db_getdata(subjectname,['meg_artifact_cfg_pt',num2str(k)]);
        tmpartfctcfg        = {cfgeog1 cfgeog2 cfgjump cfgmuscle};
        [tmpdata, tmpecg]   = compute_data(tmpdataset, tmpartfctcfg, subjectname);
        if k == 1
            data = tmpdata;
            ecg  = tmpecg;
        else
            data = ft_appenddata([],data,tmpdata);
            ecg  = ft_appenddata([],ecg,tmpecg);
        end
    end
else
    mous_db_getdata(subjectname, 'meg_artifact_cfg');
    artfctcfg   = {cfgeog1 cfgeog2 cfgjump cfgmuscle};
    [data, ecg] = compute_data(dataset{1}, artfctcfg, subjectname);
end 

% if mous_bfica_ecg was not called previously
% compute polarity (+ve/-ve value) and threshold for detecting peaks
if nargin==1
    % compute peak times for ecg
    ecg = ft_channelnormalise([], ecg);
    tmp = cat(2, ecg.trial{:});
    %polarity = 2*(double(sum(tmp>4)>sum(tmp<-4))-0.5);
    figure;plot(tmp);
    s1 = input('polarity?','s');
    s2 = input('threshold?','s');
    close;

    polarity = str2double(s1);
    threshold = str2double(s2);

    for k = 1:numel(ecg.trial)
    p{k} = peakdetect2(polarity*ecg.trial{k},4,1);
    end
end

% determine components for ecg 
% remove components that explain variance in top 10% of ecg pattern
paramscell.tr = p;
paramscell.pre = 0.25*data.fsample;
paramscell.pst = 0.50*data.fsample;
paramscell.demean = true;

cfg                   = [];
cfg.method            = 'dss';
cfg.dss.denf.function = 'denoise_avg2';
cfg.dss.denf.params   = paramscell;
cfg.dss.wdim          = 75;
cfg.numcomponent      = 10;
cfg.channel           = 'MEG';
cfg.cellmode          = 'yes';
comp                  = ft_componentanalysis(cfg, data);

s.state = 1;
[~,~,avgcomp] = denoise_avg2(paramscell, comp.trial, s);
[~,~,avgpre]  = denoise_avg2(paramscell, data.trial, s);
comp = rmfield(comp, 'trial');

%%% SUBFUNCTION %%%
% remove artifacts from MEG data
function [data, ecg] =  compute_data(dataset, artfctcfg, subjectname)

% remove artifacts from dataset
cfg          = [];
cfg.dataset  = dataset;  
if strcmp(subjectname(1),'V')
    cfg.trialfun = 'trialfun_visual_sentence';
elseif strcmp(subjectname(1),'A')
    cfg.trialfun = 'trialfun_auditory_sentence';
end
%cfg.trialfun = 'trialfun_visual_word';
%cfg.trialdef.prestim  = 0;
%cfg.trialdef.poststim = 0.8;
cfg          = ft_definetrial(cfg);
trl          = cfg.trl;
trl          = mous_artifact_remove(trl, dataset, artfctcfg([1 2 3 4]), 'partial', 1); % don't do the horizontal EOG

cfg            = [];
cfg.dataset    = dataset;
cfg.trl        = trl;
cfg.continuous = 'yes';
cfg.demean     = 'yes';
cfg.channel    = 'MEG';
data           = ft_preprocessing(cfg);

if nargin>1 
  cfg.padding    = 1.5;
  cfg.hpfilter   = 'yes';
  cfg.hpfreq     = 4;
  cfg.channel    = 'EEG059';
  ecg            = ft_preprocessing(cfg); 
end

% downsample
cfg            = [];
cfg.demean     = 'yes';
cfg.detrend    = 'no';
cfg.resamplefs = 200;
data           = ft_resampledata(cfg, data);
ecg            = ft_resampledata(cfg, ecg);
