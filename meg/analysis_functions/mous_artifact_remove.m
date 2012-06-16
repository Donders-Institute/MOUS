function [trl] = mous_artifact_remove(trlIN, filename, tmp)

% NL 31-5-2012.  Removes artifacts
% add optionality for: (1) partial / complete rejection  (2) focus on targets (or other elements)

cfg         = [];
cfg.trl     = trlIN;
cfg.dataset = filename;
cfg.artfctdef.zvalue1.artifact = tmp{1}.artfctdef.zvalue.artifact;
cfg.artfctdef.zvalue2.artifact = tmp{2}.artfctdef.zvalue.artifact;
cfg.artfctdef.zvalue3.artifact = tmp{3}.artfctdef.zvalue.artifact;
cfg.artfctdef.zvalue4.artifact = tmp{4}.artfctdef.zvalue.artifact;
cfg.artfctdef.reject           = 'partial';
cfg.artfctdef.minlength        = 0.1;
cfg         = ft_rejectartifact(cfg);
trl         = cfg.trl;

% uncomment to focus on the target words
% sel = mod(trl(:,5),2)==0;
% trl = trl(sel,:);
