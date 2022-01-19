import UIKit

class ProductListViewController: UIViewController {

    private enum Section: Hashable {
        case list
        case grid
    }
    
    typealias page = ProductListAsk.Response.Page
    private var dataStorage: PageDataStorable = ListDataStorager()
    private lazy var listCollectionView = UICollectionView(
        frame: view.bounds,
        collectionViewLayout: makeListLayout()
    )
    private lazy var gridCollectionView = UICollectionView(
        frame: view.bounds,
        collectionViewLayout: makeGridLayout()
    )
    var collectionViews: [UICollectionView] = []
    private var listDataSource: UICollectionViewDiffableDataSource<Section, page>?
    private var gridDataSource: UICollectionViewDiffableDataSource<Section,page>?
    private var dataSources: [UICollectionViewDiffableDataSource<Section,page>] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchProductList()
        configureMainView()
        configureDataSources()
        configureCollectionView()
        
    }
    
    private func configureMainView() {
        view.backgroundColor = .white
        configureNavigationItems()
        segmentedControl.addTarget(self, action: #selector(touchUpListButton), for: .valueChanged)
    }
    
    private func configureDataSources() {
        configureListDataSource()
        configureGridDataSource()
        guard let listDataSource = listDataSource, let gridDataSource = gridDataSource else {
            return
        }
        dataSources.append(listDataSource)
        dataSources.append(gridDataSource)
    }
    
    private func configureCollectionView() {
        collectionViews.append(listCollectionView)
        collectionViews.append(gridCollectionView)
        view.addSubview(listCollectionView)
        view.addSubview(gridCollectionView)
        gridCollectionView.isHidden = true
    }

    private func fetchProductList() {
    self.dataStorage.updateStorage {
        DispatchQueue.main.async {
        let section: Section = self.segmentedControl.selectedSegmentIndex == 0 ? .list : .grid
        self.applyListSnapShot(section: section)
        self.applyGridSnapShot(section: section)
                }
            }
}
    private func configureNavigationItems() {
        let bounds = CGRect(
            x: 0,
            y: 0,
            width: view.bounds.width * 0.4 ,
            height: segmentedControl.bounds.height
        )
        segmentedControl.bounds = bounds
        navigationItem.titleView = segmentedControl
    }
    
    private func makeGridLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(CollectionView.Grid.Group.fractionalHeight)
        )
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            subitem: item,
            count: CollectionView.Grid.Group.itemsPerGroup
        )
        group.interItemSpacing = .fixed(CollectionView.Grid.Item.spacing)
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = CollectionView.Grid.Item.spacing
        
        let layout = UICollectionViewCompositionalLayout(section: section)
        return layout
    }
    
    private func makeListLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { (section, layoutEnvironment) in
            let appearance = UICollectionLayoutListConfiguration.Appearance.plain
            let configuration = UICollectionLayoutListConfiguration(appearance: appearance)
            
            return NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: layoutEnvironment)
        }
    }
    
    private func configureListDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<CollectionViewListCell,page> {
            (cell, indexPath, item) in
        }
      
        listDataSource = UICollectionViewDiffableDataSource<Section, page>(collectionView: listCollectionView) {
            (collectionView, indexPath, item) -> UICollectionViewCell? in
            let cell = collectionView.dequeueConfiguredReusableCell(
                using: cellRegistration,
                for: indexPath,
                item: item
            )
            cell.updateAllComponents(from: item)
            cell.accessories = [.disclosureIndicator()]
            
            return cell
        }
    }
    
    private func configureGridDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<CollectionViewGridCell, page> {
            (cell, indexPath, item) in
            cell.layer.borderColor = CollectionView.Grid.Item.borderColor
            cell.layer.borderWidth = CollectionView.Grid.Item.borderWidth
            cell.layer.cornerRadius = CollectionView.Grid.Item.cornerRadius
        }
      
        gridDataSource = UICollectionViewDiffableDataSource<Section, page>(collectionView: gridCollectionView) {
            (collectionView, indexPath, item) -> UICollectionViewCell? in
            let cell = collectionView.dequeueConfiguredReusableCell(
                using: cellRegistration,
                for: indexPath,
                item: item
            )
            cell.updateAllComponents(from: item)
            return cell 
        }
    }
    
    private func applyListSnapShot(section: Section) {
        guard let storage = dataStorage.storage else {
            return
        }

        var snapshot = NSDiffableDataSourceSnapshot<Section, page>()
        snapshot.appendSections([section])
        snapshot.appendItems(storage.pages)
        self.listDataSource?.apply(snapshot, animatingDifferences: false)
    }
    
    private func applyGridSnapShot(section: Section) {
        guard let storage = dataStorage.storage else {
            return
        }

        var snapshot = NSDiffableDataSourceSnapshot<Section, ProductListAsk.Response.Page>()
        snapshot.appendSections([section])
        snapshot.appendItems(storage.pages)
        self.gridDataSource?.apply(snapshot, animatingDifferences: false)
    }
    
    private let segmentedControl: UISegmentedControl = {
        let items: [String] = ["List","Grid"]
        var segmented = UISegmentedControl(items: items)
        segmented.layer.cornerRadius = SegmentedControl.cornerRadius
        segmented.layer.borderWidth = SegmentedControl.borderWidth
        segmented.layer.borderColor = SegmentedControl.borderColor
        segmented.selectedSegmentTintColor = SegmentedControl.selectedSegmentTintColor
        segmented.backgroundColor = SegmentedControl.backgroundColor
        let selectedAttribute: [NSAttributedString.Key : Any] = [.foregroundColor : SegmentedControl.selectedColor]
        segmented.setTitleTextAttributes(selectedAttribute, for: .selected)
        let normalAttribute: [NSAttributedString.Key : Any] = [.foregroundColor : SegmentedControl.normalColor]
        segmented.setTitleTextAttributes(normalAttribute, for: .normal)
        segmented.selectedSegmentIndex = SegmentedControl.defaultSelectedSegmentIndex
        return segmented
    }()
    

}

//MARK: - Segmented Control
extension ProductListViewController {
    @objc func touchUpListButton() {
        if segmentedControl.selectedSegmentIndex == 0 {
            listCollectionView.isHidden.toggle()
            gridCollectionView.isHidden.toggle()
            listCollectionView.becomeFirstResponder()
        } else if segmentedControl.selectedSegmentIndex == 1 {
            listCollectionView.isHidden.toggle()
            gridCollectionView.isHidden.toggle()
            gridCollectionView.becomeFirstResponder()
        }
    }
}

//MARK: - Layout 상수
extension ProductListViewController {
    enum CollectionView {
        enum Grid {
            enum Group {
                static let fractionalHeight = 0.3
                static let itemsPerGroup = 2
            }
            enum Item {
                static let spacing = 10.0
                static let borderColor = UIColor.systemGray.cgColor
                static let borderWidth = 1.0
                static let cornerRadius = 15.0
            }
        }
    }
    enum SegmentedControl {
        static let cornerRadius = 4.0
        static let borderWidth = 1.0
        static let borderColor = UIColor.systemBlue.cgColor
        static let selectedSegmentTintColor = UIColor.white
        static let backgroundColor = UIColor.systemBlue
        static let selectedColor = UIColor.systemBlue
        static let normalColor = UIColor.white
        static let defaultSelectedSegmentIndex = 0
    }
}

//MARK: - paging


