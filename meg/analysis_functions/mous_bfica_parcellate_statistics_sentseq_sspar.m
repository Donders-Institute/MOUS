function mous_bfica_parcellate_statistics_sentseq_sspar(freq,chansel,bsltype)
% Calculate statistics for parcellate cortical sheet
% cortical sheet created by interpolating from 3D volumetric space (output
% from beamformer)

rootdir     = '/project/3011020.09/MEG/';
subj  = mous_db_getfilename('allV', 'subjectname');
[f,s] = mous_db_getfilename('allV','meg_bfica_sourcedatasentseq_low',rootdir);
subj  = subj(s);
subj  = subj(2:end);  % first subject has no Wordlist-RC trials
Nsubj = numel(subj);

savedir  = '/project/3011020.09/nielam/groupresults/bfica/visual/complexity/';

% Input file specfications:
% sourcedata
savename1 = 'sourcedatasentseq';
sourcedat1 = '_bfica_sourcedata_sent_';
sourcedat2 = '_bfica_sourcedata_seq_';

savename2 = 'sourcedatasentseqpar';
sourcedat3 = '_bfica_sourcedata_sentpar_';
sourcedat4 = '_bfica_sourcedata_seqpar_';

% TOI
time = [0.25 0.35 0.45];
if isnumeric(time)
  tmp = num2str(time*100,'%03d');
  toi = [tmp(1:3),'-',tmp(end-2:end),'s'];
else
  toi = '';
end


%% create data structure
  
% define parameters and subjects
if ismember(freq(1),2.5:2.5:12.5)
  suff = 'low';
elseif ismember(freq(1),12:4:32)
  suff = 'medium';
elseif ismember(freq(1),40:4:100)
  suff = 'high';
end

% set frequencies for filename 
if mod(freq(1),1)  % isdecimal
  f1 = num2str(freq(1)*10,'%03d');
else
  f1 = num2str(freq(1),'%02d');
end
frqall = [f1,'Hz','_'];

if numel(freq) == 2
  if mod(freq(end),1)  % isdecimal
    f2 = num2str(freq(2)*10,'%03d');
  else
    f2 = num2str(freq(2),'%02d');
  end
  frqall = [f1,'-',f2,'Hz','_'];
end

for k = 1:Nsubj
  if k == 1
  s1{k,1} = ft_read_cifti(fullfile('/project/3011020.09/MEG',subj{k},'bfica',[subj{k}, sourcedat1,frqall,toi,'.ptseries.nii']));
  s2{k,1} = ft_read_cifti(fullfile('/project/3011020.09/MEG',subj{k},'bfica',[subj{k}, sourcedat2,frqall,toi,'.ptseries.nii']));
  s3{k,1} = ft_read_cifti(fullfile('/project/3011020.09/MEG',subj{k},'bfica',[subj{k}, sourcedat3,frqall,toi,'.ptseries.nii']));
  s4{k,1} = ft_read_cifti(fullfile('/project/3011020.09/MEG',subj{k},'bfica',[subj{k}, sourcedat4,frqall,toi,'.ptseries.nii']));

  else
  % apply data structure to all subjs
  s1{k,1} = s1{k-1,1};
  s2{k,1} = s2{k-1,1};
  s3{k,1} = s3{k-1,1};
  s4{k,1} = s4{k-1,1};
  % insert subj specific data
  % mous_cifti_quickread only loads the voxel data (one field), instead of entire data structure
  s1{k,1}.ptseries = mous_cifti_quickread(fullfile('/project/3011020.09/MEG',subj{k},'bfica',[subj{k}, sourcedat1 ,frqall,toi,'.ptseries.nii']));
  s2{k,1}.ptseries = mous_cifti_quickread(fullfile('/project/3011020.09/MEG',subj{k},'bfica',[subj{k}, sourcedat2 ,frqall,toi,'.ptseries.nii']));
  s3{k,1}.ptseries = mous_cifti_quickread(fullfile('/project/3011020.09/MEG',subj{k},'bfica',[subj{k}, sourcedat3 ,frqall,toi,'.ptseries.nii']));
  s4{k,1}.ptseries = mous_cifti_quickread(fullfile('/project/3011020.09/MEG',subj{k},'bfica',[subj{k}, sourcedat4 ,frqall,toi,'.ptseries.nii']));
  end
