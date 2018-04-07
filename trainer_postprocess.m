clearvars
close all

%% Setup

% Retrieve classified nnet file over SSH
weight_size = 4;                    % Weight size
image_size = 16;                    % Image size
pw = 'RememberThePass';             % SSH password (A+ security)

linuxdir = 'ogordon@pppzam2.nottingham.ac.uk:/home/ogordon/';
windowsdsk = winqueryreg('HKEY_CURRENT_USER',...
    'Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders',...
    'Desktop');
windowsdir = [pwd,'\Output'];

if strcmp(input('Import model over SSH? [y/n]: ','s'),'y') == 1
    getthefuckoverhere_1 = system(['pscp -pw ',pw,' ',...
        linuxdir,'model_',num2str(image_size),...
        '_',num2str(weight_size),'.h5 c', windowsdsk(2:end)]);
    movefile_1 = movefile([windowsdsk,'\model_',num2str(image_size),...
        '_',num2str(weight_size),'.h5'],windowsdir);
    getthefuckoverhere_2 = system(['pscp -pw ',pw,' ',...
        linuxdir,'nnet_',num2str(image_size),...
        '_',num2str(weight_size),'.mat c', windowsdsk(2:end)]);
    movefile_2 = movefile([windowsdsk,'\nnet_',num2str(image_size),...
        '_',num2str(weight_size),'.mat'],windowsdir);
end

% Input directories
[input_file_excel,input_folder_excel] = uigetfile...
    ('Output/*.xlsx','Select Excel File:');
input_data_excel = fullfile(input_folder_excel,input_file_excel);
[input_file_py,input_folder_py] = uigetfile...
    ('Output/*.mat','Select Neural Net Output:');
input_data_py = fullfile(input_folder_py,input_file_py);


%% Read in

% Read in nicely organised output from Big_Data_Helper.m and neural net
disp('Reading in Scores   ... ')
ex_mean_scores = xlsread(input_data_excel,'Mean_Score',"C2:H8000");
ex_agreement_scores = xlsread(input_data_excel,...
    'Agreement_Score',"I2:I8000");
py_mean_scores_temp = load(input_data_py);
py_mean_scores = py_mean_scores_temp.nnet_score;

%% Make Comparisons (EMPERICAL!!!!!!!!!!!)

% Calculate Z; position on x axis of Guassian to integrate to
disp('Performing Integrals... ')
Z = ((1./(4.*ex_agreement_scores)).*...
    (1./abs(ex_mean_scores-py_mean_scores)));

% Cap high Z scores for speed (adds tiny inaccuracy)
Z(Z>10) = 10;

% Preallocate loop for vague speed
acc_all = zeros(1,numel(Z));

for integ_no = 1:numel(Z)
    % Define normal distribution
    rnge = 0:0.01:Z(integ_no);
    guas = (1/sqrt(2*pi)) .* exp(-0.5.*rnge.^2);
    
    % Calculate integral up until Z
    cumu = cumtrapz(rnge,guas);
    acc_all(integ_no) = cumu(end-1);
end

% Double to take into account only half of distribution
acc_all = acc_all.*2;

% Calculate mean
acc_fin = 100*mean(acc_all);

disp(['Accuracy = ',num2str(acc_fin),'%'])
beep