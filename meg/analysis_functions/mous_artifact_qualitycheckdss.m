function [h1,h2] = mous_artifact_qualitycheckdss(subjectname)

% MOUS_ARTIFACT_QUALITYCHECKDSS does a quality control check on the
% ouput of the artifact pipeline, mrelying on visual inspection of a
% number of output figures, generated from the output from the dss artifact
% identification.
%
% Use as
%   mous_artifact_qualitycheckdss(subjectname)
%
% For example
%   mous_artifact_qualitycheckdss('V1020')
%
% See also MOUS_ARTIFACT_PIPELINE

mous_db_getdata(subjectname, 'meg_artifactdssblinks');

h1 = figure;
plot(avgcomp');
title(subjectname);

h2 = figure;
comp.trial = cell(1,numel(comp.time));

cfg           = [];
cfg.layout    = 'CTF275.lay';
cfg.component = 1:4;
cfg.title     = subjectname;
ft_topoplotIC(cfg, comp);

mous_db_putdata(subjectname, 'meg_artifact_figure_dssblinks1', h1);
mous_db_putdata(subjectname, 'meg_artifact_figure_dssblinks2', h2);
