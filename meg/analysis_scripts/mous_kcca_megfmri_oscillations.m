% this script is intended as a first try to implement Kernel canonical correlation analysis
% and to see how far it will bring us
clear all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% load in the data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%sent vs seq
fmridir  = '/project/3011020.09/MRI/XXXX/mri_task/ffxstats/';
fmriname = 'con_0014.img';  %sent vs sequence
megname  = 'meg_bfica_sourcedatasentseq_low';

[subj,s] = mous_db_getfilename('allV','subjectname'); 
Nsubj    = numel(subj);
ok       = true(numel(subj),2);

for k = 1:numel(subj)
  try
    tmp = ft_read_mri(fullfile(strrep([fmridir fmriname], 'XXXX', subj{k})));
    tmp = mous_fmri_3dto2d(subj{k}, tmp);
    S(k).fmri = tmp.pow(:);
    clear tmp;
  catch
    ok(k,1) = false;
  end
  
  try
    megnames = {megname, strrep(megname, 'low', 'medium'), strrep(megname, 'low', 'high')};
    for m = 1:3
      mous_db_getdata(subj{k}, megnames{m});
      %ix = (1:nearest(tlcksent.time, -0.09));
      %iy = setdiff(1:numel(tlcksent.time),ix);
      iy = nearest(tlcksent.time, 0.2):numel(tlcksent.time);
      %tlcksent.avg = nanmean(tlcksent.avg,3);%./nanmean(tlcksent.avg(:,:,ix),3);
      %tlckseq.avg  = nanmean(tlckseq.avg,3);%./nanmean(tlckseq.avg(:,:,ix),3);
      tmp{m}     = tlcksent;
      %tmp{m}.avg = (tlcksent.avg - tlckseq.avg)./(tlcksent.avg + tlckseq.avg);
      %tmp{m}.avg = nanmean(tlcksent.avg(:,:,iy)-tlckseq.avg(:,:,iy),3)./nanmean(tlcksent.avg(:,:,ix)+tlckseq.avg(:,:,ix),3);
      %tmp{m}.avg = nanmean(tlcksent.avg(:,:,iy)-tlckseq.avg(:,:,iy),3)./nanmean(tlcksent.avg(:,:,iy)+tlckseq.avg(:,:,iy),3);
      tmp{m}.avg = nanmean(tlcksent.avg(:,:,iy),3)./nanmean(tlckseq.avg(:,:,iy),3)-1;
    end
    tmp_avg  = cat(2, tmp{1}.avg, tmp{2}.avg(:,2:end), tmp{3}.avg);
    S(k).meg = tmp_avg(:);
    clear tmp;
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

Nfoi = size(meg,1)./5782;
for k = 1:Nfoi
  indx = (1:5782)+(k-1)*5782;
  meg(indx,:) = meg(indx,:)*diag(1./mean(abs(meg(indx,:))));
end

% % only select voxels where all subject contribute
% i_meg  = sum(isfinite(meg),2)==size(meg,2);
% i_fmri = sum(isfinite(fmri),2)==size(fmri,2);
% 
% meg  = meg(i_meg,:);
% fmri = fmri(i_fmri,:);

% std normalise per subject
%fmri = fmri./repmat(nanstd(fmri),size(fmri,1),1);

% mean subtract across observations (subjects), as discussed with Andre
m_meg  = nanmean(meg,2);
s_meg  = nanstd(meg,[],2);
m_fmri = nanmean(fmri,2);
s_fmri = nanstd(fmri,[],2);
for k = 1:size(meg,2)
  meg(:,k)  = (meg(:,k)  - m_meg)./s_meg;
  fmri(:,k) = (fmri(:,k) - m_fmri)./s_fmri;
end

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
addpath ~/matlab/toolboxes/kcca_package2/

foi = [2.5:2.5:12.5 16:4:32 40:4:100];
tmptmp = repmat(foi, [5782, 1]);
tmptmp = tmptmp(:);

selfoi = [5 10 16 40];%[5:2.5:12.5 16:4:32];% 40:8:100];
selmeg = ismember(tmptmp,selfoi);

% run using cross-validation
opt = [];
opt.allcomponents = true;
opt.eta   = 0.5;
opt.kappa = 0.5;
opt.stand = true;
opt.nfold = 10;
opt.nrand = 0;%5000;
%opt.verbose = false;
iz = randperm(101);
iz = iz(1:100);
[n_meg, n_fmri, r, opt_kappa, test_corr, nalpha, nbeta, K1, K2] = mous_kcca_kfoldcv(meg(selmeg,iz)',fmri(:,iz)',opt);
[m,ix] = max(test_corr(:,1));

mous_db_getdata('V1010','meg_bfica_leadfield8mm');
dum    = zeros(11000,numel(selfoi),10);
%dum(newinside, :) = reshape(meg(selmeg,:)*n_meg(:,ix),numel(newinside),[]); %%THIS WAS WRONG

mri  = ft_read_mri(fullfile( strrep([fmridir fmriname], 'XXXX', 'V1010')));
dum2 = zeros(mri.dim);
dum2 = zeros(8196,1);
% for the different folds we now can interpret the weights of the forward
% model (as per Haufe 2014)
for k = 1:10
  % training and test indices
  N   = size(meg(:,iz),2);
  npf = floor(N / 10);
  te = false(N,1);
  if (k < 10)
    te((1:npf)+(k-1)*npf) = true;
  else
    te((((k-1)*npf)+1):N) = true;
  end
  tr = ~te;
  find(te)
  
  w       = nalpha{k};
  meg_tmp = standardise(meg(selmeg,iz(tr)),2);
  s       = meg_tmp*w;
  sigma_s = cov(s);
  sigma_x = cov(meg_tmp);
  a       = sigma_x*w/sigma_s;
  A(k,:)  = a(ix,:);
  cX(k) = cond(sigma_x);
  cS(k) = cond(sigma_s);
  dum(newinside, :, k) = reshape(s*a(ix,:)',numel(newinside),[]);

  w        = nbeta{k};
  fmri_tmp = standardise(fmri(:,iz(tr)),2);
  s        = fmri_tmp*w;
  sigma_s  = cov(s);
  sigma_x  = cov(fmri_tmp);
  a = sigma_x*w/sigma_s;
  dum2(i_fmri) = s*a(ix,:)';
  B(k,:)    = a(ix,:);
  alldum2(:,k) = dum2;
end
dum2 = alldum2; clear alldum2;

sourcemodel.pow   = dum;
sourcemodel.freq  = selfoi;
sourcemodel.time  = 1:10;

cfgp.funparameter = 'pow';
cfgp.funcolormap  = 'jet';
ft_sourceplot(cfgp, sourcemodel);

figure;volplot(dum2,'montage');



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
  
  
  
  
