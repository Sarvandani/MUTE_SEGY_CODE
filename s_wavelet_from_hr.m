function [seismic,header]=s_wavelet_from_hr(filename)
% Read wavelet in Hampson-Russell format from ASCII file 
% Written by: E. R.: October 18, 2005
% Last updated:
%
% OBSOLETE: replaced by "s_wavelet_from_hampson_russell"
%           [seismic,header]=s_wavelet_from_hr(filename)
% INPUT
% filename  file name (optional)
%           the filename and the directory are saved in global variable S4M
% OUTPUT
% seismic   seismic data set read from file
% header    text header of Hampson-Russell file

alert('OBSOLETE: use "s_wavelet_from_hampson_russell" instead.')
