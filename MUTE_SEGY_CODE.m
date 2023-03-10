clear all
clc
%% Author: Sarvandani
%% I would like to acknowledge the authors and team of  several used functions especially SeisLab, POLYDEMO and Wail A. Mousa & Abdullatif A. Al-Shuhail.  
%% important thing is to check seismic.headers and select X.
%% this X is used to get offset's line number or column number in the data set. You
%% can check it by header(:,:) = seismic.headers.
X = 1;
%% contrast in image dispplay
contrast_coff = 100;


for nn=1:1
    %%%%%%%%%%%%%%%%%%%%%%%%
    %% we define the favourite range of refraction or muting range here
    %% I select the range of traces by checking the favourite max (4km) and min offset (4.3km) in header matrix
    min_offset_km = 4;
    max_offset_km = 4.3;
    %% This parameter is for muting short offsets,
    %% If you don't wanna apply, 0 for negative possitive offsets, same value for positive offsets
    min_offset_km_short_dist = 4.03 ; 
    max_offset_km_short_dist = 4.03 ;
    min_time_sec = 0;
    max_time_sec = 10;
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    %% this parameter is the maximum range of sampled time for decimating extracted 
    %% or exported segy file:
    %% 4001* 2 ms = 8 second, 900* 10 ms = 9second
    max_sample_time = 900;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    lab=strcat('synthetic_data', num2str(nn),'.segy');
    seismic=read_segy_file(lab);

    offkm=seismic.headers(X,:)./1000;
    %% the trace number is obtained as follows if the offset is always positive
    min_trace_num = min(find(floor(offkm)==min_offset_km));
    max_trace_num = min(find((offkm)==max_offset_km));
    %% negative offset
    %min_trace_num = max(find(fix(offkm)==min_offset_km));
    %max_trace_num = min(find(floor(offkm)==max_offset_km));
    %% the trace number of short distance if offsets are always positive
    min_trace_num_short_distance = min(find(floor(offkm)==min_offset_km_short_dist));
    max_trace_num_short_distance = min(find((offkm)==max_offset_km_short_dist));
    %% in real data set, tsec will be defind by the next follwing line
    tsec = linspace(0,20.4, 2040);
    %tsec=(0:seismic.step/1000:seismic.last/1000);
    min_t_sampled = (find((tsec)==min_time_sec));
    max_t_sampled = min(find(floor(tsec)==max_time_sec));
    data=seismic.traces(:,1:length(seismic.headers(1,:)));
    [rownum,colnum] = size(data);
    off = 1:colnum;
    t = 1:rownum;       
    header(:,:) = seismic.headers;
%%%%%%%%%%%%%%%%%%%%%%
    %% method1 display of data
%      figure
%      mwigb((data),2.0,off,t)
%  %%%%%%%%%%%%%%%%%%%%%%%%%%%    
   %% method2 display of data
%      maximums   = max(data,[],'all');
%      figure ,simage_display(data,off,t,1) 
%      caxis ([-maximums/contrast_coff maximums/contrast_coff]);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% method3 display of data 
%% the first fig is in terms of traces to check the traces 
%% and change it in the beginig of the code
     maximums   = max(data,[],'all');
     figure (1) ,
     simage_display(data,off,t,1) 
     caxis ([-maximums/(contrast_coff.*1) maximums/(contrast_coff.*1)]);
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    set(gcf, 'Units', 'centimeters', 'Position', [0, 0, 50, 25], ...
        'PaperUnits', 'centimeters', 'PaperSize', [20, 9])
    set(gca,'TickDir','out');
    set(gca,'xaxislocation','top');
    ax = gca;
    ax.XAxis.LineWidth = 6;
    ax.YAxis.LineWidth = 6;
    fs=16; 
    xlim([min_trace_num max_trace_num])
    ylim([min_t_sampled max_t_sampled])
    set(gca,'fontsize', fs, 'FontWeight', 'bold')
    set(gca,'FontName','Times New Roman')
    xlabel('Offset [trace number]', 'FontName','Times New Roman','FontSize', fs, 'FontWeight', 'bold')
    ylabel('Time [sample number]', 'FontName','Times New Roman','FontSize', fs,'FontWeight', 'bold')
    
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%
     hPoly = drawpolyline('Color','r'); 
     polyPoints1= hPoly.Position;
     xtop = round(polyPoints1(:,1));
     ytop = round(polyPoints1(:,2));
