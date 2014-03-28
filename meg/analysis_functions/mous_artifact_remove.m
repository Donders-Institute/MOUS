function [trlclean] = mous_artifact_remove(trl, filename, artifactcfg, method, minlength)

% MOUS_ARTIFACT_REMOVE removes epochs with artifacts from the input trial
% definition. 
% 
% Use as
%   trlclean = mous_artifact_remove(trl, filename, artifactcfg, method, minlength)
%
% Input arguments:
%   trl = a Nx3 matrix (can have more columns) that specifies the original
%     epochs.
%   filename = string that refers to the dataset from which the original
%     trl was obtained (needed because the data header has to be read to get
%     the sampling rate.
%   artifactcfg = a cell-array of cfg structures containing artifact
%     definitions
%   method   = 'partial', or 'complete', pertaining to whether the whole
%     epoch is rejected once it is contaminated, or whether the artifact is
%     cut out. If not specified, the default is partial.
%   minlength =   minimum length  in seconds of remaining trial (default = 0.1)
% 
%
% Output arguments:
%   trlclean = the updated matrix specifying the epochs containing clean
%     data.

% NL 31-5-2012.  Removes artifacts
% add optionality for: (1) partial / complete rejection  (2) focus on targets (or other elements)

if nargin<4
  method = 'partial';
end

if nargin<5
  minlength = 0.1;
end

cfg         = [];
cfg.trl     = trl;
cfg.dataset = filename;
for k = 1:numel(artifactcfg)
  type = artifactcfg{k}.artfctdef.type;
  if strcmp(type, 'zvalue')
    % there may be more of those
    cfg = setsubfield(cfg, ['artfctdef.zvalue',num2str(k),'.artifact'], artifactcfg{k}.artfctdef.zvalue.artifact);
    
    % clunky way of doing it, can be improved
    %eval(['cfg.artfctdef.zvalue',num2str(k),'.artifact = artifactcfg{',num2str(k)','}.artfctdef.zvalue.artifact']);
  else
    % assume this type name to be unique
    cfg = setsubfield(cfg, ['artfctdef.',type,'.artifact'], artifactcfg{k}.artfctdef.(type).artifact);
  end
end
cfg.artfctdef.reject       = method;
cfg.artfctdef.minaccepttim = minlength;
cfg         = ft_rejectartifact(cfg);
trlclean    = cfg.trl;

