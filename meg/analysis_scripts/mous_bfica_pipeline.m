% execute script that sets some variables if they have not been specified
mous_bfica_pipelineoptions;
if doecg,
  [polarity, threshold, p] = mous_bfica_ecg(subjectname);
  mous_db_putdata(subjectname, 'meg_bfica_ecg', 'polarity', 'threshold', 'p', rootdir);
end
if dodss,
  %try
    mous_db_getdata(subjectname, 'meg_bfica_ecg', rootdir);
    [comp, avgpre, avgcomp] = mous_bfica_dss(subjectname, p);
  %catch
  %  [comp, avgpre, avgcomp] = mous_bfica_dss(subjectname);
  %end
  mous_db_putdata(subjectname, 'meg_bfica_comp', 'comp', 'avgcomp', 'avgpre', rootdir);
end
if dofreq,
    if strcmp(suff,'_low')
        
        options = [];
        options.taper      = 'hanning';
        options.resamplefs = 300;
        options.t_ftimwin  = ones(1,numel(frequency))*0.4;
        freqlowtest = mous_bfica_freq(subjectname, frequency, rootdir, options);
        mous_db_putdata(subjectname, ['meg_bfica_freq' suff], 'freq', rootdir);

    elseif strcmp(suff,'_medium')

        options            = [];
        options.t_ftimwin  = ones(1,numel(frequency))*0.25; 
        options.taper      = 'hanning';
        options.resamplefs = 300;
        freq = mous_bfica_freq(subjectname, frequency, rootdir, options);
        mous_db_putdata(subjectname, ['meg_bfica_freq',suff], 'freq', rootdir);
        
    elseif strcmp(suff,'_high')
        % *** gamma with DFT FILTER ***
        options = [];
        options.tapsmofrq   = 8;
        options.taper       = 'dpss';
        options.t_ftimwin   = ones(1,numel(frequency))*0.25; % 1/0.25 = 4Hz steps
        options.resamplefs  = 300;
        options.dftfilter   = 'yes';
        options.padding     = 4;
        % settings below are needed for bfica-visualsubj because inarg are in JMs dir
        % options.savedir     = '/project/3011020.09/nielam/';
        % rootdir = '/project/3011020.09/jansch';
        % freq = mous_bfica_freq(subjectname,frequency,options.savedir,options);
        freq = mous_bfica_freq(subjectname,frequency,rootdir,options);

        mous_db_putdata(subjectname, ['meg_bfica_freq',suff], 'freq', rootdir);
        % use manual save if calculating bfica for all words 
        % savename = [options.savedir,subjectname,filesep,'bfica',filesep,subjectname,'_bfica_freq_dft_high'];
        % save(savename,'freq','-v7.3');

%         % broadband gamma frequency
%         options = [];
%         options.tapsmofrq = 30;
%         options.taper = 'dpss';
%         options.t_ftimwin = 0.1;
%         options.resamplefs = 300;
%         freq = mous_bfica_freq(subjectname, 70, rootdir, options);
%         mous_db_putdata(subjectname, 'meg_bfica_freq70', 'freq', rootdir);
    end
end

if dofreqmtmfft
  options = [];
  options.taper = 'hanning';
  options.resamplefs = 300;
  options.tapsmofrq  = 2.5;
  options.toilim     = [0.2 0.6];
  freq = mous_bfica_freq_mtmfft(subjectname, [0 40], rootdir, options);
  mous_db_putdata(subjectname, 'meg_bfica_freq_mtmfft', 'freq', rootdir);
end
if dofreqmtmfft_preword
  options = [];
  options.taper = 'hanning';
  options.resamplefs = 300;
  options.tapsmofrq  = 2.5;
  options.toilim     = [-0.4 0];
  freq = mous_bfica_freq_mtmfft(subjectname, [0 40], rootdir, options);
  mous_db_putdata(subjectname, 'meg_bfica_freq_mtmfft_preword', 'freq', rootdir);
end
if dofreqmtmfft_contrast
  mous_db_getdata(subjectname, 'meg_bfica_freq_mtmfft_preword', rootdir);
  freq1 = ft_struct2double(freq);
  mous_db_getdata(subjectname, 'meg_bfica_freq_mtmfft', rootdir);
  freq2 = ft_struct2double(freq);
  [sent, seq] = mous_bfica_freq_contrast(freq1, freq2);
  mous_db_putdata(subjectname, 'meg_bfica_freq_mtmfft_sentseq', 'sent', 'seq', rootdir);
end
if dofreqmtmfft_contrast_nobaseline
%   mous_db_getdata(subjectname, 'meg_bfica_freq_mtmfft_preword', rootdir);
%   freq1 = ft_struct2double(freq);
  mous_db_getdata(subjectname, 'meg_bfica_freq_mtmfft', rootdir);
  freq2 = ft_struct2double(freq);
  [sent, seq] = mous_bfica_freq_contrast([], freq2);
  mous_db_putdata(subjectname, 'meg_bfica_freq_mtmfft_sentseqnobaseline', 'sent', 'seq', rootdir);
end
if dofreqbaseline,
  options.taper = 'dpss';
  options.tapsmofrq = 4;
  freq = mous_bfica_freqbaseline(subjectname, rootdir, options);
  mous_db_putdata(subjectname, 'meg_bfica_freqbaseline', 'freq', rootdir);
