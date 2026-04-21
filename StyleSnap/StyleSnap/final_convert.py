import os
import sys

# 1. 시스템 환경 변수 최우선 설정 (충돌 방지)
os.environ['KMP_DUPLICATE_LIB_OK'] = 'True'
os.environ['OMP_NUM_THREADS'] = '1'
os.environ['MKL_NUM_THREADS'] = '1'
os.environ['VECLIB_MAX_CPU_THREADS'] = '1'

try:
    import numpy as np
    import torch
    import torch.nn as nn
    import coremltools as ct
    print("SUCCESS: Libraries loaded safely.")
except Exception as e:
    print(f"LOAD ERROR: {e}")
    sys.exit(1)

# 2. Siamese Compatibility Scorer 모델 정의
class FashionCompatibilityScorer(nn.Module):
    def __init__(self):
        super(FashionCompatibilityScorer, self).__init__()
        self.fc = nn.Sequential(
            nn.Linear(1024, 512),
            nn.ReLU(),
            nn.Linear(512, 128),
            nn.ReLU(),
            nn.Linear(128, 1),
            nn.Sigmoid()
        )

    def forward(self, embedding_top, embedding_bottom):
        combined = torch.cat((embedding_top, embedding_bottom), dim=1)
        return self.fc(combined)

# 3. 모델 준비
model = FashionCompatibilityScorer()
model.eval()

# 4. Tracing (JIT)
example_top = torch.rand(1, 512)
example_bottom = torch.rand(1, 512)
traced_model = torch.jit.trace(model, (example_top, example_bottom))

# 5. CoreML 변환
print("Converting to CoreML... please wait.")
try:
    mlmodel = ct.convert(
        traced_model,
        inputs=[
            ct.TensorType(name="embedding_top", shape=(1, 512)),
            ct.TensorType(name="embedding_bottom", shape=(1, 512))
        ],
        outputs=[ct.TensorType(name="compatibility_score")],
        minimum_deployment_target=ct.target.iOS16
    )
    
    # 6. 저장
    if not os.path.exists('coreml'):
        os.makedirs('coreml')
        
    mlmodel.save("coreml/FashionCompatibilityScorer.mlpackage")
    print("✨ SUCCESS: FashionCompatibilityScorer.mlpackage created successfully!")
except Exception as e:
    print(f"CONVERSION ERROR: {e}")

