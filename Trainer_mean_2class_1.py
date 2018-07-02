# Import stuff
from __future__ import print_function
import keras
#from keras.datasets import cifar100
from keras.models import Sequential
from keras.layers import Dense, Dropout, Flatten, Activation
from keras.layers import Conv2D, MaxPooling2D
from keras.preprocessing.image import ImageDataGenerator
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
num_classes = 2                                     # Number of categories
epochs = int(input('Number of Epochs: '))           # Number of "repeats" of training
img_rows = int(input('Size of Images: '))
weight_size = int(input('Max Images per Category: '))
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

y_test[:,1] = numpy.mean(y_test[:,1:],axis=1)
y_train[:,1] = numpy.mean(y_train[:,1:],axis=1)
y_train = y_train[:,0:2]
y_test = y_test[:,0:2]
#y_train[:,1] = 0
#y_test[:,1] = 0
#y_train[y_train[:,0]<0.2,1] = 1
#y_test[y_test[:,0]<0.2,1] = 1

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
#keras.layers.normalization.BatchNormalization(input_shape=(input_shape))
 #{0:w_mult.item(0),
               # 1:w_mult.item(1),
               # 2:w_mult.item(2),
               # 3:w_mult.item(3),
               # 4:w_mult.item(4),
               # 5:w_mult.item(5)}
#class_weight = {0:3,
#                1:3,
#                2:1,
#                3:2,
#                4:2,
#                5:1}

class_weight = {0:10,
                1:1}

datagen = ImageDataGenerator(
        featurewise_center=False,  # set input mean to 0 over the dataset
        samplewise_center=False,  # set each sample mean to 0
        featurewise_std_normalization=False,  # divide inputs by std of the dataset
        samplewise_std_normalization=False,  # divide each input by its std
        zca_whitening=False,  # apply ZCA whitening
        rotation_range=0,  # randomly rotate images in the range (degrees, 0 to 180)
        width_shift_range=0,  # randomly shift images horizontally (fraction of total width)
        height_shift_range=0,  # randomly shift images vertically (fraction of total height)
        horizontal_flip=False,  # randomly flip images
        vertical_flip=False)  # randomly flip images
datagen.fit(x_train)

model = Sequential()

model.add(Conv2D(32, (4, 4), padding='same',
                 input_shape=input_shape))
#model.add(Activation('relu'))
#model.add(Conv2D(32, (4, 4)))
#model.add(Activation('relu'))
#model.add(MaxPooling2D(pool_size=(2, 2)))
model.add(Dropout(0.25))
#model.add(Conv2D(64, (4, 4), padding='same'))
model.add(Activation('relu'))
#model.add(Conv2D(64, (4, 4)))
#model.add(Activation('relu'))
model.add(MaxPooling2D(pool_size=(2, 2)))
#model.add(Dropout(0.25))
model.add(Flatten())
model.add(Dense(512))
model.add(Activation('relu'))
model.add(Dropout(0.5))
model.add(Dense(num_classes))
model.add(Activation('sigmoid'))

sgd = SGD(lr=0.0001, decay=1e-6, momentum=0.9, nesterov=False)
model.compile(loss='categorical_crossentropy', optimizer=sgd, metrics=['accuracy'])

history = model.fit(x_train, y_train,
          batch_size=batch_size,
          epochs=epochs,
          verbose=1,
          validation_data=(x_test, y_test),
          class_weight=class_weight)

score = model.evaluate(x_test, y_test, batch_size=batch_size)

print('Test loss:', score[0])
print('Test accuracy:', score[1])

# Save learning curves
acc_history = [history.history['acc'],history.history['val_acc']]
loss_history = [history.history['loss'],history.history['val_loss']]
scipy.io.savemat(("history_loss_"+str(img_rows)+"_"+str(weight_size)+".mat"),
                 mdict={'loss_history': loss_history})
scipy.io.savemat(("history_acc_"+str(img_rows)+"_"+str(weight_size)+".mat"),
                 mdict={'acc_history': acc_history})

# Save weights of model
weight_name = "Models/model_"+str(img_rows)+"_"+str(weight_size)+".h5"
json_name = "Models/model_"+str(img_rows)+"_"+str(weight_size)+".json"
model.save(weight_name)
with open(json_name, "w") as outfile:
      json.dump(model.to_json(), outfile)
