import SwiftUI
import SwiftData

struct ManualLogView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = ManualLogViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    Text("Log Session")
                        .font(.largeTitle)
                        .bold()

                    VStack(alignment: .leading) {
                        Text("device")
                            .foregroundColor(.gray)
                            .font(.caption)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(viewModel.devices, id: \.self) { device in
                                    CapsuleButton(
                                        title: device,
                                        isSelected: viewModel.selectedDevice == device
                                    )
                                    .onTapGesture {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            viewModel.selectedDevice = device
                                        }
                                    }
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading) {
                        Text("duration")
                            .foregroundColor(.gray)
                            .font(.caption)
                        HStack(spacing: 16) {
                            VStack(alignment: .leading) {
                                Text("start")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                DatePicker("", selection: $viewModel.startTime, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                                    .accentColor(.mint)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)

                            VStack(alignment: .leading) {
                                Text("end")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                DatePicker("", selection: $viewModel.endTime, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                                    .accentColor(.mint)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }

                    VStack(alignment: .leading) {
                        HStack {
                            Text("volume")
                                .foregroundColor(.gray)
                                .font(.caption)
                            Spacer()
                            Text(viewModel.volumeDisplay)
                                .bold()
                                .foregroundColor(viewModel.volumeColor)
                        }
                        Slider(value: $viewModel.volume, in: 40...120, step: 1)
                            .accentColor(viewModel.volumeColor)
                        HStack {
                            Text("40 dB")
                                .font(.caption2)
                                .foregroundColor(.gray)
                            Spacer()
                            Text("120 dB")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)

                    VStack(alignment: .leading) {
                        Text("activity")
                            .foregroundColor(.gray)
                            .font(.caption)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(viewModel.activities, id: \.self) { activity in
                                    CapsuleButton(
                                        title: activity,
                                        isSelected: viewModel.selectedActivity == activity
                                    )
                                    .onTapGesture {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            viewModel.selectedActivity = activity
                                        }
                                    }
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("summary")
                            .foregroundColor(.gray)
                            .font(.caption)

                        HStack {
                            Image(systemName: viewModel.deviceIcon)
                                .foregroundColor(.mint)
                            Text(viewModel.selectedDevice)
                            Spacer()
                            Text("\(viewModel.durationMinutes) min")
                                .bold()
                        }

                        HStack {
                            Image(systemName: viewModel.activityIcon)
                                .foregroundColor(.mint)
                            Text(viewModel.selectedActivity.capitalized)
                            Spacer()
                            Text(viewModel.volumeDisplay)
                                .bold()
                                .foregroundColor(viewModel.volumeColor)
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)

                    VStack {
                        if viewModel.showSuccess {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.mint)
                                Text("Session added!")
                                    .foregroundColor(.mint)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .cornerRadius(12)
                        } else {
                            Button(action: { viewModel.addSession(to: modelContext) }) {
                                Text("add session")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.mint)
                                    .foregroundColor(.black)
                                    .cornerRadius(15)
                            }
                            .padding(.bottom, 8)
                        }
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            viewModel.resetForm()
        }
    }
}
