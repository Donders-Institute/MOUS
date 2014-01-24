function [comp, avgcomp, avgpre, avgeog] = mous_artifact_eog_dss_saccades(filename, trl)

% read and resample in chunks for memory efficiency
div = linspace(0,size(trl,1),5);
for k = 1:(numel(div)-1)
  cfg            = [];
  cfg.dataset    = filename;
  cfg.trl        = trl((div(k)+1):div(k+1),:);
  cfg.continuous = 'yes';
  cfg.demean     = 'yes';
  cfg.channel    = 'EEG057';
  tmpeog            = ft_preprocessing(cfg);
  cfg.channel    = 'MEG';
  tmpdata           = ft_preprocessing(cfg);
  
  cfg            = [];
  cfg.demean     = 'yes';
  cfg.detrend    = 'no';
  cfg.resamplefs = 300;
  tmpeog            = ft_resampledata(cfg, tmpeog);
  tmpdata           = ft_resampledata(cfg, tmpdata);
  
  if k==1
    data = tmpdata;
    eog  = tmpeog;
  else
    data = ft_appenddata([], data, tmpdata);
    eog  = ft_appenddata([], eog,  tmpeog);
  end
  clear tmpdata tmpeog;
end

% detect the saccades
for k = 1:numel(eog.trial)
  [tmp, R{k}] = mous_preproc_saccades(eog.trial{k});
  on{k}       = find(diff([0 tmp 0])>0 | (diff([0 tmp 0])<0 & [0 tmp]>0 & [tmp 0]>0));
  off{k}      = find(diff([0 tmp 0])<0 | (diff([0 tmp 0])>0 & [0 tmp]>0 & [tmp 0]>0));
  if ~isempty(R{k})
    on{k}(R{k}<0.9)  = [];
    off{k}(R{k}<0.9) = [];
    R{k}(R{k}<0.9)   = [];
  end
end
nsmp   = cell2mat(off)-cell2mat(on)+1;
dat    = zeros(numel(nsmp),max(nsmp));
offset = floor(max(nsmp)/2) - floor(nsmp/2);

cnt = 0;
for k = 1:numel(eog.trial)
  for m = 1:numel(on{k})
    cnt = cnt+1;
    tmp = eog.trial{k}(on{k}(m):off{k}(m));
    tmp = tmp-mean(tmp);
    if sign(mean(tmp(1:floor(nsmp(cnt)/2)))) > 0,
      tmp = -tmp;
    end
    dat(cnt, offset(cnt) + (1:nsmp(cnt))) = tmp;
  end
end

paramscell.tr  = floor((on+off)./2);
paramscell.pre = paramscell.tr - on + 20; 
paramscell.pst = off - paramscell.tr + 20;
paramscell.demean = 1;

cfg                   = [];
cfg.method            = 'dss';
cfg.dss.denf.function = 'denoise_avg2';
cfg.dss.denf.params   = paramscell;
cfg.dss.wdim          = 75;
cfg.numcomponent      = 16;
cfg.channel           = 'MEG';
cfg.cellmode          = 'yes';
comp                  = ft_componentanalysis(cfg, data);

s.state       = 1; 
[~,~,avgpre]  = denoise_avg2(paramscell, data.trial, s);
[~,~,avgcomp] = denoise_avg2(paramscell, comp.trial, s);
[~,~,avgeog]  = denoise_avg2(paramscell,  eog.trial, s);
