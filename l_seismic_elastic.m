function wlog=l_seismic_elastic(wlog,varargin)
% Function computes seismic-relevant curves such as P-velocity, S-velocity, acoustic
% impedance, and Poison's ratio provided they do not yet exist
% Function assumes that the input wlog has at least the following curves
%      DTp or Vp
%      DTs or Vs
%      rho
% and computes the following additional curves if they do not exist
%      Vp
%      Vs
%      PR
%      aImp
%
% Written by: E. R.: December 22, 2000
% Updated: September 28, 2004: Update field "curve_types" if this field is present
%
%               wlog=l_seismic_elastic(wlog,varargin)
% INPUT
% wlog   log structure with at least the curves listed above
% varargin    one or more cell arrays; the first element of each cell array is 
%        a keyword, he other elements are parameters. Presently, keywords are:
%     'fix_pr"  defines what to do with PR values that are < 0 or > 0.5
%        possible values are 'yes'  (replace them by their limits), 
%                            'no',  (keep them as is
%                            'nan', (replace them by NaN's)
%        DEfault: {fix_pr','yes'}
%      new definitions of curve mnemonics of the form {'rho','RHOB')
%        By default, the function uses the definitions of global structure
%        CURVES as defined in function "presets"
%          
% OUTPUT
% wlog   log structure with all input curves and those additional curves listed 
%        above if they do not exist among the curves of the input log.

param.fix_pr='yes';

[param,cm]=l_assign_input(param,varargin);


% Check for existence of density
[irho,ier]=curve_index1(wlog,cm.rho);
if isempty(irho)
   disp(' Log must have curve for density')
   disp([' Curve mnemonics of log: ',cell2str(wlog.curve_info(:,1),', ')])
   error(' Abnormal termination')  
end

%    Check for existence of P-velocity curve and compute it from sonic if absent
[ivp,ier]=curve_index1(wlog,cm.vp);
if isempty(ivp)
   [idtp,ier]=curve_index1(wlog,cm.dtp);
   if isempty(idtp)
      disp(' Log must have either a P-sonic (DTP) or a P-velocity (Vp) curve')
      disp([' Curve mnemonics of log: ',cell2str(wlog.curve_info(:,1),', ')])
      error(' Abnormal termination')
   else
      nadd=1;
      new_col=1.0e6./wlog.curves(:,idtp);  
      if strcmpi(wlog.curve_info{idtp,2},'us/m')
         punits='m/s';
      elseif strcmpi(wlog.curve_info{idtp,2},'us/ft')
         punits='ft/s';
      else
        error([' Unknown units of sonic log: ', wlog.curve_info{idtp,2}]) 
      end 
      new_info={cm.vp,punits,'P-velocity'};
      new_curve_type={cm.vp,'Vp','sonic velocity'};
  end
else
   punits=wlog.curve_info{ivp,2};
   nadd=0;
   new_col=[];
   new_info=[];
   new_curve_type=[];
end

%    Check for existence of S-velocity curve and compute it from shear sonic if absent
[ivs,ier]=curve_index1(wlog,cm.vs);
if isempty(ivs)
   [idts,ier]=curve_index1(wlog,cm.dts);
   if isempty(idts)
      disp(' Log must have either a S-sonic (DTS) or an S-velocity (Vs) curve')
      disp([' Curve mnemonics of log: ',cell2str(wlog.curve_info(:,1),', ')])
      error(' Abnormal termination')
   else
      nadd=nadd+1;
      new_col=[new_col,1.0e6./wlog.curves(:,idts)];    
      if strcmpi(wlog.curve_info{idts,2},'us/m')
         sunits='m/s';
      elseif strcmpi(wlog.curve_info{idts,2},'us/ft')
         sunits='ft/s';
      else
         error([' Unknown units of shear log: ', wlog.curve_info{idts,2}]) 
      end
      new_info=[new_info;{cm.vs,punits,'S-velocity'}];
      new_curve_type=[new_curve_type;{cm.vs,'Vs','shear velocity'}];
   end
else
   sunits=wlog.curve_info{ivs,2};
end

%       Check if P-velocity and S-velocity have the same units of measurement
if ~strcmpi(sunits,punits)
   disp([' P-velocity and S-velocity do not have the same units of measurement: ', ...
      punits,', ',sunits])
   error(' Abnormal termination')
end

if nadd > 0
   wlog.curves=[wlog.curves,new_col];
   wlog.curve_info=[wlog.curve_info;new_info];
   wlog=add_curve_type(wlog,new_curve_type);
end

%       Compute Poison's ratio if not present in input log
ivp=curve_index1(wlog,cm.vp);
[ipr,ier]=curve_index1(wlog,cm.pr);
if isempty(ipr)
   ivs=curve_index1(wlog,cm.vs);
%   nadd=1;
   vp2=wlog.curves(:,ivp).^2;
   vs2=wlog.curves(:,ivs).^2;
   new_curve=0.5*(vp2-2*vs2)./(vp2-vs2);
   switch param.fix_pr
      case 'yes'
         new_curve(new_curve > 0.5)=0.5;
         new_curve(new_curve < 0)=0;
      case 'nan'
         new_curve(new_curve > 0.5  |  new_curve < 0)=NaN;
      case 'no'
         % Do nothing
      otherwise
         alert('Unknown value for keyword "fix_par"')
   end

   new_info={cm.pr,'n/a','Poisson''s ratio'};

else
%   nadd=0;
   new_curve=[];
   new_info=[];

end

%       Compute acoustic impedance if not present in input log
[iaimp,ier]=curve_index1(wlog,cm.aimp);
if isempty(iaimp)
  runits=wlog.curve_info{irho,2};
%  nadd=nadd+1;
  new_curve=[new_curve,wlog.curves(:,ivp).*wlog.curves(:,irho)];
  new_info=[new_info;{cm.aimp,[punits,' x ',runits],'Acoustic impedance'}]; 
  wlog=add_curve_type(wlog,{cm.aimp,'Imp','impedance'});
end

%       Add to existing curves
wlog.curves=[wlog.curves,new_curve];
wlog.curve_info=[wlog.curve_info;new_info];

