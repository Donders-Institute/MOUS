function varargout = mous_genetics_sel_statistics(subjects, geneticsinfo, suffix, grouping, cfg, selft)

% MOUS_GENETICS_SEL_STATISTICS does a statistical comparison across 2 groups of
% participants based on their genetic make up.
% "SEL": Data is manipulated (selected) prior to statistics. 
%
% Use as
%  stat = mous_genetics_statistics(subjects, geneticsinfo, suffix, grouping, cfg)
%
% Input parameters
%  subjects     = cell-array, list of subjects to be used
%  geneticsinfo = struct-array with fields 'name' Axxxx/Vyyyy and 'genotype'
%  suffix       = string or 2-element cell-array that contains info as to which data to load
%  grouping     = define groups being tested against each other;
%                 2-element cell-array that defines the genotype
%  cfg          = cfg-structure for the statistics function, required
%                 field: 'parameter'

%% create groups for contrast
if numel(grouping)~=2,
  error('number of groups different from 2 is not allowed');
end

sel = cell(1,2);
for k = 1:numel(grouping)
  if iscell(grouping{k})
    sel{k} = zeros(0,1);
    for m = 1:numel(grouping{k})
      sel{k} = [sel{k}; find(strcmpi({geneticsinfo.genotype}', grouping{k}{m}))];
    end
  else
    sel{k} = find(strcmpi({geneticsinfo.genotype}', grouping{k}));  % use strcmpi, because there's 'Allele X', and 'allele X';
  end
end

group{1} = intersect(subjects, {geneticsinfo(sel{1}).name}');
group{2} = intersect(subjects, {geneticsinfo(sel{2}).name}');


%% create contrasts 
if ~iscell(suffix)
  suffix = {suffix};
end

if numel(suffix)>2, error('more than two conditions in the input is not allowed'); end
dat = cell(2,numel(suffix));
for j = 1:2
  for k = 1:numel(group{j})
    for m = 1:numel(suffix)
      
      % load the data
      tmp = mous_db_getdata(group{j}{k},suffix{m});
      
      % modify the data (select frequency, do contrast 'late-early')
      if nargin == 6
        
        if m == 1 && k == 1 && j == 1
        % load sourcemodel
        [p,n,e] = fileparts(which('mous_anatomy_sourcemodel3D'));
        load([p(1:end-18),'templates/sourcemodel/standard_sourcemodel3d8mm']);
        sourcemodeltemplate = sourcemodel;
        
       
          mous_db_getdata(group{m},'meg_bfica_leadfield8mm', '/project/3011020.09/MEG/');
          sourcemodel = rmfield(sourcemodel,'leadfield');
          if isfield(sourcemodel, 'cfg')
            sourcemodel = rmfield(sourcemodel,'cfg');
          end
        end
        
        %% poststim selection
        cfgs = [];
        cfgs.frequency = selft.freq;
        cfgs.latency   = selft.toi; 
        tlckearly      = ft_selectdata(cfgs, tmp.tlckearly);
        tlcklate       = ft_selectdata(cfgs, tmp.tlcklate);
        
        %% baseline subtraction
%         bsltoi   = [-inf -0.09];
%         bslearly = ft_selectdata(tlckearly, 'toilim',bsltoi);
%         bsllate  = ft_selectdata(tlcklate, 'toilim',bsltoi);
%         
%         bslearly = nanmean(bslearly.avg,2); bsllate = nanmean(bsllate.avg,2);
%         bslcom   = (bslearly+bsllate)/2;
        
        %% modify data structure for statistics & calculate late-early for each group
        tmp            = tlckearly;
        tmp.dimord     = 'pos_time';
        tmp            = copyfields(sourcemodel,tmp,{'inside','outside','pos','dim','unit'});
        tmp            = rmfield(tmp,{'dof','label','cfg','var','avg'});
        tmpdat         = squeeze(tlcklate.avg-tlckearly.avg);
        if exist('bslcom','var')
          tmpdat         = tmpdat - repmat(bslcom,1,size(tmpdat,2));
        end 
        
        % situate insides voxels in box
        % select  inside voxels of interest for ROI-analysis using 
        % atlas_conte69_8196reg_LR_brodmann_subparc.mat
        %% IK BEN HIER
        tmp.pow              = zeros(prod(tmp.dim),numel(tmp.time));
        tmp.pow(newinside,:) = tmpdat; 
        
      end 
          
      % do some checks and remove some fields
      if isfield(tmp, 'mu'),            tmp     = tmp.stat;                   end
      if isfield(tmp, 'cfg'),           tmp     = rmfield(tmp, 'cfg');        end
      if issubfield(tmp, 'avg.filter'), tmp.avg = rmfield(tmp.avg, 'filter'); end
      
      dat{j,m}{k} = tmp;
      
      % do some checks and replace some fields
      if isfield(dat{j,m}{k}, 'pos'), dat{j,m}{k}.pos = dat{1,1}{1}.pos; end
      
    end % subjects
  end % conditions
end % groups

% call selectdata to ensure the dimensions (and orders) to match
str = makevarargoutstring('ft_selectdata', 'dat{1,1}', numel(dat{1,1}));
eval(str);
str = makevarargoutstring('ft_selectdata', 'dat{2,1}', numel(dat{2,1}));
eval(str);
if size(dat,2)>1
  str = makevarargoutstring('ft_selectdata', 'dat{1,2}', numel(dat{1,2}));
  eval(str);
  str = makevarargoutstring('ft_selectdata', 'dat{2,2}', numel(dat{2,2}));
  eval(str);
end

% create the averages per group / condition
avg = cell(size(dat));
for j = 1:size(dat,1)         % each group
  for k = 1:size(dat,2) 
    for m = 1:numel(dat{j,k}) % subj in each group
      if m==1
        avg{j,k} = dat{j,k}{m}.(cfg.parameter);
      else
        avg{j,k} = dat{j,k}{m}.(cfg.parameter) + avg{j,k};
      end
    end
    avg{j,k} = avg{j,k}./m;
  end
end

% make the subtraction across conditions if needed
if size(dat,2)>1
  for j = 1:size(dat,1)
    for k = 1:numel(dat{j,1})
      dat{j,1}{k}.(cfg.parameter) = dat{j,1}{k}.(cfg.parameter) - dat{j,2}{k}.(cfg.parameter);
    end
  end
end
dat = dat(:,1);

% do the statistical comparison
N1 = numel(group{1});
N2 = numel(group{2});


cfg.method    = ft_getopt(cfg, 'method',    'montecarlo');
cfg.statistic = ft_getopt(cfg, 'statistic', 'indepsamplesT');
cfg.design    = [ones(1,N1) ones(1,N2)*2];
cfg.ivar      = 1;
cfg.numrandomization = ft_getopt(cfg, 'numrandomization', 0);
if isfield(dat{1,1}{1}, 'pos')
  stat          = ft_sourcestatistics(cfg, dat{1}{:}, dat{2}{:});
else
  stat          = ft_timelockstatistics(cfg, dat{1}{:}, dat{2}{:});
end

switch nargout
  case 1
    varargout{1} = stat;
  case 2
    varargout{1} = stat;
    varargout{2} = avg(:,1);
  case 3
    varargout{1} = stat;
    varargout{2} = avg(:,1);
    if numel(suffix)>1
      varargout{3} = avg(:,2);
    else
      varargout{3} = nan;
    end
end

function str = makevarargoutstring(functionname, varname, n)

str = '[';
for k = 1:n
  str = [str,varname,'{',num2str(k),'},'];
end
str = str(1:end-1);
str = [str,']=',functionname,'([],'];
for k = 1:n
  str = [str,varname,'{',num2str(k),'},'];
end
str = str(1:end-1);
str = [str,');'];

