function [source3d, sourcemodel] = mous_corrmnebf_interpolate(subjectname,cfg)
% mous_corrmnebf_interpolate interpolates the correlation matrix of voxels by vertices

% This function calls the 2D MNE source solution to which the correlation m
% matrix substitutes the MNE source values
% These values are projected to 3D space
% Following, the MNE3D space solution i.e. sources are replaced by the
% Beamforming sources.
% Visualisation of projected data is done by calling mous_connectivitybrowser

% voxels = source solution for TFR analyses
% vertices = source solution for ERF analyses
% subjectname can be a single subject or averaged across participants where
% inarg subjectname = 'groupresults';
% correlation matrix can also be between vertices (Vertvert) or voxels (Voxvox) only

%% steps of this function
% load correlation data = cor
% load TFR sourcedata == source2
% load ERF sourcedata == source

% replace ERF sourcedata with transposed correlation matrix 
%             (also with time dimension)

% Make 3D sourcemodel:
%    Turn ERF sourcedata (with correlation values) into 3D using 8mm
%          sourcemodel (as used for calculating TFR with beamformer)
%    Define 3D source locations (inside and outside) to be those defined by
%    TFR sourcedata

% Create 3D correlation matrix from 3D sourcemodel
%   3D correlation matrix values may not all be displayed
%   Displayed values are limited to sources that are WITHIN source space as
%   defined by the TFR sourcedata.

%% voxvert filenames
corfilename = cfg.cor;
tfrsource   = cfg.tfr;
erfsource   = cfg.erf;

%% VOXVERT: same code for all subject(s) and file type combinations 
mous_db_getdata(subjectname, corfilename);  % correlation matrix
mous_db_getdata(subjectname, tfrsource);    % beamforming source locations
source2 = source; clear source;           

mous_db_getdata(subjectname, erfsource);    % MNE source locations

cor = double(cor);   % to prevent issue of multiplying sparse matrix (cor) with other matrices
source.avg.pow = cor';
source.time    = 1:size(cor,1);

source3d = mous_mne_2dto3d(subjectname, source, 'resolution', 8,'sphereradius', 0.8);  % source changed to source2
source3d.inside  = source2.inside;
source3d.outside = source2.outside; % assuming they are the same as the interpolation target

sourcemodel = rmfield(source2, 'avg');
clear source source2;

% restructure to only include power and position data of sources that are
% INSIDE the brain
% source2's inside positions determine source3d's inside positions since
% sourece 2 (beamformer is 3d to begin with, but the source (MNEs) has to
% be interpolated to 3d).
source3d.corrmat = source3d.avg.pow(source3d.inside,:); % interpolated vertices X voxels
source3d.pos     = source3d.pos(source3d.inside,:);
source3d.inside  = 1:numel(source3d.inside);
source3d.outside = [];
source3d         = rmfield(source3d, 'avg');
%                          grid        source
%mous_connectivitybrowser(sourcemodel,source3d,'parameter','corrmat','method',{'slice','slice'}); %'anasc',[-0.095 0.095],'cohsc',[-0.095 0.095]);


