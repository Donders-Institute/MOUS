function mous_bfica_maxvoxel(subjectname,sourcedata,toi,bslflag,rootdir)

% this function works with source-level data
% the voxels belonging to each parcel are identified
% Within each parcel the voxel with the maximum power will be selected
% the parcellation for MOUS is done using the AAL template with 330 parcels
% inspired by Hilllebrand et al. 2012 (atlas-based beamformer)
% Note not all parcels belong within the functional data, therefore some
% parcels will not have a representing maximum voxel.
% NL 

if nargin < 2
  sourcedata = 'meg_bfica_sourcedatasentseq_low';
  warning('selecting parcels for %s by default, for correlation',sourcedata) 
end 

if nargin < 3
  warning('selecting and averaging across 0.2 - 0.5s') 
  toi = [0.2 0.5];
end 

if nargin < 4
  bslflag = false;
end

if nargin < 5 
  rootdir = '/project/3011020.09/MEG/'; 
end 

% load aal template
load('/home/language/nielam/MOUS/meg/templates/sourcemodel/standard_sourcemodel3d8mm_parcellated_aal_sub');
aal = sourcemodel;

% load regular sourcemodel (3d8mm)
[p,n,e] = fileparts(which('mous_anatomy_sourcemodel3D'));
load([p(1:end-18),'templates/sourcemodel/standard_sourcemodel3d8mm']);

% get insides: (5782 new inside; 5219 new outside)
lf = mous_db_getdata('V1001','meg_bfica_leadfield8mm','/project/3011020.09/MEG/');
sourcemodel.inside = lf.newinside;

% assign memory: [parcel | representing voxel | rep. vox.'s power]
roi = 1:330;     % all parcels
voxlist = zeros(numel(roi),3); voxlist(:,1) = roi; 

%  load data 
mous_db_getdata(subjectname,sourcedata,rootdir) 

%  make script flexible to all/target words (vis/aud words)
if regexp(sourcedata,'tar')
  tlcksent  = tlcksenttar;
  tlckseq   = tlckseqtar;
end 

% calculate prestim and poststim 
% use combined conditions vs. bsl to determine max. voxel for each subj
if bslflag 
  % combine conditions (sent+seq)
     % note: ft_math doesn't work because ft_selectdata will sort the output!   
  tmp = tlcksent;
  tmp.avg = tlcksent.avg+tlckseq.avg;  % all values are positive

  % subtract baseline from poststim
  
  cfg = [];
  cfg.latency = [-inf -0.09];
  bsl = ft_selectdata(cfg,tmp);       % prestim (bsl)

  cfg = [];
  cfg.latency = toi;   
  sentseq = ft_selectdata(cfg,tmp);   % poststim 

  dat = sentseq;
  bsl = repmat(bsl.avg,[1,1,size(sentseq.avg,3)]);
  dat.avg = abs(((dat.avg)./bsl)-1);
end 

% average across time and freq
datvoxmean = mean(mean(dat.avg,3),2);

for cntr = 1:numel(roi)
  
  ivox = find(aal.tissue == roi(cntr));   % voxel positions corresponding to parcel 
                                          % values in sourcemodel.inside
                                          % (not indices of sourcemodel.inside)
  
  [iisvox, isourceins] = ismember(ivox,sourcemodel.inside); % which voxels in current parcel are within functional data 
  
  [m,imax] = max(datvoxmean(isourceins));  % get max. voxel: use indexing from sourcemodel.inside 
                                         % as source position = 8889 doesn't fit within 1-5782 source positions) 
  
  voxlist(cntr,2) = sourcemodel.inside(isourceins(imax));  % voxel positions(in current parcel(maximum power))
  voxlist(cntr,3) = m;

end     % end parcel loop

% save
tmp = num2str(toi(1));   tmp2 = num2str(toi(2));  toi2 = [tmp(1), tmp(3), tmp2(1), tmp2(3)];
if bslflag 
  mous_db_putdata(subjectname,[sourcedata,'_bslVSsentseq',toi2],'sentseq','bsl','dat',rootdir,1);
end 

mous_db_putdata(subjectname,[sourcedata,'_voxlist4parcels_330parcels_usingbslVSsentseq',toi2],'voxlist',rootdir,1);

%% check that voxlist is a unique list of voxels 
% i.e. no voxel should belong to >1 parcel
% voxsort = sort(voxlist(:,2));
% voxsort(voxsort == 0) = [];  % remove parcels w/o vox.
% numel(unique(voxsort))

%% notes - code that I might use at a later stage
% % negative values
% find(A==min(A) & A<0)
% % positive values
% find(A==max(A) & A>0)

%% IF contrasts (e.g. sent vs. seq) have been computed
%     then separate between positive and negative voxels (for each condition)
%     tlcksentpos = tlcksent;  tlcksentpos.avg(tlcksentpos.avg < 0) = NaN;
%     tlcksentneg = tlcksent;  tlcksentneg.avg(tlcksentneg.avg > 0) = NaN;
%     
%     tlckseqpos  = tlckseq;   tlckseqpos(tlckseqpos < 0) = NaN;        
%     tlckseqneg  = tlckseq;   tlckseqpos(tlckseqpos > 0) = NaN;
% 
% currvox  = ft_selectdata(cfg,tlckseq);
      
% 
% if currvoxsent.avg > maxvoxsent
%   maxvoxsent = currvoxsent.avg;
%   voxidsent  = ivox(cntv);
% end
% if currvoxseq.avg > maxvoxseq
%   maxvoxseq = currvoxseq.avg;
%   voxidseq  = ivox(cntv);
% end
% voxseq  = zeros(numel(roi),3); voxseq(:,1) = roi;    

%% first try for finding max. voxel

%   for cntv = 1:numel(ivox)              % calc average power for each voxel and find max. voxel
%       if cntv == 1
%         maxvox = 0;
%         voxid  = 0;
%       end 
%       if ismember(ivox(cntv),sourcemodel.inside)  % only if voxel is within sourcemodel.inside (5782/11000)
%         cfg = [];
%         cfg.foilim  = [min(dat.freq) max(dat.freq)];
%         cfg.latency = toi;
%         cfg.channel = ivox(cntv);
%         cfg.avgoverfreq = 'yes';
%         cfg.avgovertime = 'yes';
%         currvox = ft_selectdata(cfg,dat);
% 
%         if currvox.avg > maxvox           % get max. voxel within parcel
%           maxvox = currvox.avg;
%           voxid  = ivox(cntv);
%         end 
%       end 
%   end % end voxel loop
%   
%   if exist('voxid','var') && cntv == numel(ivox)
%     voxlist(cntr,2) = voxid; voxlist(cntr,3) = maxvox;  % store max. voxel; 0 = no voxels
%   end 
%   



