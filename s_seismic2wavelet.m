function wavelet=s_seismic2wavelet(seismic,varargin)
% Function computes wavelet with about the spectrum expected on the basis of the
% seismic data. Can also be used to compute the approximate minimum-phase, 
% zero-phase, or maximum-phase equivalent of a wavelet
%
% Written by: E. R.: June 15, 2001
% Last updated: July 18, 2005: Add keyword "scaling"
%
%           wavelet=s_seismic2wavelet(seismic,varargin)
% INPUT
% seismic   seismic structure
% varargin    one or more cell arrays; the first element of each cell array is a keyword,
%             the other elements are parameters. Presently, keywords are:
%       'dc'    Determines if DC component of wavelet should be removed.
%               Possible values are: logical(1) (yes) and logical(0) (no)
%               Default: {'dc',0}  (deactivated)
%       'wlength' wavelet length. For symmetric wavelets this should be an even
%               multiple of the sample interval. An optional second parameter
%               can be used to indicate if the wavelet length is to be exact 
%               ('exact') or an approximation ('approx'). In the latter case
%               the actual length of the wavelet is chosen so that it ends 
%               just prior to a zero crossing 
%               Default: {'length',80,'approx'}
%       'color' Color of reflectivity. Possible values are 'white' and 'blue'.
%               If 'blue', the amplitude spectrum of the reflectivity is assumed to be 
%               proportional to the square root of the frequency.
%               Default: {'color','blue'} 
%       'scale' Scale factor to apply to the wavelet in such a way that
%               the energy of the wavelet is equal to the average trace energy of
%               of the input data multiplied by "scale".
%               Default: {'scale',1}
%       'type'  type of wavelet. Possible options are:
%               'zero-phase'    zero-phase wavelet
%               'min-phase'     minimum-phase wavelet
%               'max-phase'     maximum-phase wavelet
%               Default: {'type','zero-phase'}
%       'window' type of window to use.  Possible values are (not case-sensitive): 	
%                    'Hamming', 'Hanning', 'Nuttall',  'Papoulis', 'Harris',
% 	             'Rect',    'Triang',  'Bartlett', 'BartHann', 'Blackman'
% 	             'Gauss',   'Parzen',  'Kaiser',   'Dolph',    'Hanna',
% 	             'Nutbess', 'spline',  'none'
%                    (the empty string means no window, 'Rect' and 'none'  are 
%                     equivalent)
%                Default: {'window','Hanning'}
%                         
% OUTPUT
% wavelet      seismic structure with desired wavelet
%
% EXAMPLE
%          %    Compute minimum-phase equivalent of wavelet "wavelet"
%          seismic=s_data;
%          minwav=s_seismic2wavelet(seismic,{'color','blue'},{'type','min-phase'},{'wlength',80});
%          s_wplot(minwav)

global S4M

history=S4M.history;
S4M.history=logical(0);

%	Assign default values of input argumnets
param.length=[];
param.wlength=80;
param.type='zero-phase';
param.color='blue';
param.scale=1;
param.window='Hanning';
param.dc=logical(0);

%       Decode and assign input arguments
param=assign_input(param,varargin,'s_seismic2wavelet');

%	Handle legacy code
if ~isempty(param.length)
   alert('Use of keyword "length" is obsolete. Use "wlength" instead.')
   param.wlength=param.length;
end

if iscell(param.wlength)
   len=param.wlength{1};
   lopt=param.wlength{2};
else
   len=param.wlength;
   lopt='approx';
end

if strcmpi(param.window,'none')
   param.window='rect';
end

nlag=round(0.5*len/seismic.step);
lag=nlag*seismic.step;
ntr=size(seismic.traces,2);

switch param.type

                case 'zero-phase'
lag2=2*lag;
%seismic1=seismic;
%seismic1.traces=cumsum(seismic1.traces);%test
temp=s_correlate(seismic,seismic,{'lags',-lag2,lag2},{'normalize','no'}, ...
       {'option','corresponding'});
if ntr > 1
   temp.traces=mean(temp.traces,2);
end

