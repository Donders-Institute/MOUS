function voxdata = mous_cifti_quickread(filename)

% read the header section
hdr = read_nifti2_hdr(filename);
fid = fopen(filename, 'rb', hdr.endian);

% determine the file size, this is used to catch endian errors
fseek(fid, 0, 'eof');
filesize = ftell(fid);
fseek(fid, 0, 'bof');

fseek(fid, 540, 'bof');
hdrext = fread(fid, [1 4], 'int8');
if hdrext(1)~=1
  error('cifti requires a header extension');
end

% determine the size of the header extension
esize = fread(fid, 1, 'int32=>int32');
etype = fread(fid, 1, 'int32=>int32');

hdrsize = 540;
voxsize = filesize-hdr.vox_offset;
if esize>(filesize-hdrsize-voxsize)
  warning('the endianness of the header extension is inconsistent with the nifti-2 header');
  esize = swapbytes(esize);
  etype = swapbytes(etype);
end

if etype~=32 && etype~=swapbytes(int32(32)) % FIXME there is an endian problem
  error('the header extension type is not cifti');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% read the voxel data section
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


fseek(fid, hdr.vox_offset, 'bof');
switch hdr.datatype
  case   2, [voxdata, nitemsread] = fread(fid, inf, 'uchar');   assert(nitemsread==prod(hdr.dim(2:end)), 'could not read all data');
  case   4, [voxdata, nitemsread] = fread(fid, inf, 'short');   assert(nitemsread==prod(hdr.dim(2:end)), 'could not read all data');
  case   8, [voxdata, nitemsread] = fread(fid, inf, 'int');     assert(nitemsread==prod(hdr.dim(2:end)), 'could not read all data');
  case  16, [voxdata, nitemsread] = fread(fid, inf, 'float');   assert(nitemsread==prod(hdr.dim(2:end)), 'could not read all data');
  case  64, [voxdata, nitemsread] = fread(fid, inf, 'double');  assert(nitemsread==prod(hdr.dim(2:end)), 'could not read all data');
  case 512, [voxdata, nitemsread] = fread(fid, inf, 'ushort');  assert(nitemsread==prod(hdr.dim(2:end)), 'could not read all data');
  case 768, [voxdata, nitemsread] = fread(fid, inf, 'uint');    assert(nitemsread==prod(hdr.dim(2:end)), 'could not read all data');
  otherwise, error('unsupported datatype');
end
% hdr.dim(1) is the number of dimensions
% hdr.dim(2) is reserved for the x-dimension
% hdr.dim(3) is reserved for the y-dimension
% hdr.dim(4) is reserved for the z-dimension
% hdr.dim(5) is reserved for the time-dimension
voxdata = reshape(voxdata, hdr.dim(6:end))';

fclose(fid);
