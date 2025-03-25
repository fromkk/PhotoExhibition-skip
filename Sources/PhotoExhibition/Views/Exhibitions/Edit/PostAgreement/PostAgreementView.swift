import SwiftUI

struct PostAgreementView: View {
  var body: some View {
    ZStack {
      VStack {
        VStack {
          Image("illustration", bundle: .module)
            .resizable()
            .aspectRatio(contentMode: .fit)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .frame(height: 200)
        .background {
          LinearGradient(
            colors: [
              Color("gradient_purple", bundle: .module),
              Color("gradient_blue", bundle: .module),
            ],
            startPoint: UnitPoint(x: 1, y: 0),
            endPoint: UnitPoint(x: 0, y: 1)
          )
        }
      }
      .background {

      }
      .clipShape(RoundedRectangle(cornerRadius: 16))
      .padding(.horizontal, 24)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background {
      Color.black.opacity(0.75)
    }
    .ignoresSafeArea()
  }
}

#Preview {
  PostAgreementView()
}
