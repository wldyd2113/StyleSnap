import torch
import torch.nn as nn

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

# 3. 더미 데이터 생성 및 Tracing
example_top = torch.rand(1, 512)
example_bottom = torch.rand(1, 512)
traced_model = torch.jit.trace(model, (example_top, example_bottom))

# 4. PyTorch 모델 파일로 저장 (메모리 충돌 방지를 위해 여기서 종료)
traced_model.save("traced_fashion_model.pt")
print("STEP 1: PyTorch model saved successfully.")
