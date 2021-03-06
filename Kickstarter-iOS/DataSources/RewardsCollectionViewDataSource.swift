import Foundation
import KsApi
import Library
import Prelude
import UIKit

final class RewardsCollectionViewDataSource: ValueCellDataSource {
  func load(_ values: [(Project, Either<Reward, Backing>)]) {
    self.set(
      values: values,
      cellClass: RewardCell.self,
      inSection: 0
    )
  }

  override func configureCell(collectionCell cell: UICollectionViewCell, withValue value: Any) {
    switch (cell, value) {
    case let (cell as RewardCell, value as (Project, Either<Reward, Backing>)):
      cell.configureWith(value: value)
    default:
      assertionFailure("Unrecognized (cell, value) combo.")
    }
  }
}
