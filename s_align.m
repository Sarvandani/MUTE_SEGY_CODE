function seisout=s_align(seisin,varargin)
% Function aligns (flattens) user-specified events on seismic traces. The 
% shifts required for alignment as well as the correlation coefficient can 
% be stored in headers.
%
% Written by: E. R.: February 19, 2001
% Last updated: April 3, 2006: Add all header mnemonics with the "add_ne" option
%
%             seisout=s_align(seisin,varargin)
% INPUT
% seisin      seismic structure
% varargin    one or more cell arrays; the first element of each cell array is a keyword,
%             the other elements are parameters. Presently, keywords are:
%     'reference' reference trace in terms of a header mnemonic
%           General form: {'reference',mnem,value}
%           "mnem" denotes a string with a header mnemonic ('trace_no' is permissible
%           even if there are no headers). "value" is the value of the header mnemonic.
%           An error message is printed if the header mnemonic does not exist or if
%           there is no trace or more than one trace with this value.
%           Default: {'reference','trace_no',1}
%     'window'   start time and end time of a window on the reference trace;
%           the other traces are aligned to the signal in this window.
%           General form: {'window',ta,te};  seisin.first < ta < te < seisin.last
%           Default: {'window',seisin.first,seisin.last}
%     'maxshift' Maximum shift (ms) allowed in either direction. It should be
%           chosen big enough to include all possible shifts between the 
%           reference signal on the reference trace and the corresponding 
%           signal on any other trace. See also keyword 'adapt' below.
%           Default: {'maxshift',0.5*seisin.last-seisin.first)}
%     'adapt'    String variable specifying if the window should remain fixed (adapt='no')
%           or move with the event (adapt='yes'). If the shifts have a "trend" the
%           maxshift value can be chosen to equal the maximum trace-to-trace shift
%           which could be fairly small.
%           Default: {'adapt','yes'} unless 'maxshift' is not defined.
%     'shifts'   Header mnemonic to use to store the shifts that were applied
%           to the traces. General form: {'shifts',mnemonic}
%           Shifts are not stored if "mnemonic" is an empty string
%           Default: {'shifts','align_shifts'}
%     'correlations' Header mnemonic used to store correlation coefficients. 
%           General form: {'correlation',mnemonic}
%           Correlation coefficients are not stored if "mnemonic" is 
%           an empty string
%           Default: {'correlation','align_corr'}
%     'method'   Method used to establish maximum similarity.
%           Method 1: Normalized cross-correlation
%           method 2: Crosscorrelation without trace-segment normalization
%           Default: {'method',2}
%     'update'   numerical factor specifying if the reference signal is to be 
%           the signal  updated to account for systematic column-to-column changes in
%           (e.g. NMO stretch). "update" must satisfy 0 <= update <= 1.           
%           new_reference_signal=(1-update)*old_reference_signal + 
%                         update*signal_on_last_trace
%           Default: {'update',0}   (i.e. reference signal is not updated)
%     'option'   this keyword determines what should be done with data that 
%           are shifted outside the time range of seisin. Options are:
%           'extend'   extend the time range to accommodate all shifts. 
%                  This is the default. It means that
%                  seisout.first=seisin.first+min(shifts)
%                  seisout.last=seisin.last+max(shifts)                   
%           'truncate' trace values that fall outside the time range of seisin are 
%                    discarded  
%          'circular' a circular time shift is applied.
%     'null'     value to use for samples that have been shifted into the time range of
%          "seisout". This will happen whenever different traces are shifted by 
%           different amounts AND 'type' is not 'circular'. 
%           Default: null=0.
%           If seisin has no null field and null=0, then a seisout will have no null
%           field either.
%           
% OUTPUT
% seisout     seismic structure with shifts applied; unless specified otherwise, shifts and
%             correlation coefficients are stored in headers.    

if ~istype(seisin,'seismic')
   error(' First input argument must be a seismic dataset.')
end

%       Set default values for input arguments
param.adapt='yes';      
param.correlations='align_corr';
param.maxshift=[];
param.null=0;
param.reference={'trace_no',1};
param.option='extend';
param.shifts='align_shifts';
param.method=2;
param.update=0;
param.window={seisin.first,seisin.last};

%       Get input arguments
param=assign_input(param,varargin,'s_align');

method=param.method;

ntr=size(seisin.traces,2);
if ntr == 1
   seisout=seisin;
   if ~isempty(param.shifts)
      seisout=s_header(seisout,'add_ne',param.shifts,0,seisout.units, ...
             'Time shifts applied to traces in param');
   end
   if ~isempty(param.correlations)
      seisout=s_header(seisout,'add_ne',param.correlations,1,'n/a', ...
             'Coefficient of correlation with reference signal');
   end
   return
end

if isempty(param.window)
   error(' Window containing event must be specified')
