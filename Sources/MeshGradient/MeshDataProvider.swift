
public protocol MeshDataProvider {
	var grid: Grid<ControlPoint> { get }
}

public class StaticMeshDataProvider: MeshDataProvider {
    public var grid: Grid<ControlPoint>
	
    public init(grid: Grid<ControlPoint>) {
		self.grid = grid
	}
}
