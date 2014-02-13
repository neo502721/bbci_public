function file_writeBVheader(file, varargin)
% FILE_WRITEBVHEADER - Write Header in BrainVision Format
%
% Synopsis:
%   file_writeBVheader(FILE, 'Property1', Value1, ...)
%
% Arguments:
%   FILE: string containing filename to save in.
%  
% Properties: 
%   'Fs': sampling interval of raw data, required
%   'CLab': cell array, channel labels, required
%   'Scale': scaling factors for each channel, required
%   'DataPoints': number of datapoints, required
%   'Precision': precision (default 'int16')
%   'DataFile': name of corresponding .eeg file (default FILE)
%   'MarkerFile': name of corresponding .mrk file (default FILE)
%   'Impedances': for each channel
%
% See also: file_*


global BTB

props= {'Folder'    BTB.TmpDir    'CHAR'};
opt= opt_proplistToStruct(varargin{:});
opt= opt_setDefaults(opt, props);

if fileutil_isAbsolutePath(file),
  fullName= file;
else
  fullName= fullfile(opt.export_dir, file);
end

[pathstr, fileName]= fileparts(fullName);
props= {'Precision'     'int16'   'CHAR(int16 int32 single double float32 float64)'
        'DataFile'     fileName  'CHAR'
        'MarkerFile'   fileName  'CHAR'
        'Impedances'   []        'DOUBLE'};
opt= opt_setDefaults(opt, props);

if ~ischar(opt.DataPoints),  %% not sure, why DataPoints is a string
  opt.DataPoints= sprintf('%d', opt.DataPoints);
end

fid= fopen([fullName '.vhdr'], 'w','b');
if fid==-1, error(sprintf('cannot write to %s.vhdr', fullName)); end
fprintf(fid, ['Brain Vision Data Exchange Header File Version 1.0' 13 10]);
fprintf(fid, ['; Data exported from BTB Matlab Toolbox' 13 10]);
fprintf(fid, [13 10 '[Common Infos]' 13 10]);
fprintf(fid, ['DataFile=%s.eeg' 13 10], opt.DataFile);
fprintf(fid, ['MarkerFile=%s.vmrk' 13 10], opt.MarkerFile);
fprintf(fid, ['DataFormat=BINARY' 13 10]);
fprintf(fid, ['DataOrientation=MULTIPLEXED' 13 10]);
fprintf(fid, ['NumberOfChannels=%d' 13 10], length(opt.CLab));
fprintf(fid, ['DataPoints=%s' 13 10], opt.DataPoints);
fprintf(fid, ['SamplingInterval=%g' 13 10], 1000000/opt.Fs);
fprintf(fid, [13 10 '[Binary Infos]' 13 10]);
switch(lower(opt.Precision)),
 case 'int16',
  fprintf(fid, ['BinaryFormat=INT_16' 13 10]);
  fprintf(fid, ['UseBigEndianOrder=NO' 13 10]);
 case 'int32',
  fprintf(fid, ['BinaryFormat=INT_32' 13 10]);
  fprintf(fid, ['UseBigEndianOrder=NO' 13 10]);
 case {'float32','single','float'},
  fprintf(fid, ['BinaryFormat=IEEE_FLOAT_32' 13 10]);
 case {'float64','double'},
  fprintf(fid, ['BinaryFormat=IEEE_FLOAT_64' 13 10]);
 otherwise,
  error(['Unknown precision, not implemented yet: ' opt.Precision]);
end
fprintf(fid, [13 10 '[Channel Infos]' 13 10]);
for ic= 1:length(opt.CLab),
  fprintf(fid, ['Ch%d=%s,,%g' 13 10], ic, opt.CLab{ic}, ...
          opt.Scale(min(ic,end)));
end
fprintf(fid, ['' 13 10]);

if ~isempty(opt.Impedances),
   fprintf(fid, ['Impedance [kOhm].' 13 10]);
   for ic= 1:length(opt.CLab)
      if isinf(opt.Impedances(ic))
          fprintf(fid, [opt.CLab{ic} ':   Out of Range!' 13 10]);
      else
          fprintf(fid, [opt.CLab{ic} ':   ' num2str(opt.Impedances(ic)) 13 10]);
      end
   end
end

fclose(fid);