nsamp=length(temp.traces);
if ~isempty(param.window)
   w=mywindow(nsamp,param.window);
   sp=sqrt(abs(fft(w.*temp.traces)));
else
   sp=sqrt(abs(fft(temp.traces)));
end


%	Reflectivity correction
if strcmpi(param.color,'blue')
   refl=min((1:nsamp-1)',(nsamp-1:-1:1)');
   refl=sqrt(refl);
   sp(2:end)=sp(2:end)./refl;
   sp(1)=0;
end  


%       Determination of wavelet length
filt=fftshift(real(ifft(sp)));
%filt=real(ifft(sp));

if strcmp(lopt,'approx')
   index=find(filt(1:nlag+1).*filt(2:nlag+2) <= 0);
   if isempty(index)
      filt=filt(nlag+1:end-nlag);
      filt([1,end])=0.5*filt([1,end]);
      filt=filt-sum(filt)/(length(filt)-1);
   else
      nlag=index(end);
      filt=filt(nlag+1:end-nlag);
      lag=lag2-nlag*seismic.step;
      filt=filt-sum(filt)/(length(filt)-1);
   end
else
   filt=filt(nlag+1:end-nlag);
   filt([1,end])=0.5*filt([1,end]);
   filt=filt-sum(filt)/(length(filt)-1);
%  disp('here')
end

if ~param.dc	% Remove DC component
%   filt=lf_dc_removal(filt);
end

htext='Zero phase wavelet';
wavelet=s_convert(filt,-lag,seismic.step,htext,seismic.units);
wavelet.name='Zero-phase wavelet from seismic';


                case {'min-phase','max-phase'}
% lag2=4*lag;
lag2=2*round(len/seismic.step);
temp=s_correlate(seismic,seismic,{'lags',-lag2,lag2},{'normalize','no'}, ...
       {'option','corresponding'});
if ntr > 1
   temp.traces=mean(temp.traces,2);
end

if param.dc	% Remove DC component
%   temp.traces=lf_dc_removal(temp.traces);
end

nsamp=length(temp.traces);
if ~isempty(param.window)
   w=mywindow(nsamp,param.window);
   sp=sqrt(abs(fft(w.*temp.traces,8*nsamp)));
else
   index=find(temp.traces(1:end-1).*temp.traces(2:end) <= 0);
   ik=index(1);
   sp=sqrt(abs(fft(temp.traces(ik+1:end-ik),8*nsamp)));
end

nlag2=round(len/seismic.step)+1;
filt=minimum_phase(sp,2*nlag2);
if strcmp(lopt,'approx')
   index=find(filt(nlag2-1:end-1).*filt(nlag2:end) <= 0);
   nlag2=index(1)+nlag2-2;
end
filt=filt(1:nlag2);

if strcmpi(param.type,'min-phase')
   htext='Minimum-phase wavelet';
   wavelet=s_convert(filt,0,seismic.step,htext,seismic.units);
   wavelet.name='Minimum-phase wavelet from seismic';

else
   htext='Maximum-phase wavelet';
   wavelet=s_convert(flipud(filt),(1-nlag2)*seismic.step,seismic.step,htext, ...
      seismic.units);
      wavelet.name='Maximum-phase wavelet from seismic';
end
                otherwise
error([' Unknown or unimplemented type: "',param.type,'"'])
      
end		% End of switch block


%       Scaling
temp1=mean(sum(seismic.traces.^2));
temp2=sum(wavelet.traces.^2);
wavelet.traces=wavelet.traces*(param.scale*sqrt(temp1/temp2));


S4M.history=history;
wavelet.tag='wavelet';
wavelet.window_type=param.window;

if strcmpi(param.color,'blue')
   wavelet.info={'Wavelet estimation method: ','Wavelet estimate from seismic (blue reflectivity)'};
else
   wavelet.info={'Wavelet estimation method: ','Wavelet estimate from seismic (white reflectivity)'};
end

if isfield(seismic,'history')
   wavelet.history=seismic.history;
   wavelet=s_history(wavelet,'append',['Window-type: ',param.window,'; length: ',num2str(len),' ms']);
end

