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
fname = fullfile(p(1:end-18), 'templates', 'sourcemodel', ['standard_sourcemodel3d',num2str(resolution),'mm.mat']);
load(fname);


if ~isempty(range)
  tmp = getsubfield(comp, fieldname);
  
  % tmp can be posxfreqxtime or posxtime or posxfreq. in case it is 3D
  % require range to be a cell-array, where the first cell selects
  % frequencies, and the second cell selects time points
  if ndims(tmp)==3 && size(tmp,1) == 11000
    if ~iscell(range), error('the input argument range should be a cell-array'); end
    comp = setsubfield(comp, fieldname, nanmean(nanmean(tmp(:,range{1},range{2}),3),2));
    comp.time = mean(comp.time(range{2}));
    comp.freq = mean(comp.freq(range{1}));
  elseif ndims(tmp) == 2 && size(tmp,1) == 11000 % 2D 
    % comp = setsubfield(comp,mean(tmp(:,range),2),fieldname); % inarg in wrong order
    comp = setsubfield(comp, fieldname, mean(tmp(:,range),2));
    if numel(comp.time) >1 % not necessary if data is posxfreq (only if posxtime)
      comp.time = mean(comp.time(range));
    end
  end
  
  source = mous_bfica_sourceinterpolate(comp, fieldname, inside);
  return;
end


% % demean
% dat = cat(2,data.trial{:});
% mdat = mean(dat,2);
% for k = 1:size(dat,2)
% dat(:,k) = dat(:,k) - mdat;
% end
% vdat = sum(dat.^2,2);
%
% % create correlation maps
% C = zeros(size(comp.topo));
% for k = 1:Ncomp
% cdat = comp.unmixing(k,:)*dat;
% cdat = cdat - mean(cdat);
% cdat = cdat./norm(cdat);
% C(:,k) = (dat*cdat')./sqrt(vdat);
% end

if isempty(inside)
  inside = sourcemodel.inside;      
end

cfgi = [];
cfgi.parameter = 'avg.pow';
cfgi.downsample = 2;

sourcemodel.avg.pow = zeros(prod(sourcemodel.dim),1);
mri = ft_read_mri(which('templateMRI.nii'));
tmp = getsubfield(comp, fieldname);
if ndims(tmp)==2
  for k = 1:size(tmp,2)
    try
      sourcemodel.avg.pow(inside) = tmp(:,k);
    catch
      try
        sourcemodel.avg.pow(:) = tmp(:,k);
      catch
        sourcemodel.avg.pow(:) = tmp(:);
      end
    end
    %sourcemodel.avg.pow(sourcemodel.inside) = comp.corrmap(:,k);
    source(k) = ft_sourceinterpolate(cfgi, sourcemodel, mri);
  end
%elseif % FIXME: make it work for 3D array: ndims(tmp)==3
elseif ndims(tmp) == 3 && size(tmp,1) == 11000
  for k = 1:size(tmp,3)
    % sourcemodel.avg.pow = 11000 x 1
    % tmp  = 11000 x 16 x 14 
    sourcemodel.avg.pow(:) = tmp(:,:,k);
    source(k) = ft_sourceinterpolate(cfgi,sourcemodel,mri);
  end
else 
  sourcemodel.avg.pow(:) = tmp(:);
  source = ft_sourceinterpolate(cfgi, sourcemodel, mri);
end
source.coordsys = 'spm';