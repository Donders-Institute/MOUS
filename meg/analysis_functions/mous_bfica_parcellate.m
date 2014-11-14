function [tlck] = mous_bfica_parcellate(sourcemodel, tlck, inside, varargin)

% MOUS_BFICA_PARCELLATE parcellates a source-level TFR.
%
% Use as
%
% [output] = mous_bfica_parcellate(sourcemodel, tlck, inside)
%
%
% [output] = mous_bfica_parcellate(sourcemodel, tlck, inside, varargin)
%
% Input arguments
%   sourcemodel = struct, defining the volumetric source space onto which
%                   the functional data is defined.
%   tlck        = struct that contains the functional data, as a 'tlck' type
%                   of structure, only defined on the inside voxels.
%   inside      = vector that indexes the 'inside' voxels into the full source
%                   space
%
% Further arguments come as key-value pairs:
%
%   method = string, 'volume'(default) or 'surface'. If volume, the old
%            implementation is applied, using a volumetric parcellation
%            that should be defined in the sourcemodel.
%            If using 'surface', an interpolation onto a cortical sheet is
%            performed using workbench, and a separate parcellation should
%            be defined. When using 'surface', note that the sourcemodel
%            and the cortical sheet need to be in the same space.
%   filename = the filename that is used for saving the result (only used
%              in the 'surface' method
%   labelfile = the filename that points to a cifti.dlabel file that
%               defines the parcellation.

method = ft_getopt(varargin, 'method', 'volume');
switch method
  case 'volume'
    
    % create parcels from the regular 8mm grid
    % each parcel is an averaged power estimate from the grid points that fall
    % into that parcel, according to the
    % standard_sourcemodel3d8mm_parcellated_aal_sub.mat file
    
    % source  = sourcemodel for type of parcellation to be used
    % tlck    = timelock structure of source level estimates based on Xmm grid
    % inside  = grid points that are inside the brain (data of interest)
    %           this needs to be specified (for MOUS) which has inside
    %           of 5782 (newinside) instead of the original 5798 (oldinside)
    
    % pre-allocate memory
    % freqlow/med/high have diff number of time points and frequency points
    tmpavg = zeros(size(sourcemodel.pos,1),size(tlck.avg,2),size(tlck.avg,3));
    
    % assign points within brain to tmp
    tmpavg(inside,:,:) = tlck.avg;
    % tmpvar(inside,:,:) = tlck.var;
    
    % average across points
    for k = 1:max(sourcemodel.tissue(:))
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
    
  case 'surface'
    p   = fileparts(which('mous_bfica_parcellate'));  % location of atlas depends on user
    labelfile = ft_getopt(varargin, 'labelfile', fullfile(p(1:end-18),'templates','atlas_subparc.dlabel.nii'));
    if isfield(tlck, 'freq')
      frequency = ft_getopt(varargin, 'frequency', tlck.freq([1 end]));
    else
      frequency = nan;
    end
    filename  = ft_getopt(varargin, 'filename');
%     labelfile = ft_getopt(varargin, 'labelfile', '/home/language/jansch/projects/mous/meg/templates/atlas_subparc.dlabel.nii');
    scale     = ft_getopt(varargin, 'scale', 1); % scaling. NOTE: if ~=1 this needs to be the same for all subjects when later statistics are planned, use with extreme care
    if isempty(filename)
      error('the input should contain a filename');
    end
    
    % select the frequency range
    if numel(frequency)==1 && ~isfinite(frequency)
      % don't do anything but scaling
      tlck.avg = tlck.avg.*scale;
    elseif numel(frequency)==1
      findx    = nearest(tlck.freq, frequency);
      tlck.avg = squeeze(tlck.avg(:,findx,:)).*scale;
    else
      findx1   = nearest(tlck.freq, frequency(1));
      findx2   = nearest(tlck.freq, frequency(2));
      tlck.avg = squeeze(mean(tlck.avg(:,findx1:findx2,:),2)).*scale;
    end
    try, tlck = rmfield(tlck, 'freq'); end
    
    % 'map' the data onto the inside voxels
    try, sourcemodel = rmfield(sourcemodel, {'xgrid' 'ygrid' 'zgrid'}); end
    sourcemodel.pow = zeros(size(sourcemodel.pos,1), numel(tlck.time));
    sourcemodel.pow(inside,:) = tlck.avg;
    
    % ensure correct units
    sourcemodel = ft_convert_units(sourcemodel, 'mm');
    
    % do the interpolation to the cortical sheet using workbench
    ciftiname = mous_mne_3dto2d(sourcemodel, 'filename', filename, 'method', 'wb', 'parameter', 'pow');
    ciftiname2 = strrep(ciftiname, 'dtseries', 'ptseries');
    
    % and do the parcellation using workbench
    wbpath = '/project/3011020.09/workbench/bin_rh_linux64';
    system(sprintf('%s/wb_command -cifti-parcellate %s %s COLUMN %s', wbpath, ciftiname, labelfile, ciftiname2));
    tlck = ciftiname2;
    
end



