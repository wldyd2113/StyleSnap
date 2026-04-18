import SwiftUI
import PhotosUI
import AVFoundation

// MARK: - Camera Analysis View
struct CameraAnalysisView: View {
    @StateObject private var viewModel = CameraViewModel()
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    
    var body: some View {
        ZStack {
            // 1. 카메라 프리뷰 (내부 정의된 컴포넌트 사용)
            CameraPreviewLayerComponent(session: viewModel.cameraManager.session)
                .edgesIgnoringSafeArea(.all)
                .blur(radius: viewModel.state.isShowingResult ? 10 : 0)
            
            // 2. UI 레이어
            VStack {
                if !viewModel.state.isShowingResult {
                    HStack {
                        Text("실시간 스타일 분석 중...")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Capsule())
                    }
                    .padding(.top, 60)
                }
                
                Spacer()
                
                // [추가] 촬영된 이미지 카드 표시
                if viewModel.state.isShowingResult, let image = viewModel.state.capturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 200, height: 260)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white, lineWidth: 4)
                        )
                        .shadow(radius: 10)
                        .padding(.bottom, 20)
                }
                
                // 3. 분석 결과 카드
                VStack(spacing: 15) {
                    HStack(spacing: 20) {
                        AnalysisChip(label: "카테고리", value: viewModel.state.currentCategory)
                        AnalysisChip(label: "스타일", value: viewModel.state.currentStyle)
                        ColorPreviewChip(color: viewModel.state.dominantColor)
                    }
                    
                    if viewModel.state.isShowingResult {
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 12) {
                            // [수정] 상의/하의 단어 제거
                            Text("어울리는 추천 컬러 조합")
                                .font(.system(size: 16, weight: .bold))
                            
                            if viewModel.state.isRecommendationLoading {
                                HStack {
                                    Spacer()
                                    ProgressView("최적의 코디를 찾는 중...")
                                    Spacer()
                                }
                                .padding()
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(viewModel.state.recommendations) { item in
                                            RecommendationCard(item: item)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(24)
                .padding(.horizontal)
                
                // 4. 하단 컨트롤 바
                HStack(spacing: 40) {
                    if viewModel.state.isShowingResult {
                        // 다시 스캔 버튼 (로컬 정의)
                        Button(action: { viewModel.send(intent: .resetToRealtime) }) {
                            Text("다시 스캔하기")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.black)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 40)
                    } else {
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Circle().fill(Color.black.opacity(0.5)))
                        }
                        
                        Button(action: { viewModel.send(intent: .capturePhoto) }) {
                            Circle()
                                .stroke(Color.white, lineWidth: 4)
                                .frame(width: 80, height: 80)
                                .overlay(Circle().fill(Color.white).frame(width: 68, height: 68))
                        }
                        
                        Button(action: { print("DEBUG: Filter tapped") }) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Circle().fill(Color.black.opacity(0.5)))
                        }
                    }
                }
                .padding(.bottom, 50)
                .padding(.top, 20)
            }
        }
        .onAppear {
            viewModel.send(intent: .checkPermissions)
            viewModel.send(intent: .startAnalysis)
        }
        .onChange(of: selectedPhotoItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    viewModel.send(intent: .analyzeGalleryImage(image))
                }
            }
        }
    }
}

// MARK: - Internal Components (빌드 에러 방지를 위해 통합)
struct CameraPreviewLayerComponent: UIViewRepresentable {
    let session: AVCaptureSession
    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }
    func updateUIView(_ uiView: PreviewView, context: Context) { }
    class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
        override func layoutSubviews() { super.layoutSubviews(); videoPreviewLayer.frame = self.bounds }
    }
}

struct RecommendationCard: View {
    let item: RecommendedItem
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            RoundedRectangle(cornerRadius: 15)
                .fill(item.color)
                .frame(width: 130, height: 160)
                .overlay(
                    VStack {
                        Spacer()
                        Text("\(Int(item.matchScore * 100))% Match")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(item.color == .white ? .black : .white)
                            .padding(.bottom, 12)
                    }
                )
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 5)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name).font(.system(size: 12, weight: .bold)).foregroundColor(.black).lineLimit(1)
                Text(item.category).font(.system(size: 10)).foregroundColor(.gray)
            }
        }
    }
}

struct AnalysisChip: View {
    let label: String
    let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.system(size: 10, weight: .bold)).foregroundColor(.gray)
            Text(value).font(.system(size: 14, weight: .medium)).foregroundColor(.black)
        }
    }
}

struct ColorPreviewChip: View {
    let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("색상").font(.system(size: 10, weight: .bold)).foregroundColor(.gray)
            Circle().fill(color).frame(width: 14, height: 14).overlay(Circle().stroke(Color.gray.opacity(0.5), lineWidth: 1))
        }
    }
}

struct CameraAnalysisView_Previews: PreviewProvider {
    static var previews: some View {
        CameraAnalysisView()
    }
}
