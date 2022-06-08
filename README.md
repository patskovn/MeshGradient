# MeshGradient

Metal-based implementation of beautiful mesh gradient. Image worth thousands of words, so just let me show you.

![Mesh gradient gif](Files/mesh.gif)

## How to generate mesh

Small notes before I show you the code. This mesh is generated from the constants you provide. To create mesh you have to provide grid with `ControlPoint` matrix that *describe* your gradient (just like with other gradients, huh?):

* You need to provide `colors` for gradient - that is obvious, right?
* You need to provide `location`s of control points. Locations are in metal coordinate space - that one is a bit scarier. Relax, it is just values in -1...1
* You need to provide how *turbulent* your mesh is. This is `uTangent` and `vTangent` exists for.

Again, **don't be scared**. You have all the randomizers out of the box and they are pretty easy to use.

Now, to the code:

```swift
typealias MeshColor = SIMD3<Float>

// You can provide custom `locationRandomizer` and `turbulencyRandomizer` for advanced usage
var meshRandomizer = MeshRandomizer(colorRandomizer: MeshRandomizer.arrayBasedColorRandomizer(availableColors: meshColors))

private var meshColors: [simd_float3] {
 return [
  MeshRandomizer.randomColor(),
  MeshRandomizer.randomColor(),
  MeshRandomizer.randomColor(),
 ]
}

// This methods prepares the grid model that will be sent to metal for rendering
func generatePlainGrid(size: Int = 6) -> Grid<ControlPoint> {
  let preparationGrid = Grid<MeshColor>(repeating: .zero, width: size, height: size)
  
  // At first we create grid without randomisation. This is smooth mesh gradient without 
  // any turbulency and overlaps
  var result = MeshGenerator.generate(colorDistribution: preparationGrid)

  // And here we shuffle the grid using randomizer that we created
  for y in stride(from: 0, to: result.width, by: 1) {
   for x in stride(from: 0, to: result.height, by: 1) {
    meshRandomizer.locationRandomizer(&result[x, y].location, x, y, result.width, result.height)
    meshRandomizer.turbulencyRandomizer(&result[x, y].uTangent, x, y, result.width, result.height)
    meshRandomizer.turbulencyRandomizer(&result[x, y].vTangent, x, y, result.width, result.height)

    meshRandomizer.colorRandomizer(&result[x, y].color, result[x, y].color, x, y, result.width, result.height)
   }
  }

  return result
}

```

### SwiftUI

```swift
// If you want just show static grid without any animations
struct MyStaticGrid: View {
 var body: some View {
  MeshGradient(grid: generatePlainGrid())
 }
}

struct MyAnimatedGrid: View {

 // MeshRandomizer is a plain struct with just the functions. So you can dynamically change it!
 @State var meshRandomizer = MeshRandomizer(colorRandomizer: MeshRandomizer.arrayBasedColorRandomizer(availableColors: meshColors))

 var body: some View {
  MeshGradient(initialGrid: generatePlainGrid(), 
    		   animatorConfiguration: .init(animationSpeedRange: 2 ... 4, meshRandomizer: meshRandomizer)))
 }
}
```

### UIKit

Use `MTKView` and `MetalMeshRenderer`. I hope you have minimal knowledge in metal rendering. Good luck ;)
Check source code of SwiftUI `MeshGradient` implementation that just wraps `MTKView`.
