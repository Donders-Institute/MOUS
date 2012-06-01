function mous_execute_pipeline(pipelinename, subjectname)

% this function serves the purpose to make a script executable by qsub.
% supply it with the name of the script that has to be run, and the
% subjectname. the subjectname is assumed to be the only free parameter in
% the script.

eval(pipelinename);
