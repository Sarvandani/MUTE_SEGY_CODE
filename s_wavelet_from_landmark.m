function seismic=s_wavelet_from_landmark(filename)
% Read seismic data in Jason format from file
%
% Written by: E. R.: May 11, 2004
% Last updated: April 19, 2006: Handle failed reads
%
%           [seismic,header]=s_wavelet_from_landmark(filename)
% INPUT
% filename  file name (optional)
%           the filename and the directory are saved in global variable S4M
% OUTPUT
% seismic   seismic data set read in; if reading was failed or was
%           aborted, "seismic" is empty.


global S4M

if nargin == 0
   cols=read_ascii_table;
%   cols=rd_columns('',1,1);
else
   cols=read_ascii_table(filename);
%   cols=rd_columns(filename,1,1);
end

if isempty(cols)
   seismic=[];
   return
end

history=S4M.history;
S4M.history=0;
seismic=s_convert(cols(4:end),-cols(2)*cols(3),cols(3));
S4M.history=history;
seismic=s_history(seismic,'add',fullfile(S4M.filepath,S4M.filename));
[dummy,name]=fileparts(S4M.filename);   %#ok  % First output argument is not used
seismic.name=name;
seismic.tag='Landmark wavelet';