else
   if iscell(param.window)
      param.window=cell2num(param.window);
   end
   ita=round((param.window(1)-seisin.first)/seisin.step);
   ite=round((param.window(2)-seisin.first)/seisin.step);
   ta=ita*seisin.step+seisin.first;
   te=ite*seisin.step+seisin.first;
   if find(diff([seisin.first;ta;te;seisin.last]) < 0)
      error([' Window (',num2str([ta,te]),') is not within range of seismic data (', ...
          num2str([seisin.first,seisin.last]),').'])
   end
end

if isempty(param.maxshift)
   param.maxshift=round(0.5*(seisin.last-seisin.first)/seisin.step);
   param.adapt='no';
else
   param.maxshift=round(param.maxshift/seisin.step);
end

if ~iscell(param.reference)   % Substitute default header if none is given
   param.reference={'trace_no',param.reference};
end
itrace=param.reference{2};

if strcmpi(param.reference{1},'trace_no') 
   if itrace < 1 | itrace > ntr
      error([' Reference trace (',num2str(itrace),') outside range of traces (1-', ...
         num2str(ntr),') available'])
   end
else
   headers=s_gh(seisin,param.reference{1});
   itrace=find(ismember(headers,itrace));
   if length(itrace) > 1
      error([' More than one header "',param.reference{1},'" with value ',num2str(param.reference{2})])
   elseif isempty(itrace)
      error([' No header "',param.reference{1},'" with value ',num2str(param.reference{2})])
   else
      %  Everything OK
   end
end

%      Compute lags
if isfield(seisin,'null')
   temp=seisin.traces;
%   index=find(isnan(temp));
   temp(isnan(temp))=0;
   disp(' Alert from "s_align": Null values in data set replaced by zeros')
   if strcmpi(param.adapt,'yes')
      [lags,cc]=trace_align_adapt(temp,itrace,ita+1,ite+1, ...
                param.maxshift,param.update,method);
   else
      [lags,cc]=trace_align_noadapt(temp,itrace,ita+1,ite+1, ...
                 param.maxshift,param.update,method);
   end
else
   if strcmpi(param.adapt,'yes')
      [lags,cc]=trace_align_adapt(seisin.traces,itrace,ita+1,ite+1, ...
                param.maxshift,param.update,method);
   else
      [lags,cc]=trace_align_noadapt(seisin.traces,itrace,ita+1,ite+1, ...
                param.maxshift,param.update,method);
   end
end

shifts=lags*seisin.step;

%      Shift input traces
seisout=s_shift(seisin,{'shifts',shifts},{'option',param.option},{'null',param.null});

%      Store crosscorrelations in header
if ~isempty(param.correlations)
   seisout=s_header(seisout,'add_ne',param.correlations,cc,'n/a', ...
                  'Coefficient of correlation with reference signal');
end

%      Store shifts in header
if ~isempty(param.shifts)
   seisout=s_header(seisout,'add_ne',param.shifts,shifts,'ms', ...
                  'Time shifts applied to traces');
end

%    Append history field
if isfield(seisin,'history')
   htext=[ 'adapt: ',param.adapt,', update: ',num2str(param.update),', option: ',param.option];
   seisout=s_history(seisout,'append',htext);
end 


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [lag,cc]=trace_align_adapt(a,itr,ia,ie,maxshift,update,method)
% Function aligns a "signal" in columns of matrix "a" with the signal in a 
% reference column. 
% It outputs the shifts required for alignment with this reference signal 
% and the coefficient of correlation.
%                [lag,cc]=align(a,itr,ia,ie,maxshift,update,method)
% INPUT
% a         matrix whose columns are to be aligned
% itr       index of column to use as reference for alignment
% ia        index of first row to use for the signal in the reference column
% ie        index of last row to use for the signal in the reference column
% maxshift  maximum shift (up or down) allowed
% update    numerical factor specifying if the reference signal is to be updated to account
%           for systematic column-to-column changes in the signal (e.g. NMO stretch).
%           "update" must satisfy 0 <= update <= 1.
%           new_reference_signal=(1-update)*old_reference_signal + update*signal_on_last_trace
% method    option regarding measurement of similarity
% OUTPUT
% lag       shifts found (of course, lag(itr)=0). Positive values of the lag 
%           mean a shift down, negative values a shift up.
% cc        crosscorrelation between the reference signal and the signal
%            on each trace. (Of course, cc(itr)=1).


[nsamp,ntr]=size(a);
ref=a(ia:1:ie,itr);
nref=length(ref);
%index=zeros(ntr,1);

