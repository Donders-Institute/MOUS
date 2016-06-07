function mous_restingstate_prewhite_calcpow(subj,len)

[tmp] = mous_db_getdata(subj,'meg_restingstate_data','/project/3011020.09/nielam/');
data  = tmp.data;

cfg   = [];
cfg.length     = len;  % 2s = only half a cycle of theta (4 hz = 4 cycles / s)
cfg.overlap    = 0.5;
data           = ft_redefinetrial(cfg,data);

%% prewhitening to remove the 1/f trend: on a trial by trial basis
% how: taking temporal derivative of signal  (autoregressive)
% The following should allow for single trial prewhitening.  
% but it doesnt work ;)
% cfg.keeptrials = 'yes'; 
% data = ft_mvaranalysis(cfg,data);

cfg = [];
cfg.output      = 'residual';  
cfg.order       = 1;   % order of autoreg model - ??
cfg.univariate  = 'yes';
datpw           = cell(size(data.trial));
for q = 1:numel(data.trial)
    cfgs        = [];
    cfgs.trials = q;
    tmpdata     = ft_selectdata(cfgs,data);
    datpw{q}    = ft_mvaranalysis(cfg,tmpdata);
end 
datpw = ft_appenddata([],datpw{:});
data  = datpw;
mous_db_putdata(subj,'meg_restingstate_data_prewhite_3s','data','/project/3011020.09/nielam/')
    

%% calculate power
%  trllen    min smoothing
%  1 / 4 s   = 0.25 Hz         
%  1 / 2 s   = 0.5 Hz   
% pad because ft_mvaranalysis removes one sample (800 -> 799)
% ft_freqanalysis doesnt allow padding of 1 sample
% padding must > max(trllength) which is 799 samples i.e. 4 s for 800
% samples

mous_db_getdata(subj, 'meg_restingstate_dss', '/project/3011020.09/nielam/');    % cardiac components

% reject cardiac components    
v = var(avgcomp,[],2); % each row of v = variance on each column in avgcomp 
v = v./v(1);

cfg           = [];
cfg.component = find(v>0.1);
data          = ft_rejectcomponent(cfg, comp, data);

% calculate FR
cfg = [];
cfg.method    = 'mtmfft';
cfg.output    = 'pow';
cfg.foilim    = [1 12]; % 2s data, goes in 0.5 Hz increm, 4s data 0.25 increm.
cfg.taper     = 'dpss';
cfg.tapsmofrq = 1;  % +/- 1 Hz smoothing
cfg.pad       = 3;  % total number of seconds once padding as been applied
freq = ft_freqanalysis(cfg,data);

mous_db_putdata(subj,['meg_restingstate_pow_',num2str(len),'s'],'freq','/project/3011020.09/nielam/');






