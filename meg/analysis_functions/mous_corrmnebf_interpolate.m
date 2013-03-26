function [source3d, sourcemodel] = mous_corrmnebf_interpolate(subjectname,cormat)

switch cormat
    case 'voxvert'
        mous_db_getdata(subjectname, 'meg_corrmnebf_corVoxvert8mm');  % vox * vert
        mous_db_getdata(subjectname, 'meg_corrmnebf_bfsourcesingletrial8mm_02-06');

        source2 = source; clear source;
        %FIXME the above is not needed yet, think of using the sourcemodel3d
        %directly in mous_mne_2dto3d rather than doing the warp on the fly
        mous_db_getdata(subjectname, 'meg_corrmnebf_mnesingletrial_02-06');

        source.avg.pow = cor';
        source.time    = 1:size(cor,1);

        source3d = mous_mne_2dto3d(subjectname, source, 'resolution', 8);  
        source3d.inside  = source2.inside;
        source3d.outside = source2.outside; % assuming they are the same as the interpolation target

        sourcemodel = rmfield(source2, 'avg');
        clear source source2;

        source3d.corrmat = source3d.avg.pow(source3d.inside,:); % interpolated vertices X voxels
        source3d.pos     = source3d.pos(source3d.inside,:);
        source3d.inside  = 1:numel(source3d.inside);
        source3d.outside = [];
        source3d         = rmfield(source3d, 'avg');
        
    case 'grpvoxvert'  % FIXME: Condense: pretty much the same code as single subject voxvert 
        mous_db_getdata('groupresults','meg_corrmnebf_corVoxvert8mm.mat'); %  groupaverage vox*vert
        subjectname = 'V1020';  % arbitrary subject chosen such that a grid is available
        cor = dataAvg;
        
        source2 = source; clear source;
        mous_db_getdata(subjectname, 'meg_corrmnebf_mnesingletrial_02-06');

        source.avg.pow = cor';
        source.time    = 1:size(cor,1);

        source3d = mous_mne_2dto3d(subjectname, source, 'resolution', 8);  % source changed to source2
        source3d.inside  = source2.inside;
        source3d.outside = source2.outside; % assuming they are the same as the interpolation target

        sourcemodel = rmfield(source2, 'avg');
        clear source source2;

        source3d.corrmat = source3d.avg.pow(source3d.inside,:); % interpolated vertices X voxels
        source3d.pos     = source3d.pos(source3d.inside,:);
        source3d.inside  = 1:numel(source3d.inside);
        source3d.outside = [];
        source3d         = rmfield(source3d, 'avg');
        
     case 'voxvox' %CHECKME - may not be working properly
        mous_db_getdata(subjectname, 'meg_corrmnebf_corVoxvox8mm');   % correlation matrix
        mous_db_getdata(subjectname, 'meg_corrmnebf_bfsourcesingletrial8mm_02-06');  % source data
        res         = 8;
        sourcemodel = mous_db_getdata(subjectname, ['meg_anatomy_sourcemodel3D_nonlin',num2str(res),'mm']);  % sourcemodel (grid)
        cor         = corvox;
        
        source.avg.pow = cor';       % substitute source values for correlation values
        source.time    = 1:size(cor,1);

        %N.B: number of inside sources must match between sourcemodel and source.
        sourcemodel.inside = source.inside;
        sourcemodel.pos    = source.pos;
            
        source.corrmat = source.avg.pow;  % mous_connectivitybrowser takes "corrmat" parameter
        source.pos     = source.pos(source.inside,:);
        source.inside  = 1:numel(source.inside);
        source.outside = [];
        source         = rmfield(source, 'avg');
       
        source3d       = source;     % keeping output arguments consistent
    case 'vertvert'
        mous_db_getdata(subjectname, 'meg_corrmnebf_corVertvert8mm'); % vert* vert corr matrix
        cor = corvert;

        mous_db_getdata(subjectname, 'meg_corrmnebf_bfsourcesingletrial8mm_02-06');  % BF for 3D interp.
        source2 = source; clear source;

        mous_db_getdata(subjectname, 'meg_corrmnebf_mnesingletrial_02-06');  % MNE source to be interpolated

        source.avg.pow = cor';
        source.time    = 1:size(cor,1);

        source3d = mous_mne_2dto3d(subjectname, source, 'resolution', 8); 
        %% change to match source.inside (MNEs, not TFRs)
        source3d.inside  = source.inside;  
        source3d.outside = source.outside; % assuming they are the same as the interpolation target

        sourcemodel = rmfield(source2, 'avg');
        clear source source2;

        source3d.corrmat = source3d.avg.pow(source3d.inside,:); % interpolated vertices X voxels
        source3d.pos     = source3d.pos(source3d.inside,:);
        source3d.inside  = 1:numel(source3d.inside);
        source3d.outside = [];
        source3d         = rmfield(source3d, 'avg');
end 
