import SwiftUI
import PhotosUI
import AVFoundation

// MARK: - Camera Analysis View
struct CameraAnalysisView: View {
    @StateObject private var viewModel = CameraViewModel()
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    
    var body: some View {
        ZStack {
            CameraPreviewLayerComponent(session: viewModel.cameraManager.session)
                .edgesIgnoringSafeArea(.all)
                .blur(radius: viewModel.state.isShowingResult ? 10 : 0)
            
            VStack {
                if !viewModel.state.isShowingResult {
                    HStack {
                        Text("실시간 컬러 및 스타일 분석 중...")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16).padding(.vertical, 8)
                            .background(Color.black.opacity(0.6)).clipShape(Capsule())
                    }.padding(.top, 60)
                }
                
                Spacer()
                
                if viewModel.state.isShowingResult, let image = viewModel.state.capturedImage {
                    Image(uiImage: image).resizable().aspectRatio(contentMode: .fill)
                        .frame(width: 200, height: 260).clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white, lineWidth: 4))
                        .shadow(radius: 10).padding(.bottom, 20)
                }
                
                VStack(spacing: 15) {
                    HStack(spacing: 20) {
                        AnalysisChip(label: "카테고리", value: viewModel.state.currentCategory)
                        AnalysisChip(label: "스타일", value: viewModel.state.currentStyle)
                        ColorPreviewChip(color: viewModel.state.dominantColor)
                    }
                    
                    if viewModel.state.isShowingResult {
                        Divider()
                        VStack(alignment: .leading, spacing: 12) {
                            Text("AI 추천 컬러 (5가지)")
                                .font(.system(size: 16, weight: .bold))
                            
                            if viewModel.state.isRecommendationLoading {
                                HStack { Spacer(); ProgressView(); Spacer() }.padding()
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(viewModel.state.recommendations) { recommendation in
                                            IndividualColorCard(recommendation: recommendation)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding().background(.ultraThinMaterial).cornerRadius(24).padding(.horizontal)
                
                HStack(spacing: 40) {
                    if viewModel.state.isShowingResult {
                        Button(action: { viewModel.send(intent: .resetToRealtime) }) {
                            Text("다시 스캔하기").font(.system(size: 16, weight: .bold)).foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 16).background(Color.black).cornerRadius(12)
                        }.padding(.horizontal, 40)
                    } else {
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            Image(systemName: "photo.on.rectangle").font(.system(size: 24)).foregroundColor(.white).frame(width: 60, height: 60).background(Circle().fill(Color.black.opacity(0.5)))
                        }
                        Button(action: { viewModel.send(intent: .capturePhoto) }) {
                            Circle().stroke(Color.white, lineWidth: 4).frame(width: 80, height: 80).overlay(Circle().fill(Color.white).frame(width: 68, height: 68))
                        }
                        Button(action: { print("DEBUG: Filter tapped") }) {
                            Image(systemName: "slider.horizontal.3").font(.system(size: 24)).foregroundColor(.white).frame(width: 60, height: 60).background(Circle().fill(Color.black.opacity(0.5)))
                        }
                    }
                }.padding(.bottom, 50).padding(.top, 20)
            }
        }
        .onAppear { 
            viewModel.send(intent: .checkPermissions)
            viewModel.send(intent: .startAnalysis) 
        }
        .onChange(of: selectedPhotoItem) { oldValue, newValue in
            if let item = newValue {
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        viewModel.send(intent: .analyzeGalleryImage(image))
                    }
                }
            }
        }
    }
}

// [개편] 개별 컬러를 강조하는 심플한 카드 UI
struct IndividualColorCard: View {
    let recommendation: ColorRecommendation
    
    var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 15)
                .fill(recommendation.color)
                .frame(width: 80, height: 80)
                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
            
            Text(recommendation.name)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Helper Components
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
            Text("추출 색상").font(.system(size: 10, weight: .bold)).foregroundColor(.gray)
            Circle().fill(color).frame(width: 14, height: 14).overlay(Circle().stroke(Color.gray.opacity(0.5), lineWidth: 1))
        }
    }
}

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
