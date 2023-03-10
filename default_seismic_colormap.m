function colormatrix=default_seismic_colormap
% Create the color matrix for the default seismic color display
% Written by: E. Rietsch: February 23, 2004
% Last updated:
%
%              colormatrix=default_seismic_colormap
% OUTPUT
% colormatrix  three-column color matrix

nc=32;
up=(0:nc)';
down=flipud(up);
eins=nc*ones(nc+1,1);
colormatrix=[up,up,eins;eins,down,down]/nc; 
