function [bndinflated] = mous_inflatedmesh(subjectname)

% MOUS_INFLATEDMESH returns the inflated mesh of a named subject.
%
% Use as
%   bndinflated = mous_inflatedmesh(subjectname)

fiffile = mous_db_getfilename(subjectname, 'meg_anatomy_sourcemodelfif');
fiffile = fiffile{1};

% assume p to end with 'bem'
[p,n,e] = fileparts(fiffile);

bnd     = ft_read_headshape(fiffile, 'format', 'mne_source');

surfdir = [p(1:end-3),'surf'];
fnames  = {fullfile(surfdir,'lh.inflated');
          fullfile(surfdir,'rh.inflated')};
bndinflated  = ft_read_headshape(fnames);

sel             = bnd.orig.inuse~=0;
bndinflated.pnt = bndinflated.pnt(sel,:);
bndinflated.tri = bnd.tri;
if isfield(bndinflated, 'sulc')
  bndinflated.sulc = bndinflated.sulc(sel,:);
end
if isfield(bndinflated, 'curv')
  bndinflated.curv = bndinflated.curv(sel,:);
end
if isfield(bndinflated, 'hemisphere')
  bndinflated.hemisphere = bndinflated.hemisphere(sel,:);
end
if isfield(bndinflated, 'thickness')
  bndinflated.thickness = bndinflated.thickness(sel,:);
end
if isfield(bndinflated, 'area')
  bndinflated = rmfield(bndinflated, 'area');
end

bndinflated.pos = bndinflated.pnt;
bndinflated     = rmfield(bndinflated, 'pnt');

