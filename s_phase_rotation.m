function seisout=s_phase_rotation(seisin,phase,varargin)
% Function rotates phase of each trace in the input data set.
% If more than one phase angle is given (if "phase" is an array), the output
% can be a seismic structure array with the same dimension as "phase" or a regular
% seismic structure where the number of traces of the output data set equals 
% the number of traces of the input data set multiplied by the number of elements
% of "phase" (default).
% Written by: E. R., January 28, 2001.
% Last updated:
%
%       seisout=s_phase_rotation(seisin,phase,varargin)
% INPUT
% seisin    seismic data set
% phase     phase angle or array of phase angles (in degree)
% varargin    one or more cell arrays; the first element of each cell array is a keyword,
%             the other elements are parameters. Presently, keywords are:
%       'output'   Type of output. The options are 'standard' and 'array'. the latter
%             creates a structure array; one structure element for each phase if "phase" 
%             is an array.   Default: {'output','standard'}
%             This is only relevant if "phase" has at least two elements.
%       'header'  header mnemonic to use for phase. No header added if empty string
%             Default: {'header','phase'}
%       'add_option'  Possible values are 'add' (add header, abort with error 
%             if header already exists) and 'add_ne' (add header, overwrite 
%             header if it exists; no error)
%             Default:{'add_option','add'}
% OUTPUT
% seisout   seismic structure or seismic structure array with phase rotated 

global S4M

%       Set defaults
param.output='standard';
param.header='phase';
param.add_option='add';

%       Get input arguments
param=assign_input(param ,varargin);

[nsamp,ntr]=size(seisin.traces);
nphase=length(phase);

if nsamp < 3
   disp([' Alert from "s_phase_rotation": traces have only ',num2str(nsamp),' samples'])
end

if isfield(seisin,'null')
   temp=seisin.traces;
   index=find(isnan(temp));
   if ~isempty(index)
      temp=temp(index);
      disp(' Alert from "s_phase_rotation": NaNs replaced by zeros')
    end
   hseis=myhilbert(temp);
else
   hseis=myhilbert(seisin.traces);
end

cphase=phase*pi/180;
sph=sin(cphase);
cph=cos(cphase);
if nphase == 1
  seisout.traces=cph*real(hseis)-sph*imag(hseis);

%       Copy rest of fields
  seisout=copy_fields(seisin,seisout);

  if ~isempty(param.header)
    temp=S4M.history;
    S4M.history=0;
    seisout=s_header(seisout,param.add_option,param.header,phase,'degree','Phase angle');
    S4M.history=temp;
  end

%	Append history field
  if isfield(seisin,'history')
    htext=['Phase rotation: ',num2str(phase),' degrees'];
    seisout=s_history(seisout,'append',htext);
  end 
 
else

  switch param.output
                        case 'standard'
  ntr_new=ntr*nphase;
  seisout.traces=zeros(nsamp,ntr_new);
  if isfield(seisin,'headers')
    nh=size(seisin.headers,1);
    seisout.headers=zeros(nh+1,ntr_new);
    seisout.header_info=[seisin.header_info;{param.header,'degree','Phase angle'}];
  else
    nh=0;
    seisout.headers=zeros(1,ntr_new);
    seisout.header_info={param.header,'degree','Phase angle'};
  end
  
  ia=1;
  ie=ntr;
  for ii=1:nphase
     seisout.traces(:,ia:ie)=cph(ii)*real(hseis)-sph(ii)*imag(hseis); 
     if nh > 0
       seisout.headers(1:nh,ia:ie)=seisin.headers;
     end
     seisout.headers(nh+1,ia:ie)=phase(ii);
     ia=ie+1;
     ie=ie+ntr;  
  end

%       Copy rest of fields
  seisout=copy_fields(seisin,seisout);

%    Append history field
  if isfield(seisin,'history')
     htext=['Phase rotations: ',num2str(phase),' degrees'];
     seisout=s_history(seisout,'append',htext);
  end 
 
                        case 'array'
  temp=seisin;
  if isfield(seisin,'headers')
     nh=size(seisin.headers,1);
     temp.header_info=[temp.header_info;{param.header,'degrees','Phase angle'}];
     temp.headers=[temp.headers;zeros(1,ntr)];
  else
     nh=0;
     temp.header_info={param.header,'degrees','Phase angle'};
     temp.headers=zeros(1,ntr);
  end
  for ii=1:nphase
     seisout(ii)=temp;
     seisout(ii).traces=cph(ii)*real(hseis)-sph(ii)*imag(hseis);
     seisout(ii).headers(nh+1,:)=phase(ii);

%       Append history field
     if isfield(seisin,'history') & S4M.history
        htext=['Phase rotation: ',num2str(phase(ii)),' degrees'];
        seisout(ii)=s_history(seisout(ii),'append',htext);
     end 
  end

                        otherwise
  error([' Unknown output type "',param.output,'"'])

   end
end

if isfield(seisout,'null')
   seisout=rmfield(seisout,'null');
end



