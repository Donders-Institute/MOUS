% mous_gamma_compute
% REF: jansch/public/mous/20130505/analysis20130505.m

clear all;

date    = '20131001';
accessdir = '/home/language/jansch/public/mous';

load(fullfile(accessdir,'subjects_coregOK_20130611'), 'subj');
% only versions of subjects_coregOK_XXX have saved the subjects list as 'subj_ok'.
%subj  = subj_ok;  

addpath ~/matlab/fieldtrip/qsub
addpath ~/matlab/toolboxes/dss2_1-0

[f,s] = mous_db_getfilename(subj, 'meg_bfica_comp',[], '/project/3011020.09/jansch/');
subj  = subj(s);
Nsubj = numel(subj);
pname = repmat({'mous_bfica_pipeline'},[Nsubj 1]);


str1  = repmat({{'dofreq' 1}},             [Nsubj 1]);
str2  = repmat({{'frequency' (32:4:100)}}, [Nsubj 1]);  % 30:4:100, only gets up to 98Hz.  % we have 32Hz in mous_bfica_medium
str3  = repmat({{'suff' '_high'}},         [Nsubj 1]);
%str4  = repmat({{'rootdir' '/project/3011020.09/nielam/'}}, [Nsubj 1]);  % needs to specify, default is to JM's dir.

qsubcellfun('mous_execute_pipeline', pname, subj, str1, str2, str3, 'memreq', 12*1024^3, 'timreq', 60*60);

%% question:
% JM doesn't specify rootdir in shell script/mous_execute_pipeline, so how
% does mous_bfica_pipeline know which rootdir to use for mous_db_putdata??