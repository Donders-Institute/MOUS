% set the defaults for the possible pipeline parts to be executed
if ~exist('doecg',                  'var'), doecg                  = 0; end  
if ~exist('dodss',                  'var'), dodss                  = 0; end  
if ~exist('dofreq',                 'var'), dofreq                 = 0; end 
if ~exist('dofreqmtmfft',           'var'), dofreqmtmfft           = 0; end 
if ~exist('dofreqmtmfft_preword',   'var'), dofreqmtmfft_preword   = 0; end 
if ~exist('dofreqmtmfft_contrast',  'var'), dofreqmtmfft_contrast  = 0; end 
if ~exist('dofreqmtmfft_contrast_baseline', 'var'), dofreqmtmfft_contrast_baseline = 0; end 
if ~exist('dofreqmtmfft_contrast_nobaseline', 'var'), dofreqmtmfft_contrast_nobaseline = 0; end 
if ~exist('dofreqbaseline',         'var'), dofreqbaseline         = 0; end 
if ~exist('dosource',               'var'), dosource               = 0; end 
if ~exist('dosource8mm',            'var'), dosource8mm            = 0; end 
if ~exist('dosource8mmparcellate',  'var'), dosource8mmparcellate  = 0; end
if ~exist('doleadfield8mm',         'var'), doleadfield8mm         = 0; end 
if ~exist('dovox',                  'var'), dovox                  = 0; end 
if ~exist('dovoxbaseline',          'var'), dovoxbaseline          = 0; end 
if ~exist('doica',                  'var'), doica                  = 0; end 
if ~exist('doccc',                  'var'), doccc                  = 0; end 
if ~exist('dosourcedss',            'var'), dosourcedss            = 0; end 
if ~exist('dosentvsseq',            'var'), dosentvsseq            = 0; end 
if ~exist('dosentvsseqTarget',      'var'), dosentvsseqTarget      = 0; end 
if ~exist('dosentvsseq_chan',       'var'), dosentvsseq_chan       = 0; end 
if ~exist('dosentvsseqTarget_chan', 'var'), dosentvsseqTarget_chan = 0; end 
if ~exist('dosent1vssent2_chan',    'var'), dosent1vssent2_chan    = 0; end 
if ~exist('dowordsentpar',          'var'), dowordsentpar          = 0; end 
if ~exist('dowordseqpar',           'var'), dowordseqpar           = 0; end 
if ~exist('sourcedata2avgword',     'var'), sourcedata2avgword     = 0; end 
if ~exist('dowordsentpar2',         'var'), dowordsentpar2         = 0; end 
if ~exist('dowordseqpar2',          'var'), dowordseqpar2          = 0; end
if ~exist('docleanup',              'var'), docleanup              = 0; end
if ~exist('dosource_contrasts',     'var'), dosource_contrasts     = 0; end

% set the rootdir variable
if ~exist('rootdir', 'var'), rootdir = '/home/language/jansch/public/mous/'; end 

% set some defaults that are needed for some parts of the pipeline
if ~exist('suff', 'var'),      suff      = ''; end
if ~exist('frequency', 'var'), frequency = 20; end
if ~exist('toi', 'var'),       toi = 0.4;      end
