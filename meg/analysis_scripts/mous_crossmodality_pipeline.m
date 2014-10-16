%% this script is intended as a first try to implement Kernel canonical correlation analysis
% and to see how far it will bring us
clear all
fprintf('Computing kcc for fmri and meg data\n')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% load in the data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
condition = 'sent';
condition2 = 'Zinnen';

doParametric = 0;

if doParametric
    %sentence progression vs baseline (only 100 subjects exist)
    fmridir  = '/project/3011020.09/hubfon/conImg1stLevel_Visual/';
    fmriname = ['con_' condition2 'LTZero_LinearIncrease_XXXX.img'];
    megname  =  [ 'meg_processed_{_mne_allwords_02-nextword_' condition '_parametric_blc}'];
else
    %sent vs baseline
    fmridir  = '/project/3011020.09/MRI/XXXX/mri_task/ffxstats/'; %sent vs baseline
    fmriname = 'con_0012.img';
    megname  = ['meg_mne_allwords_02-nextword_' condition];
end
k= 1;

[subj,s] = setdiff(mous_db_getfilename('allV','subjectname'), mous_db_getfilename('bad','subjectname'));

ok   = true(numel(subj),1);

for k = 1:numel(subj)
  try,
    tmp = ft_read_mri(fullfile( strrep([fmridir fmriname], 'XXXX', subj{k}))); 
    S(k).fmri = tmp.anatomy(:);
  catch
    ok(k) = false;
  end
  
  try,
    %mous_db_getdata(subj{k}, megname);
    source = mous_db_getdata(subj{k}, megname);
    % mous_db_getdata(subj{k},['meg_mne_allwords_02-nextword_' condition]);
    % do a dspm here: note that this may not work in parametric results
    % data because the avg.noise may be absent: in that case (if we think
    % the normalization with the baseline noise is appropriate) the noise
    % should be grabbed from the corresponding mne sentence m
    % structure
    if doParametric
        % load the noise cov from the all words mne
        mne = mous_db_getdata(subj{k}, ['meg_mne_allwords_02-nextword_' condition]);
        source.avg.noise = mne.avg.noise;
        source.avg.pow = source.stat;
    end
    tmp = spdiags(1./sqrt(source.avg.noise),0,8196,8196)*source.avg.pow;
    S(k).meg = reshape(tmp(:,1:240),[],1);
  catch
    ok(k) = false;
  end
end

% only take the subjects for whom we have both fMRI and MEG data
% subjects 1116 and 1117 are missing both fmri constant repsonse and progression data

S = S(ok);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% get the kernels
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
meg  = cat(2,S(:).meg);
fmri = cat(2,S(:).fmri);

% mean subtract across observations (subjects), as discussed with Andre
m_meg  = nanmean(meg,2);
m_fmri = nanmean(fmri,2);
for k = 1:size(meg,2)
  meg(:,k)  = meg(:,k)  - m_meg;
  fmri(:,k) = fmri(:,k) - m_fmri;
end

% only select voxels where all subject contribute
i_meg  = sum(isfinite(meg),2)==size(meg,2);
i_fmri = sum(isfinite(fmri),2)==size(fmri,2);

meg  = meg(i_meg,:);
fmri = fmri(i_fmri,:);

% compute the kernels
K_meg  = meg'*meg;
K_fmri = fmri'*fmri;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% do the correlation analysis
%
% for this you need to install the 'KCCA Package with all files required',
% which can be downloaded from
% www.davidroihardoon.com/Professional/Code.html
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%[nalpha, nbeta, r, Kx, Ky] = kcanonca_reg_ver2(K_meg,K_fmri, eta, kapa, sl, nor, Rx, Ry);
%[n_meg, n_fmri, r] = kcanonca_reg_ver2(K_meg,K_fmri, 0.1, 0.1);

% run using cross-validation
opt.eta   = 0.5;
opt.kappa = -2;
opt.stand = true;
opt.nfold = 10;
[n_meg, n_fmri, r, opt_kappa] = mous_kcca_kfoldcv(meg',fmri',opt);




