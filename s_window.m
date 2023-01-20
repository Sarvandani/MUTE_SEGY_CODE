function seismic=s_window(seismic,window,option)
% Function applies window to traces of a seismic dataset.
%
% Written by: E. R.: March 21, 2004
% Last updated: January 9, 2006: bug fixes
%
%           seismic=s_window(seismic,window)
% INPUT
% seismic  seismic data set
% window   string specifying the type of window
%          Possible windows are (not case-sensitive):
%          'BartHann', 'Bartlett',  'Blackman', 'Dolph',  'Gauss',
%          'Hamming',  'Hanning',   'Harris',   'Kaiser', 'none', 'Nutbess', 
% 	   'Nuttall',  'Papoulis',  'Parzen',   'Rect',         
%          'sine'      'spline',    'Triang',  
%          'none' and 'rect' are the same as are "Bartlett' and 'triang'.
% option   optional input argument; possible values are -1, 0, 1
%          This parameter allows one to specify if the full window should
%          be used (option=0) or the first half (option=-1) or the 
%          last half (option=1).
%          A window with option 1 might be applied to a maximum-phase wavelet; 
%                        option 0 might be applied to a zero-phase wavelet;
%                        option -1 might be applied to a minimum-phase wavelet.
%          Default: option=0
% OUTPUT
% seismic  input data set with window applied to each trace
%
% EXAMPLE
%        seismic=s_convert(ones(101,1),0,4);
%        seismic.name='Constant';
%        s_wplot(s_window(seismic,'parzen',-1))
%        s_wplot(s_window(seismic,'parzen', 0))
%        s_wplot(s_window(seismic,'parzen', 1))


[nsamp,ntr]=size(seismic.traces);

wndws={'BartHann','Bartlett','Blackman','Dolph','Gauss','Hamming', ...
       'Hanning','Harris','Kaiser','none','Nutbess','Nuttall','Papoulis',  ...
       'Parzen','Rect','sine','spline','Triang'};                 ...
      

idx=find(ismember(lower(wndws),lower(window)));
if isempty(idx)
   disp([' Unknown window type: ',window])
   disp(' Possible types are:')
   disp(cell2str(wndws,','));
   error('Abnormal termination')
end

%       Create the window for the three options
if nargin < 3  |  option == 0
   wndw=mywindow(nsamp,wndws{idx});
elseif option > 0
   wndw=mywindow(2*nsamp-1,wndws{idx});
   wndw=wndw(1:nsamp);
else
   wndw=mywindow(2*nsamp-1,wndws{idx});
   wndw=wndw(nsamp:end);
end

%       Apply window to seismic traces
for ii=1:ntr
   seismic.traces(:,ii)=seismic.traces(:,ii).*wndw;
end
seismic.name=[seismic.name,' (',wndws{idx},')'];

%    Append history field
htext=[wndws{idx},' applied to seismic'];
seismic=s_history(seismic,'append',htext);
