function data = mous_wav2mat(filename, method)

% MOUS_WAV2MAT does some processing on a named wav-file.
% These processing steps consist of:
%   - The creation of a Hilbert envelope version of the signal, using the strategy
%     described in Joachim's 2013 PLoS biology paper.
%   - Downsampling of the data to 1200 Hz sampling rate.
%
% Use as
%   audio = mous_wav2mat(filename)
%
% Input argument
%   filename = string, pointing to a wav-file
%   
% Output argument
%   audio = structure, fieldtrip-style, containing the data

if nargin<2,
  method = 1;
end
[y,fs]         = wavread(filename);

% Do the envelope processing on the high temporal resolution data
addpath('/home/language/jansch/matlab/toolboxes/ChimeraSoftware');
n   = 10;
fco = equal_xbm_bands(100, 10000, n);

switch method
  case 1
    % NOTE added 20150722: this filter introduces a time shift, of approx 16 ms!!
    % current results are based on this shifted signal.
    b = quad_filt_bank(fco, fs);
    z = zeros(size(y,1),size(b,2));
    for m = 1:size(b,2)
      z(:,m) = abs(fftfilt(b(:,m), y(:,1)));
    end
  case 2
    for m = 1:numel(fco)-1
      tmp = ft_preproc_bandpassfilter(y(:,1)',fs,fco(m:(m+1)),[],'firws');
      z(:,m) = abs(hilbert(tmp(:)));
    end
end
label = cell(numel(fco)-1,1);
for m = 1:numel(label)
  label{m} = sprintf('audio_%d-%d',round(fco(m)),round(fco(m+1)));
end

% Create a Fieldtrip-style structure
data       = [];
data.trial = {[y(:,1)';z';mean(z,2)']};
data.time  = {(0:size(data.trial{1},2)-1)./fs};
data.label = [{'audio'};label;{'audio_avg'}];
data.fsample = fs;

% Resample to 1200 Hz
cfg = [];
cfg.resamplefs = 1200;
data = ft_resampledata(cfg, data);
