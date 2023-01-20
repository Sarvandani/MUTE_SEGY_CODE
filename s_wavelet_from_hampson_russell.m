function [seismic,header]=s_wavelet_from_hampson_russell(filename)
% Read wavelet in Hampson-Russell format from ASCII file
%
% Written by: E. R.: October 18, 2005
% Last updated: May 3, 2006: handle case of no header
%
%           [seismic,header]=s_wavelet_from_hampson_russell(filename)
% INPUT
% filename  file name (optional)
%           the filename and the directory are saved in global variable S4M
% OUTPUT
% seismic   seismic data set read from file
% header    text header of Hampson-Russell file

global ABORTED S4M

ABORTED=logical(1);
seismic=[];
header=[];

if nargin > 0
   fid=fopen(filename);
else
   fid =-1;
end
if fid == -1
   selected_file=get_filename4r('.txt');
   fid=fopen(selected_file,'rt');
   if fid == -1
      return
   end
else
   filename2S4M(filename)
end 
S4M.default_path=S4M.pathname;

header=cell(25,1);

line=deblank(fgetl(fid));

if length(line) > 3  &  ~strcmp(line(1:3),'~SR')
%       Read header
   ik=0;

   try
      while length(line) < 15  | ~strcmp(line(1:15),'#STRATA_WPARAMS')
         ik=ik+1;
         header{ik}=line;
         line=fgetl(fid);
      end

   catch
      disp('Problem reading file')
      msgdlg({['Problem encountered when trying to read file "',selected_file,'".']; ...
      'File is probably not in Hampson-Russell format.'})
      return
   end
   header=header(1:ik);
   line=fgetl(fid);
end


%       Read wavelet parameters
ierr=0;

if strcmp(line(1:3),'~SR')
   step=str2double(line(4:end));
else
   ierr=1;
end


line=fgetl(fid);
if strcmp(line(1:3),'~TZ')
   nt0=str2double(line(4:end));
else
   ierr=1;
end

line=fgetl(fid);
if strcmp(line(1:3),'~NS')
   nsamp=str2double(line(4:end));
else
   ierr=1;
end

line=fgetl(fid);
if strcmp(line(1:3),'~PR') |  strcmp(line(1:3),'~RP')  % Second option is a fix to handle an aberration from H-R format
   pr=str2double(line(4:end));
else
   ierr=1;
end

if ierr > 0
   fclose(fid)
   disp('File is not in Hampson-Russell format.')
   warndlg('File is not in Hampson-Russell format!')
   ABORTED =logical(1);
   seismic=[];
   return
end

%       Prepare seismic structure
seismic.type='seismic';
seismic.tag='wavelet';
[dummy,name]=fileparts(S4M.filename);
seismic.name=name;
seismic.first=(1-nt0)*step;
seismic.last=seismic.first+(nsamp-1)*step;
seismic.step=step;
seismic.units='ms';


%	Read the first trace-data line to determine the number of columns
seismic.traces=fscanf(fid,'%g',[1,nsamp])';

fclose(fid);

if S4M.history
   seismic=s_history(seismic,'add',['File ',seismic.name,' from Hampson-Russell']);
end

ABORTED=logical(0);