%%    hPoly = drawfreehand('Color','b');
%% hPoly.FaceAlpha = 0; %it can be 0 or 1 for freehand or polygone
     hPoly = drawpolyline('Color','b');
     polyPoints2= hPoly.Position;
     xbot = round(polyPoints2(:,1));
     ybot = round(polyPoints2(:,2));
     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
     lab=strcat('OBS_', num2str(nn),'_PICKING');
     set(gcf, 'PaperPositionMode', 'auto' );
     print(gcf,'-r300','-dpng',lab)
     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
     %% we interpolate our top line here since we want to have one value for
     %% every trace mostly between 4 and 4.3 km offsets
     x_interpolated_top=(min(xtop):1:max(xtop))';
     %% if we are going to interploate for whole tracec and not limited in our muted region
%      x_interpolated_top=(min(off):1:max(off))';
     y_interpolated_top = interp1(xtop,ytop,x_interpolated_top,'spline','extrap');
     y_interpolated_top = round(y_interpolated_top);
     Interpolated_data (:,1) = x_interpolated_top;
     Interpolated_data (:,2) = y_interpolated_top;
     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
     %% we obtain x (offset) of top line (in terms of trace number)
     data_org_x=zeros(1,colnum);
     data_x = 1:colnum;
     zeros_left= data_org_x(:, 1:min(x_interpolated_top)-1)==1;
     zeros_middle_x= data_org_x(:, min(x_interpolated_top):max(x_interpolated_top))==0;
     zeros_botsss = data_org_x(:, max(x_interpolated_top):end-1)==1;
     data_x_new_top=cat(2,zeros_left,zeros_middle_x,zeros_botsss);
     xtop_final= (data_x_new_top.*data_x)';

     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
     %% we obtain y (time) of top line (in terms of time sample number)
     data_org_y=zeros(colnum,1);
     zeros_topss= data_org_y(1:min(x_interpolated_top)-1,:)==1;
     zeros_middle_y= y_interpolated_top;
     zeros_botsss = data_org_y(max(x_interpolated_top):end-1,:)==1;
     data_y_new_top=cat(1,zeros_topss,zeros_middle_y,zeros_botsss);
     ytop_final= data_y_new_top;
     

     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
     %% This part added since we were not able to pick the mute line for 