end  

%% baseline subtraction
if strcmp(suff,'low')
    bslt = 1;
elseif strcmp(suff,'medium') || strcmp(suff,'high')
    bslt = [1 2];
end

%%%%% ABSOLUTE BASELINE %%%%%
if strcmp(bsltype,'abs') 
  for k = 1:Nsubj
    % s1
    bsl = mean(s1{k}.ptseries(:,bslt),2);  % do subtraction
    tmp = s1{k}.ptseries - bsl*ones(1,numel(s1{k}.time));
    if strcmp(suff,'low')                    % remove baseline timepoints
      s1{k}.ptseries = tmp(:,2:end);
    elseif strcmp(suff,'medium') || strfind(suff,'high')
      s1{k}.ptseries = tmp(:,3:end);
    end

    % s2
    bsl = mean(s2{k}.ptseries(:,bslt),2);
    tmp = s2{k}.ptseries - bsl*ones(1,numel(s2{k}.time));
    if strcmp(suff,'low')
      s2{k}.ptseries = tmp(:,2:end);
    elseif strcmp(suff,'medium') || regexp(suff,'high')
      s2{k}.ptseries = tmp(:,3:end);
    end

    % s3
    bsl = mean(s3{k}.ptseries(:,bslt),2);  % do subtraction
    tmp = s3{k}.ptseries - bsl*ones(1,numel(s3{k}.time));
    if strcmp(suff,'low')                    % remove baseline timepoints
      s3{k}.ptseries = tmp(:,2:end);
    elseif strcmp(suff,'medium') || strfind(suff,'high')
      s3{k}.ptseries = tmp(:,3:end);
    end

    % s4
    bsl = mean(s4{k}.ptseries(:,bslt),2);
    tmp = s4{k}.ptseries - bsl*ones(1,numel(s4{k}.time));
    if strcmp(suff,'low')
      s4{k}.ptseries = tmp(:,2:end);
    elseif strcmp(suff,'medium') || regexp(suff,'high')
      s4{k}.ptseries = tmp(:,3:end);
    end

    % update time axis after subtraction
    s1{k}.time = time; s2{k}.time = time;  s3{k}.time = time; s4{k}.time = time;
  end 

%%%%%%% COMMON BASELINE %%%%%
elseif strcmp(bsltype,'comabs')  
  for k = 1:Nsubj
    tmp1 = mean(s1{k}.ptseries(:,bslt),2);
    tmp2 = mean(s2{k}.ptseries(:,bslt),2);
    tmp3 = mean(s3{k}.ptseries(:,bslt),2);
    tmp4 = mean(s4{k}.ptseries(:,bslt),2);
    bsl1 = (tmp1+tmp2)/2;
    bsl2 = (tmp3+tmp4)/2;
    
    % s1
    tmp = s1{k}.ptseries - bsl1*ones(1,numel(s1{k}.time));  % remove baseline
    if strcmp(suff,'low')                    % remove baseline timepoints from data
      s1{k}.ptseries = tmp(:,2:end);
    elseif strcmp(suff,'medium') || strfind(suff,'high')
      s1{k}.ptseries = tmp(:,3:end);
    end

    % s2
    tmp = s2{k}.ptseries - bsl1*ones(1,numel(s2{k}.time));
    if strcmp(suff,'low')
      s2{k}.ptseries = tmp(:,2:end);
    elseif strcmp(suff,'medium') || regexp(suff,'high')
      s2{k}.ptseries = tmp(:,3:end);
    end

    % s3
    tmp = s3{k}.ptseries - bsl2*ones(1,numel(s3{k}.time));
    if strcmp(suff,'low')                   
      s3{k}.ptseries = tmp(:,2:end);
    elseif strcmp(suff,'medium') || strfind(suff,'high')
      s3{k}.ptseries = tmp(:,3:end);
    end

    % s4
    tmp = s4{k}.ptseries - bsl2*ones(1,numel(s4{k}.time));
    if strcmp(suff,'low')
      s4{k}.ptseries = tmp(:,2:end);
    elseif strcmp(suff,'medium') || regexp(suff,'high')
      s4{k}.ptseries = tmp(:,3:end);
    end

    % update time axis after subtraction
    s1{k}.time = time; s2{k}.time = time;  s3{k}.time = time; s4{k}.time = time;
  end 
  
