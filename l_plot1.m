function aux=l_plot1(wlog,varargin)
% Function plots log curves into one plot window
% Due to a quirk in MATLAB's legend command the legend is wrong if logical
% curves are plotted together with regular curves and the logical curves are
% NOT the last ones to be plotted.
%
% Written by: E. R.: April 1, 2001
% Last updated: December 25, 2005: make legend version-dependent
%
%	    aux=l_plot1(wlog,varargin)
% INPUT
% wlog      log structure
% varargin  one or more cell arrays; the first element of each cell array is a keyword,
%           the other elements are parameters. Presently, keywords are:
%           'figure'  Specifies if new figure should be created or if the seismic traces 
%                     should be plotted to an existing figure. Possible values are 'new'  
%                     and any other string. 
%                     Default: {'figure','new'} 
%           'colors'  color of curves. 
%                     Default: {'colors','r','b','g','c','m','k','y'}
%           'curves'  mnemonics of curves to plot. {'curves','*'} means all
%                     curves.
%                     Default: {'curves',[]} which brings up a list of curve 
%                               mnemonics for interactive curve selection
%           'depths'  Depth range (or rather range of values of first column); can be two
%                     comma-separated numbers or a two-element vector 
%                     Default: the whole depth range
%           'linewidth' linewidth of curves. 
%                     Default: {'linewidth',0.5}
%           'lloc'    location of label.
%                     Default: {'lloc',5} i.e. outside of plot 
%           'orient'  plot orientation; possible values are: 'landscape' and 'portrait'
%                     Default: for four or fewer curves:  {'orient','portrait'
%                              for more than four curves: {'orient','landscape'}
%           'scale'   Force independent scaling of the curves. Possible values are 'yes' and 'no'
%                     Default: {'scale','no'}
% OUTPUT
% aux   structure with the following field
%          'figure_handle'  handle to the figure 
%
% EXAMPLES  l_plot1(l_data)         % Interactively select curves to plot
%
%           %      Plot sonic and density log in landscape orientation                                
%           l_plot1(l_data,{'curves','DTp','rho'},{'orient','landscape'})
%
%           %      Plot selected logs in the depth range from 4000 to 5000 
%                  (in terms of log depth units).                                
%           l_plot1(l_data,{'depths',6000,8000})

global S4M

if ~istype(wlog,'well_log')
   error(' First input argument must be a well log')
end

if length(wlog) > 1
  error(' Log structure must have length 1 --- must not be an array')
end

%       Set defaults for input parameters
param.curves=[];
param.figure='new';
param.orient='portrait';
param.colors={'r','b','g','c','m','k','y'};
param.linewidth=0.5;
param.lloc=5;
param.depths=[wlog.first,wlog.last];
param.tracking='yes';
param.scale=[];

%       Decode and assign input arguments
param=assign_input(param,varargin);

if iscell(param.depths)
  param.depths=cat(2,param.depths{:});
end

if isempty(param.curves)
   str=wlog.curve_info(2:end,1);
   [idx,ok] = mylistdlg(str,{'promptstring','Select one or more curves:'},...
                      {'selectionmode','multiple'},...
		      {'previous','l_plot1','l_plot'}, ...
		      {'name','SeisLab: l_plot1'});
   if ~ok
      return
   else
      param.curves=wlog.curve_info(idx+1,1);
   end
end

if ~iscell(param.curves)
  param.curves={param.curves};
end
if iscell(param.curves{1})
  param.curves=param.curves{1};
end

ncurves=length(param.curves);

if ncurves == 1 & strcmp(param.curves,'*')
  param.curves=wlog.curve_info(2:end,1)';
  ncurves=length(param.curves);
end

if strcmp(param.figure,'new')
   font_size=10;
   if strcmpi(param.orient,'portrait')
      fh=pfigure;
      set(fh,'DoubleBuffer','on');
   else
      fh=lfigure;
      set(fh,'DoubleBuffer','on');
   end
   figure_export_menu(fh);
   set(gca,'FontSize',font_size);
   hold on
   set(fh,'DoubleBuffer','on')
end


index=find(wlog.curves(:,1) >= param.depths(1) & wlog.curves(:,1) <= param.depths(2));
if isempty(index)
   error([' Log has no values in requested depth/time range: ', ...
          num2str(param.depths)])
end

%       Check if units of measurement of all curves are the same
[index1,ier]=curve_indices(wlog,param.curves);
index1=index1(ier==0);
if isempty(index1)
   curve_indices(wlog,param.curves);
   alert(' Check input arguments')
end
units=wlog.curve_info(index1,2);

same_units=sum(ismember(units,units{1})) == ncurves;

irregular=0;  	% For later check if both logical and
ilogical=0;  	% regular curves are to be plotted

if isempty(param.scale)
   if same_units
      scale=0;
   else
      scale=1;
   end

elseif strcmpi(param.scale,'yes')
   scale=1;
else
   scale=0;
end

ltext1={};
ltext2={};
ier=0;
if ~iscell(param.colors)
   param.colors={param.colors};
end
ncol=length(param.colors);
if ncurves > ncol
  alert([' Only ',num2str(ncol),' curve colors defined; ', ...
       'hence not all ',num2str(ncurves),' displayed'])
  ncurves1=ncol;
else
  ncurves1=ncurves;
end

for ii=1:ncurves1
  [idx,ier]=curve_index1(wlog,param.curves{ii});
  if isempty(idx)
    disp([' Requested curve mnemonic "',param.curves{ii},'" not available'])
    ier=1;
  elseif length(idx) > 1
    error([' More than one curve with mnemonic "',param.curves{ii},'"'])
  else 
    if ~strcmpi(wlog.curve_info(idx(1),2),'logical')
       irregular=1;
       if scale
         temp=wlog.curves(index,idx(1));
         mint=min(temp);
         maxt=max(temp);
         temp=((temp-mint)+eps/2)/((maxt-mint)+eps);
         plot(temp,wlog.curves(index,1),param.colors{ii},'LineWidth',param.linewidth)
         ltext1=[ltext1,{[strrep(param.curves{ii},'_','\_'),': ']}];
         ltext2=[ltext2,{[num2str(mint),' - ',num2str(maxt), ...
               ' ',strrep(l_gu(wlog,param.curves{ii}),'n/a','')]}];
       else
         plot(wlog.curves(index,idx(1)),wlog.curves(index,1),param.colors{ii}, ...
             'LineWidth',param.linewidth)
         ltext1=[ltext1,{strrep(param.curves{ii},'_','\_')}];

       end
       hold on
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
       fill([0;xx(idx2);0],[yy(1);yy(idx2);yy(end)],param.colors{ii},'EdgeColor','none');
       ltext1=[ltext1,{strrep(param.curves{ii},'_','\_')}];
       ltext2=[ltext2,{'0 - 1 (logical)'}];
    end
  end 
end

linemenu	% Allow interactive modification of curves

if ier == 1
  disp([' Available curves: ',cell2str(wlog.curve_info(2:end,1))])
end

if same_units
   xlabel(units2tex(wlog.curve_info{idx,2}));
else
   xlabel('Units are curve-dependent')
end

ylabel(info2label(wlog.curve_info(1,:)));

pos=get(gca,'Position');
set(gca,'YDir','reverse','XAxisLocation','top', ...
        'Position',[pos(1),pos(2)-0.04,pos(3),0.8])

timeStamp

if irregular & ilogical
   alert(' Legend will be wrong if logical curves were not last on the list')
end

%	Handle legend
if scale
   ltext1=[char(ltext1),char(ltext2)];
end

if S4M.matlab_version < 7  &  param.lloc == 5
   legend(ltext1,param.lloc)
else
   legend(ltext1,'Location','BestOutside')
end

grid on
zoom on
box on

%	Create title
mytitle(mnem2tex(wlog.name))

%       Add button for cursor tracking
if strcmp(param.figure,'new')  &  strcmp(param.tracking,'yes')
   initiate_2d_tracking({'x','n/a','x'},wlog.curve_info(1,:))
end

if nargout > 0
   aux.figure_handle=fh;
end

