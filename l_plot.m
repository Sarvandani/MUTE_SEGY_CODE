function aux=l_plot(wlog,varargin)
% Function plots log curves; a curve's properties can be changed by 
% right-clicking on the curve and choosing new curve parameters from the 
% pop-up menu.
%
% Written by: E. R.: May 6, 2000
% Last update: July 17, 2006: use "mysuptitle" with different location for
%                             landscape and portrait
%
%           aux=l_plot(wlog,varargin)
% INPUT
% wlog      log structure
% varargin  one or more cell arrays; the first element of each cell array is a
%           keyword, the other elements are parameters. Presently, keywords are:
%           'annotation' subplot (curve annotation). Possible values are 'mnemonic'
%                     and 'description' which refer to columns 1 or 3 of the
%                     field "curve_info'. Mnemonic is generally much shorter.
%                     Default: {'annotation','mnemonic'} 
%           'figure'  Specifies if new figure should be created or if the 
%                     seismic traces should be plotted to an existing figure.
%                     Possible values are 'new' and any other string. 
%                     Default: {'figure','new'} 
%           'color'   color (and line style) of curves. Default {'color','r'}
%                     Colors may be changed interactively by right-clicking on
%                     a curve and selecting a new color from the pop-up menu.
%           'curves'  mnemonics of curves to plot. {'curves',[]} means all
%                     curves.
%                     Default: {'curves',[]} 
%                     If S4M.interactive == 1 this brings up a list of curve 
%                               mnemonics for interactive curve selection
%                     otherwise all curves are plotted
%           'orient'  plot orientation; possible values are: 'landscape' and 'portrait'
%                     Default: for four or fewer curves:  {'orient','portrait'
%                              for more than four curves: {'orient','landscape'}
%           'depths'  Depth range (or rather range of values of first column); can be two
%                     comma-separated numbers or a two-element vector 
%                     Default: the whole depth range
%           'axis_scaling'  controls axis scaling (see help axis); 
%                     possible values are: 'auto' and 'tight'
%                     Default: {'axis_scaling','tight'}
% OUTPUT
% aux     optional output argument. Structure with fields "figure_handle" and
%          "axis_handles" which contains the handles to the axes of all subplots
%           
% EXAMPLES
%           l_plot(wlog,{'curves','DT','RHOB'},{'orient','landscape'})   % Plot 
%                           % sonic and density log in landscape orientation
%           l_plot(wlog,{'color','b'},{'depths',4000,5000})   % Plot all logs in the depth
%                           % range from 4000 to 5000 (in terms of log depth units)
%                           %  using line color blue.  
%           aux=l_plot(wlog)   Plot all curves of log structure; output "aux",
%                           %  structure with axis handles; changing, say, 
%                           %  the x-axis direction from normal to reverse,                  
%                           %  of the third curve (e.g. a sonic log) can be 
%                           %  achieved by
%           set(aux.axis_handles(3),'XDir','reverse') % Reverse the x-axis for 
%                           % the third curve

global S4M

aux.figure_handle=[];

if ~istype(wlog,'well_log')
   error(' First input parameter must be a well log')
end
if length(wlog) > 1
   error(' Log structure must have length 1 --- must not be an array')
end

%       Set defaults for input parameters
param.annotation='mnemonic';
param.color='r';
param.curves='';
param.depths=[wlog.first,wlog.last];
param.figure='new';
param.orient=[];
param.axis_scaling='tight';

%       Decode and assign input arguments
param=assign_input(param,varargin);

if iscell(param.depths)
   param.depths=cat(2,param.depths{:});
end

if isempty(param.curves)  
   if S4M.interactive
      str=wlog.curve_info(2:end,1);
      [idx,ok] = mylistdlg(str,{'promptstring','Select one or more curves:'},...
                      {'selectionmode','multiple'},...
		      {'previous','l_plot','l_plot1'}, ...
		      {'name','SeisLab: l_plot'});
                      
      if ~ok
         if nargout == 0
            clear aux
         end
         return
      else
         param.curves=wlog.curve_info(idx+1,1);
      end
   else
      param.curves=wlog.curve_info(2:end,1);
   end  
end

if strcmp(param.annotation,'mnemonic')
   idescr=1;          % Curve mnemonics used as subplot titles
else
   idescr=3;          % Curve descriptions used as subplot titles  
end

if ~iscell(param.curves)
   param.curves={param.curves};
end
ncurves=length(param.curves);

if ncurves > 12
   alert('The maximum number of curves that can be displayed is 12')
   ncurves=12;
end
if ncurves == 1 & strcmp(param.curves,'*')
   param.curves=wlog.curve_info(2:end,1)';
   ncurves=length(param.curves);
end

aux.figure_handle=[];

if strcmp(param.figure,'new')
   if isempty(param.orient)
      if ncurves > 4
         param.orient='landscape';
      else
         param.orient='portrait';
      end
   end
  
   if strcmpi(param.orient,'landscape')
      figure_handle=lfigure;
      font_size=(60/max([7.5,ncurves]))+1;    % Adjust font size to the number of curves to plot
   elseif strcmpi(param.orient,'portrait') 
      figure_handle=pfigure;
      font_size=(40/max([5,ncurves]))+1;    % Adjust font size to the number of curves to plot
   else
      alert([' Unknown picture orientation (',param.orient',')'])
   end
   timeStamp
   bgGray
   figure_export_menu(figure_handle);
else
   font_size=10;
end

index=find(wlog.curves(:,1) >= param.depths(1) & wlog.curves(:,1) <= param.depths(2));
if isempty(index)
  error([' Log has no values in requested depth/time range: ', ...
          num2str(param.depths)])
end
ier=0;
hh=zeros(ncurves,1);        % Reserve room for axis handles

tracking_button=logical(1);

if ncurves > 1
   switch param.orient
   case 'landscape'
      mysuptitle(mnem2tex(wlog.name),{'yloc',1.09})
   case 'portrait'
      mysuptitle(mnem2tex(wlog.name))
   end
else
   mytitle(mnem2tex(wlog.name))
end

for ii=1:ncurves
   if ncurves > 1           % Avoid the "subplot" command if there is only one curve
      hh(ii)=subplot(1,ncurves,ii);
   else
      hh=gca;
   end
   pos=get(hh(ii),'Position');
   set(hh(ii),'FontSize',font_size,'Position',[pos(1),pos(2)-0.04,pos(3),0.75]);
   [idx,ier]=curve_index1(wlog,param.curves{ii});
   if isempty(idx)
      disp([' Requested curve mnemonic "',param.curves{ii},'" not available'])
      ier=1;
   elseif length(idx) > 1
      error([' More than one curve with mnemonic "',param.curves{ii},'"'])
   else 
      if ~strcmpi(wlog.curve_info(idx(1),2),'logical') % Regular curves
         plot(wlog.curves(index,idx(1)),wlog.curves(index,1),param.color)


         try
            axis(param.axis_scaling)
         catch
            disp(['Unknown value for "axis_scaling": "',param.axis_acaling,'".'])
         end

      else        % Logical curves
          x=wlog.curves(index,idx(1));
          y=wlog.curves(index,1);
          ya=(y(1:end-1)+y(2:end))*0.5;
          lya=length(ya);
          iidx=reshape([1:lya;1:lya],1,2*lya);      
          yy=[y(1);y(1);ya(iidx);y(end);y(end)];
          xx=[0;x(iidx);x(end);x(end);0];
          dxx=diff(xx);
          idx1=find(dxx ~= 0);
          idx2=unique([idx1;idx1+1]);
          fill([0;xx(idx2);0],[yy(1);yy(idx2);yy(end)],param.color,'EdgeColor','none');
      end

      	 %	Create a "menu button" if "tracking_button" is true
      initiate_2d_tracking(wlog.curve_info(idx(1),:), ...
	                      wlog.curve_info(1,:),tracking_button)
      tracking_button=logical(0);

      set(hh(ii),'XAxisLocation','top')
      title(mnem2tex(wlog.curve_info{idx,idescr}));
      units=wlog.curve_info{idx,2};
      if ncurves > 1
         if ~strcmpi(units,'n/a')
             xlabel(units2tex(wlog.curve_info{idx,2}));
         end
      else
         if ~strcmpi(units,'n/a')
             xlabel([strrep(wlog.curve_info{idx,idescr},'_','\_'),' (',units2tex(wlog.curve_info{idx,2}),')']);
         else
             xlabel(strrep(wlog.curve_info{idx,idescr},'_','\_'));
         end
      end
      set(hh(ii),'YDir','reverse')
      if strcmpi(wlog.curve_info{1,2},'n/a')
         dunits='';
      else
         dunits=[' (',units2tex(wlog.curve_info{1,2}),')'];
      end
      if ii == 1
         ylabel([wlog.curve_info{1,idescr},dunits])
      end
      if ii > 1 & ii < ncurves
         set(hh(ii),'YtickLabel','')
      end
      if ii == ncurves & ii ~= 1
         set(hh(ii),'YAxisLocation','right')
         ylabel([wlog.curve_info{1,idescr},dunits])
      end
   end
   grid
end

if ier == 1
  disp([' Available curves: ',cell2str(wlog.curve_info(2:end,1))])
end

%	Create linked zoom
if length(hh) > 1
    axes(hh(1))
    mylinkaxes(hh,'y')
else
   zoom on
end

%	Create over-all title

linemenu		% Allow interactive modification of curves

if nargout > 0
   aux.figure_handle=figure_handle;
   aux.axis_handles=hh;
else
   clear aux
end

