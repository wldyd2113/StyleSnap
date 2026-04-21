import coremltools as ct
import torch # torch를 불러오지만 최소한의 개체만 사용

print("STEP 2: Loading PyTorch model for conversion...")
# 1. 저장된 PyTorch 모델 불러오기 (메모리 격리된 상태)
traced_model = torch.jit.load("traced_fashion_model.pt")

# 2. CoreML 입력 형태 정의 (512차원 벡터 2개)
example_top_shape = (1, 512)
example_bottom_shape = (1, 512)

# 3. CoreML 변환 수행
mlmodel = ct.convert(
    traced_model,
    inputs=[
        ct.TensorType(name="embedding_top", shape=example_top_shape),
        ct.TensorType(name="embedding_bottom", shape=example_bottom_shape)
    ],
    outputs=[ct.TensorType(name="compatibility_score")],
    minimum_deployment_target=ct.target.iOS16
)

# 4. 저장
mlmodel.save("coreml/FashionCompatibilityScorer.mlpackage")
print("SUCCESS: FashionCompatibilityScorer.mlpackage created successfully.")
