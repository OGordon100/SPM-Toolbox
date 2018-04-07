# -*- coding: utf-8 -*-
"""
Created on Tue Aug 22 12:26:30 2017

@author: Oliver
"""

# Import stuff
from __future__ import print_function
import keras
#from keras.datasets import cifar100
from keras.models import Sequential
from keras.layers import Dense, Dropout, Flatten, Activation
from keras.layers import Conv2D, MaxPooling2D
from keras import initializers
from keras.preprocessing.image import ImageDataGenerator
from keras.wrappers.scikit_learn import KerasRegressor
from sklearn.model_selection import cross_val_score
from sklearn.model_selection import KFold
from sklearn.preprocessing import StandardScaler
from sklearn.pipeline import Pipeline
import numpy
#import numpy
import os
from scipy.io import loadmat
import scipy

# If windows, load file dialogue window
try:
    import tkinter as tk
    from tkinter import filedialog
except:
    print('linux')
from keras.optimizers import SGD

import json

# Settings
batch_size = 128                                    # Training batch size
num_classes = 6                                     # Number of categories
epochs = int(input('Number of Epochs: '))           # Number of "repeats" of training
img_rows = int(input('Size of Images: '))
weight_size = int(input('Max Images per Category: '))
seed = 7
numpy.random.seed(seed)
img_cols = img_rows

# Import .mat file
if os.name == 'nt':
    root = tk.Tk()
    root.withdraw()
    file_path = filedialog.askopenfilename()
    #file_path = "C:/Users/Oliver/OneDrive/MATLAB/GORDON/Output/SPNet_Out_16_4.mat"
else:
    file_path = "/home/ogordon/SPNet_Out_"+str(img_rows)+"_"+str(weight_size)+".mat"

mat = loadmat(file_path)

x_train = mat['x_train']
x_test = mat['x_test']
y_train = mat['y_train']
y_test = mat['y_test']
w_mult = mat['weight_multiplier']
x_train = x_train/255
x_test = x_test/255

# For reasons unknown to humanity, for sufficiently large data sets
# python will randomly decide that it should make 3 or 4 random cats = 255
# This breaks everything. For that reason, we randomly set them to category 0
# just to make things run. If you find out why, please email me
# *shrug*
y_train[y_train==255] = 0

#y_test[:,1] = numpy.mean(y_test[:,1:],axis=1)
#y_train[:,1] = numpy.mean(y_train[:,1:],axis=1)
#y_train = y_train[:,0:2]
#y_test = y_test[:,0:2]
#y_train[y_train[:,0]>0,0] = 1
#y_train[y_train[:,0]==0,1] = 1
#y_test[y_test[:,0]>0,0] = 1
#y_test[y_test[:,0]==0,1] = 1

# Reshape
x_train = x_train.reshape(x_train.shape[2], img_rows, img_cols, 1)
x_test = x_test.reshape(x_test.shape[2], img_rows, img_cols, 1)
input_shape = (img_rows, img_cols, 1)

# Convert to proper grayscale
x_train = x_train.astype('float32')
x_test = x_test.astype('float32')
#y_train = y_train.astype('float32')

# Print out nice things
print('x_train shape:', x_train.shape)
print(x_train.shape[0], 'train samples')
print(x_test.shape[0], 'test samples')

# Convert class vectors to binary class matrices
#y_train = keras.utils.to_categorical(y_train, num_classes)
#y_test = keras.utils.to_categorical(y_test, num_classes)

# Normalise and weight to remove hilariously high loss and imbalanced data
keras.layers.normalization.BatchNormalization(input_shape=(input_shape))
 #{0:w_mult.item(0),
               # 1:w_mult.item(1),
               # 2:w_mult.item(2),
               # 3:w_mult.item(3),
               # 4:w_mult.item(4),
               # 5:w_mult.item(5)}
class_weight = {0:1,
                1:1,
                2:1,
                3:1,
                4:1,
                5:1}

#class_weight = {0:5,
#                1:1}

datagen = ImageDataGenerator(
        featurewise_center=False,  # set input mean to 0 over the dataset
        samplewise_center=False,  # set each sample mean to 0
        featurewise_std_normalization=False,  # divide inputs by std of the dataset
        samplewise_std_normalization=False,  # divide each input by its std
        zca_whitening=False,  # apply ZCA whitening
        rotation_range=90,  # randomly rotate images in the range (degrees, 0 to 180)
        width_shift_range=0.2,  # randomly shift images horizontally (fraction of total width)
        height_shift_range=0.2,  # randomly shift images vertically (fraction of total height)
        horizontal_flip=False,  # randomly flip images
        vertical_flip=False)  # randomly flip images
datagen.fit(x_train)

#def baseline_model():
# create model
model = Sequential()
model.add(Conv2D(32, (4, 4), padding='same',
             input_shape=input_shape))
#model.add(Activation('relu'))
model.add(MaxPooling2D(pool_size=(2, 2)))
#model.add(Dropout(0.25))
model.add(Flatten())
#model.add(Dense(256))
#model.add(Activation('sigmoid'))
model.add(Dropout(0.5))
model.add(Dense(num_classes))
model.add(Activation('sigmoid'))

# Compile model

model.compile(loss='mean_squared_error', optimizer='adam')

model.fit(x_train, y_train, epochs=epochs, batch_size=1, verbose=1)
scores = model.evaluate(x_test, y_test, verbose=1)
#print("%s: %.2f%%" % (model.metrics_names[1], scores[1]*100))

# Save weights of model
weight_name = "Models/model_"+str(img_rows)+"_"+str(weight_size)+".h5"
json_name = "Models/model_"+str(img_rows)+"_"+str(weight_size)+".json"
model.save(weight_name)
with open(json_name, "w") as outfile:
    json.dump(model.to_json(), outfile)
#return model


# fix random seed for reproducibility

#estimators = []
#estimators.append(('standardize', StandardScaler()))
#estimators.append(('mlp', KerasRegressor(build_fn=baseline_model, epochs=50, batch_size=5, verbose=0)))
#pipeline = Pipeline(estimators)
# evaluate model with standardized dataset
#estimator = KerasRegressor(build_fn=baseline_model, nb_epoch=20, batch_size=10, verbose=1)
#model.fit(X[train], Y[train], epochs=150, batch_size=10, verbose=0)
#kfold = KFold(n_splits=2, random_state=seed)
#results = cross_val_score(estimator, x_train, y_train, cv=kfold)
#print("Results: %.2f (%.2f) MSE" % (results.mean(), results.std()))



