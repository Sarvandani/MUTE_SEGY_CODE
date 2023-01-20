function aux=mysuptitle(text,varargin)
% Places text as a title on a group of subplots.
% Returns a handle to the label and a handle to the superaxis.
% Based on function "suplabel" by Ben Barrowes (Matlab File Exchange)
%
% Written by: E. R.: December 25, 2005
% Last updated: December 26, 2005: 
%
%          title_handle=mysuptitle(text,varargin)
% INPUT
% text     text for the title
% varargin  one or more cell arrays; the first element of each cell array is a
%           keyword, the other elements are parameters. Presently, keywords are:
%     'fontsize'  Size of the title font
%           Default: {'fontsize',16}
%     'yloc'  relative y-location of the title
%           Default: {'yloc',1.00}
% OUTPUT
% title_handle  handle to the title (allows subsequent changes of the title)
% EXAMPLE
%      lfigure
%      subplot(2,2,1);ylabel('ylabel1');title('title1')
%      subplot(2,2,2);ylabel('ylabel2');title('title2')
%      subplot(2,2,3);ylabel('ylabel3');xlabel('xlabel3')
%      subplot(2,2,4);ylabel('ylabel4');xlabel('xlabel4')
%      aux=mysuptitle('super X label',{'yloc',1.05});
%      pause(2)
%      set(aux.title_handle,'FontSize',50,'Color','blue')

if nargin < 1
   error('One input argument with a title string is requred.')
end

old_axes=gca;

%	Set defaults for input parameters
param.fontsize=16;
param.yloc=1.0;

%	Replace defaults by input arguments
param=assign_input(param,varargin);

supAxes=[.08 .08 .84 .84];

ah=findall(gcf,'type','axes');
if ~isempty(ah)
   supAxes=[inf,inf,0,0];
   leftMin=inf;  bottomMin=inf;  leftMax=0;  bottomMax=0;
   axBuf=.04;
   set(ah,'units','normalized')
   ah=findall(gcf,'type','axes');
   for ii=1:length(ah)
      if strcmp(get(ah(ii),'Visible'),'on')
         thisPos=get(ah(ii),'Position');
         leftMin=min(leftMin,thisPos(1));
         bottomMin=min(bottomMin,thisPos(2));
         leftMax=max(leftMax,thisPos(1)+thisPos(3));
         temp=thisPos(2)+thisPos(4);
         if strcmpi(get(ah(ii),'XAxisLocation'),'top')
            temp=temp+0.04;
         end
         bottomMax=max(bottomMax,temp);
      end
   end
   supAxes=[leftMin-axBuf,bottomMin-axBuf,leftMax-leftMin+axBuf*2, ...
            bottomMax-bottomMin+axBuf*2];
end

if ~ischar(text)
   error('The first input argument must be a string.')
end

axis_handle=axes('Units','Normal','Position',supAxes,'Visible','off');
title_handle=title(text);
set(title_handle,'Visible','on','color','r','FontSize',param.fontsize, ...
    'Position',[0.5,param.yloc,1])

if nargout > 0
   aux.axis_handle=axis_handle;
   aux.title_handle=title_handle;
end

set(axis_handle,'HandleVisibility','off');
axes(old_axes)
