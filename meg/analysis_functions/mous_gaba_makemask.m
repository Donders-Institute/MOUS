function [mask] = mous_gaba_makemask(mri)

% corner coordinates in MNI space have been provided by Julia:

V1corners = [22  -74  -2;
             22  -88  12;
             22 -102  -2;
             22  -88 -14;
              2  -74  -2;
              2  -88  12;
              2 -102  -2;
              2  -88 -14];

Bcorners  = [45 22  -8;
             41 38   9;
             48 12  30;
             50 1    1;
             37 25  -7;
             34 34   7;
             38 10  23;
             42 -2  -1];

Wcorners = [54 -17 -17;
            54 -11   4;
            54 -49  14;
            54 -57 -10;
            44 -17 -17;
            44 -11   4;
            44 -49  14;
            44 -57 -10];

% load the MNI-template
%mri = ft_read_mri(fullfile('/home/language/jansch/matlab/mri/templateMRI.nii'));
mri = ft_convert_units(mri, 'mm');

V1.bnd.pnt = V1corners;
V1.bnd.tri = convhull(V1corners);
V1.unit = 'mm';
V1.type = 'singleshell';

B.bnd.pnt  = Bcorners;
B.bnd.tri  = convhull(Bcorners);
B.unit = 'mm';
B.type = 'singleshell';

W.bnd.pnt  = Wcorners;
W.bnd.tri  = convhull(Wcorners);
W.unit = 'mm';
W.type = 'singleshell';

if ~isfield(mri, 'pos')
  [X,Y,Z] = ndgrid(1:mri.dim(1),1:mri.dim(2),1:mri.dim(3));
  pos     = warp_apply(mri.transform, [X(:) Y(:), Z(:)]);
  clear X Y Z
else
  pos = mri.pos;
end

V1in = ft_inside_vol(pos, V1);
Bin  = ft_inside_vol(pos, B);
Win  = ft_inside_vol(pos, W);

mask           = [];
mask.dim       = mri.dim;
if isfield(mri, 'transform'), 
  mask.transform = mri.transform; 
  mask.V1        = reshape(V1in, mri.dim);
  mask.Broca     = reshape(Bin,  mri.dim);
  mask.Wernicke  = reshape(Win,  mri.dim);
end
if isfield(mri, 'pos'),       
  mask.pos       = mri.pos; 
  mask.V1        = V1in;
  mask.B         = Bin;
  mask.W         = Win;
end
mask.label     = {'V1';'Broca';'Wernicke'};

mask = ft_datatype_parcelation(mask);           
            