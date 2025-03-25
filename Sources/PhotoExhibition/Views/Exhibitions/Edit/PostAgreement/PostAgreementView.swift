import SwiftUI

struct PostAgreementItemView: View {
  @Binding var isChecked: Bool
  let text: LocalizedStringKey

  var body: some View {
    Button {
      isChecked = !isChecked
    } label: {
      HStack(spacing: 8) {
        Image(systemName: isChecked ? "checkmark.square" : "square")
          .foregroundColor(Color("text", bundle: .module))
        Text(text)
          .font(.subheadline)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
    .buttonStyle(.plain)
  }
}

#Preview {
  PostAgreementItemView(isChecked: .constant(true), text: "agree")
  PostAgreementItemView(isChecked: .constant(false), text: "disagree")
}

struct PostAgreementView: View {
  let onAgree: () -> Void
  let onDismiss: () -> Void

  init(
    onAgree: @escaping () -> Void,
    onDismiss: @escaping () -> Void
  ) {
    self.onAgree = onAgree
    self.onDismiss = onDismiss
  }

  /// 他人を不快にさせる画像は投稿しない
  @State var noOffensiveContent: Bool = false
  /// 著作権や肖像権を侵害しない
  @State var respectsCopyright: Bool = false
  /// 法令・公序良俗に反しない
  @State var legalCompliance: Bool = false

  public var body: some View {
    ZStack {
      ZStack(alignment: .topTrailing) {
        VStack(spacing: 0) {
          VStack {
            Image("illustration", bundle: .module)
              .resizable()
              .aspectRatio(contentMode: .fit)

            Text("This illustration was created using JOY.")
              .frame(maxWidth: .infinity, alignment: .trailing)
              .font(.caption)
              .padding(8)
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

          VStack(spacing: 16) {
            VStack(spacing: 8) {
              Text("Please review and agree to the following before creating an exhibition.")
                .font(.headline)
                .foregroundStyle(Color("text", bundle: .module))

              PostAgreementItemView(
                isChecked: $noOffensiveContent,
                text: "I will not upload images that may offend others."
              )

              PostAgreementItemView(
                isChecked: $respectsCopyright,
                text: "I will only upload images that respect copyrights and portrait rights."
              )

              PostAgreementItemView(
                isChecked: $legalCompliance,
                text: " I will not upload images that violate laws or public morals."
              )
            }

            Button {
              onAgree()
            } label: {
              Text("Agree")
                .font(.headline)
            }
            .disabled(!noOffensiveContent || !respectsCopyright || !legalCompliance)
          }
          .padding(16)
        }

        Button {
          onDismiss()
        } label: {
          Image(systemName: "xmark")
            .foregroundStyle(Color("text", bundle: .module))
            .padding(8)
            .background(Color("background", bundle: .module))
            .clipShape(Circle())
            .padding(8)
        }
        .accessibilityLabel(Text("Close"))
      }
      .background {
        Color("background", bundle: .module)
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
  PostAgreementView(onAgree: {}, onDismiss: {})
}
