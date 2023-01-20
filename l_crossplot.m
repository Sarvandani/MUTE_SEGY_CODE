function aux=l_crossplot(wlog,mnem1,mnem2,varargin)
% Function makes crossplot of curve with mnemonic "mnem1" (x-axis) vs curve with
% mnemonic "mnem2" (y-axis)
%
% Written by: E. R.: March 19, 2001.
% Last updated: December 15, 2005: general update, 
%                                  added cursor tracking, figure-export menu
%
%         aux=l_crossplot(wlog,mnem1,mnem2,varargin)
% INPUT
% wlog    log structure
% mnem1   mnemonic of curve with values plotted along the x-axis
% mnem2   mnemonic of curve whose values are plotted along the y-axis
% varargin one or more cell arrays; the first element of each cell array is a keyword string,
%         the following arguments contains a parameter(s). Accepted keywords are         
%         'color'   Color of symbols. Default: {'color','r'}
%         'depths'  first and last depth to use
%                   Default: {'depths',wlog.first,wlog.last}
%         'figure'  Possible values are 'new' (create new figure) and 'old' (plot onto
%                   existing figure)
%                   Default: {'figure','new'}
%         'rows'    used to select specific rows in the matrix of curve values on the basis
%                   of a logical conditions (see "l_select")
%                   Example: {'rows','Vclay < 0.25'} selects all row of the matrix of curve
%                      values for which the clay volume is less than 25 %
%                   Default: all rows
%         'linewith' Line width for plotting.
%                   Default: {'linewidth',1.5}
%         'linestyle' Style of line to use
%                   Default: {'linestyle','none'}  i.e. no connecting lines between markers
%         'marker', Marker to plot. Default: {'marker','*'}
%         'markersize' Size of Marker. Default: {'markersize',5}
%         'xaxis'   Possible values are "linear' and 'log' (linear or logarithmic x-axis)
%                   Default: {'xaxis','linear'}
%         'yaxis'   Possible values are "linear' and 'log' (linear or logarithmic y-axis)
%                   Default: {'yaxis','linear'}
% OUTPUT
% aux     structure with handles to the figure

%       Defaults of input arguments
param.color='r';
param.depths=[];
param.figure='new';
param.rows=[];
param.linewidth=1.5;
param.linestyle='none';     % No connecting lines
param.marker='*';
param.markersize=5;
param.xaxis='linear';
param.yaxis='linear';

%       Replace defaults by input parameters
param=assign_input(param,varargin);

if ~istype(wlog,'well_log')
   error(' First input argument must be a well log')
end

%       Select log samples based on depth range and row restrictions
if ~isempty(param.depths)
   if iscell(param.depths)
      wlog=l_select(wlog,{'depths',cat(2,param.depths{:})});
   else
      wlog=l_select(wlog,{'depths',param.depths});
   end
end
if ~isempty(param.rows)
   wlog=l_select(wlog,{'rows',param.rows});
end

%       Get requested curves and the related rows of curve_info
[c1,info1]=l_gc(wlog,mnem1);
[c2,info2]=l_gc(wlog,mnem2);

%       Create figure window (if required)
if strcmpi(param.figure,'new')
   aux.figure_handle=lfigure;
   figure_export_menu(aux.figure_handle)
   timeStamp
else
   aux.figure_handle=gcf;
end

%       Make cross-plot
if strcmpi(param.xaxis,'linear') & strcmpi(param.yaxis,'linear')
   line(c1,c2,'Color',param.color,'Marker',param.marker,'MarkerSize',param.markersize, ...
      'LineWidth',param.linewidth,'LineStyle',param.linestyle)
elseif strcmpi(param.xaxis,'log') & strcmpi(param.yaxis,'linear')
   semilogx(c1,c2,'Color',param.color,'Marker',param.marker,'MarkerSize',param.markersize, ...
      'LineWidth',param.linewidth,'LineStyle',param.linestyle)  
elseif strcmpi(param.xaxis,'linear') & strcmpi(param.yaxis,'log')
   semilogy(c1,c2,'Color',param.color,'Marker',param.marker,'MarkerSize',param.markersize, ...
      'LineWidth',param.linewidth,'LineStyle',param.linestyle)
elseif strcmpi(param.xaxis,'log') & strcmpi(param.yaxis,'log')
   loglog(c1,c2,'Color',param.color,'Marker',param.marker,'MarkerSize',param.markersize, ...
      'LineWidth',param.linewidth,'LineStyle',param.linestyle)  
else
   error([' At least one of the axis parameters ("',param.xaxis,'", "',param.yaxis,'") is wrong'])
end

if ~isempty(inputname(1))
   mytitle(['Cross-plot: ',strrep(wlog.name,'_','\_')])
end

xlabel(info2label(info1))
ylabel(info2label(info2))

grid on
zoom on
box on
bgGray

initiate_2d_tracking(info1,info2)

if nargout == 0
   clear aux
end