%%%%%% RELATIVE BASELINE %%%%% 
elseif strcmp(bsltype,'rel')  
  for k = 1:Nsubj
    % s1
    bsl = mean(s1{k}.ptseries(:,bslt),2);  % do subtraction
    tmp = (s1{k}.ptseries)./ (bsl*ones(1,numel(s1{k}.time)));
    if strcmp(suff,'low')                    % remove baseline timepoints
      s1{k}.ptseries = tmp(:,2:end);
    elseif strcmp(suff,'medium') || strfind(suff,'high')
      s1{k}.ptseries = tmp(:,3:end);
    end

    % s2
    bsl = mean(s2{k}.ptseries(:,bslt),2);
    tmp = (s2{k}.ptseries) ./(bsl*ones(1,numel(s2{k}.time)));
    if strcmp(suff,'low')
      s2{k}.ptseries = tmp(:,2:end);
    elseif strcmp(suff,'medium') || regexp(suff,'high')
      s2{k}.ptseries = tmp(:,3:end);
    end

    % s3
    bsl = mean(s3{k}.ptseries(:,bslt),2);  % do subtraction
    tmp = (s3{k}.ptseries) ./ (bsl*ones(1,numel(s3{k}.time)));
    if strcmp(suff,'low')                    % remove baseline timepoints
      s3{k}.ptseries = tmp(:,2:end);
    elseif strcmp(suff,'medium') || strfind(suff,'high')
      s3{k}.ptseries = tmp(:,3:end);
    end

    % s4
    bsl = mean(s4{k}.ptseries(:,bslt),2);
    tmp = (s4{k}.ptseries) ./ (bsl*ones(1,numel(s4{k}.time)));
    if strcmp(suff,'low')
      s4{k}.ptseries = tmp(:,2:end);
    elseif strcmp(suff,'medium') || regexp(suff,'high')
      s4{k}.ptseries = tmp(:,3:end);
    end

    % update time axis after subtraction
    s1{k}.time = time; s2{k}.time = time;  s3{k}.time = time; s4{k}.time = time;
  end 
end


  %% variance
for k = 1:Nsubj
  if k==1
    sums1 = s1{k}.ptseries;
    sums2 = s2{k}.ptseries;
    ssqs1 = s1{k}.ptseries.^2;
    ssqs2 = s2{k}.ptseries.^2;

    sums3 = s3{k}.ptseries;
    sums4 = s4{k}.ptseries;
    ssqs3 = s3{k}.ptseries.^2;
    ssqs4 = s4{k}.ptseries.^2;

  else
    sums1 = sums1 + s1{k}.ptseries;
    sums2 = sums2  + s2{k}.ptseries;
    ssqs1 = ssqs1 + s1{k}.ptseries.^2;
    ssqs2 = ssqs2  + s2{k}.ptseries.^2;

    sums3 = sums3 + s3{k}.ptseries;
    sums4 = sums4  + s4{k}.ptseries;
    ssqs3 = ssqs3 + s3{k}.ptseries.^2;
    ssqs4 = ssqs4  + s4{k}.ptseries.^2;
  end  
end

% compute mean per condition and sem
avgs1 = sums1./Nsubj;
vars1 = (ssqs1 - sums1.^2./Nsubj)./(Nsubj-1);
sems1 = sqrt(vars1./Nsubj);

avgs2  = sums2./Nsubj;
vars2 = (ssqs2 - sums2.^2./Nsubj)./(Nsubj-1);
sems2  = sqrt(vars2./Nsubj);

avgs3 = sums3./Nsubj;
vars3 = (ssqs3 - sums3.^2./Nsubj)./(Nsubj-1);
sems3 = sqrt(vars3./Nsubj);

avgs4  = sums4./Nsubj;
vars4 = (ssqs4 - sums4.^2./Nsubj)./(Nsubj-1);
sems4  = sqrt(vars4./Nsubj);


