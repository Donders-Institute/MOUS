function [source3d, sourcemodel] = mous_corrmnebf_interpolate(subjectname)
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

% subjectname = 'groupresults';  % 'V1020' 
%% voxvert
docorVoxvert8mm_sdregwordord_jack_bf01mne0306  = true;
docorVoxvert8mm_sdregwordord_bf01mne0306  = true;
docorVoxvert8mm_sdregwordord_bf02mne0306  = false;
docorVoxvert8mm_sdregwordord_N1           = false;
docorVoxvert8mm_regwordord_bf02mne0306    = false;
docorVoxvert8mm_regwordord_bf01mne0306    = false;
docorVoxvert8mm_bf01mne0306               = false;
docorVoxvert8mm_N1                        = false;
doorig                                    = false; % TFR and ERF are 0.2-0.6 =

%% voxvox
docorVoxvox8mm_sdregwordord_bf01mne0306  = false;
docorVoxvox8mm_sdregwordord_bf02mne0306  = false;
docorVoxvox8mm_sdregwordord_N1           = false;
docorVoxvox8mm_regwordord_bf02mne0306    = false;
% docorVoxvox8mm_regwordord_bf01mne0306    = false; % doesn't exist
docorVoxvox8mm_bf01mne0306               = false;
docorVoxvox8mm_N1                        = false;
docorVoxvox8mm                           = false; % TFR and ERF are 0.2-0.6 =

%% vertvert
docorVertvert8mm_sdregwordord_bf01mne0306  = false;
docorVertvert8mm_sdregwordord_bf02mne0306  = false;
docorVertvert8mm_sdregwordord_N1           = false;
docorVertvert8mm_regwordord_bf02mne0306    = false;
% docorVertvert8mm_regwordord_bf01mne0306    = false; % doesn't exist
docorVertvert8mm_bf01mne0306               = false;
docorVertvert8mm_N1                        = false;
docorVertvert8mm                           = false; % TFR and ERF are 0.2-0.6 =


%% voxvert
if docorVoxvert8mm_sdregwordord_jack_bf01mne0306
    corfilename = 'meg_corrmnebf_corVoxvert8mm_sdregwordord_jack_bf01mne0306.mat';
    tfrsource   = 'meg_corrmnebf_bfsourcesingletrial8mm_01';
    erfsource   = 'meg_corrmnebf_mnesingletrial_0306_bf01';
end

if docorVoxvert8mm_sdregwordord_bf01mne0306
    corfilename = 'meg_corrmnebf_corVoxvert8mm_sdregwordord_bf01mne0306.mat';
    tfrsource   = 'meg_corrmnebf_bfsourcesingletrial8mm_01';
    erfsource   = 'meg_corrmnebf_mnesingletrial_0306_bf01';
end

if docorVoxvert8mm_sdregwordord_bf01mne0306
    corfilename = 'meg_corrmnebf_corVoxvert8mm_sdregwordord_bf01mne0306.mat';
    tfrsource   = 'meg_corrmnebf_bfsourcesingletrial8mm_01';
    erfsource   = 'meg_corrmnebf_mnesingletrial_0306_bf01';
end
    
if docorVoxvert8mm_sdregwordord_bf02mne0306
    corfilename = 'meg_corrmnebf_corVoxvert8mm_sdregwordord_bf02mne0306.mat';
    tfrsource   = 'meg_corrmnebf_bfsourcesingletrial8mm_02';
    erfsource   = 'meg_corrmnebf_mnesingletrial_0306_bf02';
end

if docorVoxvert8mm_sdregwordord_N1
    corfilename = 'meg_corrmnebf_corVoxvert8mm_sdregwordord_N1.mat';
    tfrsource   = 'meg_corrmnebf_bfsourcesingletrial8mm_-01';
    erfsource   = 'meg_corrmnebf_mnesingletrial_N1';
end

if docorVoxvert8mm_regwordord_bf02mne0306
    corfilename = 'meg_corrmnebf_corVoxvert8mm_regwordord_bf02mne0306.mat';
    tfrsource   = 'meg_corrmnebf_bfsourcesingletrial8mm_02';
    erfsource   = 'meg_corrmnebf_mnesingletrial_0306_bf02';
end
    
if docorVoxvert8mm_regwordord_bf01mne0306
    corfilename = 'meg_corrmnebf_corVoxvert8mm_regwordord_bf01mne0306.mat';
    tfrsource   = 'meg_corrmnebf_bfsourcesingletrial8mm_01';
    erfsource   = 'meg_corrmnebf_mnesingletrial_0306_bf01';
end

if docorVoxvert8mm_bf01mne0306
    corfilename = 'meg_corrmnebf_corVoxvert8mm_bf01mne0306.mat';
    tfrsource   = 'meg_corrmnebf_bfsourcesingletrial8mm_01';
    erfsource   = 'meg_corrmnebf_mnesingletrial_0306_bf01';
end

if docorVoxvert8mm_N1
    corfilename = 'meg_corrmnebf_corVoxvert8mm_N1.mat';
    tfrsource   = 'meg_corrmnebf_bfsourcesingletrial8mm_-01';
    erfsource   = 'meg_corrmnebf_mnesingletrial_N1';
end