%% all the offsets(including out of mauted domain)
%       x_y_top_final= [xtop_final ytop_final];
     y_left_top = zeros(x_interpolated_top(1)-1,1);
     for i = 1:x_interpolated_top(1)-1
         y_left_top(i,1) = y_interpolated_top(1);
     end
     right_traces_num = max(off)-x_interpolated_top(end)-1;
       y_right_top = zeros(right_traces_num,1);
     for z = x_interpolated_top(end)+1:max(off)
         y_right_top(z,1) = y_interpolated_top(end);
     end
     y_right_top = y_right_top(x_interpolated_top(end)+1:end);
     y_middle_top = y_interpolated_top;
     y_all_traces_top = cat(1,y_left_top,y_middle_top,y_right_top);
     x_all_traces_top = 1:max(off);
     x_y_all_trace_top= [x_all_traces_top' y_all_traces_top];
%      destination=strcat('/Volumes/DRIVE_DATA/TEST3/MUTE__OUTPUT_files/eswi_tmut_', num2str(nn),'hydr');
%      dlmwrite(destination, x_y_all_trace_top, 'precision', 6, 'delimiter', '\t')
%     destination=strcat('/Volumes/DRIVE_DATA/TEST3/Preprocessed_files/eswi_tmut_', num2str(nn),'hydr');
%     dlmwrite(destination, x_y_top_final, 'precision', 6, 'delimiter', '\t')
%     
     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
     %% we interpolate our bottom line here
     x_interpolated_bot=(min(xbot):1:max(xbot))';
     %% if we are going to interploate for whole trace and not limited in our muted region
%      x_interpolated_bot=(min(off):1:max(off))';
     y_interpolated_bot = interp1(xbot,ybot,x_interpolated_bot,'spline','extrap');
     y_interpolated_bot = round(y_interpolated_bot);
     Interpolated_data_bot (:,1) = x_interpolated_bot;
     Interpolated_data_bot (:,2) = y_interpolated_bot;
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
     %% we obtain x of bottom line
     data_org_x=zeros(1,colnum);
     data_x = 1:colnum;
     zeros_left= data_org_x(:, 1:min(x_interpolated_bot)-1)==1;
     zeros_middle_x= data_org_x(:, min(x_interpolated_bot):max(x_interpolated_bot))==0;
     zeros_botsss = data_org_x(:, max(x_interpolated_bot):end-1)==1;
     data_x_new_bot=cat(2,zeros_left,zeros_middle_x,zeros_botsss);
     xbot_final= (data_x_new_bot.*data_x)';
     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
     %% we obtain y of bottom line
     data_org_y=zeros(colnum,1);
     zeros_topss= data_org_y(1:min(x_interpolated_bot)-1,:)==1;
     zeros_middle_y= y_interpolated_bot;
     zeros_botsss = data_org_y(max(x_interpolated_bot):end-1,:)==1;
     data_y_new_bot=cat(1,zeros_topss,zeros_middle_y,zeros_botsss);
     ybot_final= data_y_new_bot;
          
%% This part added since we were not able to pick the mute line for 
%% all the offsets(including out of mauted domain)
%      x_y_bot_final= [xbot_final ybot_final];
     y_left_bot = zeros(x_interpolated_bot(1)-1,1);
     for i = 1:x_interpolated_bot(1)-1
         %% y_interpolated_top has been chosen for bottom line to have the same values  
         %% for traces out of the selected domain
         y_left_bot(i,1) = y_interpolated_top(1);
     end
     right_traces_num = max(off)-x_interpolated_bot(end)-1;
       y_right_bot = zeros(right_traces_num,1);
     for z = x_interpolated_bot(end)+1:max(off)
         y_right_bot(z,1) = y_interpolated_top(end);
     end
     y_right_bot = y_right_bot(x_interpolated_bot(end)+1:end);
     y_middle_bot = y_interpolated_bot;
     y_all_traces_bot = cat(1,y_left_bot,y_middle_bot,y_right_bot);
     x_all_traces_bot = 1:max(off);
     x_y_all_trace_bot= [x_all_traces_bot' y_all_traces_bot];
%      destination=strcat('/Volumes/DRIVE_DATA/TEST3/MUTE__OUTPUT_files/eswi_bmut_', num2str(nn),'hydr');
%      dlmwrite(destination, x_y_all_trace_bot, 'precision', 6, 'delimiter', '\t')
     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
     x_y_all_trace_bot_top= [x_all_traces_bot' y_all_traces_top y_all_traces_bot];
     if nn<10
     destination=strcat('/Volumes/DRIVE_DATA/TEST3/MUTE__OUTPUT_files/eswi_mut_000', num2str(nn),'hydr');
     else
     destination=strcat('/Volumes/DRIVE_DATA/TEST3/MUTE__OUTPUT_files/eswi_mut_00', num2str(nn),'hydr');
     end
     savefile = destination;
     fid=fopen(savefile,'wt'); 
     %% I am transferiing the information to the destination
     for ll=1:length(offkm)
         fprintf(fid, '%7d\t%7d\t%7d\n',x_y_all_trace_bot_top(ll,:));
    end    
    fclose(fid);    
%   fprintf(fid,'%3d\n',mut_samp)
%   dlmwrite(lab1, mut_samp, 'precision', 6, 'delimiter', '\t')
     destination = load(destination);
     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% This figure gives the data in terms of trace numbers and time samples+top and bottm layers
      figure (2),
      maximums   = max(data,[],'all');
      simage_display(data,off,t,0) 
      caxis ([-maximums/contrast_coff maximums/contrast_coff]);
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      x=10;y=10;%starting screen position
     w=450;%figure width
     h=300;%figure hieght
    set(gcf,'position',[x y w h]);
    set(gca,'TickDir','out');
    set(gca,'xaxislocation','top');
    set(gca,'TickDir','out');
    ax = gca;
    ax.XAxis.LineWidth = 7;
    ax.YAxis.LineWidth = 7;
    fs=14;
      xlim([min_trace_num max_trace_num])
      ylim([min_t_sampled max_t_sampled])
    
      %%%%%%%%%%%%%%%%%%%
      set(gca,'fontsize', fs, 'FontWeight', 'bold')
      set(gca,'FontName','Times New Roman')
      xlabel('Offset [trace number]', 'FontName','Times New Roman','FontSize', fs, 'FontWeight', 'bold')
      ylabel('Time [sample number]', 'FontName','Times New Roman','FontSize', fs,'FontWeight', 'bold')
      hold on
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Plot of top and bottom lines. 
    %% we have to plot only with . or * since there is one componenet at (0,0).
    %% It is happening since we are not picking all the traces of data.
    plot( xtop_final, ytop_final, 'r.', 'MarkerSize',17)
    plot( xbot_final, ybot_final, 'b.', 'MarkerSize',17)
    %% if we really need to show by line, we can use the interpolation data rather than
    %% final data. Therefore, we won't have (0,0) in our plot.
%     plot( x_interpolated_top, y_interpolated_top, 'b-','LineWidth',10)   
%     plot( x_interpolated_bot, y_interpolated_bot, 'r-','LineWidth',10)
  %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
      lab=strcat('OBS_', num2str(nn),'_trace_time_samples');
      set(gcf, 'PaperPositionMode', 'auto' );
      print(gcf,'-r300','-dpng',lab)
%   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
%% This figure gives the data in terms of km and second
figure (3),
      maximums   = max(data,[],'all');
      simage_display(data,offkm,tsec,0) 
      caxis ([-maximums/contrast_coff maximums/contrast_coff]);
      x=10;y=10;%starting screen position
     w=450;%figure width
     h=300;%figure hieght
    set(gcf,'position',[x y w h]);
    set(gca,'TickDir','out');
    set(gca,'xaxislocation','top');
    set(gca,'TickDir','out');
    ax = gca;
    ax.XAxis.LineWidth = 7;
    ax.YAxis.LineWidth = 7;
    fs=14;
%     xticks(min_offset_km:5:max_offset_km);
%     yticks(3:0.5:7.5);
    xlim([min_offset_km max_offset_km])
    ylim([min_time_sec max_time_sec])
    set(gca,'fontsize', fs,'FontWeight','Bold')
    set(gca,'FontName','Times New Roman')
    xlabel('Offset [km]', 'FontName','Times New Roman','FontSize', fs)
    ylabel('Time [s]', 'FontName','Times New Roman','FontSize', fs)
    hold on
    %%%%%%%%%%%%%%%%%%%%%
    %% we plot our selected lines (bottom and top) in terms of km and second.
    xx_top = zeros(1,max(x_interpolated_top));
    for i= min(x_interpolated_top) : max(x_interpolated_top)
     xx_top (i) = offkm(i);   
    end
    xx_top = xx_top(1,min(x_interpolated_top) : max(x_interpolated_top));
    %% I am plotting mutted short offsets here 
    
    negative_short_distance = max(find(fix(xx_top)==min_offset_km_short_dist));
    positive_short_distance = min(find(floor(xx_top)==max_offset_km_short_dist));
    y_interpolated_top(negative_short_distance:positive_short_distance)=mean(y_interpolated_top(positive_short_distance:positive_short_distance),'all');

    %%%%%%%%%%%%%%%%%
    xx_bot = zeros(1,max(x_interpolated_bot));
    for i= min(x_interpolated_bot) : max(x_interpolated_bot)
     xx_bot (i) = offkm(i);   
    end
    xx_bot = xx_bot(1,min(x_interpolated_bot) : max(x_interpolated_bot));
    %% I am plotting mutted short offsets here
    %% when all offsets are positive
    negative_short_distance = min(find(floor(xx_bot)==min_offset_km_short_dist));
    positive_short_distance = min(find((xx_bot)==max_offset_km_short_dist));
    %% Important: when we have negative positive offsets
    %negative_short_distance = max(find(fix(xx_top)==min_offset_km_short_dist));
    %positive_short_distance = min(find(floor(xx_top)==max_offset_km_short_dist));
    y_interpolated_bot(negative_short_distance:positive_short_distance)=mean(y_interpolated_top(positive_short_distance:positive_short_distance),'all');
    
 %%%%%%%%%%%%%%%%%%%%%%%%%%   
    
    plot(xx_top,(seismic.step/1000)* y_interpolated_top, 'r-', 'LineWidth',7)
    plot(xx_bot,(seismic.step/1000)* y_interpolated_bot, 'b-', 'LineWidth',7)

%   plot(offkm,(4/1000)* ytop_final, 'r.', 'MarkerSize',26)  
%   plot(offkm,(4/1000)* ybot_final, 'b.', 'MarkerSize',26)
       
       set(gca, 'Ydir', 'reverse')
     %%%%%%%%%%%%%%%%%%%%%%%%%%%
     lab=strcat('OBS_', num2str(nn),'_KM_SEC');
     set(gcf, 'PaperPositionMode', 'auto' );
     print(gcf,'-r300','-dpng',lab)
     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
     %% we plot our selected lines (bottom and top) in terms of km and second.
     %% we also mute the data. It can be posibble to extract muted traces as segy!
      for I=1:colnum 
     data(1:ytop_final(I)+1,I)=0;
     %% this line is for muting offsets less than 5 km
     data(1:mean(y_interpolated_top(positive_short_distance:positive_short_distance),'all'),I)=0;
     data(ybot_final(I)+1:end, I)=0;
      end
      figure (4),
%       maximums   = max(data,[],'all');
      simage_display(data,offkm,tsec,0) 
      caxis ([-maximums/contrast_coff maximums/contrast_coff]);
      x=10;y=10;%starting screen position
     w=450;%figure width
     h=300;%figure hieght
    set(gcf,'position',[x y w h]);
    set(gca,'TickDir','out');
    set(gca,'xaxislocation','top');
    set(gca,'TickDir','out');
    ax = gca;
    ax.XAxis.LineWidth = 7;
    ax.YAxis.LineWidth = 7;
    fs=14;
    %xticks(min_offset_km:5:max_offset_km);
    %yticks(3:0.5:7.5);
    xlim([min_offset_km max_offset_km])
    ylim([min_time_sec  max_time_sec])
    set(gca,'fontsize', fs,'FontWeight','Bold')
    set(gca,'FontName','Times New Roman')
    xlabel('Offset [km]', 'FontName','Times New Roman','FontSize', fs)
    ylabel('Time [s]', 'FontName','Times New Roman','FontSize', fs)
    hold on
    %%%%%%%%%%%%%%%%%%%%%
    %% we plot our selected lines (bottom and top) in terms of km and second.
 %%%%%%%%%%%%%%%%%%%%%%%%%%   
    
    plot(xx_top,(seismic.step/1000)* y_interpolated_top, 'r-', 'LineWidth',7)
    plot(xx_bot,(seismic.step/1000)* y_interpolated_bot, 'b-', 'LineWidth',7)

%   plot(offkm,(4/1000)* ytop_final, 'r.', 'MarkerSize',26)  
%   plot(offkm,(4/1000)* ybot_final, 'b.', 'MarkerSize',26)
       
       set(gca, 'Ydir', 'reverse')
     %%%%%%%%%%%%%%%%%%%%%%%%%%%
     lab=strcat('OBS_', num2str(nn),'_KM_SEC_MUTED');
     set(gcf, 'PaperPositionMode', 'auto' );
     print(gcf,'-r300','-dpng',lab)
     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
     %% DECIMATING THE TIME AND writing segy
     data((max_sample_time+1:end),:) = [];
     seismic.traces= data;
     %% changing the header for last sampled time
     seismic.last = max_sample_time;
% seismic.traces= DATA_freq_decovolved;
    KK=find(all(ismember(seismic.header_info,'ffid'),X)==1);
    seismic.headers(KK,:)=nn;
    lab1=strcat('0',num2str(nn),'b_obs',num2str(nn),'FILTERED_MUTED.segy');
    write_segy_file(seismic,lab1);
    system('mv /Volumes/DRIVE_DATA/TEST3/*MUTED.segy /Volumes/DRIVE_DATA/TEST3/MUTED_SEGY_FILES')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Reading data afetr writing segy file
maximums = max(data,[],'all');
     figure,
     % DECIMATE THE TIME
     tsec(:,(max_sample_time+1:end)) = [];   
     simage_display(data,offkm,tsec,1) 
     caxis ([-maximums/contrast_coff  maximums/contrast_coff ]);
     x=10;y=10;%starting screen position
     w=450;%figure width
     h=300;%figure hieght
    set(gcf,'position',[x y w h]);
    set(gca,'TickDir','out');
    set(gca,'xaxislocation','top');
    set(gca,'TickDir','out');
    ax = gca;
    ax.XAxis.LineWidth = 7;
    ax.YAxis.LineWidth = 7;
    fs=14;
%     xticks(min_offset_km:5:max_offset_km);
%     yticks(3:0.5:7.5);
    xlim([min_offset_km max_offset_km])
    ylim([min_time_sec  max_time_sec])
    set(gca,'fontsize', fs,'FontWeight','Bold')
    set(gca,'FontName','Times New Roman')
    xlabel('Offset [km]', 'FontName','Times New Roman','FontSize', fs)
    ylabel('Time [s]', 'FontName','Times New Roman','FontSize', fs)
     lab=strcat('OBS_', num2str(nn), '_AFTER_MUTING_');
     set(gcf, 'PaperPositionMode', 'auto' );
     print(gcf,'-r300','-dpng',lab)
    
end
