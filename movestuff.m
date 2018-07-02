clear all
close all

%% Setup

% Settings
score_clip = 0.5;            % Threshold to remove images
cat_names = {'Atoms','Asymmetries','Dimers','Rows','Tip Change',...
    'Bad Blurry'};           % Category names

% Input excel sheet
if exist('input_data','var') == 0
    [input_file,input_folder] = uigetfile...
        ('*.xlsx','Select Excel File:');
    input_data = fullfile(input_folder,input_file);
end

% Input image database
image_folder = uigetdir(pwd, 'Select image folder:');
input_folder_path = extractfield(rdir([image_folder,'*\**\*.png'])...
    ,'name')';


%% Read in

% Read in nicely organised output from Big_Data_Helper.m
mean_scores = xlsread(input_data,'Mean_Score',"C2:H8000");
[~,image_names] = xlsread(input_data,'Mean_Score');
classified_images = image_names(2:end,1);

% Get file and full folder names from image database
input_folder_name = cell(length(input_folder_path),1);
for cantcode = 1:length(input_folder_path)
    [~,input_name_temp] = fileparts(char(input_folder_path(cantcode)));
    input_folder_name(cantcode) = cellstr([input_name_temp,'.png']);
end

%% Delete logic

% Pre-allocate deletion index matrix
delete_index = zeros(1,length(classified_images));

% For all classified images
for loop = 1:length(classified_images)
    
    % Get max score for category
    maximum = max(mean_scores(loop,:));
    
    % If max score below threshold OR tie for max
    if maximum(1)<score_clip ...
            || length(find((mean_scores(loop,:)) == maximum))>1
        delete_index(loop) = loop;
    end
end

% Remove failing results
delete_index(delete_index==0)=[];
classified_images(delete_index)=[];
mean_scores(delete_index,:)=[];

% Get category corresponding to maximum
[~,maxindex] = max(mean_scores');

%% Move images

% Make output folders if not existing
for mkdir_loop = 1:6
    if exist(char(cat_names(mkdir_loop)),'dir') == 0
        mkdir(char(cat_names(mkdir_loop)))
    end
end

for moveloop = 1:length(classified_images)
    % Find image index
    moveindex = find(ismember(input_folder_name,...
        classified_images(moveloop)));
    
    % Move to appropriate folder
    if maxindex(moveloop) == 1
        copyfile(char(input_folder_path(moveindex)),char(cat_names(1)))
    elseif maxindex(moveloop) == 2
        copyfile(char(input_folder_path(moveindex)),char(cat_names(2)))
    elseif maxindex(moveloop) == 3
        copyfile(char(input_folder_path(moveindex)),char(cat_names(3)))
    elseif maxindex(moveloop) == 4
        copyfile(char(input_folder_path(moveindex)),char(cat_names(4)))
    elseif maxindex(moveloop) == 5
        copyfile(char(input_folder_path(moveindex)),char(cat_names(5)))
    elseif maxindex(moveloop) == 6
        copyfile(char(input_folder_path(moveindex)),char(cat_names(6)))
    end
    
end