
% extract the trial definition for the sentences
filename = mous_db_getfilename(subjectname, 'meg_ds_task');
filename = filename{1};

if 0,
  cfg          = [];
  cfg.dataset  = filename;
  cfg.trialfun = 'visual_word';
  cfg.trialdef.prestim  = -0.3;
  cfg.trialdef.poststim =  0.8-1./1200; %FIXME assumes 1200 Hz sampling rate
  cfg = ft_definetrial(cfg);
  trl = cfg.trl;
  
  % get the description of the artifacts
  tmp = mous_db_getdata(subjectname, 'meg_artifactcfg');
  
  % remove the data containing artifacts from the epoch definition
  cfg         = [];
  cfg.trl     = trl;
  cfg.dataset = filename;
  cfg.artfctdef.zvalue1.artifact = tmp.cfgeog1.artfctdef.zvalue.artifact;
  cfg.artfctdef.zvalue2.artifact = tmp.cfgeog2.artfctdef.zvalue.artifact;
  cfg.artfctdef.zvalue3.artifact = tmp.cfgjump.artfctdef.zvalue.artifact;
  cfg.artfctdef.zvalue4.artifact = tmp.cfgmuscle.artfctdef.zvalue.artifact;
  cfg.artfctdef.reject = 'complete';
  cfg         = ft_rejectartifact(cfg);
  trl         = cfg.trl;
  
  % compute frequency representation of data
  freq = mous_beamformer_freq(filename, trl);
  mous_db_putdata(subjectname, 'meg_processed_{freq03-08}', 'freq');
end

if 0,
  cfg          = [];
  cfg.dataset  = filename;
  cfg.trialfun = 'visual_word';
  cfg.trialdef.prestim  =  0.5;
  cfg.trialdef.poststim =  0-1./1200; %FIXME assumes 1200 Hz sampling rate
  cfg = ft_definetrial(cfg);
  trl = cfg.trl;
  
  % get the description of the artifacts
  tmp = mous_db_getdata(subjectname, 'meg_artifactcfg');
  
  % remove the data containing artifacts from the epoch definition
  cfg         = [];
  cfg.trl     = trl;
  cfg.dataset = filename;
  cfg.artfctdef.zvalue1.artifact = tmp.cfgeog1.artfctdef.zvalue.artifact;
  cfg.artfctdef.zvalue2.artifact = tmp.cfgeog2.artfctdef.zvalue.artifact;
  cfg.artfctdef.zvalue3.artifact = tmp.cfgjump.artfctdef.zvalue.artifact;
  cfg.artfctdef.zvalue4.artifact = tmp.cfgmuscle.artfctdef.zvalue.artifact;
  cfg.artfctdef.reject = 'complete';
  cfg         = ft_rejectartifact(cfg);
  trl         = cfg.trl;
  
  % compute frequency representation of data
  freq = mous_beamformer_freq(filename, trl);
  mous_db_putdata(subjectname, 'meg_processed_{freq05-00}', 'freq');
end

if 1,
  cfg          = [];
  cfg.dataset  = filename;
  cfg.trialfun = 'visual_word';
  cfg.trialdef.prestim  =  0.5;
  cfg.trialdef.poststim =  0-1./1200; %FIXME assumes 1200 Hz sampling rate
  cfg = ft_definetrial(cfg);
  trl = cfg.trl;
  trl = trl(trl(:,end)==1,:);
  
  % get the description of the artifacts
  tmp = mous_db_getdata(subjectname, 'meg_artifactcfg');
  
  % remove the data containing artifacts from the epoch definition
  cfg         = [];
  cfg.trl     = trl;
  cfg.dataset = filename;
  cfg.artfctdef.zvalue1.artifact = tmp.cfgeog1.artfctdef.zvalue.artifact;
  cfg.artfctdef.zvalue2.artifact = tmp.cfgeog2.artfctdef.zvalue.artifact;
  cfg.artfctdef.zvalue3.artifact = tmp.cfgjump.artfctdef.zvalue.artifact;
  cfg.artfctdef.zvalue4.artifact = tmp.cfgmuscle.artfctdef.zvalue.artifact;
  cfg.artfctdef.reject = 'complete';
  cfg         = ft_rejectartifact(cfg);
  trl         = cfg.trl;
  
  % compute frequency representation of data
  freq = mous_beamformer_freqbaseline(filename, trl);
  mous_db_putdata(subjectname, 'meg_processed_{freqbaseline05-00}', 'freq');
end

if 0,
  headmodel   = mous_db_getdata(subjectname, 'meg_anatomy_headmodel');
  sourcemodel = mous_db_getdata(subjectname, 'meg_anatomy_sourcemodel3D_nonlin8mm');
  freq1       = mous_db_getdata(subjectname, 'meg_processed_{freq03-08}');
  freq2       = mous_db_getdata(subjectname, 'meg_processed_{freq05-00}');   
  
  % post word onset versus pre word onset sentences
  sel1   = ismember(freq1.trialinfo(:,2), [1 2 5 6]);
  sel2   = ismember(freq2.trialinfo(:,2), [1 2 5 6]);
  tmp    = cell(2,1);  
  tmp{1} = ft_selectdata(freq1, 'rpt', find(sel1));
  tmp{2} = ft_selectdata(freq2, 'rpt', find(sel2));
  freq   = ft_selectdata(tmp{:}, 'param', 'fourierspctrm');
  freq.grad = tmp{1}.grad;
  design = [ones(1,sum(sel1)) ones(1,sum(sel2))*2];

  source = mous_beamformer_dics(freq, sourcemodel, headmodel, design);
  source(1).stat = cat(4,source(:).stat);
  source(1).freq = cat(2,source(:).freq);
  source = source(1);
  source = rmfield(source, 'prob');
  source = rmfield(source, 'mask');
  source.stat = reshape(source.stat, size(source.pos,1), numel(source.freq));
  
  mous_db_putdata(subjectname, 'meg_processed_{sourceDICSsent}', 'source');
end

if 0,
  freq        = mous_db_getdata(subjectname, 'meg_processed_{freq03-08}');
  headmodel   = mous_db_getdata(subjectname, 'meg_anatomy_headmodel');
  sourcemodel = mous_db_getdata(subjectname, 'meg_anatomy_sourcemodel3D_nonlin8mm');
  source      = mous_beamformer_dics(freq, sourcemodel, headmodel);
  
  source(1).stat = cat(4,source(:).stat);
  source(1).freq = cat(2,source(:).freq);
  source = source(1);
  source = rmfield(source, 'prob');
  source = rmfield(source, 'mask');
  source.stat = reshape(source.stat, size(source.pos,1), numel(source.freq));
  
  mous_db_putdata(subjectname, 'meg_processed_{sourceDICS}', 'source');
end
