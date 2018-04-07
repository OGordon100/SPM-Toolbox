# Setup
import keras
from scipy.io import loadmat, savemat
try:
    import tkinter as tk
    from tkinter import filedialog
except:
    print('linux')
import os

# Input
img_rows = int(input('Size of Images: '))                # Size of images
weight_size = int(input('Max Images per Category: '))    # Number of images for weighting

# Load images
img_cols = img_rows
if os.name == 'nt':
    root = tk.Tk()
    root.withdraw()
    file_path = filedialog.askopenfilename()
else:
    file_path = "/home/ogordon/Greyscale_Images_"+str(img_rows)+".mat"

mat = loadmat(file_path)

x_train = mat['u8']/255

# Reshape
x_train = x_train.reshape(x_train.shape[2], img_rows, img_cols, 1)
input_shape = (img_rows, img_cols, 1)

# Load model
#root = tk.Tk()
#root.withdraw()
#weight_path = filedialog.askopenfilename()
weight_path = "Models/model_"+str(img_rows)+"_"+str(weight_size)+".h5"
model = keras.models.load_model(weight_path)
out = model.predict(x_train)

print(out)
savemat(("Database/nnet_"+str(img_rows)+"_"+str(weight_size)+".mat"),
                 mdict={'nnet_score': out})