import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
        
    @AppStorage("yearsWearing") private var yearsWearing: Int = 5
    @AppStorage("hoursPerDay") private var hoursPerDay: Int = 3
    @AppStorage("volumeLevel") private var volumeLevel: String = "Medium"
    @AppStorage("birthDate") private var birthDate: Double = (Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()).timeIntervalSince1970
    private let volumeOptions = ["Low", "Medium", "High"]

    var body: some View {
        VStack(alignment: .leading, spacing: 25) {
            Text("Your Hearing History")
                .foregroundColor(.white)
                .font(.largeTitle)
                .bold()

            VStack(alignment: .leading) {
                Text("What is your date of birth?")
                    .foregroundColor(.gray)
                
                DatePicker(
                    "",
                    selection: Binding(
                        get: { Date(timeIntervalSince1970: birthDate) },
                        set: { birthDate = $0.timeIntervalSince1970 }
                        ),
                    in: ...Date(),
                    displayedComponents: .date
                )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .colorScheme(.dark)
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
            }
            
            VStack(alignment: .leading) {
                Text("How long have you worn earphones?")
                    .foregroundColor(.gray)

                HStack {
                    Button(action: {
                        if yearsWearing > 0 { yearsWearing -= 1 }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.mint)
                    }

                    Text("\(yearsWearing)")
                        .bold()
                        .frame(minWidth: 60)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)

                    Button(action: {
                        if yearsWearing < 50 { yearsWearing += 1 }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.mint)
                    }

                    Spacer()

                    Text("years")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
            }

            VStack(alignment: .leading) {
                Text("How many hours per day on average?")
                    .foregroundColor(.gray)

                HStack {
                    Button(action: {
                        if hoursPerDay > 0 { hoursPerDay -= 1 }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.mint)
                    }

                    Text("\(hoursPerDay)")
                        .bold()
                        .frame(minWidth: 60)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)

                    Button(action: {
                        if hoursPerDay < 24 { hoursPerDay += 1 }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.mint)
                    }

                    Spacer()

                    Text("hours")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
            }

            VStack(alignment: .leading) {
                Text("What volume level do you usually listen at?")
                    .foregroundColor(.gray)

                HStack {
                    ForEach(volumeOptions, id: \.self) { option in
                        CapsuleButton(
                            title: option,
                            isSelected: volumeLevel == option
                        )
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                volumeLevel = option
                            }
                        }
                    }
                }
            }

            Spacer()

            Button(action: { hasCompletedOnboarding = true }) {
                Text("Next →")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.mint)
                    .foregroundColor(.black)
                    .cornerRadius(15)
            }
        }
        .padding()
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
}
