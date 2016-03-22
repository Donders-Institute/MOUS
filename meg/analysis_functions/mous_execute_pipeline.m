function mous_execute_pipeline(pipelinename, subjectname, varargin)

% MOUS_EXECUTE_PIPELINE serves the purpose to make a script executable by qsub.
% supply it with the name of the script that has to be run, and the
% subjectname. the subjectname is assumed to be the only free parameter in
% the script.
%
% example use in combination with qsubcellfun:
%
% subjectnames = {'V1001';'V1002';'V1003'};
% pipelinename = 'mous_bfica_pipeline';
%
% qsubcellfun('mous_execute_pipeline', repmat({pipelinename}, [numel(subjectnames) 1]), subjectnames, 'memreq', memreq, 'timreq', timreq);
% 
% example use (standalone; not so useful):
%
% mous_execute_pipeline('mous_bfica_pipeline', 'V001');



if numel(varargin)>0
  for k = 1:numel(varargin)
    eval([varargin{k}{1},'=varargin{k}{2}']);
  end
end
eval(pipelinename);
