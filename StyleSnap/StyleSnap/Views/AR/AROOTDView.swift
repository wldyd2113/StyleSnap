import SwiftUI
import ARKit
import SceneKit

struct AROOTDView: View {
    @State private var showWardrobe = false
    @State private var alertMessage: String? = nil
    
    // 코디네이터 상태 관찰 (선택된 노드 감지)
    @StateObject private var coordinator = ARCoordinator()
    
    @EnvironmentObject var tabManager: TabManager
    
    var body: some View {
        ZStack {
            // AR 배경
            ARViewInternal(coordinator: coordinator)
                .ignoresSafeArea()
            
            // UI 레이어
            VStack {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("AR OOTD")
                            .font(.system(size: 26, weight: .black))
                        Text("옷을 터치하여 위치 이동 및 가로세로를 바꿔보세요")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(VisualEffectBlur(blurStyle: .systemUltraThinMaterialDark).cornerRadius(20))
                    
                    Spacer()
                    
                    Button(action: { coordinator.startSession(reset: true) }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .padding(15)
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                }
                .padding(.top, 60)
                .padding(.horizontal, 20)
                
                Spacer()
                
                // 하단 컨트롤 영역
                VStack(spacing: 20) {
                    // [핵심 추가] 옷 선택 시 나타나는 가로세로 전환 및 삭제 버튼
                    if coordinator.selectedNode != nil {
                        HStack(spacing: 25) {
                            // 가로세로 전환 (90도 회전)
                            Button(action: { coordinator.rotate90Degrees() }) {
                                ControlButton(icon: "arrow.right.arrow.left.square.fill", label: "방향 전환", color: .blue)
                            }
                            
                            // 삭제 버튼
                            Button(action: { coordinator.deleteSelectedNode() }) {
                                ControlButton(icon: "trash.fill", label: "삭제", color: .red)
                            }
                        }
                        .padding(.vertical, 15)
                        .padding(.horizontal, 30)
                        .background(VisualEffectBlur(blurStyle: .systemUltraThinMaterialDark).cornerRadius(25))
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    
                    // 옷 추가 버튼
                    Button(action: { 
                        coordinator.pauseSession()
                        showWardrobe = true 
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20))
                            Text("옷 추가하기")
                                .font(.system(size: 18, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.black)
                        .cornerRadius(18)
                        .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 50)
            }
        }
        .sheet(isPresented: $showWardrobe, onDismiss: {
            coordinator.startSession()
        }) {
            ARWardrobePicker(coordinator: coordinator) { _ in }
                .environmentObject(tabManager)
        }
    }
}

// 컨트롤 버튼 컴포넌트
struct ControlButton: View {
    let icon: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(Circle().fill(color.opacity(0.8)))
            
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

// 나머지 헬퍼 컴포넌트들...
struct ARViewInternal: UIViewRepresentable {
    let coordinator: ARCoordinator
    func makeUIView(context: Context) -> ARSCNView {
        let scnView = ARSCNView(frame: .zero)
        scnView.delegate = coordinator
        scnView.autoenablesDefaultLighting = true
        coordinator.sceneView = scnView
        coordinator.setupAR()
        return scnView
    }
    func updateUIView(_ uiView: ARSCNView, context: Context) {}
}

struct ARWardrobePicker: View {
    let coordinator: ARCoordinator
    let onComplete: (Bool) -> Void
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var tabManager: TabManager
    @StateObject private var viewModel = WardrobeViewModel()
    @State private var showingAddView = false
    let categories = ["전체", "상의", "하의", "신발"]
    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ForEach(categories, id: \.self) { category in
                            Button(action: { withAnimation { viewModel.send(intent: .changeCategory(category)) } }) {
                                VStack(spacing: 8) {
                                    Text(category).font(.system(size: 15, weight: viewModel.state.selectedCategory == category ? .bold : .medium))
                                        .foregroundColor(viewModel.state.selectedCategory == category ? .black : .gray)
                                    Rectangle().fill(viewModel.state.selectedCategory == category ? Color.black : Color.clear).frame(height: 2)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.top, 15).padding(.bottom, 10).background(Color.white)
                Divider()
                ZStack {
                    if viewModel.state.isLoading { ProgressView("옷장 불러오는 중...") }
                    else if viewModel.state.clothes.isEmpty {
                        VStack(spacing: 24) {
                            Image(systemName: "hanger").font(.system(size: 60)).foregroundColor(.gray.opacity(0.3))
                            Text("등록된 옷이 없습니다.").font(.system(size: 16, weight: .medium)).foregroundColor(.secondary)
                        }
                    } else {
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(viewModel.state.clothes) { clothing in
                                    Button(action: {
                                        Task { @MainActor in let success = await coordinator.placeClothing(item: clothing); onComplete(success) }
                                        dismiss()
                                    }) {
                                        VStack(alignment: .leading, spacing: 8) {
                                            ClothingThumbnail(data: clothing.imageData)
                                            Text(clothing.name).font(.system(size: 11, weight: .medium)).foregroundColor(.primary).lineLimit(1)
                                        }
                                    }
                                }
                            }
                            .padding(16)
                        }
                    }
                }
            }
            .navigationTitle("내 옷장").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("취소") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) { Button(action: { showingAddView = true }) { Image(systemName: "plus").foregroundColor(.black) } }
            }
            .onAppear { viewModel.send(intent: .loadClothes) }
            .sheet(isPresented: $showingAddView, onDismiss: { viewModel.send(intent: .loadClothes) }) { AddClothingView() }
        }
    }
}

struct ClothingThumbnail: View {
    let data: Data?
    @State private var uiImage: UIImage? = nil
    var body: some View {
        ZStack {
            if let image = uiImage { Image(uiImage: image).resizable().aspectRatio(1, contentMode: .fill) }
            else { Rectangle().fill(Color.gray.opacity(0.1)); if data != nil { ProgressView().scaleEffect(0.5) } }
        }
        .frame(maxWidth: .infinity).aspectRatio(1, contentMode: .fit).cornerRadius(12).clipped()
        .task(priority: .userInitiated) { if let data = data { let image = UIImage(data: data); await MainActor.run { self.uiImage = image } } }
    }
}

struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView { UIVisualEffectView(effect: UIBlurEffect(style: blurStyle)) }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}
