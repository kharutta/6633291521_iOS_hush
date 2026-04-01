import SwiftUI

struct InputField: View {
    var label: String
    var placeholder: String
    var body: some View {
        VStack(alignment: .leading) {
            Text(label).foregroundColor(.gray)
            TextField(placeholder, text: .constant(""))
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(10)
        }
    }
}

struct InsightRow: View {
    var color: Color
    var text: String
    var body: some View {
        HStack {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(text)
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
    }
}

struct StatBox: View {
    var label: String
    var value: String
    var valueColor: Color = .white
    
    var body: some View {
        VStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
            Text(value)
                .font(.title2)
                .bold()
                .foregroundStyle(valueColor)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

struct CapsuleButton: View {
    let title: String
    var isSelected: Bool = false
    
    var body: some View {
        Text(title)
            .font(.subheadline)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.white : Color.white.opacity(0.1))
            .foregroundColor(isSelected ? .black : .white)
            .cornerRadius(20)
    }
}

struct SessionRow: View {
    let title: String
    let sub: String
    let percent: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Circle().fill(Color.teal).frame(width: 8, height: 8)
                    Text(title).font(.body).bold()
                }
                Text(sub).font(.caption).foregroundColor(.gray)
            }
            Spacer()
            Text(percent).font(.body).bold()
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

struct StatRow: View {
    let label: String
    let value: String
    var valueColor: Color = .white
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value).bold().foregroundColor(valueColor)
        }
        .padding()
    }
}
