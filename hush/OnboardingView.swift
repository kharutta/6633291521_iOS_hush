import SwiftUI

struct OnboardingView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 25) {
            Text("ประวัติการฟังของคุณ")
                .font(.largeTitle).bold()
            
            Text("ใช้คำนวณ Estimated Hearing Age — ยิ่งแม่นยิ่งดี แต่ประมาณได้เลย")
                .foregroundColor(.gray)
            
            InputField(label: "ใส่หูฟังมากี่ปีแล้ว?", placeholder: "5 ปี")
            InputField(label: "วันละกี่ชั่วโมงโดยเฉลี่ย?", placeholder: "3-4 ชั่วโมง")
            
            VStack(alignment: .leading) {
                Text("ระดับเสียงที่ฟังโดยทั่วไป?").foregroundColor(.gray)
                HStack {
                    CapsuleButton(title: "เบา")
                    CapsuleButton(title: "ปานกลาง", isSelected: true)
                    CapsuleButton(title: "ดัง")
                }
            }
            
            Spacer()
            
            Button(action: {}) {
                Text("ถัดไป →")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(15)
            }
        }
        .padding()
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
}