iai=ia;                         % Initialize start of search window
iei=ie;
lag=zeros(ntr,1);
cc=ones(ntr,1);
refi=ref;
for ii=itr-1:-1:1
  minshift=-min([maxshift,iai-1]);
  iae=iai+minshift;
  aa=a(iae:min([iei+maxshift,nsamp]),ii);
  if method == 1 
    [cci,lagi]=cornor(aa,refi,'max');
  else
    [lagi,cci]=max_corr(aa,refi,0,-minshift+maxshift);
  end 
  lag(ii)=lag(ii+1)-lagi-minshift;
  cc(ii)=cci;

  iai=ia-lag(ii);   % Update start of search window
  iei=ie-lag(ii);

% 	Update reference signal          
  if lagi >= 0
  tie=iae+lagi+nref-1;
    if tie > nsamp
      refi=refi*(1-update)+[update*a(iae+lagi:nsamp,ii);zeros(tie-nsamp,1)];
    else
      refi=refi*(1-update)+update*a(iae+lagi:tie,ii);
    end
  else
    refi=refi+[zeros(1-lagi,1);update*aa(1:nref+lagi-1)];
  end

end

iai=ia;             % Initialize start of search window
iei=ie;
refi=ref;
for ii=itr+1:ntr
  minshift=-min([maxshift,iai-1]);
  iae=iai+minshift;
  aa=a(iae:min([iei+maxshift,nsamp]),ii);
  if method == 1 
    [cci,lagi]=cornor(aa,refi,'max');
  else
    [lagi,cci]=max_corr(aa,refi,0,-minshift+maxshift);
  end 
  lag(ii)=lag(ii-1)-lagi-minshift;
  cc(ii)=cci;
  iai=ia-lag(ii);     % Update start of search window
  iei=ie-lag(ii);

% 	Update reference signal         
  if lagi >= 0
    tie=iae+lagi+nref-1;
    if tie > nsamp
      refi=refi*(1-update)+[update*a(iae+lagi:nsamp,ii);zeros(tie-nsamp,1)];
    else
      refi=refi*(1-update)+update*a(iae+lagi:tie,ii);
    end 
  else
    nref=nref+lagi;
%    refi=refi(1-lagi:end)+update*aa(1:nref);
    refi=refi+[zeros(1-lagi,1);update*aa(1:nref+lagi-1)];
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [lag,cc]=trace_align_noadapt(a,itr,ia,ie,maxshift,update,method)
% Function aligns a "signal" in columns of matrix "a" with the signal in a 
% reference column. 
% It outputs the shifts required for alignment with this reference signal 
% and the coefficient of correlation.
% INPUT
% a         matrix whose columns are to be aligned
% itr       index of column to use as reference for alignment
% ia        index of first row to use for the signal in the reference column
% ie        index of last row to use for the signal in the reference column
% maxshift  maximum shift (up or down) allowed
% update    numerical factor specifying if the reference signal is to be updated to 
%           account for systematic column-to-column changes in the signal .
%           (e.g. NMO stretch) "update" must satisfy 0 <= update <= 1.
%           new_reference_signal=(1-update)*old_reference_signal 
%                               +update*signal_on_last_trace
% method    option regarding measurement of similarity
% OUTPUT
% lag       shifts found (of course, lag(itr)=0). Positive values of the lag mean a shift
%           down, negative values a shift up.
% cc        crosscorrelation between the reference signal and the signal on each trace.
%           (Of course, cc(itr)=1).
%                [lag,cc]=align(a,itr,ia,ie,maxshift,adapt,update)

[nsamp,ntr]=size(a);
ref=a(ia:1:ie,itr);
nref=length(ref);

minshift=-min([maxshift,ia-1]);
%iae=max([ia-maxshift,1]);
iae=ia+minshift;
aa=a(iae:min([ie+maxshift,nsamp]),:);
lag=zeros(ntr,1);
cc=ones(ntr,1);
refi=ref;
for ii=itr-1:-1:1
  if method == 1 
    [cci,lagi]=cornor(aa(:,ii),refi,'max');
  else
    [lagi,cci]=max_corr(aa(:,ii),refi,0,maxshift-minshift);
  end

  lag(ii)=-lagi-minshift;
  cc(ii)=cci;
  ia1=max(ia-lag(ii),1);
  ia1=min(nsamp-nref+1,ia1);
  refi=(1-update)*refi+update*a(ia1:ia1+nref-1,ii);
end

refi=ref;
for ii=itr+1:ntr
  if method == 1 
    [cci,lagi]=cornor(aa(:,ii),refi,'max');
  else
    [lagi,cci]=max_corr(aa(:,ii),refi,-2*maxshift,2*maxshift);
  end
  lag(ii)=-lagi-minshift;
  cc(ii)=cci;

  ia1=max(ia-lag(ii),1);
  ia1=min(nsamp-nref+1,ia1);
  refi=(1-update)*refi+update*a(ia1:ia1+nref-1,ii);
end 

