function mous_bfica_maxvoxel(subj,sourcedata,roi,toi,rootdir)

% this function works with source-level data
% the voxels belonging to each parcel are identified
% Within each parcel the voxel with the maximum power will be selected
% the parcellation for MOUS is done using the AAL template with 330 parcels
% inspired by Hilllebrand et al. 2012 (atlas-based beamformer)
% NL 

if nargin < 2
  error('specify a dataset to correlate between subjects') 
end 

if nargin < 3
  sourcedata = 'meg_bfica_sourcedatasentseq_high';
  warning('selecting parcels for %s by default, for correlation',sourcedata) 
end 

if nargin < 4
  warning('selecting and averaging across 0.2 - 0.5s') 
  toi = [0.2 0.5];
end 

if nargin < 5 
  error('specify a foi') 
end

if nargin < 6
  rootdir = '/project/3011020.09/MEG/'; 
end 

% load aal template
load('/home/language/nielam/MOUS/meg/templates/sourcemodel/standard_sourcemodel3d8mm_parcellated_aal_sub');
aal = sourcemodel;

% load regular sourcemodel (3d8mm)
[p,n,e] = fileparts(which('mous_anatomy_sourcemodel3D'));
load([p(1:end-18),'templates/sourcemodel/standard_sourcemodel3d8mm']);

% get insides
lf = mous_db_getdata('V1001','meg_bfica_leadfield8mm','/project/3011020.09/MEG/');


for cntr = 1:numel(roi)
    mous_db_getdata(subj,sourcedata,rootdir)
       
    % find number of voxels in current parcel (roi)
    ivox = find(aal.tissue == roi(cntr));
    
    % assign memory for list [parcel | representing voxel | rep. vox power]
    voxsent = zeros(numel(roi),3); voxsent(:,1) = roi;
    voxseq  = zeros(numel(roi),3); voxseq(:,1) = roi;    

    % calculate power for each voxel and find max
    % *** should i try doing this first for sent+seq combined? ***
    % *** baseline?**
    
    maxvoxsent = 0;  maxvoxseq = 0;
    for cntv = 1:numel(ivox)
         
      cfg = [];
      cfg.foilim  = [min(tlcksent.freq) max(tlcksent.freq)];
      cfg.latency = toi;
      cfg.channel = ivox(cntv);
%       cfg.avgoverfreq = 'yes';
%       cfg.avgovertime = 'yes';     
      currvoxsent = ft_selectdata(cfg,tlcksent); %% NOT SELECTING!
      currvoxseq  = ft_selectdata(cfg,tlckseq);
      
      if currvoxsent.avg > maxvoxsent
        maxvoxsent = currvoxsent.avg;
        voxidsent  = ivox(cntv);
      end
      if currvoxseq.avg > maxvoxseq
        maxvoxseq = currvoxseq.avg;
        voxidseq  = ivox(cntv);
      end
    end   % end voxel loop

    % store max. voxel for each parcel
    voxsent(cntr,2) = voxidsent; voxsent(cntr,3) = maxvoxsent;
    voxseq(cntr,2)  = voxidseq;  voxseq(cntr,3)  = maxvoxseq;  
   

end % end parcel(roi) loop  
mous_db_putdata(subj,[sourcedata,'_vox4par_330parcels'],'sentvox','seqvox',rootdir,0);

% notes

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




