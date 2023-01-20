function wavelet=s_spectrum2wavelet(freq,amps,varargin)
% Compute wavelet from its amplitude spectrum; unless spectral amplitudes are
% defined for zero frequency and/or Nyquist frequency (i.e. freq(1) == 0 and/or
% freq(end) == 500/step) they are set to zero.
%
% Written by: E. R.: November 27, 2004
% Last updated: December 29, 2005: Set amplitude at zero-frequency and Nyquist 
%                                  frequency to 0 only if they are not defined 
%                                  for these values                              
%
%          wavelet=s_spectrum2wavelet(freq,amps,varargin)
% INPUT
% freq     frequency values at which the spectrum is defined
% amps     associated values of the amplitude spectrum
% varargin    one or more cell arrays; the first element of each cell array is a keyword,
%             the other elements are parameters. Presently, keywords are:
%     'step'  sample interval of the seismic
%             Default: {'step',4}
%     'wlength'   wavelet length
%             Default: {'wlength',100} 
%     'dc_removal'  should DC be removed. Possible values: 'yes' and 'no'.
%             Default: {'dc_removal','yes'}
% OUTPUT
% wavelet  zero-phase wavelet with spectrum defined by "freq" and "amps".
%
% EXAMPLE
%          wavelet=s_spectrum2wavelet([10,20,40,60],[0,1,1,0],{'wlength',80})
%          s_spectrum(wavelet)

%	Set defaults of input arguments
param.step=4;
param.wlength=100;
param.method='linear';
param.dc_removal='yes';

%	Replace defaults by input parameters
param=assign_input(param,varargin);

nsamp=odd(param.wlength/param.step);
ansamp1=nsamp-1;
awlength=ansamp1*param.step;

%	 Wavelet length used for spectrum interpolation
nsamp1=4*ansamp1;
nsamp=nsamp1+1;
% wlength=nsamp1*param.step;

%	Sample interval in the frequency domain
equidist=(0:2:nsamp)*500/(param.step*nsamp);
if freq(1) > 0
   freq=[0;freq(:)];
   amps=[0;amps(:)];
end
if freq(end) < 500/param.step;
   freq=[freq(:);equidist(end)];
   amps=[amps(:);0];
else
   freq(end)=equidist(end);
end
   
[freq,index]=unique(freq);
amps=amps(index);

aspectrum=reshape(interp1(freq,amps,equidist,param.method),[],1);
aspectrum=[aspectrum;aspectrum(end:-1:2)];

wavelet.type='seismic';
wavelet.tag='wavelet';
wavelet.name='Wavelet with defined spectrum';
wavelet.first=-awlength/2;
wavelet.last=-wavelet.first;
wavelet.step=param.step;
wavelet.units='ms';
traces=fftshift(real(ifft(aspectrum)));
inc=(nsamp1-ansamp1)/2;
wavelet.traces=traces(inc+1:end-inc);
wavelet.traces([1,end])=wavelet.traces([1,end])*0.5;
if strcmpi(param.dc_removal,'yes')
   wavelet.traces=wavelet.traces-sum(wavelet.traces)/(length(wavelet.traces)-1);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function m=odd(m)

m=2*round((m-1)*0.5)+1;
