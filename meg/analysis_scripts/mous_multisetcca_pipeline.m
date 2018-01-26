
if ~exist('rootdir',     'var'), rootdir     = '/project/3011020.09/MEG/';  end
if ~exist('computedata', 'var'), computedata = false;                       end
if ~exist('cleandata',   'var'), cleandata   = false;                       end
if ~exist('dolcmv',      'var'), dolcmv      = false;                       end
if ~exist('computealignment', 'var'), computealignment = false;             end
if ~exist('domscca_searchlight', 'var'), domscca_searchlight = true;        end

if ~exist('subjectname', 'var') && ~exist('scenario', 'var')
  error('at least a subjectname or a scenario number needs to be defined');
end

if exist('scenario', 'var')
  subj = mous_db_getfilename('allAV', 'subjectname');
  sce  = mous_db_getfilename(subj,    'scenario');
  sel  = strncmp(sce, num2str(scenario), 1);
  subj = subj(sel);
  sce  = sce(sel);
end

if computedata
  data = mous_erf_sentences(subjectname, 1);
  mous_db_putdata(subjectname, 'meg_multisetcca_data', 'data', rootdir);
end

if cleandata
  for k = 11:numel(subj)
  mous_db_getdata(subj{k}, 'meg_multisetcca_data');
  cfg = [];
  cfg.method = 'summary';
  cfg.keeptrial = 'nan';
  cfg.channel = 'MEG';
  data = ft_rejectvisual(cfg, data);
  mous_db_putdata(subj{k}, 'meg_multisetcca_data', 'data');
  end
end

  
if dolcmv
  mous_db_getdata(subjectname, 'meg_multisetcca_data');
  [source_parc, filterlabel] = mous_multisetcca_lcmv(subjectname, data);
  mous_db_putdata(subjectname, 'meg_multisetcca_lcmv_parc', 'source_parc', 'filterlabel', rootdir);
end

if computealignment
  % this chunk of code creates a file for each subject that has been
  % presented with the same paradigm, which contains information about how
  % to align the trials such that the timing is optimised for multisetcca
  
  
  for k = 1:numel(subj)
    mous_db_getdata(subj{k}, 'meg_multisetcca_data');
    if strcmp(sce{k}(2:end), 'Vis')
      timinginfo = mous_multisetcca_adjusttiming_vis(subj{k}, data);
      elseif strcmp(sce{k}(2:end), 'Aud')
      timinginfo = mous_multisetcca_adjusttiming_aud(subj{k}, data);
    end
    mous_db_putdata(subj{k}, 'meg_multisetcca_timinginfo', 'timinginfo');
  end
  
  % the following chunk of code is needed to get a specification of how to
  % align the trials across subjects, and to accommodate the different time
  % axes within modality (potentially due to block breaks etc), and to
  % accommodate the time axes across modalities.
  D = cell(1,numel(subj));
  for k = 1:numel(subj)
    mous_db_getdata(subj{k}, 'meg_multisetcca_timinginfo');
    D{k} = timinginfo;
  end
  
  trialid = (1:1000)';
  sel     = false(1000,numel(D));
  nsmp    =   nan(1000,numel(D));
  begtim  =   nan(1000,numel(D));
  
  for k = 1:numel(D)
    % identify the sentences that occur in any of the input datasets
    tmp = D{k}.trialinfo(:,end);
    seltmp = isfinite(tmp);
    tmp = tmp(seltmp);
    sel(tmp,k)    = true;
    nsmp(tmp,k)   = cellfun('size',D{k}.time(seltmp),2);
    begtim(tmp,k) = cell2mat(cellcolselect(D{k}.time(seltmp),1));
  end
  ix = ~all(sel==false,2);
  
  trialid = trialid(ix);
  ntrl    = numel(trialid);
  sel     = sel(ix,:);
  nsmp    = nsmp(ix,:);
  begtim  = begtim(ix,:);
  endtim  = begtim+(nsmp-1)./120;
  
  maxnsmp = max(nsmp,[],2);
  mintim  = min(begtim,[],2);
  maxtim  = max(endtim,[],2);
  
  groupinfo.trialid = trialid;
  groupinfo.ntrl    = ntrl;
  groupinfo.sel     = sel;
  groupinfo.nsmp    = nsmp;
  groupinfo.begtim  = begtim;
  groupinfo.endtim  = endtim;
  groupinfo.maxnsmp = maxnsmp;
  groupinfo.mintim  = mintim;
  groupinfo.maxtim  = maxtim;
  groupinfo.subj    = subj;
  for k = 1:numel(subj)
    mous_db_putdata(subj{k}, 'meg_multisetcca_groupinfo', 'groupinfo');
  end
