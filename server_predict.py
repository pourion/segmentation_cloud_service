import os
import pdb
from typing import List
from omegaconf import OmegaConf
from PIL import Image

import torch
from torchvision import transforms as T

from segment.inference import inference_server
# from segment.analytics import uq_analytics


# device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
device = 'cpu'

# ----- Parameters
cfg = OmegaConf.load("conf/config.yaml")

num_predictions: int = 1
num_monte_carlo: int = 10

data_set : str = cfg.predict.data_set
output_path: str = os.path.join("/workspace/output", data_set)


# model
bilinear: bool = cfg.model.bilinear
unet_base_exp: int = cfg.model.unet_base_exp
unet_dims: List = []
for i in range(5):
    unet_dims.append(2**(unet_base_exp + i))
    
# ----- Load trained model
model = inference_server(n_channels=3,
                  n_classes=1,
                  bilinear=bilinear,
                  ddims=unet_dims,
                  device=device)

# ------ Quantify Uncertainties
# uqx = uq_analytics(cfg=cfg,
#                    save_path='/workspace/output/analytics',
#                    base_filename=cfg.exp_name)


# ------ Evaluation

def predict_single_image(image_obj):
    """
    ONLY MADS DATA
    """
    path = os.path.join("/workspace/static", image_obj.filename)
    image = Image.open(path).convert('RGB')
    transforms = T.Compose([T.Resize((256, 256)), T.ToTensor(),])
    image = transforms(image)
    output, image_pred = model.predict(image=image)
    return output.squeeze().cpu().numpy(), torch.swapaxes(image_pred.squeeze(), 0, 2).cpu().numpy()