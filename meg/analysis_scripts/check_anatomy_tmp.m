% check coreg

V1001 surface OK
V1001 vol OK
V1001 coreg ~OK
% cause: coregCTF is a resliced volume, coregMNI is not.
% solution: redo the parts of the pipeline that rely on the MRI
% coregistered to CTF-space
% -> redid the coreg to CTF based on the coreg to MNI mri. also redid the
% creation of the volume conductor

V1002 surface OK
V1002 vol OK
V1002 coreg ~OK
% cause and solution: same as in V1001

V1006 no BEM yet

V1007 surface OK
V1007 vol ~OK % -> faulty V1007coregCTF, x and y seem swapped
% somehow a correct coregistration does not do the trick -> do a
% segmentation of the skullstripped image
% after this it looks quite OK, but at the frontal pole the mesh seems to
% stick out for a tiny bit -> TO DO for Annika: check the coregistration
% (CTF)
V1007 coreg OK

V1009 no BEM yet

V1014 no BEM yet

V1016 surface OK
V1016 vol ~OK % -> don't know what was wrong here.
% somehow the segmentation failed. redid it using the skullstripped image.
% after this it looks quite OK.
% -> TO DO for Annika: check the coregistration
V1016 coreg OK

V1017 no BEM yet

V1020 no BEM yet

V1022 and beyond: no BEM yet



