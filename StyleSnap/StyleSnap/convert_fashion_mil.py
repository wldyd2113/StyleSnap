import coremltools as ct
from coremltools.converters.mil.mil import Builder as mb
import numpy as np

# 1. Siamese Network 아키텍처 정의 (Pure MIL Builder 사용 - Torch 미사용)
@mb.program(
    input_specs=[
        mb.TensorSpec(shape=(1, 512)),
        mb.TensorSpec(shape=(1, 512))
    ]
)
def fashion_siamese(embedding_top, embedding_bottom):
    # 1. 두 벡터를 하나로 합침 (Concat: 1024차원)
    combined = mb.concat(values=[embedding_top, embedding_bottom], axis=1)
    
    # 2. 첫 번째 히든 레이어 (1024 -> 512)
    w1 = np.random.randn(512, 1024).astype(np.float32) * 0.1
    b1 = np.zeros(512, dtype=np.float32)
    linear1 = mb.linear(x=combined, weight=w1, bias=b1)
    relu1 = mb.relu(x=linear1)
    
    # 3. 두 번째 히든 레이어 (512 -> 128)
    w2 = np.random.randn(128, 512).astype(np.float32) * 0.1
    b2 = np.zeros(128, dtype=np.float32)
    linear2 = mb.linear(x=relu1, weight=w2, bias=b2)
    relu2 = mb.relu(x=linear2)
    
    # 4. 출력 레이어 (128 -> 1)
    w3 = np.random.randn(1, 128).astype(np.float32) * 0.1
    b3 = np.zeros(1, dtype=np.float32)
    linear3 = mb.linear(x=relu2, weight=w3, bias=b3)
    
    # 5. Sigmoid (0~1 사이 점수 반환)
    score = mb.sigmoid(x=linear3, name="compatibility_score")
    return score

# 2. CoreML 모델로 변환
mlmodel = ct.convert(
    fashion_siamese,
    minimum_deployment_target=ct.target.iOS16
)

# 3. 메타데이터 설정 및 저장
mlmodel.author = "StyleSnap AI Engine"
mlmodel.short_description = "Siamese Fashion Compatibility Model"
mlmodel.save("coreml/FashionCompatibilityScorer.mlpackage")
print("SUCCESS: FashionCompatibilityScorer.mlpackage created without PyTorch!")
