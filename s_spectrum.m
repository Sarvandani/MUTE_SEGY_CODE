function aux=s_spectrum(varargin)
% Function computes the spectrum of seismic input data sets. Null values in any
% data set are replaced by zeros.
%
% Written by E. R., July 3, 2000
% Last updated: May 4, 2006: Also output the curve handles
% 
%          aux=s_spectrum{varargin}
% INPUT
% The first input parameters are seismic data sets (seismic data structures) or matrices;
% If they are matrices they are converted to seismic structures with units 'samples'.
% It is importatn that all seismic input data sets and matrices converted to seismic data 
% sets have the same units
% The seismic data sets may be followed by cell arrays which consist of a keyword and 
% one or more parameters
% seis1    seismic structure or matrix
% seis2    seismic structure or matrix
%  ...
% seisn    seismic structure or matrix
%          
% parameters   one or more cell arrays; the first element of each cell array is a keyword,
%             the other elements are parameters. Presently, keywords are:
%        'colors'     Colors to be used for consecutive curves.
%                     Possible values: any permissible colors and line styles
%                     Default: {'colors','r','b','g','m','k','c','y',...
%                               'r--','b--','g--','m--','k--','c--','y--' ...
%                               'r:','b:','g:','m:','k:','c:','y:'};
%        'figure'     Specifies if new figure should be created or if the seismic traces 
%                     should be plotted to an existing figure. Possible values are 'new' 
%                     and any other string. 
%                     Default: {'figure','new'} 
%        'frequencies'  Two positive numbers representing the range of frequencies to 
%                     display. The first number must be non-negative and smaller than 
%                     the second. If the second number is greater than the Nyquist 
%                     frequency of the data set with the smallest sample interval, it 
%                     is set to the Nyquist frequency.
%                     Default: {'frequencies',0,inf}
%        'legend'     Figure legend (curve annotation).
%                     Default: names of the seismic input data sets.
%        'lloc'       Location of figure legend. Possible values are 1,2,3,4,5;
%                     Default: for phase and amplitude and phase plots: {'loc',5}
%                              for amplitude plots: {loc',1}
%        'linewidth'  Line width of curves. Default: {'linewidth',2}
%        'option'     Defines how multi-trace data sets are handled. 
%                     Possible values: 'envelope' (the envelope of all spectra), 
%                                      'average'  (the average of all spectra) 
%                     Default: {'option','average'};
%        'orient' Plot orientation. Possible values are: 'portrait' and 'landscape'
%                     Default: {'orient','landscape'}
%        'plot'       Types of plot(s) to create. Possible values are: 'amp' (plot 
%                     amplitude spectrum) and/or one of the two:
%                       'phase' (plot phase spectrum restricted to -180 to 180 degrees)
%                       'phaseu' (plot phase spectrum unwrapped)
%                     Thus {'plot','amp','phase'} will plot amplitude and phase spectrum
%                     Default: {'plot','amp'} ... plot amplitude spectrum only
%        'padding'    Traces with fewer than "padding" samples are padded with
%                     zeros. This parameter is ignored if the number of samples 
%                     per trace exceeds "padding". Default:{'padding',256}
%        'normalize'  Establish if the amplitude spectra are to be normalized.
%                     Possible values: 'yes' and 'no'. Default: {'normalize','yes'}
%        'scale'      Set linear (amplitude), power, or logarithmic scale (dB) for amplitude spectrum.
%                     Possible values: 'linear', 'log'. Default: {'scale','linear'}
%        'single'     Option to plot spectra of individual traces; only one 
%                     input data set can be given {'single','yes'}
%                     Default: {'single','no'}
% OUTPUT
% aux    Structure
%        'figure_handle'   handle to figure
%        'zoom_handles'    handles to the zoom menu buttons
%        'amp_handles'     handle of the lines representing the amplitude spectrum (if any)
%        'phase_handles'   handle of the lines representing the phase spectrum (if any) 
%
% EXAMPLES
%        s_spectrum(wavelet,{'plot','amp','phase'},{'frequencies',0,80},{'padding',128})
%        s_spectrum(seismic,wavelet,{'scale','log'})


%       Find number of input seismic data sets and convert them to seismic datasets 
%       if they are matrices
nseis=nargin;
for ii=1:nargin
   if iscell(varargin{ii})
      nseis=ii-1;
      break

   else
      if ~isstruct(varargin{ii})
         varargin{ii}=s_convert(varargin{ii},1,1,' ','samples');
      end
   end
end

if nseis == 0
  error(' There must be at least one seismic data set or a matrix.')
end

%       Define defaults for parameters
param.colors={'r','b','g','k','c','m','y', ...
                 'r--','b--','g--','k--','c--','m--','y--', ...
                 'r:','b:','g:','k:','c:','m:','y:'};
param.figure='new';
param.legend=[];
param.lloc=[];
param.linewidth=2;
param.normalize='yes';
param.frequencies={0,inf};
param.padding=256;
param.option='average';
param.orient='landscape';
param.plot='amp';
param.scale='linear';
param.single='no';
param.window='none';

%       Replace defaults by actual input arguments
if nseis < nargin
   param=assign_input(param,{varargin{nseis+1:nargin}});
end

%       Prepare input arguments for actual use
if ~iscell(param.colors)
   param.colors={param.colors};
end

%       Determine what kind of plot to create (amplitude/phase/both/ ...)
ampplot=0;
phaseplot=0;
if iscell(param.plot)
   ampplot=1;
   phaseplot=1;
   if any(ismember(lower(param.plot),'phaseu'))
      unwrap_phase=1;
   else
      unwrap_phase=0;
   end
elseif strcmpi(param.plot,'amp')
   ampplot=1;
elseif strcmpi(param.plot,'phase')
   phaseplot=1;
   unwrap_phase=0;
elseif strcmpi(param.plot,'phaseu')
   phaseplot=1;
   unwrap_phase=1;
else
   error([ 'Unknown "plot" option: ',param.plot])
end


if isinf(param.frequencies{2}) 
   if nseis > 1
      dt=zeros(nseis,1);
      for ii=1:nseis
         dt(ii)=varargin{ii}.step;
      end
      param.frequencies{2}=500/min(dt);
   else
      param.frequencies{2}=500/varargin{1}.step;
   end
end
if param.frequencies{1} < 0;
   param.frequencies{1}=0;
end
if param.frequencies{1} >= param.frequencies{2}
   error([' Incompatible spectrum frequencies: ', ...
       num2str(param.frequencies{1}),' ',num2str(param.frequencies{2})])
end

if strcmpi(param.figure,'new')
   if nargout > 0
      if strcmpi(param.orient,'landscape')
         aux.figure_handle=lfigure;
      else
         aux.figure_handle=pfigure;
      end
      figure_export_menu(aux.figure_handle);
   else
      if strcmpi(param.orient,'landscape')
         figure_handle=lfigure;
      else
         figure_handle=pfigure;
      end
      figure_export_menu(figure_handle);
   end
end


%       Check if the spectra of individual traces of ONE dataset should be plotted
if strcmpi(param.single,'yes')
   if nseis > 1
      error(' If parameter "single" is "yes" there can be only one input seismic data set')
   else
      nseis=size(varargin{1}.traces,2);
   end
end

ltext=cell(nseis,1);    % Reserve room for legend

amp_handles=zeros(1,nseis);
phase_handles=zeros(1,nseis);


%       Main loop for plot generation
for ii=1:nseis
   if strcmpi(param.single,'yes')
      stemp=s_select(varargin{1},{'traces',ii});
      dsetname=['trace ',num2str(ii)];
   else
      stemp=varargin{ii};
      dsetname=inputname(ii);
   end
   if isfield(stemp,'null')
%      temp=S4M.history;
%      S4M.history=0;
      stemp=s_rm_trace_nulls(stemp);
%      S4M.history=temp;
       alert(['Null values in data set "',dsetname,'" have been replaced by zeros.'])
   end

  [nsamp,ntr]=size(stemp.traces);
  
  if nsamp <= 1
     error([' Fewer than 2 valid (not NaN) samples/trace in input data set ',num2str(ii),': ',dsetname])
  end

  if ~strcmpi(param.window,'none')      % Apply requested taper window
      stemp=s_window(stemp,param.window);
%      disp(' Taper not yet implemented')
  end

%       Compute FFT
  if param.padding > nsamp
     ft=fft(stemp.traces,param.padding);
  else
     ft=fft(stemp.traces);
  end

  nfft=size(ft,1);
  nyquist=500/stemp.step;
  f=(0:2:nfft)*nyquist/nfft;
  endfreq=f(end);
  nffth=length(f);
  if ampplot
     amp=abs(ft(1:nffth,:));
     if ntr > 0
       if strcmpi(param.option,'envelope')
         amp=max(amp,[],2);
         attribute=' (env)';
       elseif strcmpi(param.option,'average') 
         amp=mean(amp,2);
         attribute=' (av)';
       else
         disp([' Unknown option ',param.option])
         disp(' Passible values are: "envelope" and "average"')
         error(' Abnormal termination')
       end
     end

    if strcmpi(param.scale,'linear')
      if strcmpi(param.normalize,'yes')
         atext='Amplitude (normalied)';
      else
         atext='Amplitude';
      end
      amin=0;

    elseif strcmpi(param.scale,'power')
      if strcmpi(param.normalize,'yes')
         atext='Power (normalied)';
      else
         atext='Power';
      end
      amin=0;

    else
      atext='Amplitude (dB)';
      amp=amp/max(amp);
%      idx=find(amp < 1.0e-5);     
      amp(amp < 1.0e-5)=1.0e-5;   % Constrain the possible values of the amplitude spectrum
      amp=20*log10(amp/max(amp));
      amin=-inf;
    end

  end

  if phaseplot
             % Account for start time of signal 
     phshift=exp(0.002*pi*i*f*stemp.first)';
     if ntr > 1
       temp=mean(ft(1:nffth,:).*phshift(:,ones(ntr,1)),2);
     else
       temp=ft(1:nffth,:).*phshift;
     end  
 
     phase=atan2(imag(temp),real(temp));
     if ntr > 0 
       if strcmpi(param.option,'average')  
          phase=mean(phase,2);
       elseif strcmpi(param.option,'envelope')
          alert(' There is no meaningful interpretation of option "envelope" for the phase')
          alert(' average used instead')
          phase=mean(phase,2);
       else
         disp([' Unknown option ',param.option])
         disp(' Passible values are: "envelope" and "average"')
         error(' Abnormal termination')
       end
     end
     if unwrap_phase
        phase=unwrap(phase);         % Unwrap phase (MATLAB Signal Processing Toolbox)
     end
     phase=phase*(180/pi);
  end

  if param.frequencies{1} > 0 | param.frequencies{2} < endfreq;
%    idx=find(f > param.frequencies{1} & f < param.frequencies{2});
    ff=[param.frequencies{1},f(f > param.frequencies{1} & ...
                               f < param.frequencies{2}),param.frequencies{2}];
    if ampplot
       amp=interp1(f,amp,ff,'*linear');
       if strcmpi(param.scale,'linear') & strcmpi(param.normalize,'yes')
          amp=amp/max(amp);
       end
    end
    if phaseplot
       phase=interp1(f,phase,ff,'*linear');
    end
    f=ff;
  end

%               Create legend
  if ntr == 1
    attrib='';
  else
    attrib=attribute;
  end
  if ~isempty(dsetname)
    ltext(ii)={[strrep(dsetname,'_','\_'),attrib]};
  else
    ltext(ii)={['Input data ',num2str(ii),attrib]};
  end

  if ampplot		% Scale amplitude spectrum if desired
    if (strcmpi(param.scale,'linear') | strcmpi(param.scale,'power')) & strcmpi(param.normalize,'yes')
       amp=amp/max(amp);
    end
    if strcmpi(param.scale,'power')
       amp=amp.^2;
    end
  end

  if ampplot & phaseplot
     hh1=subplot(2,1,1); 
     bgGray
     amp_handles(ii)=plot(f,amp,get_color(ii,param.colors),'LineWidth',param.linewidth);
     if ii == 1
        axis([param.frequencies{1},param.frequencies{2},amin,inf])
     end
     hold on
     subplot(2,1,2); 
     phase_handles(ii)=plot(f,phase,get_color(ii,param.colors),'LineWidth',param.linewidth);
     bgGray
     hold on
     if unwrap_phase
        if nseis == 1
           ll=floor(min(phase/100))*100;
           uu=ceil(max(phase/100))*100;
           axis([param.frequencies{1},param.frequencies{2},ll,uu]);
        end

     elseif ii == 1
        axis([param.frequencies{1},param.frequencies{2},-180,180])
     end

  elseif ampplot
     amp_handles(ii)=plot(f,amp,get_color(ii,param.colors),'LineWidth',param.linewidth);
     bgGray
     hold on

  elseif phaseplot
     phase_handles(ii)=plot(f,phase,get_color(ii,param.colors),'LineWidth',param.linewidth);
     bgGray
     hold on
  else
    error(' Neither amplitude spectrum nor phase spectrum selected')
  end   
     
end

if strcmp(param.figure,'new')
   timeStamp;
end

units=getfield(varargin{1},'units');

if ampplot & phaseplot

  if isempty(param.lloc)     % Set location of legend
     loc=5;
  else
     loc=param.lloc;
  end
  if isempty(param.legend)
     legend(char(ltext),loc);
  else
     legend(param.legend,loc)
  end
  title('Phase Spectrum')
  if strcmpi(units,'ms')
     xlabel('Hz')
  elseif strcmpi(units,'s')
     xlabel('mHz')
  elseif strcmpi(units,'m')
     xlabel('Wavelengths per 1000 m')
  elseif strcmpi(units,'ft')
     xlabel('Wavelengths per 1000 ft')
  elseif strcmpi(units,'samples')
     xlabel('Wavelengths per 1000 samples')
  else
    % Unknown units: do nothing
  end
  ylabel('Phase angle in degree')
  grid on, zoom on
 
  axes(hh1)
  if isempty(param.legend)
     legend(char(ltext),loc);
  else
     legend(param.legend,loc)
  end
  
  title('Amplitude Spectrum')
  if strcmpi(units,'ms')
     xlabel('Hz')
  elseif strcmpi(units,'s')
     xlabel('mHz')
  elseif strcmpi(units,'m')
     xlabel('Wavelengths per 1000 m')
  elseif strcmpi(units,'ft')
     xlabel('Wavelengths per 1000 ft')
  elseif strcmpi(units,'samples')
     xlabel('Wavelengths per 1000 samples')
  else
    % Unknown units: do nothing
  end
  ylabel(atext)
  grid on, zoom on

elseif ampplot
  if isempty(param.lloc)     % Set location of legend
     loc=1;
  else
     loc=param.lloc;
  end
  if isempty(param.legend)
     legend(char(ltext),loc);
  else
     legend(param.legend,loc)
  end
  title('Amplitude Spectrum')

  if strcmpi(units,'ms')
     xlabel('Hz')
  elseif strcmpi(units,'s')
     xlabel('mHz')
  elseif strcmpi(units,'m')
     xlabel('Wavelengths per 1000 m')
  elseif strcmpi(units,'ft')
     xlabel('Wavelengths per 1000 ft')
  elseif strcmpi(units,'samples')
     xlabel('Wavelengths per 1000 samples')
  else
    % Unknown units: do nothing
  end
  ylabel(atext)
  grid on, zoom on

else
 if isempty(param.lloc)     % Set location of legend
     loc=5;
  else
     loc=param.lloc;
  end
  if isempty(param.legend)
     legend(char(ltext),loc);
  else
     legend(param.legend,loc)
  end
  title('Phase spectrum')

  if strcmpi(units,'ms')
     xlabel('Hz')
  elseif strcmpi(units,'s')
     xlabel('mHz')
  elseif strcmpi(units,'m')
     xlabel('Wavelengths per 1000 m')
  elseif strcmpi(units,'ft')
     xlabel('Wavelengths per 1000 ft')
  elseif strcmpi(units,'samples')
     xlabel('Wavelengths per 1000 samples')
  else
    % Unknown units: do nothing
  end
  
  ylabel('Phase angle in degree')
  grid on, zoom on

end
hold off

if ampplot
   aux.amp_handles=amp_handles;
end
if phaseplot
   aux.phase_handles=amp_handles;
end

if ampplot & phaseplot
   linkedzoom('onx2');
   if nargout > 0
      aux.zoom_handles=disable_zoom(aux.figure_handle);
   else
      disable_zoom(gcf)
   end
end


if nargout == 0
   clear aux
else
   if ampplot
      aux.amp_handles=amp_handles;
   end
   if phaseplot
      aux.phase_handles=amp_handles;
   end
end
