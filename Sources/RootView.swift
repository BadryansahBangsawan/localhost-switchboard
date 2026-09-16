import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: SwitchboardStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: FunTheme.sectionSpacing) {
            ExtraSearchField(title: "Filter", prompt: "port or command", text: $store.filter)

            if let persistenceError = store.persistenceError {
                Label(persistenceError, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let errorMessage = store.errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if store.visibleListeners.isEmpty {
                if store.filter.isEmpty {
                    ExtraEmptyState(
                        title: "No listeners",
                        detail: "No listening TCP ports.",
                        actionTitle: "Refresh",
                        action: { store.refresh() }
                    )
                } else {
                    ExtraEmptyState(
                        title: "No matches",
                        detail: "No listeners for “\(store.filter)”.",
                        actionTitle: "Clear filter",
                        action: { store.filter = "" }
                    )
                }
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: FunTheme.innerSpacing) {
                        ForEach(store.visibleListeners) { listener in
                            ListenerRow(
                                listener: listener,
                                isPinned: store.pinnedPorts.contains(listener.port),
                                onOpen: { store.open(listener) },
                                onCopyURL: { store.copyURL(listener) },
                                onCopyKill: { store.copyKill9(listener) },
                                onKill: { store.killListener(listener) },
                                onPin: { store.togglePin(port: listener.port) }
                            )
                        }
                    }
                }
                .frame(maxHeight: 480)
            }

            ExtraSettingsFooter()
        }
        .animation(reduceMotion ? nil : FunTheme.spring, value: store.visibleListeners)
        .animation(reduceMotion ? nil : FunTheme.spring, value: store.filter)
        .animation(reduceMotion ? nil : FunTheme.spring, value: store.errorMessage)
        .funPanel()
    }
}

private struct ListenerRow: View {
    let listener: Listener
    let isPinned: Bool
    let onOpen: () -> Void
    let onCopyURL: () -> Void
    let onCopyKill: () -> Void
    let onKill: () -> Void
    let onPin: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(listener.port)")
                    .font(.system(.body, design: .monospaced))
                Text(listener.command)
                    .lineLimit(1)
                Spacer(minLength: 4)
                Button(action: onPin) {
                    Image(systemName: isPinned ? "pin.fill" : "pin")
                }
                .buttonStyle(.borderless)
                .help(isPinned ? "Unpin port" : "Pin port")
            }
            HStack(spacing: 8) {
                Text(listener.host)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text("pid \(listener.pid)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 8) {
                Button("Open", action: onOpen)
                Button("Copy URL", action: onCopyURL)
                Button("Kill", action: onKill)
                Button("kill -9", action: onCopyKill)
            }
            .controlSize(.small)
            .buttonStyle(.bordered)
        }
        .extraRowSurface()
        .contextMenu {
            Button("Open", action: onOpen)
            Button("Copy URL", action: onCopyURL)
            Button("Copy kill -9 \(listener.pid)", action: onCopyKill)
            Button("Kill", action: onKill)
            Button(isPinned ? "Unpin" : "Pin", action: onPin)
        }
    }
}