%% statistics
cfg = []; 
cfg.method = 'montecarlo';
cfg.statistic = 'depsamplesT';
cfg.numrandomization = 2000;
cfg.correctm         = 'cluster'; % cluster over time, not space
cfg.neighbours       = [];
cfg.alpha             = 0.05;
cfg.correcttail       = 'alpha'; % Each tail will be tested with alpha = 0.025.
cfg.latency           = [s1{k}.time(1) s1{k}.time(end)];
if strcmp(chansel,'roi')
  cfg.channel          = {'L_44_B05_01','L_44_B05_02','L_44_B05_03','L_44_B05_04',...
        'L_45_B05_01','L_45_B05_02',...
        'L_47_B05_01',...
        'L_22_B05_01','L_22_B05_02','L_22_B05_03','L_22_B05_04','L_22_B05_05','L_22_B05_06','L_22_B05_07','L_22_B05_08','L_22_B05_09','L_22_B05_10',...
        'L_21_B05_01','L_21_B05_02','L_21_B05_03','L_21_B05_04',...
        'L_38_B05_01','L_38_B05_02','L_38_B05_03','L_38_B05_04',...
        'L_20_B05_01','L_20_B05_02','L_20_B05_03','L_20_B05_04','L_20_B05_05','L_20_B05_06','L_20_B05_07',...
        'R_44_B05_01','R_44_B05_02','R_44_B05_03','R_44_B05_04',...
        'R_45_B05_01','R_45_B05_02',...
        'R_47_B05_01',...
        'R_22_B05_01','R_22_B05_02','R_22_B05_03','R_22_B05_04','R_22_B05_05','R_22_B05_06','R_22_B05_07','R_22_B05_08','R_22_B05_09','R_22_B05_10',...
        'R_21_B05_01','R_21_B05_02','R_21_B05_03','R_21_B05_04',...
        'R_38_B05_01','R_38_B05_02','R_38_B05_03','R_38_B05_04',...
        'R_20_B05_01','R_20_B05_02','R_20_B05_03','R_20_B05_04','R_20_B05_05','R_20_B05_06','R_20_B05_07'};
end

cfg.ivar = 1;
cfg.uvar = 2;
cfg.parameter = 'ptseries';
cfg.design    = [ones(1,Nsubj) ones(1,Nsubj)*2;1:Nsubj 1:Nsubj];

%%% SENTWORD vs. SEQWORD
stat          = ft_timelockstatistics(cfg, s1{:}, s2{:});
statpar       = ft_timelockstatistics(cfg, s3{:}, s4{:});

if sign(cfg.latency(1)) == -1
  
  if ismember(freq,2.5:2.5:12.5)
    t1 = num2str(cfg.latency(1)*10,'%03d');
  elseif ismember(freq,12:4:100)
    t1 = num2str(cfg.latency(1)*100,'%04d');
  end
else
  t1 = num2str(cfg.latency(1)*100,'%03d');
end

if numel(cfg.latency) > 1
  t2 = num2str(cfg.latency(end)*100,'%03d');
  toiall = [t1,'-',t2];
else
  toiall = [t1,'s'];
end

if isfield(cfg,'channel') && numel(cfg.channel) == 64
  % single word results
  save([savedir,savename1,'_',frqall,toiall,'_','LR_IFGTEMP_',num2str(Nsubj),'subj.mat'],...
     'stat','Nsubj',...
     'avgs1','avgs2','sems1','sems2','-v7.3');    
   
  % sentence progression results 
  stat = statpar; 
  save([savedir,savename2,'_',frqall,toiall,'_','LR_IFGTEMP_',num2str(Nsubj),'subj.mat'],...
     'stat','Nsubj',...
     'avgs3','avgs4','sems3','sems4','-v7.3');    
else
  % single word results
  save([savedir,savename1,'_',frqall,toiall,'_',num2str(Nsubj),'subj.mat'],...
     'stat','Nsubj',...
     'avgs1','avgs2','sems1','sems2','-v7.3');    
   
  % sentence progression results 
  stat = statpar; 
  save([savedir,savename2,'_',frqall,toiall,'_',num2str(Nsubj),'subj.mat'],...
     'stat','Nsubj',...
     'avgs3','avgs4','sems3','sems4','-v7.3');    
end















