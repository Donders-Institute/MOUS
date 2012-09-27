function [source] = mous_bfica_sourceinterpolate(subjectname)

comp       = mous_db_getdata(subjectname, 'meg_processed_{bfICA_ica}');

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


cfgi = [];
cfgi.parameter  = 'avg.pow';
cfgi.downsample = 2;

grid.avg.pow = zeros(prod(grid.dim),1);
mri          = ft_read_mri('/home/language/jansch/matlab/mri/templateMRI.nii');
for k = 1:size(comp.topo,2)
  grid.avg.pow(grid.inside) = comp.topo(:,k);
  source(k) = ft_sourceinterpolate(cfgi, grid, mri);
end


