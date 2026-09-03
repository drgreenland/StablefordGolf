import SwiftUI

struct CourseListView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingAddCourse = false

    var body: some View {
        List {
            ForEach(dataManager.courses) { course in
                NavigationLink(value: CourseNavDest.edit(course)) {
                    CourseRow(course: course)
                }
            }
            .onDelete(perform: dataManager.deleteCourse)
        }
        .navigationTitle("Courses")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showingAddCourse = true } label: { Image(systemName: "plus") }
            }
            ToolbarItem(placement: .navigationBarLeading) { EditButton() }
        }
        .sheet(isPresented: $showingAddCourse) {
            CourseFormView(course: nil)
        }
        .navigationDestination(for: CourseNavDest.self) { dest in
            if case .edit(let course) = dest {
                CourseFormView(course: course)
            }
        }
    }
}

enum CourseNavDest: Hashable {
    case edit(Course)
}

struct CourseRow: View {
    let course: Course
    var body: some View {
        VStack(alignment: .leading) {
            Text(course.name).font(.headline)
            Text("\(course.holes.count) holes · \(course.availableTees.count) tee(s)")
                .font(.caption).foregroundColor(.secondary)
        }
    }
}
