% this script is intended as a first try to implement Kernel canonical correlation analysis
% and to see how far it will bring us
clear all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% load in the data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('condition', 'var'),  condition  = 'sent';   end
if ~exist('condition2', 'var'), condition2 = 'Zinnen'; end
if ~exist('doParametric', 'var'), doParametric = 0;    end

if doParametric
  %sentence progression vs baseline (only 100 subjects exist)
  fmridir  = '/project/3011020.09/hubfon/conImg1stLevel_Visual/';
  fmriname = ['con_' condition2 'LTZero_LinearIncrease_XXXX.img'];
  megname  =  [ 'meg_mne_allwords_02-nextword_' condition '_parametric_blc'];
else
  %sent vs seq
  fmridir  = '/project/3011020.09/MRI/XXXX/mri_task/ffxstats/'; %sent vs baseline
  fmriname = 'con_0014.img';
  megname  = 'meg_bfica_sourcedatasentseq_medium_withecgremoved';
end

[subj,s] = mous_db_getfilename('allV','subjectname'); 
Nsubj    = numel(subj);
ok       = true(numel(subj),2);

for k = 1:numel(subj)
  try
    tmp = ft_read_mri(fullfile( strrep([fmridir fmriname], 'XXXX', subj{k})));
    S(k).fmri = tmp.anatomy(:);
  catch
    ok(k,1) = false;
  end
  
  try
    mous_db_getdata(subj{k}, megname);
    tlcksent.avg = nanmean(tlcksent.avg,3);
    tlckseq.avg  = nanmean(tlckseq.avg,3);
    tmp     = tlcksent;
    tmp.avg = (tlcksent.avg - tlckseq.avg)./(tlcksent.avg + tlckseq.avg);
    %tmp.avg = mean(tmp.avg,3);
    
    S(k).meg = tmp.avg(:);
  catch
    ok(k,2) = false;
  end
end

% only take the subjects for whom we have both fMRI and MEG data
% subjects 1116 and 1117 are missing both fmri constant repsonse and progression data

S = S(ok(:,1)&ok(:,2));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% get the data in the right shape
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
meg  = cat(2,S(:).meg);
fmri = cat(2,S(:).fmri);

% mean subtract across observations (subjects), as discussed with Andre
m_meg  = nanmean(meg,2);
s_meg  = nanstd(meg,[],2);
m_fmri = nanmean(fmri,2);
s_fmri = nanstd(fmri,[],2);
for k = 1:size(meg,2)
  meg(:,k)  = (meg(:,k)  - m_meg)./s_meg;
  fmri(:,k) = (fmri(:,k) - m_fmri)./s_fmri;
end

% only select voxels where all subject contribute
i_meg  = sum(isfinite(meg),2)==size(meg,2);
i_fmri = sum(isfinite(fmri),2)==size(fmri,2);

meg  = meg(i_meg,:);
fmri = fmri(i_fmri,:);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% do the correlation analysis
%
% for this you need to install the 'KCCA Package with all files required',
% which can be downloaded from
% www.davidroihardoon.com/Professional/Code.html
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% run using cross-validation
opt = [];
opt.allcomponents = true;
opt.eta   = 0.5;
opt.kappa = -2;
opt.stand = true;
opt.nfold = 10;
opt.nrand = 0;
%opt.verbose = false;
[n_meg, n_fmri, r, opt_kappa, test_corr, nalpha, nbeta, K1, K2] = mous_kcca_kfoldcv(meg',fmri',opt);

%%%%% at this point I saved some stuff. %%%%%
load(fullfile('/home/language/jansch/tmp/mous','workspace_kcca_oscillations_20141210.mat'));
[m,ix] = max(test_corr(:,1));

% the following are the reference spatio-spectral patterns against which the permuted ones are going to be compared 
r_meg  = meg*n_meg(:,ix);
r_fmri = fmri*n_fmri(:,ix);

opt.nrand = 0;

p_meg  = zeros(size(meg,1),1);
p_fmri = zeros(size(fmri,1),1);
for k = 1:50
  P = diag(sign(randn(size(meg,2),1)));
  [x_meg, x_fmri] = mous_kcca_kfoldcv( (meg*P)', (fmri)', opt); % should I apply the same permute for each modality?
  [x,ix] = max(diag(corr(x_meg,x_fmri)));
  
  % compute the spatio-spectral patterns 
  megp  = meg*P;
  fmrip = fmri;%fmri*P;
  
  %re-standardize
  megp  = (megp  - mean(megp,2)*ones(1,size(megp,2)))./(std(megp,[],2)*ones(1,size(megp,2)));
  fmrip = (fmrip - mean(fmrip,2)*ones(1,size(fmrip,2)))./(std(fmrip,[],2)*ones(1,size(fmrip,2)));
  
  p_meg  = p_meg  + double(megp*x_meg(:,ix)>r_meg);
  p_fmri = p_fmri + double(fmrip*x_fmri(:,ix)>r_fmri);
end
  
  
  
  
