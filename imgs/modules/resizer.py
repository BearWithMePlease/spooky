import os
from PIL import Image
path = './'
initial_size = 96
final_size = 64
for root, dirs, files in os.walk(path):
    for file in files:
        if file.endswith('.jpg') or file.endswith('.png'):
            img = Image.open(os.path.join(root, file))
            img = img.resize((int(img.width / initial_size * final_size), int(img.height / initial_size * final_size)))
            img.save(os.path.join(root, file))