clearvars -except input_data

%% Setup and Reading In

% Settings
image_size = 128;                % Training resolution
pre_size = 10;                   % Move down to avoid overflow :(
image_repeats = 4;               % Repeat image data for category score
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

% Read in nicely organised output from Big_Data_Helper.m
mean_scores = xlsread(input_data,'Mean_Score',"C2:H8000");
agreement_scores = xlsread(input_data,'Agreement_Score',"I2:I8000");
[~,image_names] = xlsread(input_data,'Mean_Score');
image_names = image_names(2:end,1);

% Remove non-binary data for better score indication
%remove_index = find(sum(mean_scores,2)~=1);
%mean_scores(remove_index,:)=[];
%agreement_scores(remove_index)=[];
%image_names(remove_index)=[];

% Pre-allocate temporary 3D matrix to store database of grayscale images
no_images = length(image_names);
matrix_image_temp = zeros(image_size,image_size,no_images);
matrix_category_temp = zeros(no_images,1);
matrix_names_temp = image_names;

% Pre-allocate 3D matrix to store grayscale image data
matrix_category_fin = zeros(pre_size*no_images,1);
matrix_image_fin = zeros(image_size,image_size,pre_size*no_images,...
    'uint8');
matrix_names_fin = cell(pre_size*no_images,1);

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
%% Category Weighting
%|1=Asymmetries|2=Individual Atoms|3=Dimers|4=Rows|
%|5=Tip Change|6=Bad/Blurry|

disp('Assigning Weights   ...')

% Calculate max of weight range boundaries from 0-1
weight_range = 0:(1/(image_repeats+1)):1;

% Take 0.001 off mean scores to fix range boundaries at 0&1
for loop_range_fix = 2:length(weight_range)
    mean_scores(mean_scores==weight_range(loop_range_fix)) = ...
        weight_range(loop_range_fix)-0.0001;
end


% God has abandoned us I am so sorry if you are trying to understand what
% this does please have mercy on my wicked soul
insert_pos_temp = 1;
% For each unique image:
for loop_im_outer = 1:no_images
    % For each category:
    for loop_cat = 1:6
        % For each range:
        for loop_im_inner = 1:image_repeats+1
            % If in a range:
            if mean_scores(loop_im_outer,loop_cat) >= ...
                    weight_range(loop_im_inner) && ...
                    mean_scores(loop_im_outer,loop_cat) < ...
                    (weight_range(loop_im_inner) + ...
                    weight_range(2)-weight_range(1))
                % If images are to be replicated:
                if loop_im_inner-1 ~= 0
                    % Determine number of rows and position to insert into
                    insert_pos = insert_pos_temp:...
                        (insert_pos_temp+loop_im_inner-2);
                    
                    % Store category in category vector
                    matrix_category_fin(insert_pos) = ...
                        loop_cat.*ones(loop_im_inner-1,1);
                    
                    % Store image names in name vector
                    matrix_names_fin(insert_pos) = ...
                        repmat(matrix_names_temp(loop_im_outer),...
                        loop_im_inner-1,1);
                    
                    % Store image data in image data matrix
                    matrix_image_fin(:,:,(insert_pos)) = ...
                        matrix_image_temp(:,:,loop_im_outer).*...
                        ones(image_size,image_size,loop_im_inner-1);
                    
                    % Inform loop of increased size
                    insert_pos_temp = insert_pos_temp+loop_im_inner-1;
                end
            end
        end
    end
end

%% Output


disp('Preparing to Save   ...')
% Clip off unused matrix space
topval = find(~matrix_category_fin,1)-1;
matrix_category_fin = matrix_category_fin(1:topval);
matrix_image_fin = matrix_image_fin(:,:,1:topval);
matrix_names_fin = matrix_names_fin(1:topval);

% Clip off low agreement
disagree_index = find(agreement_scores<agreement_clip);
disagree_names = image_names(disagree_index);

for loop_disagree = 1:length(disagree_index)
    cut_index = find...
        (strcmp(matrix_names_fin,disagree_names(loop_disagree)));
    matrix_category_fin(cut_index) = [];
    matrix_image_fin(:,:,cut_index) = [];
    matrix_names_fin(cut_index) = [];
end

% Shuffle about data
disp('Shuffling Images    ...')
rng(1234)
swap_index = randperm(length(matrix_category_fin))';
matrix_names_fin = matrix_names_fin(swap_index);
matrix_category_fin = matrix_category_fin(swap_index);
matrix_image_fin = matrix_image_fin(:,:,swap_index);

% Separate into testing and training data sets
train_cutoff = round(topval-(topval*perc_test));
x_train = matrix_image_fin(:,:,1:train_cutoff);
x_test = matrix_image_fin(:,:,(train_cutoff+1):end);
y_train = matrix_category_fin(1:train_cutoff);
y_test = matrix_category_fin((train_cutoff+1):end);

% Show class imbalance :(
y_all = [y_train;y_test];
disp(['Values per Category: ', num2str([sum(y_all(y_all==1)),...
    sum(y_all(y_all==2)),sum(y_all(y_all==3)),...
    sum(y_all(y_all==4)),sum(y_all(y_all==5)),sum(y_all(y_all==6))])]);

% Save
disp('Saving Image Matrix ...')
save(['Database/Training_Images_',num2str(image_size),...
    '_',num2str(image_repeats),...
    '_unbalanced.mat'],'x_train','x_test','y_train','y_test')
%% Closing
beep
disp('Done!')
toc