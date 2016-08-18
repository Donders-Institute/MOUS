function [num,den] = mous_iirpeak_coeffs(Wo,BW,varargin)

%IIRPEAK Second-order IIR peaking (resonator) digital filter design.
%   [NUM,DEN] = IIRPEAK(Wo,BW) designs a second-order resonator digital
%   filter with the peak at frequency Wo and a bandwidth of BW at the 3 dB
%   level. Wo must satisfy 0.0 < Wo < 1.0, with 1.0 corresponding to pi 
%   radians/sample.
%
%   The bandwidth BW is related to the Q-factor of a filter by BW = Wo/Q.
%
%   [NUM,DEN] = IIRPEAK(Wo,BW,Ab) designs a peaking filter with a bandwidth
%   of BW at a level Ab in decibels. If not specified, Ab defaults to the 
%   3 dB width (10*log10(2)).
% 


Ab = 10*log10(2);

% Design a peaking filter.
[num,den] = secondorderPeak(Wo,BW,Ab);

%------------------------------------------------------------------------
function [num,den] = secondorderPeak(Wo,BW,Ab)
% Design a 2nd order IIR peaking (resonator) digital filter.

% Inputs are normalized by pi.
BW = BW*pi;
Wo = Wo*pi;

Gb   = 10^(-Ab/20);
beta = (Gb/sqrt(1-Gb.^2))*tan(BW/2);
gain = 1/(1+beta);

num  = (1-gain)*[1 0 -1];
den  = [1 -2*gain*cos(Wo) (2*gain-1)];


% [EOF]
