%% Setup
clearvars -except everything
close all
categories = {'Asymmetries','Individual Atoms','Dimers','Rows',...
    'Tip Change','Bad/Blurry'};

% Open CSV of everything from Zooniverse
[filefind,dirfind] = uigetfile('*.csv','Select Classification File');
everything = csv2struct([dirfind,filefind]);
tot_responses = length(everything.annotations);

% Make matrix to hold ALL responses (+1 column for filename)
all_responses = zeros(tot_responses,6);
all_names = cell(tot_responses,1);

%% Extract Responses
for extract_loop = 1:tot_responses
    
    % Get category answers
    response_ans_pre = jsondecode(char(everything...
        .annotations(extract_loop)));
    response = response_ans_pre.value;
    
    % Get image name
    response_name_pre_pre = jsondecode(char(everything.subject_data...
        (extract_loop)));
    response_name_pre = fieldnames(response_name_pre_pre);
    response_name = response_name_pre_pre.(char(response_name_pre))...
        .Filename;
    
    % Put individual response into row of matrix
    % =1 if category selected, =0 if not
    all_responses(extract_loop,1) = max(strcmp(response,categories(1)));
    all_responses(extract_loop,2) = max(strcmp(response,categories(2)));
    all_responses(extract_loop,3) = max(strcmp(response,categories(3)));
    all_responses(extract_loop,4) = max(strcmp(response,categories(4)));
    all_responses(extract_loop,5) = max(strcmp(response,categories(5)));
    all_responses(extract_loop,6) = max(strcmp(response,categories(6)));
    
    % Add flename to vector
    all_names(extract_loop) = cellstr(response_name);
end

%% Agreement Finder

% Find unique filenames in mega matrix
un_name = unique(all_names);
image_responses = length(un_name);
un_mean = zeros(image_responses,6);
un_response_no = zeros(image_responses,1);

% Make mini-matrix for each image containing all responses for that image
for image_no = 1:image_responses
    
    % Find indexes corresponding to responses of one image
    image_name = un_name(image_no);
    image_index = find(strcmp(all_names,image_name));
    
    % Calculate mean image and store
    mini_mat = all_responses(image_index,:);
    un_mean(image_no,:) = mean(mini_mat,1);
    
    % Store number of responses
    response_move = size(mini_mat);
    un_response_no(image_no) = response_move(1);
    
end

% Calculate agreement
un_catagreement = 2.*abs(un_mean-0.5);
un_agreement = mean(un_catagreement,2);

% Calculate weights:
% |Bad/Blurry|Tip Change|Rows|Dimers|Asymmetries|Individual Atoms|
un_weight = un_mean./sum(un_mean,2);
un_weight(isnan(un_weight)) = 1/6;

%% Send to Excel

excelname = ['Database/Classified_Data_',date,'.xlsx'];

% Write mean score per image
xlswrite(excelname,un_name,'Mean_Score','A2');
xlswrite(excelname,un_response_no,'Mean_Score','B2');
xlswrite(excelname,un_mean,'Mean_Score','C2');

% Write weighted score per image
xlswrite(excelname,un_name,'Weighted_Score','A2');
xlswrite(excelname,un_response_no,'Weighted_Score','B2');
xlswrite(excelname,un_weight,'Weighted_Score','C2');

% Write agreement score per image
xlswrite(excelname,un_name,'Agreement_Score','A2');
xlswrite(excelname,un_response_no,'Agreement_Score','B2');
xlswrite(excelname,un_catagreement,'Agreement_Score','C2');
xlswrite(excelname,un_agreement,'Agreement_Score','I2');

% Write headers
xlswrite(excelname,['Name','No. Responses',categories],'Mean_Score','A1');
xlswrite(excelname,['Name','No. Responses',categories],'Weighted_Score','A1');
xlswrite(excelname,['Name','No. Responses',categories,'Mean'],'Agreement_Score','A1');

%% Visualisation

% % Make axis
% FigHandle1 = figure(1);
% FigHandle1.Position = [100, 100, 900, 700];
% movegui(FigHandle1,'center')
% set(gca,'TickLabelInterpreter','none')
% 
% % Determine dominant category
% [~,dom_index] = max(un_weight,[],2);
% 
% % Bodge it!
% bar1 = [];
% bar2 = [];
% bar3 = [];
% bar4 = [];
% bar5 = [];
% bar6 = [];
% 
% % Plot with different colours
% hold on
% for barloop = 1:length(un_weight)
%     if dom_index(barloop) == 1
%         bar1=bar(barloop,100*un_agreement(barloop));
%         set(bar1,'FaceColor','y');
%     elseif dom_index(barloop) == 2
%         bar2=bar(barloop,100*un_agreement(barloop));
%         set(bar2,'FaceColor','m');
%     elseif dom_index(barloop) == 3
%         bar3=bar(barloop,100*un_agreement(barloop));
%         set(bar3,'FaceColor','c');
%     elseif dom_index(barloop) == 4
%         bar4=bar(barloop,100*un_agreement(barloop));
%         set(bar4,'FaceColor','r');
%     elseif dom_index(barloop) == 5
%         bar5=bar(barloop,100*un_agreement(barloop));
%         set(bar5,'FaceColor','g');
%     elseif dom_index(barloop) == 6
%         bar6=bar(barloop,100*un_agreement(barloop));
%         set(bar6,'FaceColor','b');
%     end
% end
% hold off
% 
% % Add labels
% baraxis = gca;
% baraxis.XTickLabel = un_name;
% baraxis.XTick = 1:numel(un_name);
% baraxis.XTickLabelRotation = 90;
% baraxis.FontSize = 6;
% ylabel('Total Agreement (%)')
% legend([bar1,bar2,bar3,bar4,bar5,bar6],categories)
% 
