clearvars -except input_data

%% Setup

% Settings
image_size = 128;                % Training resolution
rep_no = 10;                     % Number of repeats of each image
agreement_clip = 0.4;            % Threshold to remove low agreement image
perc_test = 0.2;                 % Percentage of data to in train/test set

% Input directories
if exist('input_data','var') == 0
    [input_file,input_folder] = uigetfile...
        ('Database/*.xlsx','Select Output File:');
    input_data = fullfile(input_folder,input_file);
end
tic
disp('Reading in Scores   ... ')

%% Read in & Convert

% Read in nicely organised output from Big_Data_Helper.m
mean_scores = xlsread(input_data,'Mean_Score',"C2:H8000");
agreement_scores = xlsread(input_data,'Agreement_Score',"I2:I8000");
[~,image_names] = xlsread(input_data,'Mean_Score');
image_names = image_names(2:end,1);

% Remove non-binary dasta for better score indication
%remove_index = find(sum(mean_scores,2)~=1);
%mean_scores(remove_index,:)=[];
%agreement_scores(remove_index)=[];
%image_names(remove_index)=[];

% Pre-allocate temporary 3D matrix to store database of grayscale images
no_images = length(image_names);
matrix_image_temp = zeros(image_size,image_size,no_images);
matrix_names_temp = image_names;

% Choose to input images and convert, or input converted form (faster)
input_choice = questdlg('Raw Image Folder, or Converted File?',...
    'Message Box','Image Folder','.mat','.mat');

if strcmp(input_choice,'Image Folder') == 1
    % Read in and convert all images
    input_images = uigetdir('Select Image Folder:');
    
    % Read in images, convert to grayscale and resize
    disp('Converting Images   ...')
    for loop_image = 1:no_images
        matrix_image_temp(:,:,loop_image) = ...
            imresize(rgb2gray(imread(strjoin...
            ([input_images,image_names(loop_image)],'\'))),...
            [image_size,image_size]);
    end
    
    % Save output 
    disp('Saving Image Matrix ...')
    u8 = uint8(matrix_image_temp);
    save(['Database/Greyscale_Images_',num2str(image_size),'.mat']...
        ,'u8')
else
    % Read in converted greyscale matrix (faster)
    [input_file_images,input_file_folder]...
        = uigetfile(['Database/Greyscale_Images_',num2str(image_size)...
        ,'.mat'],'Select Images:');
    input_images = fullfile(input_file_folder,input_file_images);
    disp('Reading in Images   ...')
    matrix_image_struct = load(input_images);
    matrix_image_temp = double(matrix_image_struct.u8); 
end

% Convert to uint8
matrix_image_temp = uint8(matrix_image_temp);

%% Weight and Shuffle

%|1=Asymmetries|2=Individual Atoms|3=Dimers|4=Rows|
%|5=Tip Change|6=Bad/Blurry|

disp('Assigning Weights   ...')

% Determine number of repeats of each category to avoid imbalanced data
total_weights = sum(mean_scores);
max_weight = max(total_weights);
weight_multiplier = round(max_weight./total_weights); 

% Repeat images to allow for random rotations, etc
matrix_names_fin = repmat(matrix_names_temp,rep_no,1);
matrix_image_fin = repmat(matrix_image_temp,[1,1,rep_no]);
matrix_category_fin = repmat(mean_scores,rep_no,1);

% Clip off low agreement
agreement_scores = repmat(agreement_scores,rep_no,1);
disagree_index = find(agreement_scores<agreement_clip);
matrix_names_fin(disagree_index) = [];
matrix_image_fin(:,:,disagree_index) = [];
matrix_category_fin(disagree_index,:) = [];

% Shuffle about data
disp('Shuffling Images    ...')
rng(1234)
swap_index = randperm(length(matrix_category_fin))';
matrix_names_fin = matrix_names_fin(swap_index);
matrix_category_fin = matrix_category_fin(swap_index,:);
matrix_image_fin = matrix_image_fin(:,:,swap_index);

%% Save

% Separate into testing and training data sets
topval = length(matrix_names_fin);
train_cutoff = round(topval-(topval*perc_test));
x_train = matrix_image_fin(:,:,1:train_cutoff);
x_test = matrix_image_fin(:,:,(train_cutoff+1):end);
y_train = matrix_category_fin(1:train_cutoff,:);
y_test = matrix_category_fin((train_cutoff+1):end,:);

% Save
disp('Saving Image Matrix ...')
save(['Database/Training_Images_',num2str(image_size),...
    '_mean.mat'],...
    'x_train','x_test','y_train','y_test','weight_multiplier')
%% Closing
beep
disp('Done!')
toc