import os
# 라이브러리 충돌 무시 설정
os.environ['KMP_DUPLICATE_LIB_OK'] = 'True'

import coremltools as ct # 임포트 순서 변경
import torch
import torch.nn as nn
import numpy as np

# 1. Siamese Compatibility Scorer 모델 정의
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

# 2. 모델 인스턴스 생성
model = FashionCompatibilityScorer()
model.eval()

# 3. CoreML 변환을 위한 더미 데이터
example_top = torch.rand(1, 512)
example_bottom = torch.rand(1, 512)
traced_model = torch.jit.trace(model, (example_top, example_bottom))

# 4. CoreML 변환 수행
mlmodel = ct.convert(
    traced_model,
    inputs=[
        ct.TensorType(name="embedding_top", shape=example_top.shape),
        ct.TensorType(name="embedding_bottom", shape=example_bottom.shape)
    ],
    outputs=[ct.TensorType(name="compatibility_score")],
    minimum_deployment_target=ct.target.iOS16
)

# 5. 저장
mlmodel.save("coreml/FashionCompatibilityScorer.mlpackage")
print("SUCCESS: FashionCompatibilityScorer.mlpackage created successfully.")
