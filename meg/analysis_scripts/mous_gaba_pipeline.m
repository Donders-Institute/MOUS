rootdir = '/home/language/jansch/public/mous';

load(fullfile(rootdir,'misc','GABAdata'));

[f,s]   = mous_db_getfilename('all', 'subjectname');
[f2,s2] = mous_db_getfilename(f, 'meg_bfica_sourcedatasentseq70', 0, rootdir);

subjmeg = f(s2);

% match the GABA data with the functional data
[i1,i2] = match_str(subj, subjmeg);
subjmeg = subjmeg(i2);
subj    = subj(i1);
data    = data(i1,:);
Nsubj   = numel(subj);

load('/home/language/jansch/matlab/fieldtrip/template/sourcemodel/standard_grid3d10mm');
for k = 1:Nsubj
  clear tlcksent tlckseq
  mous_db_getdata(subj{k}, 'meg_bfica_sourcedatasentseq70', rootdir);
  mous_db_getdata(subj{k}, 'meg_bfica_source',            rootdir);
  
  source.time = tlckseq.time;
  source      = rmfield(source, 'freq');
  %source.avg.pow = tlckseq.avg;
  source.avg.pow = log10(tlckseq.avg);% ./ repmat(Bseq, [1 numel(tlckseq.time)]);
  
  seq{k}      = source;
  %source.avg.pow = tlcksent.avg;
  source.avg.pow = log10(tlcksent.avg);% ./ repmat(Bsent, [1 numel(tlcksent.time)]);
  
  sent{k}     = source;
end

for k = 1:Nsubj
  globalpow = mean(seq{k}.avg.pow(:)+sent{k}.avg.pow(:))./2;
  %globalpow = 0;
  seq{k}.avg.pow  = seq{k}.avg.pow  - globalpow;
  sent{k}.avg.pow = sent{k}.avg.pow - globalpow;
  seq{k}.pos  = grid.pos;
  sent{k}.pos = grid.pos;
end

% the pow is only defined on the insides, ft_sourcestatistics expects all
% voxels
for k = 1:Nsubj
  tmp1 = zeros(prod(seq{k}.dim),numel(seq{k}.time));
  tmp1(seq{k}.inside,:) = seq{k}.avg.pow;
  tmp2 = zeros(prod(sent{k}.dim),numel(sent{k}.time));
  tmp2(sent{k}.inside,:) = sent{k}.avg.pow;
  
  seq{k}.avg.pow  = (tmp1);% - repmat(mean((tmp1),1), [size(tmp1,1) 1]);
  sent{k}.avg.pow = (tmp2);% - repmat(mean((tmp2),1), [size(tmp1,1) 1]);
end

for k = 1:Nsubj
  % make contrast
  dat{k} = sent{k};
  dat{k}.avg.pow = mean(sent{k}.avg.pow(:, 4:16),2);% - mean(seq{k}.avg.pow(:, 4:16),2); % 0-600 ms
  dat{k}.time    = mean(sent{k}.time(4:16));
end

load('/home/common/matlab/fieldtrip/template/sourcemodel/standard_grid3d10mm');
mask = mous_gaba_makemask(grid);
for k = 1:Nsubj
  tmp = dat{k};
  tmp.dim = [1 1 1];
  tmp.pos = mean(dat{k}.pos(mask.V1(:),:));
  tmp.inside = 1;
  tmp.outside = [];
  tmp.avg.pow = nanmean(dat{k}.avg.pow(mask.V1(:),:));
  V1{k} = tmp;
  tmp = dat{k};
  tmp.dim = [1 1 1];
  tmp.pos = mean(dat{k}.pos(mask.B(:),:));
  tmp.inside = 1;
  tmp.outside = [];
  tmp.avg.pow = nanmean(dat{k}.avg.pow(mask.B(:),:));
  B{k} = tmp;
  tmp = dat{k};
  tmp.dim = [1 1 1];
  tmp.pos = mean(dat{k}.pos(mask.W(:),:));
  tmp.inside = 1;
  tmp.outside = [];
  tmp.avg.pow = nanmean(dat{k}.avg.pow(mask.W(:),:));
  W{k} = tmp;

end

design        = data(:,1);
cfg           = [];
cfg.method    = 'montecarlo';
%cfg.statistic = 'spearman';
cfg.statistic = 'glm';
cfg.glm.statistic = 'T';
cfg.glm.demean    = 'yes';
cfg.glm.contrast  = 1;
cfg.parameter = 'avg.pow';
cfg.numrandomization = 1000;
cfg.design    = design(isfinite(design))'-mean(design(isfinite(design)));
statv1        = ft_sourcestatistics(cfg, dat{isfinite(design)});
statv1roi     = ft_sourcestatistics(cfg, V1{isfinite(design)});

design        = data(:,2);
cfg.design    = design(isfinite(design))'-mean(design(isfinite(design)));
statb         = ft_sourcestatistics(cfg, dat{isfinite(design)});
statbroi      = ft_sourcestatistics(cfg, B{isfinite(design)});

design        = data(:,3);
cfg.design    = design(isfinite(design))'-mean(design(isfinite(design)));
statw         = ft_sourcestatistics(cfg, dat{isfinite(design)});
statwroi      = ft_sourcestatistics(cfg, W{isfinite(design)});

