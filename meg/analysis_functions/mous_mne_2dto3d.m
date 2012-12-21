function source3d = mous_mne_2dto3d(subjectname, source2d, varargin)

% MOUS_MNE_2DTO3D interpolates mne results (computed on the cortical sheet)
% onto a 3D regular grid that can be easily used for group statistics a la
% FieldTrip, or interpolated to another 2D sheet.
%
% Input arguments:
%   subjectname = string, name of the subject (needed to interface with
%     database)
%   source2d    = source-structure with MNE results. Should contain the
%     triangulation of the UNINFLATED sheet.
%   
%
% Output arguments:
%   source3d    = source-structure with MNE results, interpolated onto a
%     3D-grid. Coordinate system is according to the MNI template.

resolution   = ft_getopt(varargin, 'resolution',   5);
insidemethod = ft_getopt(varargin, 'insidemethod', 'target');

% create individual 3D grid based on the MNI-template with specified
% resolution.
[p,f,e] = fileparts(which('mous_mne_2dto3d'));
fname   = fullfile(p(1:end-18), 'templates', 'sourcemodel', 'standard_sourcemodel3d5mm.mat');
load(fname);
template = sourcemodel;

cfg     = [];
cfg.mri = mous_db_getdata(subjectname, 'meg_anatomy_coregCTF'); 
cfg.mri.coordsys   = 'ctf';
cfg.grid.warpmni   = 'yes';
cfg.grid.template  = template;
cfg.grid.nonlinear = 'yes';
target  = ft_prepare_sourcemodel(cfg);

cfg              = [];
cfg.parameter    = ft_getopt(varargin, 'parameter', 'avg.pow');
cfg.interpmethod = ft_getopt(varargin, 'interpmethod', 'sphere_avg');
cfg.sphereradius = ft_getopt(varargin, 'sphereradius', 1);
source3d         = ft_sourceinterpolate(cfg, source2d, target);
 
source3d.pos      = template.pos;
source3d.coordsys = 'spm';
try,
  source3d.cfg.previous{2} = rmfield(source3d.cfg.previous{2}, 'mri');
end

% update the inside according to the original positions, rather than taking
% all 3D positions as inside
if strcmp(insidemethod, 'source')
  d = ft_getopt(varargin, 'insidedistance', 1);

  pos1 = target.pos;   n1 = size(pos1,1);
  pos2 = source2d.pos; n2 = size(pos2,1);
  
  inside = false(n1,1);
  for k = 1:n2
    dpos   = pos1 - ones(n1,1)*pos2(k,:);
    inside = inside | sqrt(sum(dpos.^2,2))<d;  
  end
  inside(source3d.outside) = false;
  
  source3d.inside  = find(inside);
  source3d.outside = find(inside==0);
end
