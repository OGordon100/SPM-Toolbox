---------------------------------------------------------------------
------ HELLO! --------
--------------------------------------------------------------------------------------------------------------------------

With these tools you can quickly (and hopeful easily) generate and test image classificationss with a 
neural network. They need to be run in the order listed below (Big_Data_Helper.m -> python_postprocess.m)
and in future it would be a great idea to join these together to run one after the other 
(and SSH over/back files to a more powerful computer!)

You just need to figure out how to make a good network!

Good luck :)

- Oliver Gordon, Nicole Landon & Greg Wilkinson 

---------------------------------------------------------------------
------ OUR FILES --------
--------------------------------------------------------------------------------------------------------------------------

report.pdf:
	- Report that explains everything done and reasoning behind it
	- Includes plenty of useful references and resources that are well worth a read
	- Probably read this first

mtrx2png.m:
	- Point at a directory containing .z_mtrx files
	- Converts and flattens proprietary .z_mtrx files to .png for zooniverse (and general consumption as
		terrible wallpapers)
	- These images should also require a .mtrx index file, but you can normally ignore error and carry on 
	- Will take a fair amount of time for lots of images
	- Will output .png images next to .z_mtrx image. 
	- IMPORTANT: Later on, all images will be needed in one single folder (i.e. no subdirectories)
		For this reason, after the program is run you should search the chosen directory in
		explorer for "*.png", select all .png images and output to a single folder e.g. \Images (Flat) 

Big_Data_Helper.m:
	- Converts .csv data of all clasification events from zooniverse -> .xlsx summarised for each image
		- https://www.zooniverse.org/projects/oliver-gordon/scanning-probe-microscopy-image-classification
		- For access to the zooniverse project, please contact me at ppyog@nottingham.ac.uk
	- For each image: 
		- Calculates agreement between people as they classify each image 
			- (0-1, where 1 = fully agree)
		- Calculates mean score for each image category 
			- (0-1, where 1 = definately in a category)
		- Calculates weighting percentages for each image category
			- Deprecated for python_preprocess.m, which does it in a more helpful way
	- Outputs to \Database\Classified Output *DATE*.xlsx

trainer_preprocess_X.m:
	- Point it at an excel sheet from Big_Data_Helper.m
	- Also point it at a folder of .png images from mtrx2png.m 
		OR a \Database\Greyscale_Images_*size*.mat folder which matches the input image_size
	- If .png images selected, will make a \Database\Greyscale_Images_*size*.mat file in same order as excel sheet
	- Using greyscale.mat file vs .png folder runs MUCH faster (but will need a new .mat for each excel file)
	- Will output file called called \Database\Training_Images_*size*_*repeats*.mat containing a 
		3D matrix of greyscale images to train the network with. 
		- x,y axis is image_size
		- z is image number
		- Each cell contains pixel brightness from 0-255
	- These options are important:
		- image_repeats (line 8): 
			- Neural networks can't take into account scores not equal to 0 or 1
			- This overcomes this drawback by repeating images based on the mean score 
			- e.g. if image1.png has means of 1 , 0 , 0.5 , 0.5 , 0.5 , 0.75 for category A,B,C,D,E,F
				and image_repeats = 4, then image1.png will be repeated 4 times with a label of A, 
				0 times with B, 2 times with C,D,E, and 3 times with F:

				1,0,0,0,0,0 ; 1,0,0,0,0,0 ; 1,0,0,0,0,0 ; 1,0,0,0,0,0
				0,0,1,0,0,0 ; 0,0,1,0,0,0
				0,0,0,1,0,0 ; 0,0,0,1,0,0
				0,0,0,0,1,0 ; 0,0,0,0,1,0
				0,0,0,0,0,1 ; 0,0,0,0,0,1 ; 0,0,0,0,0,1

		- image_size (line 6):
			- Image resolution to feed into network
			- 32,64 is a good size
			- Larger images require more time to train same number of epochs, and even longer for same accuracy
				but could potentially reach higher accuracy

	- Three preprocess files to choose from:
		- trainer_preprocess:
			- Recommended for now, and is balanced for each category
			- Outputs to \Database\Training_Images_*size*_*repeats*.mat
		- trainer_preprocess_unbalanced:
			- Computer will mistakenly make predictions based on probability of being in a category
				(i.e. far more images in one category than another) so could have high 
				accuracy, but just played the odds that most data is bad/blurry
			- Can be rebalanced in keras with class_weights but does not always work well
			- Outputs to \Database\Training_Images_*size*_*repeats*_unbalanced.mat
		- trainer_preprocess_mean:
			- Uses mean files as given in excel sheets to train with. Most potential for a good result
			- Ignores *image_repeats" option
			- Outputs to \Database\Training_Images_*size*_mean.mat
			
trainer.py:
	- Python script requiring keras module to train network
	- Input \Database\Training_Images_*size*_*repeats*.mat file
	- Output weights as \Models\model_*size*_*repeats*.h5 
	- Follow up on research (included pdf is good for this!) before trying to edit network

classifier.py:
	- Input greyscale.mat file and weight.h5 file
	- Keep tensorflow/theano backend consistent between trainer and classifier (known bug with model.load)
	- Compare output, *out*, with excel file used; greyscale.mat is in the same order as classified data excel sheet.

python_postprocess.m:
	- Will give an accuracy score of a neural network (maybe?)
	- Point at the Big_Data_Helper.m excel sheet, and nnet_X_Y.mat
	- Does this using emperical formula
	- Cannot use built in accuracy functions as images are not binary yes/no for a category, but in between
	- Only needed if using trainer_preprocess or trainer_preprocess_unbalanced
	- Not very good :(

response.png:
	- Planned response to be programmed into the SPM

Classification_GUI.m:
	- Deprecated :(
	- GUI to convert and display and move images to folders
	- Builds character

---------------------------------------------------------------------
------ OTHER FILES --------
--------------------------------------------------------------------------------------------------------------------------

Acquired code (on file exchange):
	- csv2struct.m					(Converts .csv files to MATLAB structures)
	- findjobj.m					(I don't know what this does)
	- rdir.m					(Recursive directory searching)
Acquired code (given directly/avaliable elsewhere)
	- SPIW toolbox					(Allows conversion of .$_mtrx files. 
							Needs to be installed as instructed in readme 
							Avaliable online at https://sourceforge.net/projects/spiw/
							May need to change SPIW_open.m lines 69 and 76 to XtraceImOpen

	- to_students.zip:				(Provided by Morten. Includes .z_mtrx, .I_mtrx, .mtrx, etc, files)
							Also has a copy of vernissage, which you can use to view stuff

	- dingtest.m					(Converts mtrx files in a more thorough way)
	- PuTTy						(SSH client)

--------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------