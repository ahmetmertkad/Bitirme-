import torch
import torch.nn.functional as F
import torchvision.transforms as transforms
from PIL import Image
import timm

# 1. Cihaz ve Model
device = "mps" if torch.backends.mps.is_available() else "cpu"
model_path = 'best_plant_model_efficientnet_b3.pth' 

class_names = [
    'Apple___Apple_scab', 'Apple___Black_rot', 'Apple___Cedar_apple_rust', 'Apple___healthy',
    'Cherry_(including_sour)___healthy', 'Cherry_(including_sour)___Powdery_mildew', 
    'Corn_(maize)___Cercospora_leaf_spot Gray_leaf_spot', 'Corn_(maize)___Common_rust_', 
    'Corn_(maize)___healthy', 'Corn_(maize)___Northern_Leaf_Blight', 
    'Grape___Black_rot', 'Grape___Esca_(Black_Measles)', 'Grape___healthy', 'Grape___Leaf_blight_(Isariopsis_Leaf_Spot)', 
    'Peach___Bacterial_spot', 'Peach___healthy', 
    'Pepper,_bell___Bacterial_spot', 'Pepper,_bell___healthy', 
    'Potato___Early_blight', 'Potato___healthy', 'Potato___Late_blight', 
    'Strawberry___healthy', 'Strawberry___Leaf_scorch', 
    'Tomato___Bacterial_spot', 'Tomato___Early_blight', 'Tomato___healthy', 'Tomato___Late_blight', 
    'Tomato___Leaf_Mold', 'Tomato___Septoria_leaf_spot', 'Tomato___Spider_mites Two-spotted_spider_mite', 
    'Tomato___Target_Spot', 'Tomato___Tomato_mosaic_virus', 'Tomato___Tomato_Yellow_Leaf_Curl_Virus'
]

classifier_model = timm.create_model('efficientnet_b3', pretrained=False, num_classes=len(class_names))
classifier_model.load_state_dict(torch.load(model_path, map_location=device))
classifier_model.to(device)
classifier_model.eval()

# 2. Sadece Standart Resize ve Normalize (PlantVillage'da olduğu gibi)
preprocess = transforms.Compose([
    transforms.Resize((300, 300)),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
])

# 3. KENDİ FOTOĞRAFININ YOLUNU BURAYA YAZ (Hiçbir işlem görmemiş orijinal fotoğraf)
img_path = 'mısır_giris/late-blight-on-tomato-global-eng-1.jpg'  # Değiştirin: Kendi fotoğrafınızın yolunu buraya yazın
img = Image.open(img_path).convert('RGB')

# 4. Tahmin
input_tensor = preprocess(img).unsqueeze(0).to(device)
with torch.no_grad():
    outputs = classifier_model(input_tensor)
    probabilities = F.softmax(outputs[0], dim=0)
    conf, idx = torch.max(probabilities, dim=0)

print(f"\n--- HAM FOTOĞRAF TESTİ ---")
print(f"Gerçek Tahmin: {class_names[idx.item()]} | Güven Skoru: %{conf.item() * 100:.2f}\n")