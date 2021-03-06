@testable import KsApi
@testable import Library
import Prelude
import ReactiveExtensions
import ReactiveExtensions_TestHelpers
import ReactiveSwift
import XCTest

internal final class ActivitySampleBackingCellViewModelTests: TestCase {
  internal let vm = ActivitySampleBackingCellViewModel()
  internal let backingTitleText = TestObserver<String, Never>()
  internal let backerImage = TestObserver<String?, Never>()
  internal let goToActivity = TestObserver<Void, Never>()

  internal override func setUp() {
    super.setUp()
    self.vm.outputs.backingTitleText.map { $0.string }.observe(self.backingTitleText.observer)
    self.vm.outputs.backerImageURL.map { $0?.absoluteString }.observe(self.backerImage.observer)
    self.vm.outputs.goToActivity.observe(self.goToActivity.observer)
  }

  func testBackingDataEmits() {
    let backer = User.template
      |> \.name .~ "Best Friend"
      |> \.avatar.medium .~ "http://coolpic.com/cool.png"

    let creator = User.template
      |> \.name .~ "Super Cool Creator"

    let project = .template
      |> Project.lens.name .~ "Super Sweet Project Name"
      |> Project.lens.creator .~ creator

    let activity = .template
      |> Activity.lens.category .~ .backing
      |> Activity.lens.project .~ project
      |> Activity.lens.user .~ backer

    self.vm.inputs.configureWith(activity: activity)

    self.backingTitleText.assertValues(
      ["Best Friend backed Super Sweet Project Name by Super Cool Creator"],
      "Attributed backing string emits."
    )
    self.backerImage.assertValues([backer.avatar.medium])
  }

  func testGoToActivity() {
    let activity = Activity.template

    self.vm.inputs.configureWith(activity: activity)
    self.vm.inputs.seeAllActivityTapped()

    self.goToActivity.assertValueCount(1)
  }
}
