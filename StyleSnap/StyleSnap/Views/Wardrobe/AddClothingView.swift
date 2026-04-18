import SwiftUI
import PhotosUI

struct AddClothingView: View {
    @StateObject private var viewModel = AddClothingViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    let categories = ["상의", "하의", "신발"]
    let styles = ["캐주얼", "미니멀", "스트릿", "포멀", "스포티", "빈티지"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("옷 사진")) {
                    PhotosPicker(selection: Binding(
                        get: { viewModel.state.selectedPhotoItem },
                        set: { viewModel.send(intent: .selectImage($0)) }
                    ), matching: .images) {
                        if let data = viewModel.state.capturedImageData, let uiImage = UIImage(data: data) {
                            ZStack {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 200)
                                    .cornerRadius(12)
                                    .clipped()
                                
                                if viewModel.state.isAnalyzing {
                                    Color.black.opacity(0.4).cornerRadius(12)
                                    ProgressView("AI 분석 중...")
                                        .foregroundColor(.white)
                                }
                            }
                        } else {
                            VStack(spacing: 12) {
                                Image(systemName: "camera.fill").font(.system(size: 32)).foregroundColor(.secondaryGray)
                                Text("앨범에서 사진 선택").font(.system(size: 14)).foregroundColor(.secondaryGray)
                            }
                            .frame(maxWidth: .infinity).frame(height: 200)
                            .background(Color.gray.opacity(0.1)).cornerRadius(12)
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 10)
                }
                
                Section(header: Text("AI 분석 결과 (자동 입력)")) {
                    HStack {
                        Text("카테고리")
                        Spacer()
                        Picker("", selection: Binding(
                            get: { viewModel.state.selectedCategory },
                            set: { viewModel.send(intent: .updateCategory($0)) }
                        )) {
                            ForEach(categories, id: \.self) { Text($0) }
                        }.pickerStyle(.menu)
                    }
                    
                    HStack {
                        Text("스타일")
                        Spacer()
                        Picker("", selection: Binding(
                            get: { viewModel.state.selectedStyle },
                            set: { viewModel.send(intent: .updateStyle($0)) }
                        )) {
                            ForEach(styles, id: \.self) { Text($0) }
                        }.pickerStyle(.menu)
                    }
                }
                
                Section(header: Text("상세 정보")) {
                    TextField("옷 종류", text: Binding(
                        get: { viewModel.state.itemName },
                        set: { viewModel.send(intent: .updateName($0)) }
                    ))
                    TextField("색상", text: Binding(
                        get: { viewModel.state.colorName },
                        set: { viewModel.send(intent: .updateColorName($0)) }
                    ))
                    ColorPicker("대표 색상", selection: Binding(
                        get: { viewModel.state.selectedColor },
                        set: { viewModel.send(intent: .updateColor($0)) }
                    ))
                }
                
                Section {
                    Button(action: { viewModel.send(intent: .save) }) {
                        Text("옷 등록하기")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white).frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background((viewModel.state.itemName.isEmpty || viewModel.state.capturedImageData == nil || viewModel.state.isAnalyzing) ? Color.gray : Color.black)
                            .cornerRadius(10)
                    }
                    .disabled(viewModel.state.itemName.isEmpty || viewModel.state.capturedImageData == nil || viewModel.state.isAnalyzing)
                }
                .listRowBackground(Color.clear)
            }
            .navigationTitle("새 옷 등록")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") { presentationMode.wrappedValue.dismiss() }.foregroundColor(.black)
                }
            }
            .onChange(of: viewModel.state.isSaved) { saved in
                if saved { presentationMode.wrappedValue.dismiss() }
            }
        }
    }
}

struct AddClothingView_Previews: PreviewProvider {
    static var previews: some View {
        AddClothingView()
    }
}
