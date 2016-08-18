function mous_oscerf_scca(subjectname, varargin)

frequency   = ft_getopt(varargin, 'frequency', 10);
latency     = ft_getopt(varargin, 'latency', -0.1);
latency2    = ft_getopt(varargin, 'latency2', [0.35 0.45]);


% deal with the frequency domain data
mous_db_getdata(subjectname, 'meg_bfica_freq_low');
tmpcfg = [];
tmpcfg.trials = find(ismember(freq.trialinfo(:,2),[1 2 5 6])); % sentences only
tmpcfg.frequency = frequency;
freq  = ft_selectdata(tmpcfg, freq);
freq  = ft_struct2double(freq);
freq.cumtapcnt = freq.cumtapcnt(:,1);

% convert to source space
[s,t] = mous_bfica_source(subjectname,freq,[],[],'/project/3011020.09/MEG',0);
inside = s.inside;
dim    = s.dim;

sdata = mous_bfica_sourcedata(s, freq, latency, true);

% deal with the time domain data
mous_db_getdata(subjectname, 'meg_erf_allwords_02-nextword');
tmpcfg = [];
tmpcfg.trials = find(ismember(data.trialinfo(:,2),[1 2 5 6 ]));
data = ft_selectdata(tmpcfg, data);
ok   = false(numel(data.trial),1);
for k = 1:numel(data.trial)
  ok(k,1) = data.time{k}(1)<=-0.1&data.time{k}(end)>=max(latency2);
end
tmpcfg.trials = find(ok);
data = ft_selectdata(tmpcfg, data);
tmpcfg = [];
tmpcfg.demean = 'yes';
tmpcfg.baselinewindow = [-0.1 0];
data = ft_preprocessing(tmpcfg, data);
tmpcfg = [];
tmpcfg.latency = latency2;
tmpcfg.channel = 'MEG';
data = ft_selectdata(tmpcfg, data);

% match the trials
t_osc = sdata.trialinfo(:,[end end-1]);
t_erf = data.trialinfo(:,[end end-1]);
[int, i_osc, i_erf] = intersect(t_osc, t_erf, 'rows');
tmpcfg = [];
tmpcfg.trials = i_erf;
data = ft_selectdata(tmpcfg, data);

sdata.trial{1} = log(sdata.trial{1}(:,i_osc));
sdata.time{1}  = 1:numel(i_osc);
sdata.trialinfo = sdata.trialinfo(i_osc,:);

mous_db_getdata(subjectname, 'meg_bfica_leadfield8mm');
mous_db_getdata(subjectname, 'meg_anatomy_sourcemodel2Dsurfreg');

% interpolate the oscillatory power onto the cortical sheet
sourcemodel = rmfield(sourcemodel,'leadfield');
sourcemodel.pow = zeros(prod(sourcemodel.dim),size(sdata.trial{1},2));
sourcemodel.pow(sourcemodel.inside,:) = sdata.trial{1};

cfg = [];
cfg.parameter = 'pow';
cfg.interpmethod = 'sphere_avg';
cfg.sphereradius = 0.8;
sourcemodel = ft_sourceinterpolate(cfg, sourcemodel, bnd);

% get the MNE spatial filters
mous_db_getdata(subjectname, 'meg_mne_allwords_02-nextword_sent');
load('atlas_conte69_8196reg_LR_brodmann_subparc');


inside2 = intersect(source.inside, find(atlas.inside));
F = source.avg.filter(inside2);
clear source;

% convert the time domain data to source space
dat_erf = zeros(numel(F), numel(data.trial));
for k = 1:numel(F)
  if mod(k,10)==0, fprintf('processing vertex %d/%d\n', k, numel(F)); end
  tmp = (F{k}*data.trial).^2;
  tmp = cellfun(@sum,  tmp, 'uniformoutput', false);
  tmp = cellfun(@mean, tmp, 'uniformoutput', false);
  dat_erf(k,:) = log(cell2mat(tmp)); %take the log-transform to get a better distribution of the values
end

dat_osc = sourcemodel.pow(inside2,:);%sdata.trial{1};
sel     = isfinite(dat_osc(1,:));

dat_erf = dat_erf(:,sel);
dat_osc = dat_osc(:,sel);

sdat_erf = standardise(dat_erf,2)';
sdat_osc = standardise(dat_osc,2)'; % the R-script expects the spatial dimension in the columns

datadir = fullfile('/project/3011020.09/jansch/',subjectname);
save(fullfile(datadir,'sdat_erf'),'sdat_erf');
save(fullfile(datadir,'sdat_osc'),'sdat_osc');

rscript = fullfile('/home/language/jansch/rscript.R');
systemcall = sprintf('Rscript %s %s',rscript,subjectname);
system(systemcall);

load(fullfile(datadir,'SCCA.mat'));

s_erf = sdat_erf*Werf;
s_osc = sdat_osc*Wosc;

Aerf = cov(sdat_erf)*Werf/cov(s_erf);
Aosc = cov(sdat_osc)*Wosc/cov(s_osc);

%tmp = zeros(prod(dim),size(Werf,2));
%tmp(inside,:) = Aosc;
tmp = zeros(8196,size(Werf,2));
tmp(inside2,:) = Aosc;
Aosc = tmp;
tmp(inside2,:) = Wosc;
Wosc = tmp;
tmp = zeros(8196,size(Werf,2));
tmp(inside2,:) = Aerf;
Aerf = tmp;
tmp(inside2,:) = Werf;
Werf = tmp;

[srt, ix] = sort(ccor, 'descend');
Aerf = Aerf(:,ix);
Aosc = Aosc(:,ix);
Werf = Werf(:,ix);
Wosc = Wosc(:,ix);
s_erf = s_erf(:,ix);
s_osc = s_osc(:,ix);
ccor = srt;

save(fullfile(datadir,'SCCA.mat'),'Aerf','Aosc','Werf','Wosc','s_osc','s_erf','ccor','-append');

