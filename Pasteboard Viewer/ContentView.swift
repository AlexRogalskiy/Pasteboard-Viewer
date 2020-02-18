import SwiftUI
import Combine

struct ContentView: View {
	@ViewTimer(interval: 0.5, tolerance: 0.3) private var timer
	@State private var selectedPasteboard = Pasteboard.general
	@State private var selectedType: Pasteboard.PasteboardType?
	@State private var previousChangeCount: Int?

	// This is a workaround for a SwiftUI bug where it crashes in NSOutlineView if you change from 16 to 15 elements in the list. We work around that by clearing the list first if the count changed.
	@State private var previousTypeCount = 0
	var types: [Pasteboard.PasteboardType] {
		let types = self.selectedPasteboard.types

		DispatchQueue.main.async {
			self.previousTypeCount = types.count
		}

		return types.count != previousTypeCount ? [] : types
	}

	private func nilSelectedTypeIfNeeded() {
		if selectedPasteboard.nsPasteboard.changeCount != previousChangeCount {
			DispatchQueue.main.async {
				self.previousChangeCount = self.selectedPasteboard.nsPasteboard.changeCount
				self.selectedType = self.selectedPasteboard.types.first
			}
		}
	}

	private func setWindowTitle() {
		AppDelegate.shared.window.title = selectedType?.title ?? App.name
	}

	var body: some View {
		nilSelectedTypeIfNeeded()
		setWindowTitle()

		// TODO: Set the sidebar to not be collapsible when SwiftUI supports that.
		return NavigationView {
			VStack(alignment: .leading) {
				EnumPicker(
					"",
					enumCase: $selectedPasteboard.onChange { _ in
						self.selectedType = nil
					}
				) { pasteboard, _ in
					Text(pasteboard.nsPasteboard.presentableName)
				}
					.labelsHidden()
					.padding()
				List(selection: $selectedType) {
					// The `Divider` is a workaround for SwiftUI bug where the selection highlight for the first element in the list would dissapear in some cases when the view is updated, for example, when you copy something new to the pasteboard.
					Divider()
						.opacity(0)
					ForEach(types, id: \.self) {
						Text($0.title)
							.frame(maxWidth: .infinity, alignment: .leading)
					}
						// Works around the sidebar not getting focus at launch.
						.forceFocus()
				}
					.listStyle(SidebarListStyle())
					.padding(.top, -22) // Workaround for SwiftUI bug.
			}
				// TODO: Make this `minWidth: 180` when SwiftUI is able to persist the sidebar size.
				.frame(minWidth: 200, maxWidth: 300)
			PasteboardContentsView(
				pasteboard: self.selectedPasteboard,
				type: self.selectedType
			)
		}
			.frame(minWidth: 500, minHeight: 300)
	}
}

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView()
	}
}
