function powerspect=s_power_spectrum(seismic,varargin)
% Function computes power spectrum (amplitude spectrum) of seismic traces using
% the windowed autocorrelation function
% Written by: E. R.: November 3, 2004
% Last updated:
%
%             powerspect=s_power_spectrum(seismic,varargin)
% INPUT
% seismic     seismic data set
% varargin    one or more cell arrays; the first element of each cell array is a keyword,
%             the other elements are parameters. Presently, keywords are:
%     'nfft'  Number of samples of the Fourier transform
%             Default: {'nfft',max(nsamp,1024]} where "nsamp" is the number of 
%                 samples per trace
%     'type'  type of spectrum; possible values are "amplitude' and 'power'.
%             Default: {'type','power'}
%     'window'  window type 
%	      Possible names are :
%	      'Hamming', 'Hanning', 'Nuttall',  'Papoulis', 'Harris',
%	      'Rect',    'Triang',  'Bartlett', 'BartHann', 'Blackman'
%	      'Gauss',   'Parzen',  'Kaiser',   'Dolph',    'Hanna',
%	      'Nutbess', 'spline',  'none'
%             Default" {'window','Papoulis'} 
%     'wlength', window length (essentially length of the autocorrelation function
%             used for spectrum estimation); 
%             generally recommended: effective wavelet length
%             Default: {'wlength',seismic.last-seismic.first}
% OUTPUT
% powerspect  Power spectrum (or amplitude spectrum) of the input traces
%             one output trace for each input trace

[nsamp,ntr]=size(seismic.traces);

%	Set default values for input parameters
param.nfft=max(1024,nsamp);
param.wlength=seismic.last-seismic.first;
param.type='power';
param.window='Papoulis';

%	Replace defaults by input parameters
param=assign_input(param,varargin);


corr=zeros(2*nsamp-1,ntr);

for ii=1:ntr
   corr(:,ii)=correlate(seismic.traces(:,ii),seismic.traces(:,ii),logical(1));
end
corr=corr/nsamp;
  
%nsamp4corr=min(round(param.wlength/(2*seismic.step)),nsamp)+1;
nsamp4corr=min(round(param.wlength/seismic.step),nsamp-1)+1;

ia=nsamp-nsamp4corr+1;
% ia=max(nsamp-nsamp4corr,1);
if strcmpi(param.window,'none')
   corr=corr(ia:2*nsamp-ia,:);
else
   wndws={'Hamming', 'Hanning', 'Nuttall',  'Papoulis', 'Harris', ...
	'Rect',    'Triang',  'Bartlett', 'BartHann', 'Blackman', ...
	'Gauss',   'Parzen',  'Kaiser',   'Dolph',    'Hanna', ...
	'Nutbess', 'spline'};
     
   if ismember(lower(param.window),lower(wndws))
      wndw=mywindow(2*nsamp4corr-1,param.window);
%      window_length=length(wndw)%test
      corr=vmt(corr(ia:2*nsamp-ia,:),wndw(:));
   else
      disp([' Unknown window type:', param.window])
      disp(' Possible windows are:')
      disp(wndws)
      error('Abnormal termination')
   end
end

%corr=lf_dc_removal(corr,1);
temp=fft(corr,param.nfft);
%keyboard
step=1000/(seismic.step*param.nfft);

if mod(param.nfft,2) == 0
   nsamp4power=param.nfft/2+1;
else
   nsamp4power=(param.nfft+1)/2;
end

powerspect.type='seismic';
powerspect.tag='spectrum';
powerspect.name=['Spectrum (',seismic.name,')'];
powerspect.first=0;
powerspect.last=step*(nsamp4power-1);
powerspect.step=step;
powerspect.units='Hz';
powerspect.traces=abs(temp(1:nsamp4power,:));
if strcmpi(param.type,'power')
   powerspect.name=['Power spectrum (',seismic.name,')'];
   powerspect.traces=abs(temp(1:nsamp4power,:));
else
   powerspect.name=['Amplitude spectrum (',seismic.name,')'];
   powerspect.traces=sqrt(abs(temp(1:nsamp4power,:)));
end

