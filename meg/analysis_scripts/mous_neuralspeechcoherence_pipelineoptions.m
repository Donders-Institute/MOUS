% set the defaults for the possible pipeline parts to be executed
if ~exist('dosens',             'var'), doecg                  = 0; end  
if ~exist('dosensavg',          'var'), dodss                  = 0; end  
if ~exist('dosource',           'var'), dofreq                 = 0; end 

% set the rootdir variable
if ~exist('rootdir', 'var'), rootdir = '/project/3011020.09/MEG'; end 