end
if dosource,
  mous_db_getdata(subjectname, ['meg_bfica_freq',suff], rootdir);
  [source, trialinfo] = mous_bfica_source(subjectname, freq);
  mous_db_putdata(subjectname, ['meg_bfica_source',suff], 'source', 'trialinfo', rootdir);
end
if doleadfield8mm,
  mous_db_getdata(subjectname, ['meg_bfica_freq',suff], rootdir);
  [sourcemodel, newinside, oldinside] = mous_bfica_leadfield(subjectname, ft_struct2double(freq), toi, 8);
  mous_db_putdata(subjectname, 'meg_bfica_leadfield8mm', 'sourcemodel', 'newinside', 'oldinside', rootdir, 0);
end
if dosource8mmparcellate,
  mous_db_getdata(subjectname, 'meg_anatomy_sourcemodel3D_nonlin8mm');
  sourcemodel = mous_anatomy_sourcemodelparcellate(subjectname, sourcemodel);
  mous_db_putdata(subjectname, 'meg_bfica_sourcemodel3Dparcellated_nonlin8mm', 'sourcemodel', rootdir, 0);
end
if dosource8mm,
  mous_db_getdata(subjectname, ['meg_bfica_freq',suff], rootdir);
  [source, trialinfo] = mous_bfica_source(subjectname, ft_struct2double(freq), toi, 8, rootdir);
  mous_db_putdata(subjectname, ['meg_bfica_source8mm',suff,'_',num2str(round(1000*toi),'%03d')], 'source', 'trialinfo', rootdir, 0);
end
if dovox,   
  mous_db_getdata(subjectname, ['meg_bfica_freq',suff], rootdir);
  mous_db_getdata(subjectname, ['meg_bfica_source8mm',suff,'_',num2str(round(1000*toi),'%03d')], rootdir);
  sourcedata = mous_bfica_sourcedata(source, freq, toi);
  mous_db_putdata(subjectname, ['meg_bfica_sourcedata',suff,'_',num2str(round(1000*toi),'%03d')], 'sourcedata', rootdir);
end
if dosentvsseq,
  tois = -0.2:0.05:0.8;
  mous_db_getdata(subjectname, ['meg_bfica_sourcedata',suff,'_',num2str(round(1000*toi),'%03d')], rootdir);
  mous_db_getdata(subjectname, ['meg_bfica_source8mm',suff,'_',num2str(round(1000*toi),'%03d')], rootdir);
  
  sourcedata.trialinfo(:,end+1:7) = 1; % add dummy columns, they don't mean anything
  [trial,time,trialinfonew] = trial2words(sourcedata.trial{1},sourcedata.trialinfo(:,[1 5 7 2:4 6]),tois);
  
  % match the trials with the trialinfo from the sourcedata file
  [c, ia, ib] = intersect(trialinfonew(:,1:2), trialinfo(:,[1 5]),'rows');
  % chop until word offset minus half a time window for the spectral analysis
  % FIXME
  
  sourcedata.trialinfo = trialinfonew(ia,:);
  sourcedata.trial = trial(ia);
  sourcedata.time = time(ia);
  [tlcksent, tlckseq,tstat] = mous_makecontrast(sourcedata, 'sent-seq');
  mous_db_putdata(subjectname, ['meg_bfica_sourcedatasentseq',suff,'_',num2str(round(1000*toi),'%03d')], 'tlcksent', 'tlckseq', 'tstat', rootdir, 0);
