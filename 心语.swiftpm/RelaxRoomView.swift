import SwiftUI

struct RelaxRoomView: View {
    var body: some View {
        VStack {
            Text("放松室")
                .font(.largeTitle)
                .padding()
            Text("这里是你的放松空间，后续可添加冥想、音乐等内容。")
                .foregroundColor(.gray)
        }
    }
}

struct RelaxRoomView_Previews: PreviewProvider {
    static var previews: some View {
        RelaxRoomView()
    }
} 