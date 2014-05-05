function [tlck] = mous_bfica_parcellate(sourcemodel, tlck, inside)

% create parcels from the regular 8mm grid
% each parcel is an averaged power estimate from the grid points that fall
% into that parcel, according to the 
% standard_sourcemodel3d8mm_parcellated_aal_sub.mat file

% source  = sourcemodel for type of parcellation to be used
% tlck    = timelock structure of source level estimates based on Xmm grid
% inside  = grid points that are inside the brain (data of interest)
%           this needs to be specified (for MOUS) which has inside 
%           of 5782 (newinside) instead of the original 5798 (oldinside)

% create memory
% freqlow/med/high have diff number of time points and frequency points
tmpavg = zeros(11000,size(tlck.avg,2),size(tlck.avg,3));

% assign points within brain to tmp 
tmpavg(inside,:,:) = tlck.avg;
% tmpvar(inside,:,:) = tlck.var;

% average across points
for k = 1:330
  sel=find(sourcemodel.tissue(:)==k);  % locate grid points belonging to parcel
  if ~isempty(sel)
  tmpnewavg(k,:,:)=nanmean(tmpavg(sel,:,:),1);  % average across points
%   tmpnewvar(k,:,:)=nanmean(tmpvar(sel,:,:),1);
  end
end


% create frequency data structure for subsequent statistical analysis
% i.e. sensor level data (.pos .dim .inside..don't matter here)

tlck.powspctrm = tmpnewavg;
tlck.label = sourcemodel.tissuelabel;
tlck = rmfield(tlck,'avg');
tlck = rmfield(tlck,'var');
tlck = rmfield(tlck,'dof');
% tlck.grad.sens = sourcemodel.pos_center; 
% tlck.grad.label = sourcemodel.tissuelabel;