end

if domscca_searchlight
  nfold = 5;
  shift = zeros(1,numel(subj));
  if ~exist('skip_noshuffle', 'var')
    skip_noshuffle = false;
  end
  if ~exist('parcel_indx', 'var')
    error('a parcel index needs to be specified');
  end
  % this step does a mscca on a specified parcel, and requires the
  % parcellation to have been computed. Also, it is a bit inefficient,
  % because it processes the data up until the level of a parcellated
  % representation, but that is for memory reasons
  groupdata = cell(1,numel(subj));
  for k = 1:numel(subj)
    mous_db_getdata(subj{k}, 'meg_multisetcca_data');
    mous_db_getdata(subj{k}, 'meg_multisetcca_lcmv_parc');
    source_parc.filterlabel = filterlabel;
    mous_db_getdata(subj{k}, 'meg_multisetcca_timinginfo');
    mous_db_getdata(subj{k}, 'meg_multisetcca_groupinfo');
    groupdata{1,k} = mous_multisetcca_getparceldata(subj{k}, data, source_parc, timinginfo, groupinfo, parcel_indx, shift(k));
  end
  for k = 1:numel(subj)
    cfg = [];
    cfg.method = 'acrosschannel';
    groupdata{1,k} = ft_channelnormalise(cfg, groupdata{1,k});
  end
  
  if ~skip_noshuffle
    [W, A, rho, C, comp] = mous_multisetcca(groupdata, nfold, 4, [],false); % no cv for now
    [comp, rho]          = mous_multisetcca_postprocess(comp, rho, source_parc.label{parcel_indx});
    coh                  = mous_multisetcca_coh(comp);
    comp                 = ft_struct2single(comp);
    savedir = '/project/3011020.09/jansch/mscca_group';
    system(sprintf('mkdir -p %s', savedir));
    filename = fullfile(savedir, sprintf('mscca_sce%d_parcel%03d',scenario,parcel_indx));
    save(filename, 'rho', 'W', 'A', 'comp', 'coh');
  end
  
  nrand = 50;
  for m = 1:nrand
    groupdatashuf               = mous_multisetcca_shuffle(groupdata, {(1:17) (18:33)}); % shuffle before folding
    [Wshuf, Ashuf, rhoshuf, ~, compshuf] = mous_multisetcca(groupdatashuf, nfold, 4, [], false);
    [compshuf, rhoshuf]         = mous_multisetcca_postprocess(compshuf, rhoshuf, source_parc.label{parcel_indx});
    cohshuf(m)                  = ft_struct2single(mous_multisetcca_coh(compshuf));
    Rshuf(:,:,:,m)              = single(rhoshuf);
  end
  Cshuf = cat(4,cohshuf.cohspctrm);
  Cshuf = Cshuf(:,:,1:41,:);
  foi   = cohshuf(1).freq(1:41);
  savedir = '/project/3011020.09/jansch/mscca_group';
  filename = fullfile(savedir, sprintf('mscca_sce%d_parcel%03dshuf',scenario,parcel_indx));
  if exist([filename,'.mat'], 'file')
    tmp = load(filename);
    Cshuf = cat(4,tmp.Cshuf,Cshuf);
    Rshuf = cat(4,tmp.Rshuf,Rshuf);
  end
  save(filename,'Rshuf','Cshuf', 'foi');
  
end