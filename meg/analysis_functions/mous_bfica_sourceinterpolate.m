function [source] = mous_bfica_sourceinterpolate(subjectname, fieldname, inside)

if nargin<2
  fieldname = 'topo';
end

if nargin<3
  inside = [];
end

if ischar(subjectname)
  comp = mous_db_getdata(subjectname, 'meg_processed_{bfICA_ica}');
else
  comp = subjectname;
end

load('/home/language/jansch/matlab/fieldtrip/template/sourcemodel/standard_grid3d10mm');

% % demean
% dat  = cat(2,data.trial{:});
% mdat = mean(dat,2);
% for k = 1:size(dat,2)
%   dat(:,k) = dat(:,k) - mdat;
% end
% vdat = sum(dat.^2,2);
% 
% % create correlation maps
% C = zeros(size(comp.topo));
% for k = 1:Ncomp
%   cdat = comp.unmixing(k,:)*dat;
%   cdat = cdat - mean(cdat);
%   cdat = cdat./norm(cdat);
%   C(:,k) = (dat*cdat')./sqrt(vdat);
% end

if isempty(inside)
  inside = grid.inside;
end

cfgi = [];
cfgi.parameter  = 'avg.pow';
cfgi.downsample = 2;

grid.avg.pow = zeros(prod(grid.dim),1);
mri          = ft_read_mri('/home/language/jansch/matlab/mri/templateMRI.nii');
for k = 1:size(comp.(fieldname),2)
  try
    grid.avg.pow(inside) = comp.(fieldname)(:,k);
  catch
    grid.avg.pow(:) = comp.(fieldname)(:,k);
  end
  %grid.avg.pow(grid.inside) = comp.corrmap(:,k);
  source(k) = ft_sourceinterpolate(cfgi, grid, mri);
end