if doorig % TFR and ERF are 0.2-0.6 
    % a 10mm also exists, but not listed here
    corfilename = 'meg_corrmnebf_corVoxvert8mm.mat';
    tfrsource   = 'meg_corrmnebf_bfsourcesingletrial8mm_02-06';
    erfsource   = 'meg_corrmnebf_mnesingletrial_02-06';
end

%% voxvox
if docorVoxvox8mm_sdregwordord_bf01mne0306
    corfilename = 'meg_corrmnebf_corVoxvox8mm_sdregwordord_bf01mne0306.mat';
    tfrsource   = 'meg_corrmnebf_bfsourcesingletrial8mm_01';
%     erfsource   = 'meg_corrmnebf_mnesingletrial_0306_bf01';
end
    
if docorVoxvox8mm_sdregwordord_bf02mne0306
    corfilename = 'meg_corrmnebf_corVoxvox8mm_sdregwordord_bf02mne0306.mat';
    tfrsource   = 'meg_corrmnebf_bfsourcesingletrial8mm_02';
%     erfsource   = 'meg_corrmnebf_mnesingletrial_0306_bf02';
end

%% vertvert
if docorVertvert8mm_sdregwordord_bf01mne0306
    corfilename = 'meg_corrmnebf_corVertvert8mm_sdregwordord_bf01mne0306.mat';
    tfrsource   = 'meg_corrmnebf_bfsourcesingletrial8mm_01';
    erfsource   = 'meg_corrmnebf_mnesingletrial_0306_bf01';
end
    
if docorVertvert8mm_sdregwordord_bf02mne0306
    corfilename = 'meg_corrmnebf_corVertvert8mm_sdregwordord_bf02mne0306.mat';
    tfrsource   = 'meg_corrmnebf_bfsourcesingletrial8mm_02';
    erfsource   = 'meg_corrmnebf_mnesingletrial_0306_bf02';
end

%% VOXVERT: same code for all subject(s) and file type combinations 
mous_db_getdata(subjectname, corfilename);  % correlation matrix
mous_db_getdata(subjectname, tfrsource);    % beamforming source locations
source2 = source; clear source;           

mous_db_getdata(subjectname, erfsource);    % MNE source locations

source.avg.pow = cor';
source.time    = 1:size(cor,1);

source3d = mous_mne_2dto3d(subjectname, source, 'resolution', 8,'sphereradius', 0.8);  % source changed to source2
source3d.inside  = source2.inside;
source3d.outside = source2.outside; % assuming they are the same as the interpolation target

sourcemodel = rmfield(source2, 'avg');
clear source source2;

source3d.corrmat = source3d.avg.pow(source3d.inside,:); % interpolated vertices X voxels
source3d.pos     = source3d.pos(source3d.inside,:);
source3d.inside  = 1:numel(source3d.inside);
source3d.outside = [];
source3d         = rmfield(source3d, 'avg');

%                          grid        source
%mous_connectivitybrowser(sourcemodel,source3d,'parameter','corrmat','method',{'slice','slice'})

%% vertvert
% mous_db_getdata(subjectname, corfilename);  % correlation matrix
% %mous_db_getdata(subjectname, tfrsource);    % beamforming source locations
% source2 = source; clear source;           
% 
% mous_db_getdata(subjectname, erfsource);    % MNE source locations
% 
% source.avg.pow = corvert';
% source.time    = 1:size(corvert,1);
% 
% % take 8196 x 8196 and fit into 3D: 5782 x 5782 (3d beamformer space)
% source3d = mous_mne_2dto3d(subjectname, source, 'resolution', 8,'sphereradius', 0.8);  % source changed to source2
% source3d.inside  = source2.inside;
% source3d.outside = source2.outside; % assuming they are the same as the interpolation target
% 
% sourcemodel = rmfield(source2, 'avg');
% clear source source2;
% 
% source3d.corrmat = source3d.avg.pow(source3d.inside,:); % interpolated vertices X voxels
% source3d.pos     = source3d.pos(source3d.inside,:);
% source3d.inside  = 1:numel(source3d.inside);
% source3d.outside = [];
% %source3d         = rmfield(source3d, 'avg');
% 
% mous_connectivitybrowser(sourcemodel,source3d,'parameter','corrmat','method',{'slice','slice'})
% 
% 
% %% VOXVOX 
% %%% beamforming source is 3D so I don't think I need MNE source locations or to call mous_mne2dto3d.
% mous_db_getdata(subjectname, corfilename);  % correlation matrix
% mous_db_getdata(subjectname, tfrsource);    % beamforming source locations
%         
% sourcemodel = rmfield(source,'avg');  %% is this correct for the sourcemodel?
% source3d = source;
% 
% source3d.avg.pow = corvox';
% source3d.time    = 1:size(corvox,1);
% 
% source3d.corrmat = source3d.avg.pow; %(source3d.inside,:); % interpolated vertices X voxels
% source3d.pos     = source3d.pos; %(source3d.inside,:);
% source3d.inside  = 1:numel(source3d.inside);
% source3d.outside = [];
% source3d         = rmfield(source3d, 'avg');
% 
% mous_connectivitybrowser(sourcemodel,source3d,'parameter','corrmat','method',{'slice','slice'})
% 
% 
