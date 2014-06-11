function mous_bfica_maxvoxel(subj,sourcedata,toi,bslflag,rootdir)

% this function works with source-level data
% the voxels belonging to each parcel are identified
% Within each parcel the voxel with the maximum power will be selected
% the parcellation for MOUS is done using the AAL template with 330 parcels
% inspired by Hilllebrand et al. 2012 (atlas-based beamformer)
% Note not all parcels belong within the functional data, therefore some
% parcels will not have a representing maximum voxel.
% NL 

if nargin < 1
  error('specify a dataset to correlate between subjects') 
end 

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
% [p,n,e] = fileparts(which('mous_anatomy_sourcemodel3D'));
% load([p(1:end-18),'templates/sourcemodel/standard_sourcemodel3d8mm']);

% get insides: (5782 new inside; 5219 new outside)
% lf = mous_db_getdata('V1001','meg_bfica_leadfield8mm','/project/3011020.09/MEG/');

% assign memory: [parcel | representing voxel | rep. vox power]
roi = 1:330;     % all parcels
voxlist = zeros(numel(roi),3); voxlist(:,1) = roi; 

mous_db_getdata(subj,sourcedata,rootdir) %  load data 

% calculate prestim and poststim 
% use combined conditions vs. bsl to determine max. voxel for each subj
if bslflag 
  cfg = [];
  cfg.operation = 'add';
  cfg.parameter = 'avg';
  tmp = ft_math(cfg,tlcksent,tlckseq);% combine conditions

  cfg = [];
  if ~regexp(sourcedata, 'low')
    cfg.latency = [-0.15 -0.1];
  elseif regexp(sourcedata,'low')
    cfg.latency = [-0.1 -0.1];
  end
  bsl = ft_selectdata(cfg,tmp);       % prestim (bsl)

  cfg = [];
  cfg.latency = toi;   
  sentseq = ft_selectdata(cfg,tmp);   % poststim 

  dat = sentseq;
  dat.avg = sentseq.avg - repmat(bsl.avg,[1,1,size(sentseq.avg,3)]);      
end 

for cntr = 1:numel(roi)
  ivox = find(aal.tissue == roi(cntr)); % find number of voxels in current parcel (roi)

  for cntv = 1:numel(ivox)            % calc power for each voxel and find max. voxel
      if cntv == 1
        maxvox = 0;
        voxid  = 0;
      end 
      if ivox(cntv) < 5783            % only if voxel is within sourcemodel.inside
        cfg = [];
        cfg.foilim  = [min(dat.freq) max(dat.freq)];
        cfg.latency = toi;
        cfg.channel = ivox(cntv);
        cfg.avgoverfreq = 'yes';
        cfg.avgovertime = 'yes';
        currvox = ft_selectdata(cfg,dat);

        if currvox.avg > maxvox           % get max. voxel within parcel
          maxvox = currvox.avg;
          voxid  = ivox(cntv);
        end 
      end 
  end % end voxel loop
  
  if exist('voxid','var') && cntv == numel(ivox)
    voxlist(cntr,2) = voxid; voxlist(cntr,3) = maxvox;  % store max. voxel; 0 = no voxels
  end 
  
end     % end parcel loop

if bslflag 
  tmp = num2str(toi(1));   tmp2 = num2str(toi(2));  toi2 = [tmp(1), tmp(3), tmp2(1), tmp2(3)];
  mous_db_putdata(subj,[sourcedata(1:20),'_bslVSsentseq',toi2],'sentseq','bsl','dat',rootdir,1);
end 

mous_db_putdata(subj,[sourcedata(1:20),'_voxlist4parcels_330parcels_usingbslVSsentseq',toi2],'voxlist',rootdir,1);

%% check that voxlist is a unique list of voxels 
% i.e. no voxel should belong to >1 parcel
% voxsort = sort(voxlist(:,2));
% voxsort(voxsort == 0) = [];  % remove parcels w/o vox.
% numel(unique(voxsort));

%% notes - code that I might use at a later stage
% % negative values
% find(A==min(A) & A<0)
% % positive values
% find(A==max(A) & A>0)


%     IF contrasts have been computed
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



