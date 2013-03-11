function [source] = mous_bfica_sourceinterpolate(subjectname, fieldname, inside, range, resolution)

if nargin<2
  fieldname = 'topo';
end

if nargin<3
  inside = [];
end

if nargin<4,
  range = [];
end

if nargin<5
  resolution = 8;
end

if ischar(subjectname)
  comp = mous_db_getdata(subjectname, 'meg_processed_{bfICA_ica}');
else
  comp = subjectname;
end

%load('/home/language/jansch/matlab/fieldtrip/template/sourcemodel/standard_sourcemodel3d10mm');
[p,f,e] = fileparts(which('mous_anatomy_sourcemodel3D'));
fname   = fullfile(p(1:end-18), 'templates', 'sourcemodel', ['standard_sourcemodel3d',num2str(resolution),'mm.mat']);
load(fname);


if ~isempty(range)
  comp.(fieldname) = mean(comp.(fieldname)(:,range),2);
  comp.time        = mean(comp.time(range));
  
  source = mous_bfica_sourceinterpolate(comp, fieldname, inside);
  return;
end


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
  inside = sourcemodel.inside;
end

cfgi = [];
cfgi.parameter  = 'avg.pow';
cfgi.downsample = 2;

sourcemodel.avg.pow = zeros(prod(sourcemodel.dim),1);
mri          = ft_read_mri('/home/language/jansch/matlab/mri/templateMRI.nii');
if ndims(comp.(fieldname))==2
  for k = 1:size(comp.(fieldname),2)
    try
      sourcemodel.avg.pow(inside) = comp.(fieldname)(:,k);
    catch
      try
        sourcemodel.avg.pow(:) = comp.(fieldname)(:,k);
      catch
        sourcemodel.avg.pow(:) = comp.(fieldname)(:);
      end
    end
    %sourcemodel.avg.pow(sourcemodel.inside) = comp.corrmap(:,k);
    source(k) = ft_sourceinterpolate(cfgi, sourcemodel, mri);
  end
else
  sourcemodel.avg.pow(:) = comp.(fieldname)(:);
  source          = ft_sourceinterpolate(cfgi, sourcemodel, mri);
end


