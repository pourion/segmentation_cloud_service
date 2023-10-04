# way to upload image: endpoint
# way to save the image
# function to make prediction on the image
# show the results
import os
from matplotlib import image as img
import pdb

from flask import Flask
from flask import request
from flask import render_template

import matplotlib.pyplot as plt

from server_predict import predict_single_image


app = Flask(__name__)
UPLOAD_FOLDER = '/workspace/static'
LOAD_PATH = '/static/'
@app.route("/", methods=['GET', 'POST'])
def upload_predict():
    if request.method == "POST":
        image_file = request.files['image']
        if image_file:
            image_location = os.path.join(UPLOAD_FOLDER, image_file.filename)
            image_file.save(image_location)
            output, image_pred = predict_single_image(image_file)
            
            plt.figure(figsize=(8,8))
            plt.imshow(output)
            save_out = os.path.join(UPLOAD_FOLDER, f"{image_file.filename}_segmented.png")
            plt.savefig(save_out)
            plt.close()
            
            save_out = os.path.join(UPLOAD_FOLDER, f"{image_file.filename}_pred.png")
            img.imsave(save_out, image_pred)
            
            load_segmented_path = os.path.join(LOAD_PATH, f"{image_file.filename}_segmented.png")
            load_image_path = os.path.join(LOAD_PATH, f"{image_file.filename}_pred.png")
            return render_template("index.html", 
                                   coverage = output.mean(), 
                                   segmented_path=load_segmented_path, 
                                   image_path=load_image_path,
                                   )
        
    return render_template("index.html", 
                           coverage=0.004, 
                           segmented_path='static/Taichi_S6_C2_00045.png_segmented.png', 
                           image_path='/static/Taichi_S6_C2_00045.png_pred.png')

if __name__=="__main__":
    app.run(port=8888, debug=True)