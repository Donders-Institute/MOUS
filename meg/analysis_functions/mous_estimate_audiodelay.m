function [delay, stimid, phi, trial, time] = mous_estimate_audiodelay(subjectname)

stimid = zeros(0,1);
delay  = zeros(0,1);
allphi = zeros(0, 1201);

filename = mous_db_getfilename(subjectname, 'meg_ds_task');
cnt = 0;
for k = 1:numel(filename)
  
  % get the trl-matrix
  cfg.dataset = filename{k};
  cfg.trialdef.prestim = 'audioonset';
  cfg.trialdef.poststim = 0;
  trl = trialfun_auditory_sentence(cfg);
  
  % loop over trials
  phi = zeros(size(trl,1), 1201);
  for m = 1:size(trl,1)
    cnt = cnt+1;
    
    % get the audio data for the specified trial
    cfg.trl        = trl(m,:);
    cfg.channel    = {'UADC003';'UADC004'};
    cfg.continuous = 'yes';
    cfg.demean     = 'yes';
    cfg.padding    = 10;
    cfg.dftfilter  = 'yes';
    cfg.dftfreq    = [49.7:0.1:50.3 99.7:0.1:100.3 149.7:0.1:150.3 199.7:0.1:200.3 249.7:0.1:250.3 299.7:0.1:300.3];
    %cfg.dftfreq    = (99.7:0.1:100.3);
    cfg.hpfilter   = 'yes';
    cfg.hpfreq     = 60;
    megaudio       = ft_preprocessing(cfg);
    
    % get the downsampled audio data
    audiodir  = '/home/language/jansch/projects/mous/meg/stimuli/AudioStimuli20120905';
    audiofile = fullfile(audiodir, ['audiodata',num2str(trl(m,end),'%03d')]);
    load(audiofile);
    
    % concatenate in one data structure
    nsmp1 = numel(megaudio.time{1});
    nsmp2 = numel(data.time{1});
    nsmp  = min(nsmp1,nsmp2);
    
    megaudio.trial{1} = [megaudio.trial{1}(:,1:nsmp);data.trial{1}(:,1:nsmp)];
    megaudio.time{1}  = megaudio.time{1}(1:nsmp);
    megaudio.label    = [megaudio.label;data.label];
    
    trial{cnt} = megaudio.trial{1};
    time{cnt}  = megaudio.time{1};
    
    % cut into 0.5 s epochs
    cfgr         = [];
    cfgr.length  = 2;
    cfgr.overlap = 0.5;
    megaudio     = ft_redefinetrial(cfgr, megaudio);
    
    % spectral analysis
    cfgf        = [];
    cfgf.method = 'mtmfft';
    cfgf.output = 'fourier';
    cfgf.taper  = 'hanning';
    freq        = ft_freqanalysis(cfgf, megaudio);
    
    % phase difference spectrum 
    cfgc         = [];
    cfgc.method  = 'coh';
    cfgc.complex = 'complex';
    coh          = ft_connectivityanalysis(cfgc, freq);
    
    % phase difference estimate
    phi(m,:) = mean(unwrap(reshape(angle(coh.cohspctrm(3:4,1:2,:)),4,[]),[],2));
  end
  
  % regression to get the slope
  %N      = 301;
  N      = 691;
  X      = [ones(1,1201+1-N-200);freq.freq(N:end-200)];
  X(2,:) = X(2,:)-mean(X(2,:));
  beta   = phi(:,N:end-200)/X;
  
  tmpdelay  = beta(:,2)*1000./(2*pi);
  tmpid     = trl(:,end);
  
  delay  = cat(1,delay,tmpdelay);
  stimid = cat(1,stimid,tmpid);
  allphi = cat(1,allphi,phi);
end
phi = allphi;

%if nargout==0
  mous_db_putdata(subjectname,'meg_qualitycheck_audiodelay', 'delay', 'stimid', 'phi', 0);
%end
