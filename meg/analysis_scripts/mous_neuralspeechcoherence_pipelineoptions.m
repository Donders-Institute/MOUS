% set the defaults for the possible pipeline parts to be executed
if ~exist('dosens',              'var'), dosens                 = 0; end 
if ~exist('dosensavg',           'var'), dosensavg              = 0; end  
if ~exist('dosource_low',        'var'), dosource_low           = 0; end 
if ~exist('dosource_high',       'var'), dosource_high          = 0; end 
if ~exist('doshuffle_low',       'var'), doshuffle_low          = 0; end 
if ~exist('dosource_low_regAC',  'var'), dosource_low_regAC     = 0; end 
if ~exist('dosens_cca',          'var'), dosens_cca             = 0; end

% set the rootdir variable
if ~exist('rootdir', 'var'), rootdir = '/project/3011020.09/MEG'; end 

