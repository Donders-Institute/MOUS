% Correltion of meg-fmri for all subjets 
% correlation at each timepoint
% include normalization of the meg data.
% full data set sent vs baseline and seq vs baseline

% Create a matrix Nvertex x Nsubj with fMRI values.

% Create a matrix with Nvertex x Nsubj with MEG values.
% Then, compute per vertex the correlation across subjects.
% A per subject normalization will have a non-trivial effect
% on the result because it will affect where for a given vertex
% the data points end up in the scatter plot
% (through which a correlation is fitted).
% We can also consider some more fancy things,
% like partial least squares or so, where we don't constrain ourselves
% to matching vertices but start looking for spatial patterns in
% BOLD contrast that explain spatial patterns in MEG,
% and the other way around.


if ~exist('condition', 'var'),  condition  = 'sent'; end
if ~exist('doLinInc', 'var'), doLinInc = 0; end
if ~exist('doOsc', 'var'), doOsc = 0;    end

if doLinInc
    fmrifile = 'LTibsln_LinIncr_interpol}';
    megfile = '_parametric_blc}';
    cond = [condition '_parametric'];
else
    fmrifile = 'LTibs_interpol}';
    megfile = '}';
    cond = condition;
end

if doOsc
    megfile = '_bfica_sourcedatasentseq_low}';
end

[subj,s] = setdiff(mous_db_getfilename('allV','subjectname'), mous_db_getfilename('bad','subjectname'));
[f,exist_data]   = mous_db_getfilename('allV',['meg_megmri_{' condition fmrifile]); %,rootdir);
subj    = subj(exist_data);
Nsubj   = numel(subj);
rootdir =   '/project/3011020.09/MEG';

allfmri = NaN(Nsubj,8196);
bigmeg = NaN(Nsubj,8196,240);


% subjectname = subj{1};
% tmp2 = mous_db_getdata(subjectname,[ 'meg_bfica_{' megfile]);
% meg = tmp.(['tlck' condition]);
% 
% inside = sourcemodel.inside;      
% 
% tmp2.tlcksent.inside = stat.inside;
% tmp2.tlcksent.inside = isfinite(tmp2.tlcksent.avg); 
% tmp2.tlcksent.avg = isfinite(tmp2.tlcksent.avg); 
% 
% meg = nanmean(nanmean(tmp.tlcksent.avg,3),2);
% source2d = mous_mne_3dto2d(tmp.tlcksent.avg);
%     
% meg=mous_mne_3dto2d(tmp2, 'parameter','tlcksent.avg');


for n=1:Nsubj
    subjectname = subj{n};
    
    %fmri part
    fmri = mous_db_getdata(subjectname,['meg_megmri_{' condition fmrifile], rootdir);
   
    %select the voxels within the field of view
    fov(n,:) = (fmri.pow ~= 0);
    fmri.norm = NaN(size(fmri.pow));
    fmri.norm(fov(n,:)) = fmri.pow(fov(n,:));

%  asdiceded on wrokshop nov. 5th we should not normalize    
%     %normalize fmri with the mean across the volume
%     fmri.norm = fmri.norm-nanmean(fmri.norm);
%     fmri.norm = fmri.norm/nanstd(fmri.norm);  %normalize the distribution
    
    allfmri(n,:) = fmri.norm;
    
    %meg part
    tmp = mous_db_getdata(subjectname,[ 'meg_processed_{_mne_allwords_02-nextword_' condition megfile]);
    if doLinInc  
        meg = tmp.stat;
        clear tmp
    else
        meg = tmp;
        clear tmp
    end
    meg.time = meg.time - 0.034; % check that this not accounted for earlier in the pipeline
    meg.time = meg.time(1:240);
    
    % how to normalize the meg
    % a) use the noise normalized dspm
    if ~doLinInc 
    tmp = spdiags(1./sqrt(meg.avg.noise),0,8196,8196)*meg.avg.pow;
        tmp = meg.stat;
    end
    bigmeg(n,:,:) = tmp(:,1:240);
    clear tmp
end

subjFov = sum(fov,1); 

if ~doLinInc 
megnan = ~isnan(meg.avg.pow(:,1));  %cause the whole line will either be nan or not - removes the medial surfaces
% medial walls are the same for all subjects so this can be detremined on
% the last subjects only.   
else 
megnan = (meg.stat(:,1)~= 0); 
end
    
Rm = NaN(8196,240);
Pm = NaN(8196,240);

for i = 1:length(allfmri)
    %if (empty(i)== 0) % not empty     
    if (subjFov(i) >= 20 && megnan(i)==1)  % only use those voxels where min 20 persons have data
        % move into temp variables with the size of the # of data points as
        % fmri has limited fov and meg no medial surfaces 
        whodata = find(fov(:,i) == 1);
        for j = 1:240
        var1 = bigmeg(whodata,i,j);
        var2 = allfmri(whodata,i);
        [r,p] = corrcoef(var1, var2);
        Rm(i,j) = r(1,2);
        Pm(i,j) = p(1,2);
        clear var1 var2
        end
    else
        Rm(i,:) = NaN;
        Pm(i,:) = NaN;
    end
    
end

% % % fdr on p-values (workswith matlab2010b and newer)
% % consider using fdr only over time dimension
% sel1  = ~isnan(Pm);
% fdrP= ones(size(Pm));
% fdrP(sel1)= mafdr(Pm(sel1));
% mov.mask = fdrP < 0.05;

%no fdr correction
mov.mask = (Pm < 0.05);

mov.r = Rm;
mov.r(~megnan) = NaN;
% mov.r(sel) = 0; %mask everything nonsig  
mov.r = mov.r(:,56:end); % shoorten the baseline in the movie

load matlab/MOUS/meg/templates/cortex_inflated_8196reg.mat
mov.pos = sourcemodel.pnt;
mov.tri = sourcemodel.tri;
mov.inside = fmri.inside;
mov.time = meg.time(56:240);
mov.time = mov.time-0.032;

filename = fullfile('/project/3011020.09/annhul/videos/',['meg' num2str(Nsubj) '_megfmri_' cond '_corr_' date]);
mous_makemovie_mne(mov,filename,'parameter','r', 'demean','no','maskparameter', 'mask' ,'zlim',[-0.5 0.5]);
%
% load matlab/MOUS/meg/templates/cortex_midthickness_8196reg.mat
% C = triangle2connectivity(sourcemodel.tri); % It suffices to take e.g. the cortex_midthickness_8196reg template
% clus=findcluster(mov.r > 0, full(C));

% for n = 1:length(clus)
%     temp = find(clus == n);
%     if length(temp) < 100
%         clus(temp) = 0;
%     end
% end
% mov.c = clus;
% 
% filename = fullfile('/project/3011020.09/annhul/videos/',['meg' num2str(Nsubj) '_megfmri_test' date]);
% mous_makemovie_mne(mov,filename,'parameter','c', 'demean','no','zlim',[-0.5 0.5]);
% 
