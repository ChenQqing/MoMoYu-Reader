import SwiftUI

struct ChapterListView: View {
    let chapters: [Chapter]
    @Binding var currentIndex: Int
    let onSelect: (Chapter) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("目录")
                    .font(.headline)
                Spacer()
                Text("\(currentIndex + 1)/\(chapters.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            // Chapter list
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(chapters.enumerated()), id: \.element.id) { idx, chapter in
                            Button(action: {
                                onSelect(chapter)
                                dismiss()
                            }) {
                                HStack(spacing: 6) {
                                    if idx == currentIndex {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 11))
                                            .foregroundColor(.accentColor)
                                    }
                                    Text(chapter.title)
                                        .font(.system(size: 12))
                                        .lineLimit(1)
                                        .foregroundColor(idx == currentIndex ? .accentColor : .primary)
                                    Spacer()
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .id(idx)
                        }
                    }
                }
                .onAppear {
                    proxy.scrollTo(currentIndex, anchor: .center)
                }
                .onChange(of: currentIndex) { newIdx in
                    withAnimation {
                        proxy.scrollTo(newIdx, anchor: .center)
                    }
                }
            }
        }
        .frame(width: 250, height: 400)
    }
}