end
if dowordsentpar2,
  tois = -0.2:0.05:0.8;
  mous_db_getdata(subjectname, ['meg_bfica_sourcedata',suff,'_',num2str(round(1000*toi),'%03d')], rootdir);
  mous_db_getdata(subjectname, ['meg_bfica_source8mm',suff,'_',num2str(round(1000*toi),'%03d')], rootdir);
  
  %krn = compute_kernel(source);
  %[trial,time,trialinfonew] = trial2words(krn'*sourcedata.trial{1},sourcedata.trialinfo(:,[1 5 7 2:4 6]),toi);
  sourcedata.trialinfo(:,end+1:7) = 1; % add dummy columns, they don't mean anything
  [trial,time,trialinfonew] = trial2words(sourcedata.trial{1},sourcedata.trialinfo(:,[1 5 7 2:4 6]),tois);

  sourcedata.trialinfo = trialinfonew;
  sourcedata.trial = trial;
  sourcedata.time = time;
  sourcedata.fsample = 1;

  
  % match the trials with the trialinfo from the sourcedata file
  [c, ia, ib] = intersect(trialinfonew(:,1:2), trialinfo(:,[1 5]),'rows');
  % chop until word offset minus half a time window for the spectral analysis
  % FIXME
  
  sourcedata.trialinfo = trialinfonew(ia,:);
  sourcedata.trial = trial(ia);
  sourcedata.time = time(ia);
  
  for k = 1:numel(sourcedata.trial)
    ix = nearest(sourcedata.time{k}, toi-0.001);
    iy = nearest(sourcedata.time{k}, toi+0.001);
    sourcedata.trial{k} = nanmean(sourcedata.trial{k}(:,ix:iy),2);
    sourcedata.time{k} = nanmean(sourcedata.time{k}(ix:iy),2);
  end
  
  
  [tlck,stat,stat2] = mous_makecontrast(sourcedata, 'wordsent_parametric');
  mous_db_putdata(subjectname, ['meg_bfica_sourcedatasentpar',suff,'_',num2str(round(1000*toi),'%03d')], 'tlck', 'stat2', 'stat', rootdir, 0);
end
if dowordseqpar2,
  tois = -0.2:0.05:0.8;
  mous_db_getdata(subjectname, ['meg_bfica_sourcedata',suff,'_',num2str(round(1000*toi),'%03d')], rootdir);
  mous_db_getdata(subjectname, ['meg_bfica_source8mm',suff,'_',num2str(round(1000*toi),'%03d')], rootdir);
  
  %krn = compute_kernel(source);
  %[trial,time,trialinfonew] = trial2words(krn'*sourcedata.trial{1},sourcedata.trialinfo(:,[1 5 7 2:4 6]),toi);
  sourcedata.trialinfo(:,end+1:7) = 1; % add dummy columns, they don't mean anything
  [trial,time,trialinfonew] = trial2words(sourcedata.trial{1},sourcedata.trialinfo(:,[1 5 7 2:4 6]),tois);

  sourcedata.trialinfo = trialinfonew;
  sourcedata.trial = trial;
  sourcedata.time = time;
  sourcedata.fsample = 1;

  
  % match the trials with the trialinfo from the sourcedata file
  [c, ia, ib] = intersect(trialinfonew(:,1:2), trialinfo(:,[1 5]),'rows');
  % chop until word offset minus half a time window for the spectral analysis
  % FIXME
  
  sourcedata.trialinfo = trialinfonew(ia,:);
  sourcedata.trial = trial(ia);
  sourcedata.time = time(ia);
  
  for k = 1:numel(sourcedata.trial)
    ix = nearest(sourcedata.time{k}, toi-0.001);
    iy = nearest(sourcedata.time{k}, toi+0.001);
    sourcedata.trial{k} = nanmean(sourcedata.trial{k}(:,ix:iy),2);
    sourcedata.time{k} = nanmean(sourcedata.time{k}(ix:iy),2);
  end
  
  
  [tlck,stat,stat2] = mous_makecontrast(sourcedata, 'wordseq_parametric');
  mous_db_putdata(subjectname, ['meg_bfica_sourcedataseqpar',suff,'_',num2str(round(1000*toi),'%03d')], 'tlck', 'stat2', 'stat', rootdir, 0);
end

if dosource_contrasts,
  % this is chuncking the individual subsegments above, without saving the intermediate results + looping over toi:
  % dosource8mm
  % dovox
  % dosentvsseq
  % dowordsentpar2
  % dowordseqpar2
  
  mous_db_getdata(subjectname, ['meg_bfica_freq',suff], rootdir);
  freq = ft_struct2double(freq);
  % ntap = 1; % assume hanning taper, change it if you have multi tapers;
  % implement ntap when calling mous_bfica_pipeline in batch processing
  
  freq.cumtapcnt = ones(size(freq.fourierspctrm,1)./ntap,1)*ntap;  
  for toilop = 1:numel(toi)
    %tois = -0.2:0.05:0.8;

    tmpfreq = ft_selectdata(freq, 'foilim', frequency*[1 1]+[-0.1 0.1]);
    [source, trialinfo] = mous_bfica_source(subjectname, tmpfreq, toi(toilop), 8,rootdir);  % default directory is jansch in order to get leadfield
    sourcedataorig      = mous_bfica_sourcedata(source, tmpfreq, toi(toilop));
    
    sourcedataorig.trialinfo(:,end+1:7) = 1; % add dummy columns, they don't mean anything
    [trial,time,trialinfonew]       = trial2words(sourcedataorig.trial{1},sourcedataorig.trialinfo(:,[1 5 7 2:4 6]),toi(toilop));
  
    % match the trials with the trialinfo from the sourcedata file
    [c, ia, ib] = intersect(trialinfonew(:,1:2), trialinfo(:,[1 5]),'rows');
    % chop until word offset minus half a time window for the spectral analysis
    % FIXME
  
    sourcedataorig.trialinfo = trialinfonew(ia,:);
    sourcedataorig.trial = trial(ia);
    sourcedataorig.time = time(ia);
    sourcedataorig.fsample = 1;
    
    %% dosentvsseq
    sourcedata = sourcedataorig;
    [tlcksent(toilop), tlckseq(toilop),tstat(:,toilop)] = mous_makecontrast(sourcedata, 'sent-seq');
  
    %% dowordsentpar2
    [tlcksentpar(toilop),statsentpar(toilop),stat2sentpar(toilop)] = mous_makecontrast(sourcedata, 'wordsent_parametric');
    
    %% dowordseqpar2
    [tlckseqpar(toilop),statseqpar(toilop),stat2seqpar(toilop)] = mous_makecontrast(sourcedata, 'wordseq_parametric');
  end
  
  % concatenate
  tlcksent(1).avg = cat(2,tlcksent(:).avg);
  tlcksent(1).var = cat(2,tlcksent(:).var);
  tlcksent(1).dof = cat(2,tlcksent(:).dof);
  tlcksent(1).time = cat(2,tlcksent(:).time);
  tlcksent         = tlcksent(1);
  
  tlckseq(1).avg = cat(2,tlckseq(:).avg);
  tlckseq(1).var = cat(2,tlckseq(:).var);
  tlckseq(1).dof = cat(2,tlckseq(:).dof);
  tlckseq(1).time = cat(2,tlckseq(:).time);
  tlckseq         = tlckseq(1);
  
  tlcksentpar(1).avg = cat(2,tlcksentpar(:).avg);
  tlcksentpar(1).var = cat(2,tlcksentpar(:).var);
  tlcksentpar(1).dof = cat(2,tlcksentpar(:).dof);
  tlcksentpar(1).time = cat(2,tlcksentpar(:).time);
  tlcksentpar(1).trial = cat(3,tlcksentpar(:).trial);
  tlcksentpar(1).trial2 = cat(3,tlcksentpar(:).trial2);
  tlcksentpar           = tlcksentpar(1);
  
  tlckseqpar(1).avg = cat(2,tlckseqpar(:).avg);
  tlckseqpar(1).var = cat(2,tlckseqpar(:).var);
  tlckseqpar(1).dof = cat(2,tlckseqpar(:).dof);
  tlckseqpar(1).time = cat(2,tlckseqpar(:).time);
  tlckseqpar(1).trial = cat(3,tlckseqpar(:).trial);
  tlckseqpar(1).trial2 = cat(3,tlckseqpar(:).trial2);
  tlckseqpar           = tlckseqpar(1);
  
  statsentpar(1).stat = cat(2,statsentpar(:).stat);
  statsentpar(1).prob = cat(2,statsentpar(:).prob);
  statsentpar(1).mask = cat(2,statsentpar(:).mask);
  statsentpar(1).time = cat(2,statsentpar(:).time);
  statsentpar(1).cirange = cat(2,statsentpar(:).cirange);
  statsentpar            = statsentpar(1);
  
  stat2sentpar(1).stat = cat(2,stat2sentpar(:).stat);
  stat2sentpar(1).prob = cat(2,stat2sentpar(:).prob);
  stat2sentpar(1).mask = cat(2,stat2sentpar(:).mask);
  stat2sentpar(1).time = cat(2,stat2sentpar(:).time);
  stat2sentpar(1).cirange = cat(2,stat2sentpar(:).cirange);
  stat2sentpar            = stat2sentpar(1);

  statseqpar(1).stat = cat(2,statseqpar(:).stat);
  statseqpar(1).prob = cat(2,statseqpar(:).prob);
  statseqpar(1).mask = cat(2,statseqpar(:).mask);
  statseqpar(1).time = cat(2,statseqpar(:).time);
  statseqpar(1).cirange = cat(2,statseqpar(:).cirange);
  statseqpar            = statseqpar(1);
  
  stat2seqpar(1).stat = cat(2,stat2seqpar(:).stat);
  stat2seqpar(1).prob = cat(2,stat2seqpar(:).prob);
  stat2seqpar(1).mask = cat(2,stat2seqpar(:).mask);
  stat2seqpar(1).time = cat(2,stat2seqpar(:).time);
  stat2seqpar(1).cirange = cat(2,stat2seqpar(:).cirange);
  stat2seqpar            = stat2seqpar(1);

  % save the results
  suff2 = num2str(round(frequency*10));
  mous_db_putdata(subjectname, ['meg_bfica_sourcedatasentseq',suff2], 'tlcksent',    'tlckseq',      'tstat', rootdir, 0);
  mous_db_putdata(subjectname, ['meg_bfica_sourcedatasentpar',suff2], 'tlcksentpar', 'stat2sentpar', 'statsentpar', rootdir, 0);
  mous_db_putdata(subjectname, ['meg_bfica_sourcedataseqpar', suff2], 'tlckseqpar',  'stat2seqpar',  'statseqpar', rootdir, 0);
end
  
  


if dovoxbaseline,
  mous_db_getdata(subjectname, 'meg_bfica_freqbaseline', rootdir);
  mous_db_getdata(subjectname, ['meg_bfica_source',suff], rootdir);
  sourcedata = mous_bfica_sourcedatabaseline(source, freq, frequency);
  mous_db_putdata(subjectname, ['meg_bfica_sourcedatabaseline',suff], 'sourcedata', rootdir);
end
if dosentvsseq_chan,
  mous_db_getdata(subjectname, 'meg_bfica_freq_mtmfft', rootdir);
  [fsent, fseq] = mous_makecontrast(ft_struct2double(freq), 'sent-seq', freq.trialinfo(:,2));
  mous_db_putdata(subjectname, 'meg_bfica_chandatasentseq', 'fsent', 'fseq', rootdir,0);
  %mous_db_getdata(subjectname, 'meg_bfica_freq_mtmfft_high', rootdir);
  %[fsent, fseq] = mous_makecontrast(ft_struct2double(freq), 'sent-seq', freq.trialinfo(:,2));
  %mous_db_putdata(subjectname, 'meg_bfica_chandatasentseq_high', 'fsent', 'fseq', rootdir,0);
end
if dosentvsseqTarget_chan,
  %mous_db_getdata(subjectname, 'meg_bfica_freq_mtmfft', rootdir);
  %[fsent, fseq] = mous_makecontrast(ft_struct2double(freq), 'sent-seqTarget', freq.trialinfo(:,2));
  %mous_db_putdata(subjectname, 'meg_bfica_chandatasentseqTarget', 'fsent', 'fseq', rootdir,0);
  mous_db_getdata(subjectname, 'meg_bfica_freq_mtmfft_high', rootdir);
  [fsent, fseq] = mous_makecontrast(ft_struct2double(freq), 'sent-seqTarget', freq.trialinfo(:,2));
  mous_db_putdata(subjectname, 'meg_bfica_chandatasentseqTarget_high', 'fsent', 'fseq', rootdir,0);
end
if dosent1vssent2_chan,
  mous_db_getdata(subjectname, 'meg_bfica_freq_mtmfft', rootdir);
  [fsent1, fsent2] = mous_makecontrast(ft_struct2double(freq), 'sent1-sent2', freq.trialinfo(:,2));
  mous_db_putdata(subjectname, 'meg_bfica_chandatasent1sent2', 'fsent1', 'fsent2', rootdir,0);
  %mous_db_getdata(subjectname, 'meg_bfica_freq_mtmfft_high', rootdir);
  %[fsent, fseq] = mous_makecontrast(ft_struct2double(freq), 'sent-seq', freq.trialinfo(:,2));
  %mous_db_putdata(subjectname, 'meg_bfica_chandatasentseq_high', 'fsent', 'fseq', rootdir,0);
end

if dosentvsseqTarget,
  toi = -0.2:0.05:0.8;
  mous_db_getdata(subjectname, ['meg_bfica_sourcedata',suff], rootdir);
  mous_db_getdata(subjectname, ['meg_bfica_source8mm',suff], rootdir);
  
  sourcedata.trialinfo(:,end+1:7) = 1; % add dummy columns, they don't mean anything
  [trial,time,trialinfonew] = trial2words(sourcedata.trial{1},sourcedata.trialinfo(:,[1 5 7 2:4 6]),toi);
  
  % match the trials with the trialinfo from the sourcedata file
  [c, ia, ib] = intersect(trialinfonew(:,1:2), trialinfo(:,[1 5]),'rows');
  % chop until word offset minus half a time window for the spectral analysis
  % FIXME
  
  sourcedata.trialinfo = trialinfonew(ia,:);
  sourcedata.trial = trial(ia);
  sourcedata.time = time(ia);
  [tlcksent, tlckseq,tstat] = mous_makecontrast(sourcedata, 'sent-seqTarget');
  mous_db_putdata(subjectname, ['meg_bfica_sourcedatasentseqTarget',suff], 'tlcksent', 'tlckseq', 'tstat', rootdir, 0);

end

% if dowordsentpar,
% toi = -0.2:0.05:0.8;
% sourcedata = mous_db_getdata(subjectname, ['meg_bfica_sourcedata',suff], rootdir);
% source = mous_db_getdata(subjectname, ['meg_bfica_source',suff], rootdir);
% krn = compute_kernel(source);
% [trial,time,trialinfo] = trial2words(krn'*sourcedata.trial{1},sourcedata.trialinfo(:,[1 5 7 2:4 6]),toi);
% sourcedata.trialinfo = trialinfo;
% sourcedata.trial = trial;
% sourcedata.time = time;
% [tlck,stat,stat2] = mous_makecontrast(sourcedata, 'wordsent_parametric');
% mous_db_putdata(subjectname, ['meg_bfica_sourcedatawordsentpar',suff], 'tlck', 'stat', 'stat2', rootdir);
% end
% if dowordseqpar,
% toi = -0.2:0.05:0.8;
% sourcedata = mous_db_getdata(subjectname, ['meg_bfica_sourcedata',suff], rootdir);
% source = mous_db_getdata(subjectname, ['meg_bfica_source',suff], rootdir);
% krn = compute_kernel(source);
% [trial,time,trialinfo] = trial2words(krn'*sourcedata.trial{1},sourcedata.trialinfo(:,[1 5 7 2:4 6]),toi);
% sourcedata.trialinfo = trialinfo;
% sourcedata.trial = trial;
% sourcedata.time = time;
% [tlck,stat,stat2] = mous_makecontrast(sourcedata, 'wordseq_parametric');
% mous_db_putdata(subjectname, ['meg_bfica_sourcedatawordseqpar',suff], 'tlck', 'stat', 'stat2', rootdir);
% end

if sourcedata2avgword
  toi = -0.2:0.05:0.8;
  mous_db_getdata(subjectname, ['meg_bfica_sourcedata',suff], rootdir);
  mous_db_getdata(subjectname, ['meg_bfica_source',suff], rootdir);
  krn = compute_kernel(source);
  [trial,time,trialinfo] = trial2words(krn'*sourcedata.trial{1},sourcedata.trialinfo(:,[1 5 7 2:4 6]),toi);
  for k = 1:numel(trial)
    sel = time{k}>=0;
    trial{k} = nanmean(trial{k}(:,sel),2);
    time{k} = nanmean(time{k}(sel),2);
  end
  sourcedata.trial = trial;
  sourcedata.time = time;
  sourcedata.trialinfo = trialinfo;
  mous_db_putdata(subjectname, ['meg_bfica_sourcedataavgword',suff], 'sourcedata', rootdir);
end
if doica,
  comp = mous_bfica_ica(subjectname, [], rootdir);
  mous_db_putdata(subjectname, 'meg_bfica_ica', 'comp', rootdir);
end
if dosourcedss,
  comp = mous_bfica_sourcedatadss(subjectname, rootdir);
  mous_db_putdata(subjectname, 'meg_bfica_sourcedatadss', 'comp', rootdir);
end
if doccc,
  mous_db_getdata(subjectname, ['meg_bfica_freq',suff], rootdir);
  mous_db_getdata(subjectname, 'meg_bfica_leadfield8mm', rootdir);
  
  freq              = ft_selectdata(freq, 'toilim', toi+[-0.01 0.01]);
  freq              = ft_selectdata(freq, 'foilim', frequency*[1 1]);
  [cohsent, cohseq] = mous_bfica_ccc(sourcemodel, freq, 'refindx', [], 'lambda', 0.05);
  mous_db_putdata(subjectname, ['meg_bfica_ccc_',num2str(round(frequency)),'Hz_',num2str(round(1000*toi)),'ms'], 'cohsent', 'cohseq', rootdir,0);
end
if docleanup
  % remove the source8mmF_T and sourcedataF_T
  delete(fullfile(rootdir,subjectname,'bfica',[subjectname,'_bfica_sourcedata',suff,'_',num2str(round(1000*toi)),'.mat']));
  delete(fullfile(rootdir,subjectname,'bfica',[subjectname,'_bfica_source8mm', suff,'_',num2str(round(1000*toi)),'.mat']));
end


%
% % do ica -> can this be done on single subject if sufficient data is
% % present?
% cfg = [];
% cfg.demean = 'no'; % do outside the function is possibly more memory efficient
% cfg.method = 'fastica';
% cfg.fastica.lastEig = 100;
% comp = ft_componentanalysis(cfg, sdata);


% group statistics channel level frequency data
if 0
  rootdir = '/home/language/jansch/public/mous';
  subj    = mous_db_getfilename('all', 'subjectname');
  [f,s]   = mous_db_getfilename(subj, 'meg_bfica_chandatasentseqTarget', 0, rootdir);
  subj    = subj(s);
  Nsubj   = numel(subj);
  Fsent   = cell(1,Nsubj);
  Fseq    = cell(1,Nsubj);
  for k = 1:Nsubj
    mous_db_getdata(subj{k}, 'meg_bfica_chandatasentseqTarget',rootdir);
    Fsent{1,k} = fsent;
    Fseq{1,k}  = fseq;
    %Fsent{1,k} = fsent1;
    %Fseq{1,k}  = fsent2;
  end
  cfg = [];
  cfg.method = 'montecarlo';
  cfg.statistic = 'depsamplesT';
  cfg.design = [ones(1,Nsubj) ones(1,Nsubj)*2;1:Nsubj 1:Nsubj];
  cfg.ivar = 1;
  cfg.uvar = 2;
  cfg.numrandomization = 1000;
  cfg.parameter = 'powspctrm';
  cfg.correctm = 'no';
  %cfg.clusterthreshold = 'nonparametric_common';
  %cfg.clusteralpha = 0.05;
  stat = ft_freqstatistics(cfg, Fsent{:}, Fseq{:});
end

% group statistics source level data
if 0
  rootdir = '/home/language/jansch/public/mous';
  subj = mous_db_getfilename('all', 'subjectname');
  [f,s] = mous_db_getfilename(subj, ['meg_bfica_sourcedatasentseq',suff], 0, rootdir);
  subj = subj(s);
  Nsubj = numel(subj);
  
  %load('/home/language/jansch/matlab/fieldtrip/template/sourcemodel/standard_grid3d10mm');
  load('/home/language/jansch/projects/mous/meg/templates/sourcemodel/standard_sourcemodel3d8mm');

   
  for k = 1:Nsubj
    %mous_db_getdata(subj{k}, ['meg_bfica_sourcedatabaseline',suff], rootdir);
    %sel = ismember(sourcedata.trialinfo(:,2), [2 6]); % 1 is sent, 0 is seq
    %Bsent = (mean(sourcedata.trial{1}(:,sel),2));
    %Bseq = (mean(sourcedata.trial{1}(:,~sel),2));
    
    clear tlcksent tlckseq
    mous_db_getdata(subj{k}, ['meg_bfica_sourcedatasentseq',suff], rootdir);
    %mous_db_getdata(subj{k}, ['meg_bfica_source',suff], rootdir);
    mous_db_getdata(subj{k}, ['meg_bfica_source8mm',suff], rootdir);
    
    source.time = tlckseq.time;
    source = rmfield(source, 'freq');
    
    %source.avg.pow = tlckseq.avg;
    source.avg.pow = log10(tlckseq.avg);% ./ repmat(Bseq, [1 numel(tlckseq.time)]);
    seq{k} = source;
    seq{k}.pos = sourcemodel.pos;
    
    %source.avg.pow = tlcksent.avg;
    source.avg.pow = log10(tlcksent.avg);% ./ repmat(Bsent, [1 numel(tlcksent.time)]);
    source.tstat = tstat;
    sent{k} = source;
    sent{k}.pos = sourcemodel.pos;
  
  end
  
  % the pow is only defined on the insides, ft_sourcestatistics expects all
  % voxels
  for k = 1:Nsubj
    tmp1 = zeros(prod(seq{k}.dim),numel(seq{k}.time));
    tmp1(seq{k}.inside,:) = seq{k}.avg.pow;
    tmp2 = zeros(prod(sent{k}.dim),numel(sent{k}.time));
    tmp2(sent{k}.inside,:) = sent{k}.avg.pow;
    tmp3 = zeros(prod(seq{k}.dim),numel(seq{k}.time));
    tmp3(seq{k}.inside,:) = sent{k}.tstat;
    
    
    seq{k}.avg.pow = (tmp1);% - repmat(mean((tmp1),1), [size(tmp1,1) 1]);
    sent{k}.avg.pow = (tmp2);% - repmat(mean((tmp2),1), [size(tmp1,1) 1]);
    sent{k}.tstat = tmp3;
  end
  
% cfg = [];
% cfg.method = 'montecarlo';
% cfg.statistic = 'depsamplesT';
% cfg.design = [ones(1,Nsubj) ones(1,Nsubj)*2;1:Nsubj 1:Nsubj];
% cfg.ivar = 1;
% cfg.uvar = 2;
% cfg.numrandomization = 0;
% cfg.parameter = 'avg.pow';
% senttime = sent;
% seqtime = seq;
% % for k = 1:Nsubj
% % senttime{k}.avg.pow = senttime{k}.avg.pow - repmat(mean(senttime{k}.avg.pow(:,4:11),2),[1 20]);
% % seqtime{k}.avg.pow = seqtime{k}.avg.pow - repmat(mean(seqtime{k}.avg.pow(:,4:11),2),[1 20]);
% % end
% stattime = ft_sourcestatistics(cfg, senttime{:}, seqtime{:});
%
  
  ix = nearest(sent{1}.time, 0.3);
  iy = nearest(sent{1}.time, 0.6);
  for k = 1:numel(sent)
    sent{k}.avg.pow = nanmean(sent{k}.avg.pow(:,ix:iy),2);
    seq{k}.avg.pow = nanmean(seq{k}.avg.pow(:,ix:iy),2);
    sent{k}.time = nanmean(sent{k}.time(ix:iy));
    seq{k}.time = nanmean(seq{k}.time(ix:iy));
    
    %globalpow = nanmean(sent{k}.avg.pow(sent{k}.inside)+seq{k}.avg.pow(seq{k}.inside))./2;
    %sent{k}.avg.pow = sent{k}.avg.pow - globalpow;
    %seq{k}.avg.pow = seq{k}.avg.pow - globalpow;
    %sent{k}.avg.pow = sent{k}.avg.pow - nanmean(sent{k}.avg.pow(sent{k}.inside));
    %seq{k}.avg.pow = seq{k}.avg.pow - nanmean(seq{k}.avg.pow(seq{k}.inside));
  end
  
  cfg = [];
  cfg.method = 'montecarlo';
  cfg.statistic = 'depsamplesT';
  cfg.design = [ones(1,Nsubj) ones(1,Nsubj)*2;1:Nsubj 1:Nsubj];
  cfg.ivar = 1;
  cfg.uvar = 2;
  cfg.numrandomization = 1000;
  cfg.parameter = 'avg.pow';
  cfg.correctm = 'cluster';
  cfg.clusterthreshold = 'nonparametric_common';
  cfg.clusteralpha = 0.05;
  stat = ft_sourcestatistics(cfg, sent{:}, seq{:});
  if ndims(stat.stat)>2 %i.e. being a 3d matrix, rather than space x something else
    stat.stat=stat.stat(:);
    stat.prob=stat.prob(:);
    stat.mask=stat.mask(:);
  end
  i1 = mous_bfica_sourceinterpolate(stat, 'stat', stat.inside);
  iprob = mous_bfica_sourceinterpolate(stat, 'prob', stat.inside);
  imask = mous_bfica_sourceinterpolate(stat, 'mask', stat.inside);
  i1.coordsys = 'spm';
  i1.mask = imask.avg.pow;
  i1.prob = iprob.avg.pow;
end

% group statistics
if 0
  rootdir = '/home/language/jansch/public/mous';
  subj = mous_db_getfilename('all', 'subjectname');
  [f,s] = mous_db_getfilename(subj, ['meg_bfica_sourcedatawordsentpar',suff], 0, rootdir);
  subj = subj(s);
  Nsubj = numel(subj);
  
  for k = 1:numel(subj)
    mous_db_getdata(subj{k}, ['meg_bfica_sourcedatawordsentpar',suff], rootdir);
    mous_db_getdata(subj{k}, ['meg_bfica_source',suff], rootdir);
    
    source.time = stat.time;
    source = rmfield(source, 'freq');
    source.avg.pow(1, numel(stat.time)) = nan;
    source.avg.pow(source.inside,:) = stat.stat;
    data{k} = source;
    data{k}.pos = data{1}.pos;
    
    wordavg(1:size(tlck.trial,1),:,:,k) = tlck.trial;
    
  end
  data2 = data;
  for k = 1:numel(data)
    %data2{k}.avg.pow(data2{k}.inside,:) = ones(numel(data2{k}.inside),1)*nanmean(data2{k}.avg.pow);
    data2{k}.avg.pow(data2{k}.inside,:) = 0;
  end
  
  cfg = [];
  cfg.method = 'montecarlo';
  cfg.statistic = 'depsamplesT';
  cfg.design = [ones(1,Nsubj) ones(1,Nsubj)*2;1:Nsubj 1:Nsubj];
  cfg.ivar = 1;
  cfg.uvar = 2;
  cfg.numrandomization = 0;
  cfg.parameter = 'avg.pow';
  cfg.correctm = 'no';%'cluster';
  cfg.clusterthreshold = 'nonparametric_common';
  stat = ft_sourcestatistics(cfg, data{:}, data2{:});
  i1 = mous_bfica_sourceinterpolate(stat, 'stat');
  
end

% group statistics
if 0
  rootdir = '/home/language/jansch/public/mous';
  subj = mous_db_getfilename('all', 'subjectname');
  [f,s] = mous_db_getfilename(subj, ['meg_bfica_sourcedatawordseqpar',suff], 0, rootdir);
  subj = subj(s);
  Nsubj = numel(subj);
  
  for k = 1:numel(subj)
    mous_db_getdata(subj{k}, ['meg_bfica_sourcedatawordseqpar',suff], rootdir);
    mous_db_getdata(subj{k}, ['meg_bfica_source',suff], rootdir);
    
    source.time = stat.time;
    source = rmfield(source, 'freq');
    source.avg.pow(1, numel(stat.time)) = nan;
    source.avg.pow(source.inside,:) = stat.stat;
    data{k} = source;
    data{k}.pos = data{1}.pos;
  end
  data2 = data;
  for k = 1:numel(data)
    %data2{k}.avg.pow(data2{k}.inside,:) = ones(numel(data2{k}.inside),1)*nanmean(data2{k}.avg.pow);
    data2{k}.avg.pow(data2{k}.inside,:) = 0;
  end
  
  cfg = [];
  cfg.method = 'montecarlo';
  cfg.statistic = 'depsamplesT';
  cfg.design = [ones(1,Nsubj) ones(1,Nsubj)*2;1:Nsubj 1:Nsubj];
  cfg.ivar = 1;
  cfg.uvar = 2;
  cfg.numrandomization = 0;
  cfg.parameter = 'avg.pow';
  cfg.correctm = 'no';%'cluster';
  cfg.clusterthreshold = 'nonparametric_common';
  stat = ft_sourcestatistics(cfg, data{:}, data2{:});
  i1 = mous_bfica_sourceinterpolate(stat, 'stat');
  
end

% group statistics
if 0
  rootdir = '/home/language/jansch/public/mous';
  subj = mous_db_getfilename('all', 'subjectname');
  [f,s] = mous_db_getfilename(subj, ['meg_bfica_sourcedatawordseqpar',suff], 0, rootdir);
  subj = subj(s);
  Nsubj = numel(subj);
  
  for k = 1:numel(subj)
    mous_db_getdata(subj{k}, ['meg_bfica_sourcedatawordseqpar',suff], rootdir);
    mous_db_getdata(subj{k}, ['meg_bfica_source',suff], rootdir);
    
    source.time = stat.time;
    source = rmfield(source, 'freq');
    source.avg.pow(1, numel(stat.time)) = nan;
    source.avg.pow(source.inside,:) = stat.stat;
    data{k} = source;
    data{k}.pos = data{1}.pos;
  
    %wordavg(1:size(tlck.trial,1),:,:,k) = tlck.trial;
  end
  data2 = data;
  %wordavgseq = wordavg;
  
  for k = 1:numel(subj)
    mous_db_getdata(subj{k}, ['meg_bfica_sourcedatawordsentpar',suff], rootdir);
    mous_db_getdata(subj{k}, ['meg_bfica_source',suff], rootdir);
    
    source.time = stat.time;
    source = rmfield(source, 'freq');
    source.avg.pow(1, numel(stat.time)) = nan;
    source.avg.pow(source.inside,:) = stat.stat;
    data{k} = source;
    data{k}.pos = data{1}.pos;
  
    %wordavg(1:size(tlck.trial,1),:,:,k) = tlck.trial;
  end
  %wordavgsent = wordavg;
  clear wordavg;
  
  for k = 1:Nsubj
    data{k}.avg.pow = mean(data{k}.avg.pow(:,10:16),2); %300 to 600
    data2{k}.avg.pow = mean(data2{k}.avg.pow(:,10:16),2);
    data{k}.time = 0.45;
    data2{k}.time = 0.45;
  end
  
  cfg = [];
  cfg.method = 'montecarlo';
  cfg.statistic = 'depsamplesT';
  cfg.design = [ones(1,Nsubj) ones(1,Nsubj)*2;1:Nsubj 1:Nsubj];
  cfg.ivar = 1;
  cfg.uvar = 2;
  cfg.numrandomization = 2000;
  cfg.parameter = 'avg.pow';
  cfg.correctm = 'cluster';
  cfg.clusterthreshold = 'nonparametric_common';
  cfg.clusteralpha = 0.01;
  stat = ft_sourcestatistics(cfg, data{:}, data2{:});
  if ndims(stat.stat)>2
    stat.stat=stat.stat(:);
    stat.prob=stat.prob(:);
    stat.mask=stat.mask(:);
  end
  i1 = mous_bfica_sourceinterpolate(stat, 'stat', stat.inside);
  iprob = mous_bfica_sourceinterpolate(stat, 'prob', stat.inside);
  imask = mous_bfica_sourceinterpolate(stat, 'mask', stat.inside);
  i1.coordsys = 'spm';
  i1.mask = imask.avg.pow;
  i1.prob = iprob.avg.pow;
end

