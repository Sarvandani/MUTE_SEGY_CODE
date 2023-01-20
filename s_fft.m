function [ftseismic,aux]=s_fft(seismic,varargin)
% Function computes amplitude spectrum or Fourier transform of the traces of 
% the seismic input data set
%
% Written by: E. R., February 19, 2001
% Last updated: November 14, 2004: Add output argument aux
%
%	    [ftseismic.aux]=s_fft(seismic,varargin)
% INPUT
% seismic   seismic data set
% varargin  one or more cell arrays; the first element of each cell array is a
%           keyword, the other elements are parameters. Presently, keywords are:
%      'output' type of output. Possible values are:
%              'amp'    amplitude spectrum
%              'ft'     Fourier transform (complex)
%              Default: {'output','amp'}
%      'df' sample interval in the frequency domain (achieved by padding)
%           only used if it is less than the default sample interval
%                1/(seismic.last-seismic.first)
%           Default: {'df',[]} 
%             use sample interval 2*Nyquist_frequency/(number_of_samples_per_trace - 1 )
% OUTPUT
% ftseismic  Amplitude spectrum or Fourier transform of traces of seismic input data
% aux      Auxiliary data
%      'frequencies'  vector of frequencies; i.e. ftseismic.first:ftseismic.step:ftseismic.last

%	Set default parameters
param.output='amp';
param.df=[];
param.window=[];

%	Decode input arguments
param=assign_input(param,varargin);

if isfield(seismic,'null')
   seismic=s_rm_trace_nulls(seismic);
end
nsamp=size(seismic.traces,1);
nyquist=500/seismic.step;
if ~isempty(param.df) & param.df > 0
   nfft=2*nyquist/param.df;
else
   nfft=nsamp;
end
freq=(0:2:nfft)*nyquist/nfft;

ftseismic.first=0;
ftseismic.last=freq(end);
ftseismic.step=freq(2);
ftseismic.units='Hz';
if isempty(param.window)
   temp=seismic.traces;
else
   try
      wndw=mywindow(nsamp,param.window);
      temp=zeros(nsamp,ntr);
      for ii=1:ntr
         temp(:,ii)=seismic.traces(:,ii).*wndw;
      end
   catch
      temp=seismic.traces;
      alert(['Window "',param.window,'" could not be applied'])
   end
end

%       Number of samples in the frequency domain
nsamp=round(ftseismic.last/ftseismic.step)+1;

ftseismic.traces=fft(temp,nfft);
ftseismic.traces=ftseismic.traces(1:nsamp,:);
if strcmpi(param.output,'amp')
   ftseismic.traces=abs(ftseismic.traces);
   htext='Amplitude spectrum';
else
   htext='Fourier transform';
end

if nargout > 1
   aux.frequencies=freq;
end

%       Copy rest of fields
ftseismic=copy_fields(seismic,ftseismic);

%    Append history field
if isfield(seismic,'history')
   ftseismic=s_history(ftseismic,'append',htext);
end

        

