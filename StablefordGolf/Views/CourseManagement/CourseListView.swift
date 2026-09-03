import SwiftUI

struct CourseListView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingAddCourse = false
    @State private var editingCourse: Course? = nil

    var body: some View {
        List {
            ForEach(dataManager.courses) { course in
                Button {
                    editingCourse = course
                } label: {
                    CourseRow(course: course)
                }
                .foregroundColor(.primary)
            }
            .onDelete(perform: dataManager.deleteCourse)
        }
        .scrollContentBackground(.hidden)
        .background { AppColors.grassGradient.ignoresSafeArea() }
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
        .sheet(item: $editingCourse) { course in
            CourseFormView(course: course)
        }
    }
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
